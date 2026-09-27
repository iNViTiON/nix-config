# NetworkManager, nftables and DNS-over-TLS via systemd-resolved.
{ ... }:
{
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;

  networking.nameservers = [
    "2606:4700:4700::1111#one.one.one.one"
    "2606:4700:4700::1001#one.one.one.one"
    "1.1.1.1#one.one.one.one"
    "1.0.0.1#one.one.one.one"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = true;
      Domains = [ "~." ];
      FallbackDNS = [
        "2606:4700:4700::1111#one.one.one.one"
        "2606:4700:4700::1001#one.one.one.one"
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
      ];
      DNSOverTLS = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
