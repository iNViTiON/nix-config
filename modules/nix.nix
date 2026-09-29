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
      # Th1nkK1D's package (the `th1nkk1d` flake input), built with nixpkgs-unstable
      # (a dependency needs a newer Rust than 26.05 has), plus one change: hardware video
      # decoding (VA-API) in the preview sandbox. libva loads its driver from
      # /run/opengl-driver on NixOS, which the sandbox doesn't otherwise see.
      strata = (pkgs-unstable.callPackage "${inputs.th1nkk1d}/pkgs/strata/package.nix" { }).overrideAttrs (old: {
        postPatch = old.postPatch + ''
          substituteInPlace src/sandbox.rs \
            --replace-fail '"/app",' '"/app", "--ro-bind-try", "/run/opengl-driver", "/run/opengl-driver",'
        '';
      });
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
}
