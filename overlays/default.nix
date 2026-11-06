# Local additions/overrides for the system `pkgs` (applied in ../modules/nix.nix).
# For simply newer app versions use `pkgs-unstable` instead; an overlay is for when
# `pkgs.<name>` itself has to change or a package is not in nixpkgs.
final: prev: {
  # Was the `usbeehive-flake` nix profile entry (~/Documents/usbeehive-flake).
  usbeehive = final.callPackage ../pkgs/usbeehive/package.nix { };
  # KDE Connect remote input in niri (RemoteDesktop portal); used in ../modules/compositors.nix.
  hypr-kdeconnect-portal = final.callPackage ../pkgs/hypr-kdeconnect-portal/package.nix { };
  # Accented letters in fcitx5's word hints (../modules/quick-accents). Only the package the
  # session runs gets the patch, so Mozc and the other fcitx5 addons aren't rebuilt.
  qt6Packages = prev.qt6Packages.overrideScope (
    _: qt6Prev: {
      fcitx5-with-addons = qt6Prev.fcitx5-with-addons.override {
        fcitx5 = prev.fcitx5.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../modules/quick-accents/hint-list.patch ];
        });
      };
    }
  );
}
