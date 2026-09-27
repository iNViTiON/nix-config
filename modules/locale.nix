# Time zone, locales and keyboard layout.
{ ... }:
{
  # Set your time zone.
  time.timeZone = "Europe/Tallinn";
  # time.timeZone = "Asia/Bangkok";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocales = [
    "et_EE.UTF-8/UTF-8"
    "fi_FI.UTF-8/UTF-8"
    "th_TH.UTF-8/UTF-8"
    "ja_JP.UTF-8/UTF-8"
  ];

  i18n.extraLocaleSettings = {
    LC_ALL = "et_EE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,th";
    variant = "colemak,mnc";
    options = "grp:win_space_toggle";
  };
}
