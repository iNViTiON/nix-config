# User packages: personal apps and dev tools. Moved here from the system package list,
# plus the former `nix profile` installs. Not on PATH under `sudo su` (`sudo cmd` works).
# `pkgs` is nixos-26.05, `pkgs-unstable` is nixos-unstable.
{
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages =
    (with pkgs; [
      # Chat / media / office
      discord
      vlc
      libreoffice-qt
      kdePackages.kate
      #  thunderbird

      # Editors / language servers
      nil
      nixd

      # Languages / toolchains
      go
      rustup
      uv
      volta

      # Dev / ops CLIs
      gh
      gnupg
      jq
      fastfetch

      # Database (client only; no service is enabled)
      pgadmin4-desktopmode
      postgresql

      # Android
      android-tools
      scrcpy

      # ZSA keyboard (udev rules stay system-wide via hardware.keyboard.zsa)
      keymapp
      wally-cli

      # Wine / VR
      wineWow64Packages.waylandFull
      wayvr

      wl-clipboard
      # xclip
      # xsel

      # Command runner for ../../Justfile
      just

      # was: nix profile add path:/home/hisoft/Documents/usbeehive-flake
      # (now ../../pkgs/usbeehive via ../../overlays)
      usbeehive
      strata # file manager, from ../../pkgs/strata
    ])
    ++ (with pkgs-unstable; [
      # OneDrive sync with a GUI (bundles the `onedrive` client). It runs the sync itself,
      # so don't also enable services.onedrive: both would sync the same account. From
      # unstable: 26.05's build pulls ~1.2 GB of compilers (clang, gcc) in at runtime
      # through PySide6's shiboken6; unstable's doesn't.
      onedrivegui
      telegram-desktop
      zoom-us
      gimp
      jan
      zed-editor-fhs
      vscode-fhs
      # claude-code
      codex
      # Was `local.github-copilot-cli` from ~/Documents/nixpkgs (1.0.44); nixpkgs has
      # caught up (nixos-26.05 already had 1.0.61 on 2026-09-25).
      github-copilot-cli
      rtk
      bun
      k9s
      kubernetes
      pyhanko-cli
      winetricks
      # h lab lib
      automake
      gcc
      gnumake
      # end h lab lib
    ])
    ++ [
      # was: nix profile add --no-write-lock-file github:patrickjaja/claude-desktop-extra
      inputs.claude-desktop-extra.packages.${system}.default
      # was: nix profile add git+file:///home/hisoft/Documents/MangaMeeyaCE
      # (now from its GitHub repo, iNViTiON/MangaMeeyaRush)
      inputs.mangameeya-rush.packages.${system}.default
    ];
}
