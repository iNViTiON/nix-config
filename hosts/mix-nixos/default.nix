# mix-nixos: this was /etc/nixos/configuration.nix. Machine-specific settings stay here;
# everything reusable moved to ../../modules. Help is available in the
# configuration.nix(5) man page and in the NixOS manual (`nixos-help`).
{ inputs, pkgs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Secure Boot (lanzaboote), LUKS + TPM2, swap, kernel.
    ./boot.nix
    # Was the `<nixos-hardware/lenovo/thinkpad/x1/13th-gen>` channel import.
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen

    # Split out of the old configuration.nix
    ../../modules/nix.nix
    ../../modules/locale.nix
    ../../modules/networking.nix
    ../../modules/desktop.nix
    ../../modules/fonts.nix
    ../../modules/users.nix
    ../../modules/programs.nix
    ../../modules/services.nix
    ../../modules/packages.nix
    ../../modules/power.nix
    ../../modules/estonian-id.nix
    ../../modules/browser-integration.nix

    # Carried over from /etc/nixos unchanged
    ../../modules/boot-animation
    # Claude Desktop now comes from the claude-desktop-extra flake input
    # (home/hisoft/packages.nix), which replaced claude-desktop.nix.
    ../../modules/docker.nix
    ../../modules/faster-boot.nix
    # ../../modules/japanese.nix
    ../../modules/graphics.nix
    # ../../modules/podman.nix
    ../../modules/quickshare.nix
    ../../modules/rust-replacement.nix
    ../../modules/tunnel.nix
    ../../modules/kanata.nix
    # nixpkgs-xr overlay; also uncomment the `nixpkgs-xr` input in flake.nix
    # ../../modules/vr.nix
    ../../modules/waydroid.nix
  ];

  networking.hostName = "mix-nixos"; # Must match `nixosConfigurations.<name>` in flake.nix.

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
    };
  };

  boot.kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];
  hardware.keyboard.zsa.enable = true;
  hardware.cpu.intel = {
    npu.enable = true;
    updateMicrocode = true;
  };

  # mix custom
  services.fprintd.enable = true;

  powerManagement.powerDownCommands = ''
    ${pkgs.systemd}/bin/systemctl stop fprintd.service 2>/dev/null || true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
