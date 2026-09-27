# Intel Xe2 iGPU (Lunar Lake, Core Ultra 7 258V): only what nixos-hardware doesn't set.
# Was ms-edge.nix (the Microsoft Edge package was dropped; Vivaldi is the browser now).
# Removed as duplicates or dead settings:
# - intel-media-driver, vpl-gpu-rt, intel-compute-runtime: nixos-hardware's
#   lenovo-thinkpad-x1-13th-gen → common/gpu/intel adds them
# - NIXOS_OZONE_WL: set in ./desktop.nix
# - hardware.enableRedistributableFirmware: hardware-configuration.nix's
#   not-detected.nix already sets it
# - i915.enable_guc=3: this GPU uses the `xe` driver (nixos-hardware sets it for
#   kernels >= 6.8), so the i915 option was never read
{ ... }:

{
  hardware.graphics.enable = true;

  environment.sessionVariables = {
    # VA-API: use the iHD (intel-media-driver) backend; i965 is legacy and unsupported
    LIBVA_DRIVER_NAME = "iHD";
    ENABLE_HDR_WSI = "1"; # Required by KDE for HDR Wayland surface integration
  };
}
