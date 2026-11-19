# CPU frequency/power management with auto-cpufreq.
{
  inputs,
  pkgs,
  ...
}:
let
  # Battery charge hold. Mode is a flag file in /run (tmpfs: a reboot clears it).
  #   bat-hold [once]  stop charging until every power supply is unplugged
  #   bat-hold always  stop charging until `bat-hold off` (or reboot)
  #   bat-hold off     charge normally again
  #   bat-hold status  show mode, charge_behaviour and supplies
  # The firmware keeps `inhibit-charge` across plug/unplug by itself, so only `once`
  # needs watching: any non-battery power_supply uevent (re)starts a 5s timer, then
  # bat-hold-check releases the hold if no supply is online. The delay rides out
  # USB-PD renegotiation, where AC briefly reports offline although a supply is still
  # connected (measured < 1s).
  once = "/run/bat-hold-once";
  always = "/run/bat-hold-always";
  behaviour = "/sys/class/power_supply/BAT0/charge_behaviour";

  # Writes `auto`; used by `bat-hold off`, the once-release and boot/shutdown reset.
  release = pkgs.writeShellScript "bat-hold-release" ''
    rm -f ${once} ${always}
    if [ -w ${behaviour} ]; then echo auto > ${behaviour}; fi
  '';

  check = pkgs.writeShellScript "bat-hold-check" ''
    [ -e ${once} ] || exit 0
    for d in /sys/class/power_supply/*; do
      [ "$(cat "$d/type")" = Battery ] && continue
      [ "$(cat "$d/online" 2>/dev/null)" = 1 ] && exit 0
    done
    exec ${release}
  '';

  bat-hold = pkgs.writeShellApplication {
    name = "bat-hold";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      if [ "''${1:-}" = status ]; then
        if [ -e ${always} ]; then mode=always
        elif [ -e ${once} ]; then mode="once (until every supply is unplugged)"
        else mode=off; fi
        echo "mode:      $mode"
        echo "behaviour: $(cat ${behaviour})"
        echo "battery:   $(cat /sys/class/power_supply/BAT0/status), $(cat /sys/class/power_supply/BAT0/capacity)%"
        printf 'supplies: '
        for d in /sys/class/power_supply/*; do
          [ "$(cat "$d/type")" = Battery ] && continue
          printf ' %s=%s' "$(basename "$d")" "$(cat "$d/online" 2>/dev/null || echo -)"
        done
        echo
        exit 0
      fi

      case "''${1:-once}" in
        once | always | off) ;;
        *)
          echo "usage: bat-hold [once|always|off|status]" >&2
          exit 2
          ;;
      esac

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      case "''${1:-once}" in
        once)
          rm -f ${always}
          touch ${once}
          echo inhibit-charge > ${behaviour}
          echo "charging held; goes back to auto when every power supply is unplugged"
          ;;
        always)
          rm -f ${once}
          touch ${always}
          echo inhibit-charge > ${behaviour}
          echo "charging held until 'bat-hold off' (or reboot)"
          ;;
        off)
          systemctl stop bat-hold-check.timer || true
          ${release}
          echo "charging back to auto"
          ;;
      esac
    '';
  };
in
{
  imports = [
    # Was `(builtins.getFlake "github:AdnanHodzic/auto-cpufreq").nixosModules.default`.
    inputs.auto-cpufreq.nixosModules.default
  ];

  programs.auto-cpufreq.enable = true;

  # KDE Plasma 6 built-in power is conflict with auto-cpufreq
  services.power-profiles-daemon.enable = false;

  environment.systemPackages = [ bat-hold ];

  # Battery uevents fire on every charge change, so only non-battery supplies count.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}!="Battery", TEST=="${once}", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart bat-hold-check.timer"
  '';

  systemd.timers.bat-hold-check.timerConfig = {
    OnActiveSec = "5s";
    AccuracySec = "1s"; # default 1min would delay the check
  };

  systemd.services.bat-hold-check = {
    description = "Release once-mode battery charge hold when no power supply is online";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = check;
    };
  };

  # Reset to auto at boot (covers crash / power loss) and at shutdown/reboot (so a
  # powered-off laptop on the charger still charges; the firmware keeps inhibit-charge).
  # Suspend/hibernate don't stop units, so the hold survives sleep.
  systemd.services.bat-hold-reset = {
    description = "Reset battery charge_behaviour to auto at boot and shutdown";
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false; # a restart on `nixos-rebuild switch` would drop an active hold
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = release;
      ExecStop = release;
    };
  };
}
