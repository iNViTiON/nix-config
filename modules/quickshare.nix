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

  # Autostart rquickshare in the Plasma session so the tray icon is always
  # available. rquickshare is a desktop app that closes to tray; a user
  # systemd unit is the correct integration in 26.05 since no
  # services.rquickshare NixOS module exists yet.
  systemd.user.services.rquickshare = {
    description = "rquickshare — Quick Share for Linux";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.rquickshare}/bin/rquickshare";
      Restart = "on-failure";
      RestartSec = 5;
      # Defensive: harmless on Intel iGPU, fixes the rare blank-window bug.
      Environment = "WEBKIT_DISABLE_COMPOSITING_MODE=1";
    };
  };
}
