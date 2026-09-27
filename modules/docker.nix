{ config, pkgs, ... }:
{
  # ── Kernel ─────────────────────────────────────────────────────────────────
  # Rootless Docker needs no host IP forwarding (rootlesskit/slirp4netns run their own
  # network namespace), and the NixOS kernel allows unprivileged user namespaces by
  # default, so the old `kernel.unprivileged_userns_clone` / forwarding sysctls were
  # dropped. IPv4 forwarding for Waydroid is set in ./waydroid.nix.
  boot.kernelModules = [
    "ip_tables"
    "ip6_tables"
    "iptable_nat"
    "ip6table_nat"
    "xt_conntrack"
  ];

  # ── User ───────────────────────────────────────────────────────────────────
  # subUID/subGID ranges let the daemon remap UIDs inside containers.
  # Replace "youruser" with your actual username (run `whoami` to confirm).
  # No `linger` — Docker stops cleanly when you log out.
  users.users.hisoft = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # ── Docker ─────────────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = false; # root-level daemon is disabled

    rootless = {
      enable = true;

      # Writes /etc/profile.d/docker-rootless.sh which exports:
      #   DOCKER_HOST=unix:///run/user/<UID>/docker.sock
      # This is the correct configuration.nix approach — environment.sessionVariables
      # cannot resolve $XDG_RUNTIME_DIR (which embeds the runtime UID) at eval time.
      setSocketVariable = true;

      daemon.settings = {
        storage-driver = "btrfs"; # use native BTRFS subvolumes for image layers
        log-driver = "journald"; # container logs visible via `journalctl --user`
        default-address-pools = [
          {
            base = "172.30.0.0/16";
            size = 24;
          }
        ];
        dns = [
          "1.1.1.1"
          "8.8.8.8"
          "1.0.0.1"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [ slirp4netns ];

  # ── Aliases ────────────────────────────────────────────────────────────────
  environment.shellAliases = {
    docker-start = "systemctl --user start docker";
    docker-stop = "systemctl --user stop docker";
    docker-status = "systemctl --user status docker";
  };

  # ── Privileged port forwarding (OPTIONAL) ──────────────────────────────────
  # Uncomment this entire block only if you need to serve on ports < 1024
  # (e.g. 80/443). Rootless containers cannot bind those ports directly.
  # The kernel rewrites incoming packets at PREROUTING before any process
  # sees them, redirecting :80/:443 → :8080/:8443 where your container listens.
  #
  # In your compose.yml, bind the container to the high ports:
  #   ports:
  #     - "8080:80"
  #     - "8443:443"

  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 80 443 8080 8443 ];
  # };
  #
  # boot.kernel.sysctl = {
  #   "net.ipv4.conf.all.forwarding" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  # };
  #
  # networking.firewall.extraCommands = ''
  #   # IPv4
  #   iptables  -t nat -A PREROUTING -p tcp --dport 80  -j REDIRECT --to-port 8080
  #   iptables  -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
  #   # IPv6
  #   ip6tables -t nat -A PREROUTING -p tcp --dport 80  -j REDIRECT --to-port 8080
  #   ip6tables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
  # '';
  #
  # networking.firewall.extraStopCommands = ''
  #   iptables  -t nat -D PREROUTING -p tcp --dport 80  -j REDIRECT --to-port 8080 2>/dev/null || true
  #   iptables  -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 2>/dev/null || true
  #   ip6tables -t nat -D PREROUTING -p tcp --dport 80  -j REDIRECT --to-port 8080 2>/dev/null || true
  #   ip6tables -t nat -D PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443 2>/dev/null || true
  # '';
}
