# nixpkgs-xr overlay. Not imported by default. To enable, uncomment the `nixpkgs-xr`
# input in flake.nix and the ../../modules/vr.nix import in hosts/mix-nixos/default.nix.
# Was `import (builtins.fetchTarball ".../nixpkgs-xr/archive/main.tar.gz")`, which
# is unpinned and not allowed in pure flake evaluation.
{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.nixpkgs-xr.overlays.default ];

  #nix.settings = {
  #  substituters = [ "https://nix-community.cachix.org" ];
  #  trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  #};
}
