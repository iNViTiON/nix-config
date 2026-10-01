import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

// Mitch lock screen. Started by DMS (customPowerActionLock) through the `mitch-lock` wrapper.
// Locks first with a black surface and only then loads the wallpaper and the scene.
// Set MITCH_LOCK_WINDOW=1 to show the same content in a normal window for visual checks (it does not lock).
ShellRoot {
    id: root

    readonly property bool windowed: Quickshell.env("MITCH_LOCK_WINDOW") === "1"
    readonly property string home: Quickshell.env("HOME")
    readonly property double startedAt: Date.now()

    property real time: 0
    NumberAnimation on time { from: 0; to: 100000; duration: 100000000; loops: Animation.Infinite }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // DMS's own settings (the ones on its Lock Screen tab), so changing them there changes this lock screen too
    property var settings: ({})
    function opt(key, fallback) {
        const v = settings[key];
        return v === undefined || v === null ? fallback : v;
    }
    FileView {
        path: root.home + "/.config/DankMaterialShell/settings.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.settings = JSON.parse(text());
            } catch (e) {
                root.settings = {};
            }
        }
    }

    // the desktop wallpaper, read from DMS's own state when the lock starts
    property var wallpaperInfo: ({})
    property string weatherCoordinates: ""
    // DMS can keep one wallpaper per monitor, and separate dark and light ones; follow whichever it is using
    function wallpaperFor(screenName) {
        const d = wallpaperInfo;
        if (d.perMonitorWallpaper && screenName && d.monitorWallpapers && d.monitorWallpapers[screenName])
            return d.monitorWallpapers[screenName];
        return d.wallpaperPath || d.wallpaperPathDark || d.wallpaperPathLight || "";
    }
    FileView {
        path: root.home + "/.local/state/DankMaterialShell/session.json"
        printErrors: false
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.wallpaperInfo = d;
                root.weatherCoordinates = d.weatherCoordinates || "";
            } catch (e) {
                root.wallpaperInfo = ({});
            }
        }
    }

    // notifications that arrived since the lock started, counted from DMS's notification history
    property var newNotifications: []
    FileView {
        id: history
        path: root.home + "/.cache/DankMaterialShell/notification_history.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const list = JSON.parse(text()).notifications || [];
                root.newNotifications = list.filter(n => Number(n.timestamp) > root.startedAt);
            } catch (e) {
                root.newNotifications = [];
            }
        }
    }


    // ---- profile picture, status line, weather and power actions ----
    property string profileImage: ""
    property string statusText: ""
    property string weatherText: ""

    Process {
        command: ["mitch-lock-info", "profile"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.profileImage = text.trim() }
    }

    // battery, network, volume and bluetooth, refreshed every 15 seconds
    Process {
        id: statusProc
        command: ["mitch-lock-info", "status"]
        stdout: StdioCollector { onStreamFinished: root.parseStatus(text) }
    }
    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
    function parseStatus(raw) {
        const kv = {};
        raw.split("\n").forEach(line => {
            const i = line.indexOf("=");
            if (i > 0)
                kv[line.slice(0, i)] = line.slice(i + 1).trim();
        });
        const parts = [];
        if (kv.network) {
            const j = kv.network.indexOf(":");
            const type = kv.network.slice(0, j);
            parts.push(type === "wifi" ? "wifi " + kv.network.slice(j + 1) : "wired");
        }
        if (kv.bluetooth && kv.bluetooth.startsWith("on")) {
            const n = parseInt(kv.bluetooth.split(" ")[1] || "0");
            parts.push(n > 0 ? "bluetooth " + n : "bluetooth");
        }
        if (kv.volume) {
            const m = kv.volume.match(/([0-9.]+)/);
            parts.push(kv.volume.indexOf("MUTED") >= 0 ? "muted" : "vol " + Math.round((m ? parseFloat(m[1]) : 0) * 100) + "%");
        }
        if (kv.battery) {
            const b = kv.battery.split(" ");
            parts.push("battery " + b[0] + "%" + (b[1] === "Charging" ? " charging" : ""));
        }
        statusText = parts.join("   ");
    }

    // weather from Open-Meteo, like DMS: location from DMS (detected or the fixed one in its session state)
    function weatherCondition(code) {
        if (code === 0) return "clear";
        if (code <= 2) return "partly cloudy";
        if (code === 3) return "overcast";
        if (code === 45 || code === 48) return "fog";
        if (code >= 51 && code <= 57) return "drizzle";
        if (code >= 61 && code <= 67) return "rain";
        if (code >= 71 && code <= 77) return "snow";
        if (code >= 80 && code <= 82) return "showers";
        if (code === 85 || code === 86) return "snow showers";
        if (code >= 95) return "thunderstorm";
        return "";
    }
    function fetchWeather(lat, lon) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200)
                return;
            try {
                const cur = JSON.parse(xhr.responseText).current;
                const fahrenheit = opt("useFahrenheit", false);
                const t = Math.round(fahrenheit ? cur.temperature_2m * 9 / 5 + 32 : cur.temperature_2m);
                weatherText = t + "°" + (fahrenheit ? "F" : "") + " " + weatherCondition(cur.weather_code);
            } catch (e) {
                // keep whatever was shown before
            }
        };
        xhr.open("GET", "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + "&current=temperature_2m,weather_code&timezone=auto");
        xhr.send();
    }
    Process {
        id: locationProc
        command: ["mitch-lock-info", "location"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text.trim()).result;
                    if (r && (r.latitude || r.longitude))
                        root.fetchWeather(r.latitude, r.longitude);
                } catch (e) {
                    // no location: no weather line
                }
            }
        }
    }
    function refreshWeather() {
        if (!opt("lockScreenShowWeather", true) || !opt("weatherEnabled", true))
            return;
        if (opt("useAutoLocation", false)) {
            locationProc.running = true;
        } else {
            const c = weatherCoordinates.split(",");
            if (c.length === 2)
                fetchWeather(parseFloat(c[0]), parseFloat(c[1]));
        }
    }
    // settings and session state load a moment after start; refresh when they do, then every 15 minutes
    Timer { id: weatherSoon; interval: 600; onTriggered: root.refreshWeather() }
    onSettingsChanged: weatherSoon.restart()
    onWeatherCoordinatesChanged: weatherSoon.restart()
    Timer { interval: 900000; running: true; repeat: true; onTriggered: root.refreshWeather() }

    // power actions use DMS's custom commands when it has them, otherwise systemctl
    Process { id: powerProc }
    function power(kind) {
        const defaults = {
            suspend: ["customPowerActionSuspend", "systemctl suspend"],
            hibernate: ["customPowerActionHibernate", "systemctl hibernate"],
            reboot: ["customPowerActionReboot", "systemctl reboot"],
            poweroff: ["customPowerActionPowerOff", "systemctl poweroff"]
        };
        const d = defaults[kind];
        if (!d)
            return;
        const custom = opt(d[0], "");
        powerProc.command = ["sh", "-c", custom !== "" ? custom : d[1]];
        powerProc.running = true;
    }

    // the player that is playing, else the first one
    readonly property var player: {
        const list = Mpris.players.values;
        for (let i = 0; i < list.length; i++)
            if (list[i].isPlaying)
                return list[i];
        return list.length > 0 ? list[0] : null;
    }

    Auth {
        id: authCtl
        fprintEnabled: root.opt("enableFprint", false)
        onSucceeded: {
            // logind has to hear about it, or DMS keeps thinking the session is locked
            unlockCall.running = true;
            quitTimer.start();
        }
    }
    Process { id: unlockCall; command: ["loginctl", "unlock-session"] }
    Timer {
        id: quitTimer
        interval: 250
        onTriggered: {
            lock.locked = false;
            Qt.quit();
        }
    }

    // DMS's "turn monitors off on lock": niri only here; it wakes them again on any input
    Process { id: monitorsOff; command: ["niri", "msg", "action", "power-off-monitors"] }
    Timer {
        interval: 5000
        running: !root.windowed && root.opt("lockScreenPowerOffMonitorsOnLock", false) && Quickshell.env("NIRI_SOCKET") !== ""
        onTriggered: monitorsOff.running = true
    }

    Component {
        id: viewComponent
        LockView {
            auth: authCtl
            time: root.time
            now: clock.date
            wallpaper: root.wallpaperFor(screenName)
            player: root.player
            newNotifications: root.newNotifications
            showTime: root.opt("lockScreenShowTime", true)
            showDate: root.opt("lockScreenShowDate", true)
            showMedia: root.opt("lockScreenShowMediaPlayer", true)
            notificationMode: root.opt("lockScreenNotificationMode", 1)
            clockStyle: root.opt("lockScreenClockStyle", "horizontal")
            clockFormat: root.opt("clockFormat", "")
            showSeconds: root.opt("showSeconds", false)
            dateFormat: root.opt("lockDateFormat", "")
            localeName: (Quickshell.env("LC_ALL") || Quickshell.env("LC_TIME") || Quickshell.env("LANG") || "").split(".")[0]
            showPower: root.opt("lockScreenShowPowerActions", true)
            showProfile: root.opt("lockScreenShowProfileImage", true)
            showSystemIcons: root.opt("lockScreenShowSystemIcons", true)
            showWeather: root.opt("lockScreenShowWeather", true)
            statusText: root.statusText
            weatherText: root.weatherText
            profileImage: root.profileImage
            userName: Quickshell.env("USER")
            onPowerRequested: kind => root.power(kind)
            secure: lock.secure
        }
    }

    WlSessionLock {
        id: lock
        locked: !root.windowed
        WlSessionLockSurface {
            color: "#000000"
            id: surface
            Loader {
                anchors.fill: parent
                focus: true
                sourceComponent: viewComponent
                onLoaded: item.screenName = Qt.binding(() => surface.screen ? surface.screen.name : "")
            }
        }
    }

    Loader {
        active: root.windowed
        sourceComponent: FloatingWindow {
            implicitWidth: 1280
            implicitHeight: 800
            color: "#000000"
            Loader { anchors.fill: parent; focus: true; sourceComponent: viewComponent }
        }
    }
}
