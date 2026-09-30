# System-wide programs with NixOS modules, and system-wide shell settings.
# User-level shell config (aliases from ~/.bashrc etc.) is in ../home/hisoft/bash.nix.
{ pkgs, ... }:
{
  # Install firefox.
  programs.firefox.enable = true;

  environment.shellAliases = {
    zed = "zeditor";
    zudoedit = "SUDO_EDITOR=\"zeditor --wait --new\" sudoedit";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    bash.interactiveShellInit = ''
      export HISTCONTROL=ignoreboth
    '';
    captive-browser = {
      enable = true;
      interface = "wlp0s20f3";
      browser = ''
        env XDG_CONFIG_HOME="$PREV_CONFIG_HOME" ${pkgs.vivaldi}/bin/vivaldi \
          --user-data-dir=''${XDG_DATA_HOME:-$HOME/.local/share}/chromium-captive \
          --proxy-server="socks5://$PROXY" \
          --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost" \
          --no-first-run --new-window --incognito \
          --no-default-browser-check http://cache.nixos.org/
      '';
    };
    direnv.enable = true;
    git = {
      enable = true;
      package = pkgs.gitFull;
      config.init.defaultBranch = "main";
    };
    htop.enable = true;
    kdeconnect.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure = {
        customLuaRC = ''
          	  vim.opt.clipboard = "unnamedplus"
        '';
      };
    };
    # nh: nixos-rebuild wrapper that shows which packages changed on every build/switch.
    # The Justfile's rebuild recipes use it. Garbage collection stays with nix.gc
    # (modules/nix.nix); nh's own clean timer would conflict with it.
    nh = {
      enable = true;
      flake = "/home/hisoft/nixos-config";
    };
    nix-ld.enable = true;
    # Screen recording and streaming. Captures through the ScreenCast portal (PipeWire):
    # in OBS add a "Screen Capture (PipeWire)" source, then pick a screen or a window.
    obs-studio.enable = true;
    ssh.startAgent = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
    tmux = {
      enable = true;
      clock24 = true;
    };
  };
}
