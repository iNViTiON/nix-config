# NPU translation server for the Llama Franca extension, on localhost:11434 (Ollama itself is on
# 11435, see ./local-llm.nix). Runs from the checkout through its run.sh (flake dev shell + uv
# venv), so it follows the project as it changes. Started at login, restarted on failure.
# It frees the model after `idleUnloadSeconds` idle and reloads in ~2 s (compile cache).
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.npu-translator;
in
{
  options.services.npu-translator = {
    enable = lib.mkEnableOption "the NPU translation server as a user service";

    user = lib.mkOption {
      type = lib.types.str;
      default = "hisoft";
      description = "User account that runs the server.";
    };

    directory = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/Documents/local-llm-npu-translator";
      description = "Checkout of local-llm-npu-translator (its run.sh starts the server).";
    };

    devices = lib.mkOption {
      type = lib.types.enum [
        "npu"
        "all"
      ];
      default = "npu";
      description = ''
        Devices the server may use. `npu`: the NPU only. `all`: NPU, GPU and CPU are served; a
        plain model name still runs on the NPU, and the extension's picker (or `model@GPU`) chooses
        the others. Replicas load on first use and cost RAM only while loaded.
      '';
    };

    idleUnloadSeconds = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 300;
      description = "Free the model's memory after this many idle seconds; 0 keeps it loaded.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.npu-translator = {
      description = "NPU translation server for Llama Franca (localhost:11434)";
      wantedBy = [ "default.target" ];
      unitConfig.ConditionUser = cfg.user;

      path = with pkgs; [
        bash
        coreutils
        git # nix develop reads the project flake from its git checkout
        config.nix.package
      ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs (
          [
            "${cfg.directory}/run.sh"
            "--idle-unload"
            (toString cfg.idleUnloadSeconds)
          ]
          ++ (
            if cfg.devices == "all" then
              [
                "--device"
                "NPU,GPU,CPU"
                "--default-device"
                "NPU"
              ]
            else
              [
                "--device"
                "NPU"
              ]
          )
        );
        Restart = "on-failure";
        RestartSec = 5;
        SuccessExitStatus = 143; # SIGTERM on stop, passed back through `nix develop`
      };
    };
  };
}
