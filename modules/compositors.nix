# Extra Wayland sessions to try next to Plasma: Hyprland, and niri (the HDR-capable
# niri-spicy fork). Pick them in SDDM's session menu; Plasma stays the default.
# To uninstall, remove this module's import in hosts/mix-nixos/default.nix (and the
# niri-spicy / niri-spicy-smithay inputs in flake.nix). HDR and keyboard config: README "Trying Hyprland and niri".
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  # The nixpkgs niri-spicy builds with (its own flake.lock). Extra build inputs come from
  # here too, so everything linked into niri shares one glibc.
  spicyPkgs = inputs.niri-spicy.inputs.nixpkgs.legacyPackages.${system};
in
{
  # Hyprland 0.55 from nixpkgs. HDR on the desktop is `cm = "hdr"` in its monitor config
  # (experimental upstream). UWSM is the NixOS wiki's recommended way to launch it; SDDM
  # lists the session as "Hyprland (uwsm-managed)".
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

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

  # The niri module turns on gnome-keyring by default. Keep KWallet as the only secret
  # store, so Plasma apps (Bitwarden, browsers) don't end up with two competing ones.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # What the generated default configs call, so both sessions are usable on first login.
  environment.systemPackages = with pkgs; [
    # Hyprland defaults: Super+Q terminal, Super+R launcher, Super+M exit
    kitty
    hyprlauncher
    hyprshutdown
    # niri defaults: Mod+T terminal, Mod+D launcher, waybar at startup, Super+Alt+L lock
    alacritty
    fuzzel
    waybar
    swaylock
    # X11 apps under niri (niri starts it on demand when it's installed)
    xwayland-satellite
  ];

  # swaylock needs a PAM service to check your password; without it you can't unlock.
  security.pam.services.swaylock = { };
}
