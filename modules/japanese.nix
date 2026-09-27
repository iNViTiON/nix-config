# japanese.nix
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # plasma6Support = true;
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
      settings = {
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "keyboard-us-colemak";
            DefaultIM = "keyboard-us-colemak";
          };
          "Groups/0/Items/0".Name = "keyboard-us-colemak";
          "Groups/0/Items/1".Name = "keyboard-th-mnc";
          "Groups/0/Items/2".Name = "mozc";
        };
      };
    };
  };
}
