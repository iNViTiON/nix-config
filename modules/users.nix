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
    ];
    # Per-user packages (kate, …) are in ../home/hisoft/packages.nix.
  };
}
