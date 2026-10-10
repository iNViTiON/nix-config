# System packages: only what root, boot, hardware or other system config needs.
# Personal apps and dev tools are in ../home/hisoft/packages.nix (Home Manager).
# Also system-level, in their own modules: sbctl (../hosts/mix-nixos/boot.nix),
# EE ID packages (./estonian-id.nix), the CLI tools in ./rust-replacement.nix.
{ pkgs, pkgs-unstable, ... }:
{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    bind # dig/host, also used as root
    # Must be system-wide: biometric / "system authentication" unlock goes through polkit,
    # and polkit only reads action policies (com.bitwarden.Bitwarden.policy) from the
    # system profile, not from the Home Manager / per-user profile.
    bitwarden-desktop
    # ~/tunnel.sh hard-codes /run/current-system/sw/bin/cloudflared
    pkgs-unstable.cloudflared
    intel-npu-driver
    ntfs3g # `bu`: mount looks for the mount.ntfs-3g helper in system paths
    opendrop
    owl # with opendrop; needs root / monitor mode
    python3
    usbutils # `refprintd` runs usbreset with sudo
    util-linux
    # Vivaldi and its codecs must be in the same profile; browser integration is
    # set up system-wide (./browser-integration.nix). Saved passwords and cookie keys
    # always go to KDE Wallet: Chromium only picks it by itself under Plasma, and in
    # niri it would switch to another store and lose access to them.
    (vivaldi.override {
      # --enable-wayland-ime: typing through fcitx5 (Thai, Japanese; ./japanese.nix).
      # --force-dark-mode: websites always get "dark" (prefers-color-scheme), private windows
      # included; those ignore the system setting in niri. It stays dark even if the system
      # is switched to light.
      # --load-extension: Llama Franca (../pkgs/llama-franca), an unpacked build because it isn't
      # in the Chrome Web Store. Its id comes from the store path, so it changes when the
      # package is updated (its settings are reset then).
      commandLineArgs = "--password-store=kwallet6 --enable-wayland-ime --wayland-text-input-version=3 --force-dark-mode --load-extension=${llama-franca}/share/llama-franca/chrome-mv3";
    })
    vivaldi-ffmpeg-codecs
  ];
}
