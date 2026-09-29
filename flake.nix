{
  description = "NixOS configuration for mix-nixos (ThinkPad X1 Carbon Gen 13)";

  inputs = {
    # Was the `nixos` channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Was the `nixos-unstable` channel (`unstable = import <nixos-unstable> { ... }`).
    # Modules get it as the `pkgs-unstable` argument, see `specialArgs` below.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Was the `nixos-hardware` channel.
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Was pinned with lon (lon.nix + lon.lock, `frozen: true`) at v1.0.0. Pinned here to the
    # commit of release tag v1.0.0, so even `nix flake update` can never move it.
    # To upgrade: `just releases` lists new tags; `just lanzaboote-rev v1.2.0` prints that
    # tag's commit; paste it below, then `just upp lanzaboote`.
    # Boot-critical: read the CHANGELOG first, bump it on its own (not together with other
    # updates), and keep a NixOS USB stick and your LUKS passphrase at hand.
    lanzaboote = {
      url = "github:nix-community/lanzaboote/e8c096ade12ec9130ff931b0f0e25d2f1bc63607"; # v1.0.0
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Was `builtins.getFlake "github:AdnanHodzic/auto-cpufreq"` (unlocked master, needed
    # --impure). Runs as a root daemon, so it is pinned to a release tag: `nix flake update`
    # re-resolves the tag to the same commit. To upgrade: `just releases`, change the tag
    # here, then `just upp auto-cpufreq`.
    # No `follows`: it builds with the nixpkgs lock upstream ships and tested with.
    # (`follows` stays on home-manager and lanzaboote, which plug into the system itself
    # and whose docs recommend it.)
    auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq/v3.1.0";

    # Was `builtins.fetchTarball ".../nixpkgs-xr/archive/main.tar.gz"` in vr.nix.
    # Uncomment together with the ./modules/vr.nix import in hosts/mix-nixos/default.nix.
    # nixpkgs-xr.url = "github:nix-community/nixpkgs-xr";

    # ---- Formerly installed imperatively with `nix profile add` ----

    # Taken straight from its GitHub flake (no `follows`), like the old `nix profile`
    # install. Upstream commits no flake.lock, so its nixpkgs (nixos-unstable) is whatever
    # was current when this input was last locked/updated, recorded in our flake.lock.
    claude-desktop-extra.url = "github:patrickjaja/claude-desktop-extra";

    # Own project (local clone: ~/Documents/MangaMeeyaCE), uses its own flake.lock (no
    # `follows`), so the system gets the same build as `nix build` in the repo.
    # Tracks the pushed `main` branch. After pushing: `nix flake update mangameeya-rush`.
    # To try unpushed local work without touching flake.lock:
    #   nixos-rebuild build --override-input mangameeya-rush git+file:///home/hisoft/Documents/MangaMeeyaCE
    mangameeya-rush.url = "github:iNViTiON/MangaMeeyaRush";

    # Th1nkK1D's NixOS config, for its Strata (keyboard-first file manager) and Codiff (Git
    # diff viewer) packages, neither in nixpkgs yet; used by modules/nix.nix. Only the
    # package files are taken (`flake = false`), built with our nixpkgs-unstable: its
    # flake's `packages` output refuses to build Strata, which is partly unfree (bundled
    # UnRAR), because that flake's nixpkgs doesn't allow unfree. Update: `just upp th1nkk1d`.
    th1nkk1d = {
      url = "github:Th1nkK1D/nixos-config";
      flake = false;
    };

    # Own project (local clone: ~/Documents/xdg-desktop-portal-layercapture): the
    # InputCapture portal backend for niri that makes KDE Connect's "Share input devices"
    # work. Used by modules/compositors.nix through its NixOS module; the package is built
    # with this config's nixpkgs, so `follows` only avoids fetching the flake's own pin.
    # Tracks the pushed `main` branch. After pushing: `nix flake update layercapture`.
    # To try unpushed local work without touching flake.lock:
    #   nixos-rebuild build --override-input layercapture git+file:///home/hisoft/Documents/xdg-desktop-portal-layercapture
    layercapture = {
      url = "github:iNViTiON/xdg-desktop-portal-layercapture";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri fork with experimental HDR output (mainline niri has none yet), used by
    # modules/compositors.nix. Community fork by kode54 tracking the `spicy-main` branch;
    # built from source (no binary cache), with its own nixpkgs lock.
    niri-spicy.url = "github:losnoco/niri/spicy-main";
    # niri-spicy's Cargo.toml patches Smithay to a sibling checkout (../smithay) of this
    # fork, which holds the HDR / color-management code; modules/compositors.nix puts it
    # there at build time. Update both together: `just upp niri-spicy niri-spicy-smithay`.
    niri-spicy-smithay = {
      url = "github:losnoco/smithay/spicy-master";
      flake = false;
    };
    # DankMaterialShell plugins (modules/compositors.nix uses DankKDEConnect, "Phone
    # Connect"). Follows the repo's default branch; `just upp dms-plugins` updates it. Its
    # plugins need a matching DMS (DMS itself comes from nixpkgs-unstable).
    dms-plugins = {
      url = "github:AvengeMedia/dms-plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      # The only extra nixpkgs instance: created once here, never inside modules, and
      # shared by the NixOS and Home Manager modules.
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      # `specialArgs` rather than `_module.args`, so `inputs` can be used in `imports`.
      specialArgs = { inherit inputs pkgs-unstable; };
    in
    {
      nixosConfigurations.mix-nixos = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/mix-nixos

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # The first activation moves the existing ~/.bashrc, ~/.bash_profile and
              # ~/.profile to *.hm-backup instead of failing on them.
              backupFileExtension = "hm-backup";
              # NixOS `specialArgs` do not reach Home Manager modules on their own.
              extraSpecialArgs = specialArgs;
              users.hisoft = import ./home/hisoft;
            };
          }
        ];
      };

      # Local package additions/overrides, applied to the system pkgs in modules/nix.nix.
      overlays.default = import ./overlays;

      # Build the local packages on their own, e.g. `nix build .#usbeehive`.
      # Taken from the system's pkgs, so they are exactly what gets installed.
      packages.${system} = {
        inherit (self.nixosConfigurations.mix-nixos.pkgs) usbeehive;
      };

      # `nix fmt`
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
