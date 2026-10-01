# Plymouth script theme: Mitch whisking matcha, Mälu and friends waiting (2880x1800 sprites,
# scaled at load to the real screen). Sprites come from the brand files (Mitch logo SVG, "Mälu CI"
# PDF page 4), recoloured cream for a true-black background.
{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-mitch";
  version = "1";
  src = ./mitch-theme;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    dir=$out/share/plymouth/themes/mitch
    mkdir -p $dir
    cp *.png mitch.script $dir/
    substitute mitch.plymouth $dir/mitch.plymouth --subst-var out
    runHook postInstall
  '';
}
