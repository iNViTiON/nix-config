# niri session next to Plasma: the HDR-capable niri-spicy fork, KDE Wallet for it, and
# DankMaterialShell. Pick it in SDDM's session menu; Plasma stays the default.
# To uninstall, remove this module's import in hosts/mix-nixos/default.nix (and the
# niri-spicy / niri-spicy-smithay inputs in flake.nix). Details: README "niri session".
{
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  # The nixpkgs niri-spicy builds with (its own flake.lock). Extra build inputs come from
  # here too, so everything linked into niri shares one glibc.
  spicyPkgs = inputs.niri-spicy.inputs.nixpkgs.legacyPackages.${system};
in
{
  # The InputCapture portal backend's module ("Share input devices", see below).
  imports = [ inputs.layercapture.nixosModules.default ];

  # Mainline niri (26.04) has no HDR yet, only 10-bit output. The niri-spicy fork adds
  # experimental HDR output (`hdr` in the output config). For mainline niri instead,
  # delete the `package` attribute and the niri-spicy / niri-spicy-smithay inputs.
  programs.niri = {
    enable = true;
    # Two fixes on top of the fork's own flake package:
    # - Its Cargo.toml patches Smithay to `../smithay` (a checkout of losnoco/smithay,
    #   where the HDR code lives), which doesn't exist in the Nix build sandbox. Copy the
    #   niri-spicy-smithay input there before the build starts.
    # - Its Vulkan renderer compiles shaders with the shaderc crate. Link the packaged
    #   libshaderc; otherwise shaderc-sys tries to build shaderc from source (needs cmake).
    package = inputs.niri-spicy.packages.${system}.niri.overrideAttrs (old: {
      postUnpack = (old.postUnpack or "") + ''
        cp -r ${inputs.niri-spicy-smithay} "$NIX_BUILD_TOP/smithay"
        chmod -R u+w "$NIX_BUILD_TOP/smithay"
      '';
      buildInputs = (old.buildInputs or [ ]) ++ [ spicyPkgs.shaderc ];
      SHADERC_LIB_DIR = "${lib.getLib spicyPkgs.shaderc}/lib";
    });
  };

  # ---- KDE Wallet in niri ----
  # The niri module turns on gnome-keyring by default. Keep KWallet as the only secret
  # store in every session, so apps see the same secrets as in Plasma.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # SDDM's PAM stack (pam_kwallet5, set up by the Plasma module) starts ksecretd with your
  # login password in any session, but ksecretd then waits for `pam_kwallet_init` to hand
  # over the session environment. Plasma runs that itself; its autostart entry is marked
  # X-systemd-skip, so the systemd-based autostart that niri-session uses skips it. This
  # entry runs it there instead; NotShowIn=KDE leaves Plasma alone.
  environment.etc."xdg/autostart/pam_kwallet_init-wayland.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=KDE Wallet login unlock
    Exec=${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init
    NotShowIn=KDE;
    NoDisplay=true
  '';

  # Portal "Secret" backend (for sandboxed apps): KWallet instead of gnome-keyring.
  xdg.portal.config.niri."org.freedesktop.impl.portal.Secret" = lib.mkForce "kwallet";

  # File picker ("Open"/"Save as" dialogs of apps that ask through the portal) in niri:
  # Strata (from my fork, the strata flake input, see ./nix.nix) instead of the GTK one. Plasma
  # keeps KDE's own dialog.
  # To go back, delete these two settings.
  xdg.portal.extraPortals = [
    pkgs.strata
    pkgs.hypr-kdeconnect-portal
  ];
  xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce "strata";

  # KDE Connect's remote input (phone as mouse and keyboard) needs the RemoteDesktop
  # portal, which niri doesn't provide (the GNOME portal's needs GNOME's own compositor).
  # This bridge (../pkgs/hypr-kdeconnect-portal) provides it for KDE Connect only, through
  # niri's virtual-pointer/virtual-keyboard protocols; there's no permission prompt.
  # Plasma keeps its own.
  xdg.portal.config.niri."org.freedesktop.impl.portal.RemoteDesktop" = "hypr-kdeconnect";

  # KDE Connect's "Share input devices" (push the pointer past a screen edge and the
  # laptop's mouse and keyboard drive the phone) needs the InputCapture portal, which niri
  # doesn't provide either. The layercapture backend (own project, flake input
  # `layercapture`, imported above) builds it from a 1 px layer-shell strip at the edge, a
  # pointer lock and an EIS server, for KDE Connect only and without a prompt. Its module
  # adds it to xdg.portal.extraPortals and routes InputCapture to it in niri only; Plasma
  # keeps KWin's. To leave a capture: move off the phone's edge, Mod+Escape, or
  # `pkill -KILL -x layercapture` from a TTY.
  # After a switch that adds or updates it, restart xdg-desktop-portal (it picks its
  # backends only at startup; restarting it also restarts this backend) and then kdeconnectd.
  services.xdg-desktop-portal-layercapture.enable = true;

  # Qt apps use Plasma's look (Breeze Dark from ~/.config/kdeglobals) in niri too. Plasma
  # picks its platform theme by itself; elsewhere Qt falls back to a light default. That
  # also made Vivaldi (browser theme "Qt") report light mode, so websites set to "follow
  # system" showed light. Harmless in Plasma, which uses the same theme.
  environment.sessionVariables.QT_QPA_PLATFORMTHEME = "kde";

  # DankMaterialShell: the Quickshell-based bar, launcher, notifications, control center
  # and lock screen seen in most niri screenshots (replaces waybar, fuzzel, mako,
  # swaylock). Its service normally starts with graphical-session.target, which Plasma
  # reaches too. Tie it to niri.service instead, as DMS's own niri instructions do
  # (`systemctl --user add-wants niri.service dms`): it starts and stops with niri, never
  # runs in Plasma, and systemd restarts it if it crashes. So niri's config must not also
  # spawn it.
  programs.dms-shell = {
    enable = true;
    systemd.target = "niri.service";
    # DMS from nixos-unstable (1.6.x; 26.05 has 1.4.x), with the Quickshell it's built for.
    # Its companion tools (dgop, matugen), which this module installs, come from unstable
    # through an overlay in ./nix.nix.
    package = pkgs-unstable.dms-shell;
    quickshell.package = pkgs-unstable.quickshell;
    # "Phone Connect": KDE Connect in DMS's bar and control center (battery, ring phone,
    # send files, clipboard, SMS, browse files). Uses the KDE Connect daemon that already
    # runs (programs.kdeconnect). Turn it on in DMS Settings -> Plugins.
    plugins.DankKDEConnect.src = "${inputs.dms-plugins}/DankKDEConnect";
    # "GPU and NPU usage": iGPU/NPU utilization for the bar, next to the CPU and memory
    # widgets (../pkgs/dms-accel-usage). Turn it on in DMS Settings -> Plugins, then add it
    # in Settings -> DankBar -> Add Widget.
    plugins.AccelUsage.src = ../pkgs/dms-accel-usage;
  };

  # What niri's generated default config calls, so it's usable on first login.
  environment.systemPackages = with pkgs; [
    # niri defaults: Mod+T terminal, Mod+D launcher, waybar at startup, Super+Alt+L lock
    alacritty
    fuzzel
    waybar
    swaylock
    # Brightness keys in niri (home/hisoft/niri.nix, and niri's default config). Goes
    # through logind, so it needs no root or udev rule, and it can go down to 0%.
    brightnessctl
    # "Browse phone files" in KDE Connect (and DMS's Phone Connect) mounts the phone with sshfs
    sshfs
    # X11 apps under niri (niri starts it on demand when it's installed)
    xwayland-satellite
  ];

  # swaylock needs a PAM service to check your password; without it you can't unlock.
  security.pam.services.swaylock = { };
}
