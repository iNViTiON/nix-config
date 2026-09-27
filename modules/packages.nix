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
    # ~/tunnel.sh hard-codes /run/current-system/sw/bin/cloudflared
    pkgs-unstable.cloudflared
    # Manual fallback only: `bu` now uses cryptsetup. Remove once `sudo bu` is tested.
    dislocker
    intel-npu-driver
    ntfs3g # `bu`: mount looks for the mount.ntfs-3g helper in system paths
    opendrop
    owl # with opendrop; needs root / monitor mode
    python3
    usbutils # `refprintd` runs usbreset with sudo
    util-linux
    # Vivaldi and its codecs must be in the same profile; browser integration is
    # set up system-wide (./browser-integration.nix)
    vivaldi
    vivaldi-ffmpeg-codecs
  ];
}
