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
    # Strata (../pkgs/strata): keyboard-first file manager, and niri's file picker
    # (./compositors.nix). Built with nixpkgs-unstable because a dependency needs a newer
    # Rust than 26.05 has.
    (final: prev: { strata = pkgs-unstable.callPackage ../pkgs/strata/package.nix { }; })
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
