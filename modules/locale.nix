# Time zone, locales and keyboard layout.
{ ... }:
{
  # Time zone follows your location (Tallinn, Bangkok, ...): automatic-timezoned asks
  # geoclue, which looks up nearby Wi-Fi networks with beaconDB, and sets the zone through
  # timedated. It requires time.timeZone to stay unset. To pin a zone by hand instead,
  # remove this and set time.timeZone = "Europe/Tallinn";
  services.automatic-timezoned.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocales = [
    "et_EE.UTF-8/UTF-8"
    "fi_FI.UTF-8/UTF-8"
    "th_TH.UTF-8/UTF-8"
    "ja_JP.UTF-8/UTF-8"
  ];

  # Estonian formats (dates, numbers, currency, paper size, sorting, ...), English app
  # language. This was LC_ALL = "et_EE.UTF-8", which overrides every other setting,
  # including LC_MESSAGES (the UI language), so apps such as Bitwarden showed Estonian.
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "et_EE.UTF-8";
    LC_COLLATE = "et_EE.UTF-8";
    LC_IDENTIFICATION = "et_EE.UTF-8";
    LC_MEASUREMENT = "et_EE.UTF-8";
    LC_MONETARY = "et_EE.UTF-8";
    LC_NAME = "et_EE.UTF-8";
    LC_NUMERIC = "et_EE.UTF-8";
    LC_PAPER = "et_EE.UTF-8";
    LC_TELEPHONE = "et_EE.UTF-8";
    LC_TIME = "et_EE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,th";
    variant = "colemak,mnc";
    options = "grp:win_space_toggle";
  };
}
