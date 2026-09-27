{ pkgs, ... }:
{
  programs = {
    bat.enable = true;
    zoxide = {
      enable = true;
      flags = [
        "--hook none"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    btop
    delta
    dogedns
    dust
    eza
    fd
    ripgrep
  ];
}
