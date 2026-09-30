# Nix itself: flakes, nixpkgs config/overlays, channels, registry, garbage collection.
{ inputs, pkgs-unstable, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Local packages and overrides (../overlays): usbeehive.
  nixpkgs.overlays = [
    inputs.self.overlays.default
    (final: prev: {
      # Strata: keyboard-first file manager, and niri's file picker (./compositors.nix).
      # From my fork (the `strata` flake input, `release` branch), taken as built by the
      # fork's own flake, so it's downloaded from the invition cache below. The fork's
      # package already includes the NixOS fixes (VA-API in the preview sandbox, bwrap and
      # prlimit paths); its Nix package is based on Th1nkK1D's.
      strata = inputs.strata.packages.${final.stdenv.hostPlatform.system}.strata;
      # Codiff: diff viewer for reviewing and committing Git changes (not in nixpkgs yet).
      # Th1nkK1D's package too (it repackages upstream's .deb), built with nixpkgs-unstable
      # like Strata: it names Th1nkK1D as maintainer, which 26.05's lib doesn't know yet.
      codiff = pkgs-unstable.callPackage "${inputs.th1nkk1d}/pkgs/codiff/package.nix" { };
      # DankMaterialShell's companion tools, matching DMS from unstable (./compositors.nix):
      # system monitor widgets and wallpaper-based colors. The DMS module installs
      # `pkgs.dgop` / `pkgs.matugen`, so they're swapped here, for everything that uses them.
      dgop = pkgs-unstable.dgop;
      matugen = pkgs-unstable.matugen;
    })
  ];

  # Flake inputs replace channels. nixpkgs.lib.nixosSystem already pins the `nixpkgs`
  # registry entry and sets NIX_PATH=nixpkgs=flake:nixpkgs to this flake's nixpkgs
  # (nixpkgs.flake.setFlakeRegistry / setNixPath, on by default since 24.05), so
  # `nix shell nixpkgs#foo`, `nix-shell -p foo` and `<nixpkgs>` match the system.
  # This also removes the `nix-channel` command; see README for cleaning up old channels.
  nix.channel.enable = false;

  # Same for unstable: `nix shell nixpkgs-unstable#foo` uses the locked input.
  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;

  # "Reducing Disk Usage" from the NixOS & Flakes book: weekly GC plus store dedup.
  # Replaces running `sudo nix-collect-garbage -d` by hand. Generations older than
  # 7 days are removed; the boot menu is only rewritten at the next rebuild, and it
  # holds at most boot.lanzaboote.configurationLimit entries anyway.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  # Binary cache for my Strata fork (github:iNViTiON/strata, `release` branch): its CI
  # uploads the built package, signed with my own key, so it's downloaded instead of
  # compiled here. Anything not signed by this key is refused.
  nix.settings.extra-substituters = [ "https://invition.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [
    "invition.cachix.org-1:UBnayz18duoQrchGIMu740K49/WVsaa8dThirDR/Hd4="
  ];
}
