# Home Manager configuration for hisoft (installed as a NixOS module, see flake.nix).
# Applied by `nixos-rebuild switch`; no separate `home-manager switch` needed.
{ ... }:
{
  imports = [
    ./bash.nix
    ./git.nix
    ./niri.nix
    ./packages.nix
    ./plasma.nix
    ./scripts.nix
  ];

  # Home Manager is first used on 26.05, so its state version is 26.05. This is separate
  # from NixOS's system.stateVersion (still "25.11"). Home Manager can be updated
  # without changing this value.
  home.stateVersion = "26.05";
}
