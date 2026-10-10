import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// GPU and NPU load for the bar.
//  - GPU (xe driver): there is no unprivileged "percent busy" for the xe iGPU (intel_gpu_top
//    can't see it, per-process counters miss system services like Ollama, and gtidle never
//    leaves C0 here). So this is the GPU clock between its floor and ceiling: the GPU idles
//    at min_freq and ramps to max_freq under load. It tracks load, but it is not a true
//    utilization figure.
//  - NPU (intel_vpu driver): npu_busy_time_us is a running counter of busy microseconds, so
//    the percentage is its change between two samples over wall time (exact).
PluginComponent {
    id: root

    property real gpuPercent: -1
    property real npuPercent: -1
    property real lastNpuUs: -1
    property real lastSampleMs: 0

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

    function fmt(p) {
        return p < 0 ? "–" : Math.round(p) + "%";
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: Proc.runCommand("accelUsage.sample", ["sh", "-c", root.sampleCommand],
                                     (stdout, code) => root.applySample(stdout), 0)
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "memory"
                size: Theme.iconSize - 6
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "GPU " + root.fmt(root.gpuPercent) + "  NPU " + root.fmt(root.npuPercent)
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

            DankIcon {
                name: "memory"
                size: Theme.iconSize - 6
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: "G" + root.fmt(root.gpuPercent) + "\nN" + root.fmt(root.npuPercent)
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
