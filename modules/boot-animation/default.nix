{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      systemd.enable = true;
    };
    kernelParams = [
      "quiet"
      "splash"
      "intremap=on"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "systemd.show_status=auto"
    ];

    # plymouth, showing after LUKS unlock
    plymouth = {
      enable = true;
      logo = ./mitch.png;
      # Mitch whisking matcha with Mälu and friends waiting. `logo` stays for the other themes.
      theme = "mitch";
      themePackages = [ (pkgs.callPackage ./mitch-theme.nix { }) ];
    };
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };
}
