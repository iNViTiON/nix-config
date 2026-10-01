import QtQuick
import Quickshell
import Quickshell.Services.Pam

// Password and fingerprint unlock. Two PAM contexts run side by side so a slow fingerprint wait never blocks
// the password prompt; whichever succeeds first unlocks.
Scope {
    id: auth

    property string buffer: ""
    property string message: ""
    property bool isError: false
    readonly property bool busy: passwd.active
    property bool done: false
    property bool fprintEnabled: false

    readonly property string pamDir: Quickshell.env("MITCH_PAM_DIR") || "/etc/pam.d"

    signal succeeded
    signal failed

    function submit() {
        if (done || passwd.active)
            return;
        passwd.start();
    }

    function finish() {
        if (done)
            return;
        done = true;
        passwd.abort();
        fprint.abort();
        succeeded();
    }

    PamContext {
        id: passwd
        config: "mitch-lock"
        configDirectory: auth.pamDir

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(auth.buffer);
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                auth.finish();
                return;
            }
            auth.buffer = "";
            auth.isError = true;
            auth.message = result === PamResult.Error ? "something went wrong, try again" : "that didn't work, try again";
            auth.failed();
        }
    }

    PamContext {
        id: fprint
        property int errors: 0
        config: "mitch-lock-fprint"
        configDirectory: auth.pamDir

        onMessageChanged: {
            if (message.length > 0 && !auth.isError) {
                auth.message = message;
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                auth.finish();
            } else if (result === PamResult.Error) {
                // no reader, or fprintd not ready yet: try a few more times, then give up quietly
                errors++;
                if (errors < 5)
                    retry.restart();
            } else {
                retry.restart();
            }
        }
    }

    Timer {
        id: retry
        interval: 1200
        onTriggered: if (!auth.done && auth.fprintEnabled) fprint.start()
    }

    // fingerprint follows DMS's "enable fingerprint" setting, which is read a moment after startup
    onFprintEnabledChanged: {
        if (fprintEnabled && !done && !fprint.active) {
            fprint.errors = 0;
            fprint.start();
        } else if (!fprintEnabled) {
            fprint.abort();
        }
    }
}
