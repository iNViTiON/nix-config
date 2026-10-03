# Miscellaneous system services.
# Networking/DNS (./networking.nix), power (./power.nix) and the smart card daemon
# (./estonian-id.nix) live in their own modules; fprintd is host-specific
# (../hosts/mix-nixos/default.nix).
{ ... }:
{
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  services = {
    devmon.enable = true;
    fwupd.enable = true;
    gvfs.enable = true;
    # Cap the persistent journal; the default (10% of the filesystem, up to 4G) let it
    # reach 2.3G.
    journald.extraConfig = ''
      SystemMaxUse=500M
    '';
    # SSH SOCKS tunnel user service, defined in ./tunnel.nix
    rpi-tunnel.enable = true;
    # thermald not support on Lenovo
    # (note: nixos-hardware's x1 13th-gen module still enables it with mkDefault)
    #thermald = {
    #  enable = false;
    #  package = local.thermald;
    #};
    udisks2.enable = true;
    wivrn = {
      enable = true;
      #package = wivrn;
      openFirewall = true;
      #defaultRuntime = true;
      autoStart = false;
    };
  };
}
