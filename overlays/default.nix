# Local additions/overrides for the system `pkgs` (applied in ../modules/nix.nix).
# For simply newer app versions use `pkgs-unstable` instead; an overlay is for when
# `pkgs.<name>` itself has to change or a package is not in nixpkgs.
final: prev: {
  # Was the `usbeehive-flake` nix profile entry (~/Documents/usbeehive-flake).
  usbeehive = final.callPackage ../pkgs/usbeehive/package.nix { };
  # KDE Connect remote input in niri (RemoteDesktop portal); used in ../modules/compositors.nix.
  hypr-kdeconnect-portal = final.callPackage ../pkgs/hypr-kdeconnect-portal/package.nix { };
  # Translation browser extension (unpacked build); loaded by Vivaldi in ../modules/packages.nix.
  llama-franca = final.callPackage ../pkgs/llama-franca/package.nix { };
}
