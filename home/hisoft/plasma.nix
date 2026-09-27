# KDE Plasma (Wayland) tweaks.
{ pkgs, ... }:
{
  # Stop the "allow remote control?" dialog every time KDE Connect's remote input
  # starts. xdg-desktop-portal-kde skips the RemoteDesktop dialog for apps marked "yes"
  # in the permission-store table `kde-authorized`, key `remote-desktop`
  # (isAppMegaAuthorized in the portal's remotedesktop.cpp). This writes that entry at
  # every login; it is idempotent and stored in ~/.local/share/flatpak/db/kde-authorized.
  # Revoke: remove this service, then run
  #   busctl --user call org.freedesktop.impl.portal.PermissionStore \
  #     /org/freedesktop/impl/portal/PermissionStore \
  #     org.freedesktop.impl.portal.PermissionStore DeletePermission sss \
  #     kde-authorized remote-desktop org.kde.kdeconnect.daemon
  systemd.user.services.kdeconnect-remote-desktop-permission = {
    Unit = {
      Description = "Pre-authorize KDE Connect for the RemoteDesktop portal";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.systemd}/bin/busctl --user call"
        "org.freedesktop.impl.portal.PermissionStore"
        "/org/freedesktop/impl/portal/PermissionStore"
        "org.freedesktop.impl.portal.PermissionStore"
        "SetPermission sbssas kde-authorized true remote-desktop org.kde.kdeconnect.daemon 1 yes"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
