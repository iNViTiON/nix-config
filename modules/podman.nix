{ pkgs, ... }:
{
  virtualisation.containers = {
    enable = true;
    storage.settings = {
      storage = {
        driver = "btrfs";
      };
    };
    registries.search = [ "docker.io" ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    # autoPrune = {
    #   enable = true;
    #   # Runs every Sunday at 03:00.
    #   dates = "Sun *-*-* 03:00:00";
    #   # Only prune images/containers older than 7 days.
    #   flags = [ "--filter" "until=168h" ];
    # };
  };

  # podman-compose: drop-in replacement for docker-compose.
  environment.systemPackages = with pkgs; [
    dive
    podman-tui
    # docker-compose
    podman-compose
  ];
}
