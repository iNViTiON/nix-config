# User accounts. Per-user dotfiles and packages live in ../home (Home Manager).
{ ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.hisoft = {
    isNormalUser = true;
    description = "iNViTiON";
    extraGroups = [
      "networkmanager"
      "wheel"
      "kvm"
      # Screenkey (DMS plugin) reads /dev/input. That also lets any program you run read
      # every keystroke (passwords too): remove this and the plugin if you don't want that.
      "input"
    ];
    # Per-user packages (kate, …) are in ../home/hisoft/packages.nix.
  };
}
