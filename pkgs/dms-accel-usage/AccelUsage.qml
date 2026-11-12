import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

// GPU and NPU load for the bar, and a popout (click the pill) listing what uses them.
//  - GPU (xe driver): there is no unprivileged "percent busy" for the xe iGPU (intel_gpu_top
//    can't see it and gtidle never leaves C0 here). So the bar shows the GPU clock between its
//    floor and ceiling: the GPU idles at min_freq and ramps to max_freq under load. It tracks
//    load, but it is not a true utilization figure.
//  - NPU (intel_vpu driver): npu_busy_time_us is a running counter of busy microseconds, so
//    the percentage is its change between two samples over wall time (exact).
//  - Popout: procs.sh reads the DRM fdinfo of every process of this user. xe gives memory held
//    through the GPU driver and per-engine busy cycles (busy % = change in a client's cycles over
//    the change in the engine's total cycles); intel_vpu gives memory only. Processes of other
//    users are invisible, which is the case for Ollama, so its loaded models come from /api/ps.
PluginComponent {
    id: root

    property real gpuPercent: -1
    property real npuPercent: -1
    property real lastNpuUs: -1
    property real lastSampleMs: 0

    // Popout data, refreshed every 2 s only while the popout is open.
    property bool popoutOpen: false
    property var gpuRows: []
    property var npuRows: []
    property real npuMemBytes: -1
    property var ollamaModels: []
    property var previousCycles: ({})

    // From the plugin's settings page (AccelUsageSettings.qml).
    readonly property string labelStyle: pluginData.labelStyle ?? "full"
    readonly property bool showIcon: pluginData.showIcon ?? true
    readonly property string ollamaUrl: pluginData.ollamaUrl ?? "http://127.0.0.1:11435"

    popoutWidth: 440
    popoutHeight: 560

    readonly property string procsScript: Qt.resolvedUrl("procs.sh").toString().replace(/^file:\/\//, "")
    readonly property var engines: [
        { key: "rcs", name: "render" },
        { key: "ccs", name: "compute" },
        { key: "vcs", name: "video" },
        { key: "vecs", name: "video enhance" },
        { key: "bcs", name: "copy" }
    ]

    readonly property string sampleCommand:
        "for f in /sys/class/drm/card*/device/tile0/gt0/freq0/act_freq " +
        "/sys/class/drm/card*/device/tile0/gt0/freq0/min_freq " +
        "/sys/class/drm/card*/device/tile0/gt0/freq0/max_freq " +
        "/sys/class/accel/accel*/device/npu_busy_time_us; do " +
        "[ -r \"$f\" ] && printf '%s %s\\n' \"${f##*/}\" \"$(cat \"$f\")\"; done"

    function clamp(v) {
        return Math.max(0, Math.min(100, v));
    }

    function applySample(stdout) {
        const now = Date.now();
        let act = -1;
        let minF = -1;
        let maxF = -1;
        let npuUs = -1;
        for (const line of stdout.split("\n")) {
            const parts = line.trim().split(" ");
            if (parts.length < 2)
                continue;
            if (parts[0] === "act_freq")
                act = Number(parts[1]);
            else if (parts[0] === "min_freq")
                minF = Number(parts[1]);
            else if (parts[0] === "max_freq")
                maxF = Number(parts[1]);
            else if (parts[0] === "npu_busy_time_us")
                npuUs = Number(parts[1]);
        }
        if (act >= 0 && maxF > minF)
            gpuPercent = clamp((act - minF) * 100 / (maxF - minF));
        const elapsedMs = now - lastSampleMs;
        if (lastSampleMs > 0 && elapsedMs > 0) {
            if (npuUs >= 0 && lastNpuUs >= 0)
                npuPercent = clamp((npuUs - lastNpuUs) / 10 / elapsedMs);
        }
        lastNpuUs = npuUs;
        lastSampleMs = now;
    }

    // procs.sh output -> gpuRows / npuRows. One row per process: memory summed over its clients,
    // busy % per engine summed over its clients (needs a previous sample, so the first one shows none).
    function applyProcesses(stdout) {
        const gpu = {};
        const npu = {};
        const seen = {};
        const previous = previousCycles;
        const fresh = {};
        let memBytes = -1;
        for (const line of stdout.split("\n")) {
            if (line === "")
                continue;
            const f = line.split("\t");
            if (f[0] === "NPUMEM") {
                memBytes = Number(f[1]);
                continue;
            }
            if (f.length < 16)
                continue;
            const driver = f[0];
            const pid = f[1];
            const target = driver === "xe" ? gpu : (driver === "intel_vpu" ? npu : null);
            if (!target)
                continue;
            if (!target[pid])
                target[pid] = { pid: pid, name: f[2], residentKiB: 0, totalKiB: 0, busy: [0, 0, 0, 0, 0], hasBusy: false };
            const row = target[pid];
            row.residentKiB += Number(f[4]);
            row.totalKiB += Number(f[5]);
            if (driver !== "xe")
                continue;
            const clientKey = pid + "/" + f[3];
            const cycles = [];
            for (let i = 0; i < 5; i++)
                cycles.push([Number(f[6 + i * 2]), Number(f[7 + i * 2])]);
            fresh[clientKey] = cycles;
            const before = previous[clientKey];
            if (before) {
                row.hasBusy = true;
                for (let i = 0; i < 5; i++) {
                    const dTotal = cycles[i][1] - before[i][1];
                    if (dTotal > 0)
                        row.busy[i] += (cycles[i][0] - before[i][0]) * 100 / dTotal;
                }
            }
        }
        previousCycles = fresh;
        npuMemBytes = memBytes;

        const finish = function(map, withBusy) {
            const rows = [];
            for (const pid in map) {
                const r = map[pid];
                let top = 0;
                for (let i = 1; i < 5; i++)
                    if (r.busy[i] > r.busy[top])
                        top = i;
                r.busyPercent = withBusy && r.hasBusy ? clamp(r.busy[top]) : -1;
                r.busyEngine = engines[top].name;
                if (r.residentKiB > 0 || r.busyPercent >= 0.5)
                    rows.push(r);
            }
            rows.sort((a, b) => b.residentKiB - a.residentKiB);
            return rows;
        };
        gpuRows = finish(gpu, true);
        npuRows = finish(npu, false);
    }

    function applyOllama(text) {
        let models = [];
        try {
            models = JSON.parse(text).models || [];
        } catch (e) {
            models = [];
        }
        ollamaModels = models;
    }

    function fetchOllama() {
        const xhr = new XMLHttpRequest();
        xhr.timeout = 1500;
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            applyOllama(xhr.status === 200 ? xhr.responseText : "");
        };
        xhr.open("GET", ollamaUrl.replace(/\/+$/, "") + "/api/ps");
        xhr.send();
    }

    function sampleProcesses() {
        Proc.runCommand("accelUsage.procs", ["sh", procsScript],
                        (stdout, code) => root.applyProcesses(stdout), 0);
        fetchOllama();
    }

    onPopoutOpenChanged: {
        if (!popoutOpen) {
            previousCycles = {};
            gpuRows = [];
            npuRows = [];
            ollamaModels = [];
        }
    }

    function fmtKiB(kib) {
        if (kib >= 1048576)
            return (kib / 1048576).toFixed(1) + " GB";
        if (kib >= 1024)
            return Math.round(kib / 1024) + " MB";
        return Math.round(kib) + " KB";
    }

    function fmt(p) {
        return p < 0 ? "–" : Math.round(p) + "%";
    }

    function fmtBusy(row) {
        return row.busyPercent < 0 ? "–" : Math.round(row.busyPercent) + "% " + row.busyEngine;
    }

    function sumKiB(rows) {
        let total = 0;
        for (const r of rows)
            total += r.residentKiB;
        return total;
    }

    // full: "GPU 12%  NPU 0%", short: "G 12%  N 0%", none: "12% · 0%" (GPU first).
    function label(gpu, npu, separator) {
        if (labelStyle === "none")
            return fmt(gpu) + separator + fmt(npu);
        const g = labelStyle === "short" ? "G " : "GPU ";
        const n = labelStyle === "short" ? "N " : "NPU ";
        return g + fmt(gpu) + separator + n + fmt(npu);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: Proc.runCommand("accelUsage.sample", ["sh", "-c", root.sampleCommand],
                                     (stdout, code) => root.applySample(stdout), 0)
    }

    Timer {
        interval: 2000
        running: root.popoutOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sampleProcesses()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                visible: root.showIcon
                name: "memory"
                size: Theme.iconSize - 6
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.label(root.gpuPercent, root.npuPercent, root.labelStyle === "none" ? " · " : "  ")
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DIcon {
                visible: root.showIcon
                name: "memory"
                size: Theme.iconSize - 6
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.labelStyle === "none" ? root.fmt(root.gpuPercent) + "\n" + root.fmt(root.npuPercent)
                                                 : "G" + root.fmt(root.gpuPercent) + "\nN" + root.fmt(root.npuPercent)
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: parent ? parent.width : 0
            headerText: "GPU and NPU"
            detailsText: "What uses them, and the memory they hold"
            showCloseButton: true

            property var parentPopout: null

            Connections {
                target: popout.parentPopout
                ignoreUnknownSignals: true
                function onShouldBeVisibleChanged() {
                    root.popoutOpen = popout.parentPopout.shouldBeVisible;
                }
            }

            Component.onCompleted: root.popoutOpen = true
            Component.onDestruction: root.popoutOpen = false

            DFlickable {
                width: parent.width
                height: Math.min(contentHeight, root.popoutHeight - popout.headerHeight - popout.detailsHeight - Theme.spacingM)
                contentHeight: body.implicitHeight
                contentWidth: width
                clip: true

                Column {
                    id: body
                    width: parent.width
                    spacing: Theme.spacingM

                    // GPU first, like the bar.
                    StyledRect {
                        width: parent.width
                        height: gpuColumn.implicitHeight + Theme.spacingM * 2
                        color: Theme.surfaceContainerHigh

                        Column {
                            id: gpuColumn
                            x: Theme.spacingM
                            y: Theme.spacingM
                            width: parent.width - Theme.spacingM * 2
                            spacing: Theme.spacingXS

                            SectionHeader {
                                title: "GPU"
                                load: root.fmt(root.gpuPercent)
                                memory: root.fmtKiB(root.sumKiB(root.gpuRows)) + " held"
                            }
                            Repeater {
                                model: root.gpuRows
                                delegate: ProcessRow {
                                    required property var modelData
                                    name: modelData.name + "  (" + modelData.pid + ")"
                                    memory: root.fmtKiB(modelData.residentKiB)
                                    busy: root.fmtBusy(modelData)
                                }
                            }
                            StyledText {
                                visible: root.gpuRows.length === 0
                                text: "Reading…"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                            Repeater {
                                model: root.ollamaModels
                                delegate: ProcessRow {
                                    required property var modelData
                                    name: "ollama  " + modelData.name
                                    memory: root.fmtKiB((modelData.size ?? 0) / 1024)
                                    busy: (modelData.size_vram ?? 0) > 0 ? root.fmtKiB(modelData.size_vram / 1024) + " in GPU" : "in RAM"
                                }
                            }
                            StyledText {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "Memory is what a process holds through the GPU driver (shared system RAM), not its normal RAM. Busy % is the busiest engine since the last update. Ollama runs as another user, so its models come from its API and have no busy %."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: npuColumn.implicitHeight + Theme.spacingM * 2
                        color: Theme.surfaceContainerHigh

                        Column {
                            id: npuColumn
                            x: Theme.spacingM
                            y: Theme.spacingM
                            width: parent.width - Theme.spacingM * 2
                            spacing: Theme.spacingXS

                            SectionHeader {
                                title: "NPU"
                                load: root.fmt(root.npuPercent)
                                memory: root.npuMemBytes >= 0 ? root.fmtKiB(root.npuMemBytes / 1024) + " in use" : ""
                            }
                            Repeater {
                                model: root.npuRows
                                delegate: ProcessRow {
                                    required property var modelData
                                    name: modelData.name + "  (" + modelData.pid + ")"
                                    memory: root.fmtKiB(modelData.residentKiB)
                                    busy: ""
                                }
                            }
                            StyledText {
                                visible: root.npuRows.length === 0
                                text: "Nothing is using the NPU"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                            StyledText {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: "The NPU reports busy time for the whole device only, so processes show memory without a busy %."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }
        }
    }
}
