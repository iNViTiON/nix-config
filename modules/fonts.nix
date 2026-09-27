# IBM Plex (with Thai variants) as the default font families.
{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      ibm-plex
      # Icon fonts. Without them bar icons render as empty boxes: waybar's default config
      # draws its icons with Font Awesome, many bar and terminal configs use Nerd Font
      # symbols, and DankMaterialShell uses Material Symbols (and Fira Code as mono).
      font-awesome
      nerd-fonts.symbols-only
      material-symbols
      fira-code
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
