{
  config,
  lib,
  pkgs,
  ...
}:

{
  security.pam.services.login.fprintAuth = false;
  # security.pam.services.sddm.fprintAuth = false;
  systemd.services.systemd-user-sessions.enable = false;
  systemd.services.systemd-udev-settle.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;
}
