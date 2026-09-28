# Japanese input: fcitx5 with Mozc. fcitx5 also takes over switching between your
# layouts, so all three are in one list: English (Colemak), Thai (Manoonchai), Japanese.
# Super+Space cycles forward through them, Super+Shift+Space back, and Ctrl+Super+Space
# (or the Copilot key) goes back to the previous language (in any text field).
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      # Apps talk to fcitx5 through the Wayland text-input protocol, instead of the old
      # GTK_IM_MODULE/QT_IM_MODULE variables (which the fcitx5 docs advise against on Wayland).
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
      settings = {
        # System defaults (/etc/xdg/fcitx5); changes made in fcitx5's own settings window
        # are saved in ~/.config/fcitx5 and take precedence.
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us-colemak";
            DefaultIM = "keyboard-us-colemak";
          };
          "Groups/0/Items/0".Name = "keyboard-us-colemak";
          "Groups/0/Items/1".Name = "keyboard-th-mnc";
          "Groups/0/Items/2".Name = "mozc";
        };
        globalOptions = {
          # Super+Space keeps its old job (next layout), now including Japanese.
          "Hotkey/EnumerateForwardKeys"."0" = "Super+space";
          "Hotkey/EnumerateBackwardKeys"."0" = "Super+Shift+space";
          # Ctrl+Super+Space (also the Copilot key, via ./kanata.nix): back to the
          # previous language. fcitx5's "trigger" toggles between English (the first entry)
          # and the other language used last, e.g. EN <-> JA after you've used Japanese.
          # This also moves the default trigger off Ctrl+Space, which editors use for
          # autocomplete.
          "Hotkey/TriggerKeys"."0" = "Control+Super+space";
          # No popup next to the text cursor showing the new language when you switch or
          # focus a text field; the tray icon shows it.
          Behavior = {
            ShowInputMethodInformation = "False";
            showInputMethodInformationWhenFocusIn = "False";
          };
        };
      };
    };
  };
}
