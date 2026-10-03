# Secure Boot (lanzaboote), LUKS unlock via TPM2, systemd initrd, swap and kernel.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Was `(import sources.lanzaboote { inherit pkgs; }).nixosModules.lanzaboote` via lon.
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    # The EFI partition is only 256M and each kernel + initrd takes ~69M, so keep at
    # most two generations in the boot menu (current + one fallback). Older generations
    # stay available until GC via `nixos-rebuild switch --rollback` from a running system.
    configurationLimit = 2;
  };
  # boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/44c43796-65a5-4ade-aee4-e697321fb2f4";
  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32 * 1024;
    }
  ];
  boot.initrd.systemd = {
    enable = true;
    tpm2.enable = true;
  };

  # /tmp is a plain directory on the btrfs @root subvolume (not tmpfs), so nothing ever
  # emptied it: leftovers piled up, including old `result` links that pinned whole
  # system closures against GC. Wipe it at every boot.
  boot.tmp.cleanOnBoot = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Secure Boot key management (was in the main package list).
  environment.systemPackages = [ pkgs.sbctl ];
}
