# IBM Plex (with Thai variants) as the default font families.
{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      ibm-plex
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        sansSerif = [
          "IBM Plex Sans Thai"
          "IBM Plex Sans Thai Looped"
          "IBM Plex Sans"
        ];

        serif = [
          "IBM Plex Serif Thai"
          "IBM Plex Serif"
        ];

        monospace = [
          "IBM Plex Mono"
        ];
      };
    };
  };
}
