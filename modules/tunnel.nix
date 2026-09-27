{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.rpi-tunnel;
in
{
  options.services.rpi-tunnel = {
    enable = lib.mkEnableOption "Run ~/tunnel.sh as a user service";

    user = lib.mkOption {
      type = lib.types.str;
      default = "hisoft";
      description = "User account that runs the tunnel service.";
    };

    scriptPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/tunnel.sh";
      description = "Absolute path to the tunnel script.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.rpi-tunnel = {
      description = "SSH tunnel (tunnel.sh)";
      wantedBy = [ "default.target" ];

      path = with pkgs; [
        bash
        openssh
        iputils
        coreutils
      ];

      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash ${cfg.scriptPath}";
        Restart = "always";
        RestartSec = 2;
      };
    };
  };
}
