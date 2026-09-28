{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Static port to pin in ~/.local/share/dev.mandre.rquickshare/.settings.json
  rquickSharePort = 47983;
in
{
  environment.systemPackages = with pkgs; [
    rquickshare # Tauri-2 source build from nixpkgs 26.05
    # rquickshare-legacy  # only if you hit GTK/EGL issues on Wayland
  ];

  # LocalSend for cross-platform (iPhone, Mac, Windows) since AirDrop is dead
  # on the BE201. Module ships in nixpkgs 26.05 at
  # nixos/modules/programs/localsend.nix and opens TCP+UDP 53317.
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # rquickshare uses mDNS (UDP 5353) for discovery plus a TCP port for the
  # actual transfer (random by default). The TCP port is pinned in settings.json
  # (currently 47983) and both are opened, on every network.
  # (This used to be a separate nftables table with `accept` rules. Those never opened
  # anything: an accept in one base chain doesn't stop the NixOS firewall's own input
  # chain from dropping the packet. LocalSend's 53317 comes from
  # programs.localsend.openFirewall above.)
  networking.firewall = {
    allowedUDPPorts = [ 5353 ];
    allowedTCPPorts = [ rquickSharePort ];
  };

  # Bluetooth LE is required for rquickshare to wake Android's Quick Share
  # advertiser. The user already has:
  #   hardware.bluetooth.enable = true;
  #   hardware.bluetooth.powerOnBoot = true;
  #   hardware.bluetooth.settings.General.Experimental = true;
  # which is exactly what's needed.

  # No systemd service for rquickshare: the app starts itself at login through its own
  # "Autostart" setting (~/.config/autostart/RQuickShare.desktop). A service used to start
  # it too; the second copy then told the first to open its window, ignoring
  # "Start minimized". The autostart entry also waits for the tray (home/hisoft/niri.nix).
}
