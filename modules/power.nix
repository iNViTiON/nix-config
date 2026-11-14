# CPU frequency/power management with auto-cpufreq.
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # Was `(builtins.getFlake "github:AdnanHodzic/auto-cpufreq").nixosModules.default`.
    inputs.auto-cpufreq.nixosModules.default
  ];

  programs.auto-cpufreq.enable = true;

  # KDE Plasma 6 built-in power is conflict with auto-cpufreq
  services.power-profiles-daemon.enable = false;

  # `bat-hold`: stop charging now (battery stays where it is, e.g. before a long time on
  # AC). Unplugging the charger puts charge_behaviour back to `auto` by itself: the script
  # drops a one-shot udev rule in /run (tmpfs, so a reboot clears it too) that fires when
  # the mains supply goes offline, resets the battery and deletes itself.
  # Asks for sudo itself (writes to /run and sysfs).
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "bat-hold";
      runtimeInputs = [ pkgs.systemd ]; # udevadm
      text = ''
        if [ "$(id -u)" -ne 0 ]; then
          exec sudo "$0" "$@"
        fi

        R=/run/udev/rules.d/99-bat-hold.rules
        B=/sys/class/power_supply/BAT0/charge_behaviour

        mkdir -p /run/udev/rules.d
        cat > "$R" <<EOF
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.runtimeShell} -c 'echo auto > $B; rm -f $R; ${pkgs.systemd}/bin/udevadm control --reload'"
        EOF
        udevadm control --reload
        echo inhibit-charge > "$B"
        echo "charging held; goes back to auto when the charger is unplugged"
      '';
    })
  ];
}
