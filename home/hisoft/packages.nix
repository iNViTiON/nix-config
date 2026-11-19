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

  # agent-browser (browser CLI for agents: accessibility-tree snapshots, named sessions),
  # from llm-agents.nix as in lk-nix, wrapped to drive the system Helium: the Chrome its
  # `install` downloads is an FHS binary that won't run on NixOS.
  #   agent-browser open <url>     no profile: throwaway, nothing is kept after `close`
  #   AB_PROFILE=mitch|malu agent-browser open <url>
  #                                persistent profile (logins stay) in its own session, so
  #                                two can run side by side (AB_PROFILE=mitch / =malu)
  # Profiles live in ~/.agent-browser/profiles/<name>: Helium's engine, extension policy and
  # native hosts, but not Helium's own ~/.config/net.imput.helium (a running Helium owns it,
  # and Chromium won't open its debug port on a profile in its default folder).
  # The same folders open as normal Helium windows from the "Helium (mitch)" / "Helium
  # (mälu)" launchers (../../modules/browsers.nix), so a login made there works here too.
  # One browser per folder: close that window (or `AB_PROFILE=mitch agent-browser close`).
  # AGENT_BROWSER_ENCRYPTION_KEY (encrypts saved session state) comes from KWallet,
  # folder "agent-browser", entry "encryption-key"; unset if the wallet has none.
  agent-browser = pkgs.writeShellApplication {
    name = "agent-browser";
    runtimeInputs = [ pkgs.kdePackages.kwallet ];
    text = ''
      export AGENT_BROWSER_EXECUTABLE_PATH=/run/current-system/sw/bin/helium
      # agent-browser starts Chromium with --password-store=basic; Helium encrypts cookies
      # with KWallet, so without this a profile copied from Helium looks signed out.
      export AGENT_BROWSER_ARGS="--password-store=kwallet6''${AGENT_BROWSER_ARGS:+,$AGENT_BROWSER_ARGS}"
      if [ -n "''${AB_PROFILE:-}" ]; then
        case "$AB_PROFILE" in
          mitch | malu) ;;
          *) echo "AB_PROFILE must be mitch or malu (got: $AB_PROFILE)" >&2; exit 2 ;;
        esac
        export AGENT_BROWSER_PROFILE="$HOME/.agent-browser/profiles/$AB_PROFILE"
        export AGENT_BROWSER_SESSION="$AB_PROFILE"
      fi
      # Fixed download folder per profile (throwaway: "temp"), so a download link clicked
      # with the core MCP tools lands somewhere known; the "debug" tool set (download to a
      # chosen path) stays off, it also brings upload, plugins and clipboard access.
      if [ -z "''${AGENT_BROWSER_DOWNLOAD_PATH:-}" ]; then
        export AGENT_BROWSER_DOWNLOAD_PATH="$HOME/Downloads/agent-browser/''${AB_PROFILE:-temp}"
      fi
      mkdir -p "$AGENT_BROWSER_DOWNLOAD_PATH"
      if [ -z "''${AGENT_BROWSER_ENCRYPTION_KEY:-}" ]; then
        key=$(kwallet-query -r encryption-key -f agent-browser kdewallet 2>/dev/null || true)
        if [[ $key =~ ^[0-9a-f]{64}$ ]]; then export AGENT_BROWSER_ENCRYPTION_KEY=$key; fi
      fi
      # The package's own bin/agent-browser is a wrapper that force-sets (--set)
      # AGENT_BROWSER_EXECUTABLE_PATH to its bundled Chromium, overriding Helium above, so
      # run the real binary behind it. Its wrapper sets nothing else (checked 0.43.0).
      exec ${inputs.llm-agents.packages.${system}.agent-browser}/bin/.agent-browser-wrapped "$@"
    '';
  };
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

      # WiFi hotspot while staying connected to WiFi (wihotspot GUI, create_ap): it makes a
      # virtual AP interface next to the client one, unlike NetworkManager's hotspot (DMS),
      # which takes over the only interface. Both must be on the same channel. Needs root.
      linux-wifi-hotspot

      # Command runner for ../../Justfile
      just

      # was: nix profile add path:/home/hisoft/Documents/usbeehive-flake
      # (now ../../pkgs/usbeehive via ../../overlays)
      usbeehive
      strata # file manager, from my fork (overlay in ../../modules/nix.nix)
      codiff # Git diff viewer, Th1nkK1D's package (overlay in ../../modules/nix.nix)
      showmethekey # shows pressed keys and mouse buttons on screen, for recordings (OBS)
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
      zed-editor-fhs
      vscode-fhs
      # claude-code
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
      # Sandbox for AI agents; release binary, not built from source
      inputs.nono.packages.${system}.prebuilt
      agent-browser
      # GPU task manager (`gtop` alias, bash.nix). Its flake caps uv_build below 0.13 but
      # nixpkgs-unstable ships 0.13.x, so widen the bound (tests still run in the build).
      # Drop the override once upstream raises the cap.
      (inputs.gputaskman.packages.${system}.default.overrideAttrs {
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail 'uv_build>=0.9.26,<0.10.0' 'uv_build>=0.9.26,<0.14.0'
        '';
      })
    ];

  # Claude Desktop: start without Chromium's sandbox. With it, the app dies at once
  # (SIGILL): the package ships the setuid sandbox helper, but nothing in the Nix store can
  # be setuid, and Chromium treats a wrongly set up helper as fatal. Set for the whole user
  # session (systemd user manager), so it also covers the app's own "start at login" entry
  # (~/.config/autostart/claude.desktop), which the app writes itself without the flag.
  systemd.user.sessionVariables.CLAUDE_DISABLE_SANDBOX = "1";

  # Wrangler (from project dev shells, not installed here) writes a debug log per run;
  # they piled up to ~126k files / 5.7G by 2026-10. The daily user
  # systemd-tmpfiles-clean timer deletes the ones older than 14 days.
  systemd.user.tmpfiles.rules = [
    "e %h/.config/.wrangler/logs - - - 14d"
    # Scratch folder of the DMS OCR Translate plugin (../../modules/compositors.nix).
    # The plugin never made it itself; without it `dms screenshot --dir` ignores the folder.
    "d %h/.cache/dms-ocr 0755 - - -"
  ];
}
