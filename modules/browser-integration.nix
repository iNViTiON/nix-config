# Browser native-messaging hosts for Chromium-based browsers (Vivaldi reads
# /etc/chromium/native-messaging-hosts):
# KDE Plasma browser integration and the Bitwarden desktop bridge.
{ pkgs, pkgs-unstable, ... }:
{
  environment.etc."chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
    "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
  environment.etc."chromium/native-messaging-hosts/com.8bit.bitwarden.json".text = builtins.toJSON {
    name = "com.8bit.bitwarden";
    description = "Bitwarden desktop <-> browser bridge";
    # NOTE: carried over as-is: the proxy comes from unstable, while the installed
    # bitwarden-desktop app (../home/hisoft/packages.nix) is the stable one.
    path = "${pkgs-unstable.bitwarden-desktop}/lib/bitwarden/desktop_proxy";
    type = "stdio";
    allowed_origins = [
      "chrome-extension://nngceckbapebfimnlniiiahkandclblb/"
      "chrome-extension://hccnnhgbibccigepcmlgppchkpfdophk/"
      "chrome-extension://jbkfoedolllekgbhcbcoahefnbanhhlh/"
      "chrome-extension://ccnckbpmaceehanjmeomladnmlffdjgn/"
    ];
  };
  system.activationScripts.vivaldiBitwardenNativeMessaging = {
    text = ''
      USER_HOME=$(eval echo ~hisoft)
      SRC="$USER_HOME/.config/chromium/NativeMessagingHosts/com.8bit.bitwarden.json"
      DEST="$USER_HOME/.config/vivaldi/NativeMessagingHosts/com.8bit.bitwarden.json"

      mkdir -p "$(dirname "$DEST")"

      # Remove stale symlink or wrong file, then relink
      if [ ! -L "$DEST" ] || [ "$(readlink "$DEST")" != "$SRC" ]; then
        ln -sf "$SRC" "$DEST"
      fi
    '';
  };
}
