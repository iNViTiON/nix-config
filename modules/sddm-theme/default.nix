# SDDM login screen with the same scene as the boot splash (./../boot-animation/mitch-theme): Mitch whisking,
# Mälu hopping, friends around, on true black. The sprites are the splash's own PNGs, copied in at build time.
{ pkgs, ... }:
let
  # The theme directory is named after a hash of its files. Store files all share one timestamp, so Qt's
  # compiled-QML cache (keyed by path) would keep serving the previous version of an updated theme.
  # A new name for every change gives it a new path, so the cache never matches stale code.
  qmlFiles = [ "Main.qml" "Friend.qml" "Anim.js" "metadata.desktop" "theme.conf" ];
  hash = builtins.substring 0 8 (
    builtins.hashString "sha256" (pkgs.lib.concatMapStrings (f: builtins.readFile (./theme + "/${f}")) qmlFiles)
  );
  themeName = "mitch-${hash}";
  sprites = [
    "mitch" "malu" "pear_n" "pear_f" "bean_n" "bean_f" "round_n" "round_f" "bean2_n" "bean2_f" "flat_n"
    "a_star" "a_yarc" "a_arc" "a_bdash" "a_pdash" "swish0" "swish1" "swish2"
  ];
  mitch-sddm-theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-theme-mitch";
    version = "1";
    src = ./theme;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      dir=$out/share/sddm/themes/${themeName}
      mkdir -p $dir/assets
      cp *.qml Anim.js metadata.desktop theme.conf $dir/
      ${pkgs.lib.concatMapStringsSep "\n" (n: "cp ${../boot-animation/mitch-theme}/${n}.png $dir/assets/") sprites}
      runHook postInstall
    '';
  };
in
{
  services.displayManager.sddm.theme = themeName;
  environment.systemPackages = [ mitch-sddm-theme ];
}
