# "Gaegu Mitch": Gaegu (the handwriting font used on the lock screen and login screen) plus the letters it lacks,
# built when the system is built. Gaegu has no ä ö ü õ and no kana. See ./build.py for how they are added.
# Both source fonts are under the SIL Open Font License; the result is a modified version, so it has its own name.
{ pkgs }:
let
  rev = "5174b3333331c966c38f4355d50b03ca1c1df2f9";
  gaegu = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/gaegu/Gaegu-Regular.ttf";
    hash = "sha256-qlLJgzb3xi4olvyLErVqddW0dtiKLxBLCYD0984K38M=";
  };
  yomogi = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/google/fonts/${rev}/ofl/yomogi/Yomogi-Regular.ttf";
    hash = "sha256-NCTjS7lR6Jv13SVUpl2JZDNeo8BWD40eqao1ke9zy6k=";
  };
in
pkgs.runCommand "gaegu-mitch-font"
  { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.fonttools ])) ]; }
  ''
    mkdir -p $out/share/fonts/truetype
    python3 ${./build.py} ${gaegu} ${yomogi} $out/share/fonts/truetype/GaeguMitch-Regular.ttf
  ''
