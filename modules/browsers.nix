# Browsers next to Vivaldi (./packages.nix, still the default browser): Helium, and the
# extensions both of them get.
#
# Helium reads the same system folders as Chromium: native-messaging hosts from
# /etc/chromium/native-messaging-hosts, so Bitwarden, Plasma Integration and Web eID
# (./browser-integration.nix, ./estonian-id.nix) work in it with no extra setup, and
# policies from /etc/chromium/policies. Its profile is ~/.config/net.imput.helium.
{ inputs, pkgs, ... }:
let
  # Extensions installed by policy into every profile of Vivaldi and Helium, from the
  # Chrome Web Store. "normal_installed": you can turn one off in the browser but not
  # remove it; it reinstalls itself if deleted. Only the install is declared: each one's
  # settings (Vimium keys, SwitchyOmega profiles, ...) stay in the browser profile.
  # Other extensions (Tampermonkey, Claude, Proton VPN, ...) can still be added by hand.
  extensions = {
    nngceckbapebfimnlniiiahkandclblb = "Bitwarden";
    cimiefiiaegbelhefglklhhakcgmhkai = "Plasma Integration";
    ncibgoaomkmdpilpocfeponihegamlic = "Web eID";
    dbepggeogbaibhgnhhndojpepiihcmeb = "Vimium";
    hihblcmlaaademjlakdpicchbjnnnkbo = "Proxy SwitchyOmega (V3)";
    jpbjcnkcffbooppibceonlgknpkniiff = "Global Speed";
    kngfjpghaokedippaapkfihdlmmlafcc = "Locale Switcher";
    llenpijlflekljkpjnbnmkfeakfmlcmb = "Load Lazyload Images";
    mdjildafknihdffpkfmmpnpoiajfjnjd = "Consent-O-Matic";
    ponfpcnoihfmfllpaingbgckeeldkhle = "Enhancer for YouTube";
    mdlbikciddolbenfkgggdegphnhmnfcg = "New Netflix 1080p";
    pjdbebkgllbkjfbbbbceeeenhkngnddp = "Video Downloader (M3U8)";
  };
  extensionPolicy = {
    ExtensionSettings = builtins.mapAttrs (_: _: {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    }) extensions;
  };
in
{
  imports = [ inputs.helium.nixosModules.default ];

  # Vivaldi reads its policies from /etc/vivaldi/policies (not /etc/chromium).
  environment.etc."vivaldi/policies/managed/extensions.json".text = builtins.toJSON extensionPolicy;

  programs.helium = {
    enable = true;
    # Same as Vivaldi's flags (./packages.nix): KDE Wallet for passwords in niri too,
    # fcitx5 typing (Thai, Japanese). --ozone-platform-hint=auto is needed: the package
    # passes it through a shell idiom its binary wrapper never expands, so Helium would
    # fall back to XWayland and ignore the output scale (from lk-nix).
    flags = [
      "--ozone-platform-hint=auto"
      "--password-store=kwallet6"
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"
      # Llama Franca (../pkgs/llama-franca), the local-LLM page translator, as in Vivaldi:
      # an unpacked build, not in the Web Store. Chrome 137+ ignores --load-extension unless
      # the DisableLoadExtensionCommandLineSwitch feature is turned off.
      "--load-extension=${pkgs.llama-franca}/share/llama-franca/chrome-mv3"
      "--disable-features=DisableLoadExtensionCommandLineSwitch"
    ];
    # Written to /etc/chromium/policies/managed (and /etc/helium/...).
    policies = extensionPolicy;
  };

  # DRM (Netflix, Spotify web): Helium ships no Widevine CDM and its own folder is in the
  # read-only store. Its component updater reads this hint file to find a sideloaded one,
  # here nixpkgs' widevine-cdm. https://github.com/imputnet/helium/issues/116
  # Vivaldi needs none of this: it downloads its own copy into ~/.config/vivaldi.
  home-manager.users.hisoft.xdg.configFile."net.imput.helium/WidevineCdm/latest-component-updated-widevine-cdm".text =
    builtins.toJSON {
      Path = "${pkgs.widevine-cdm}/share/google/chrome/WidevineCdm";
    };
}
