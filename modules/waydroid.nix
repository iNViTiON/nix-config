{
  config,
  lib,
  pkgs,
  ...
}:

let
  # IMPORTANT: Find your Intel GPU path with: ls -l /dev/dri/by-path/ | grep pci-.*-render
  # Usually: pci-0000:00:02.0-render (Intel is typically at 00:02.0)
  intelRenderNode = "/dev/dri/by-path/pci-0000:00:02.0-render";
in
{
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  environment.systemPackages = with pkgs; [
    waydroid-helper
  ];
  # Network configuration
  # Don't fully trust the container: the NixOS waydroid module adds waydroid0 to
  # trustedInterfaces, which lets Android apps reach every service on the host. Allow
  # only DNS + DHCP from Waydroid's dnsmasq.
  # mkForce replaces the whole list, so "lo" (which the NixOS firewall module adds
  # itself) must stay in it. Without it every new loopback connection is dropped,
  # including dnsmasq -> systemd-resolved at 127.0.0.53, which broke Waydroid's DNS.
  # Any trusted interface added elsewhere later has to be listed here too.
  networking.firewall.trustedInterfaces = lib.mkForce [ "lo" ];
  networking.firewall.interfaces.waydroid0 = {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [ 53 ];
  };
  # IPv4 forwarding is needed for Waydroid's NAT. With filterForward the laptop only
  # forwards traffic coming from waydroid0 (plus the replies), instead of routing
  # between all interfaces.
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = 1;
  networking.firewall.filterForward = true;
  networking.firewall.extraForwardRules = ''
    iifname "waydroid0" accept
  '';

  # Enhance default service (NO lib.mkForce to avoid breaking network/cgroups!)
  systemd.services.waydroid-container = {
    serviceConfig = {
      # Enable cgroups v2 delegation (fixes "Read-only file system" errors)
      Delegate = true;
      CPUAccounting = true;
      MemoryAccounting = true;
      TasksAccounting = true;

      # GPU fix runs BEFORE container starts (no race conditions)
      ExecStartPre = lib.mkAfter [
        (pkgs.writeShellScript "waydroid-gpu-fix-pre" ''
          set -e
          PROP_FILE="/var/lib/waydroid/waydroid.prop"

          mkdir -p /var/lib/waydroid
          touch "$PROP_FILE"
          chown root:root "$PROP_FILE"
          chmod 644 "$PROP_FILE"

          # Function to set properties (removes old, adds new)
          set_prop() {
            ${pkgs.gnused}/bin/sed -i "/^$1=/d" "$PROP_FILE"
            echo "$1=$2" >> "$PROP_FILE"
          }

          # Force Intel GPU (GBM/Mesa)
          set_prop ro.hardware.gralloc gbm
          set_prop ro.hardware.egl mesa
          set_prop gralloc.gbm.device ${intelRenderNode}
          set_prop ro.hardware.vulkan intel

          # Clean empty lines
          ${pkgs.gnused}/bin/sed -i '/^$/d' "$PROP_FILE"
        '')
      ];
    };
  };

  # Backup persistence service (runs after start as fallback)
  systemd.services.waydroid-gpu-persistence = {
    description = "Enforce Intel GPU for Waydroid (Post-Start Backup)";
    after = [ "waydroid-container.service" ];
    bindsTo = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "waydroid-intel-fix-post" ''
        set -e
        ${pkgs.coreutils}/bin/sleep 5
        ${config.virtualisation.waydroid.package}/bin/waydroid prop set ro.hardware.gralloc gbm
        ${config.virtualisation.waydroid.package}/bin/waydroid prop set ro.hardware.egl mesa
        ${config.virtualisation.waydroid.package}/bin/waydroid prop set gralloc.gbm.device ${intelRenderNode}
        ${config.virtualisation.waydroid.package}/bin/waydroid prop set ro.hardware.vulkan intel
      '';
    };
  };
}
