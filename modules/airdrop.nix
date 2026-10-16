# AirDrop with iPhones and Macs on the Intel BE201, which has no AWDL of its own:
# omdrop-owl (radio backend: OWL runs AWDL in userspace, plus the root helper and its polkit
# policy) and omdrop (the `omdrop` command and file receiver, ../pkgs/omdrop). Nothing runs
# until `omdrop on`; omdrop-owl's wiki lists the BE201 as untested, hence `allowUntested`.
# It only works in "exclusive" mode on Intel, which turns Wi-Fi off while visible; `omdrop off`
# brings it back. Wired internet keeps working. Received files land in ~/Downloads.
{ inputs, pkgs, ... }:

{
  imports = [ inputs.omdrop-owl.nixosModules.default ];

  services.omdrop-owl = {
    enable = true;
    allowUntested = true;
  };

  environment.systemPackages = [
    (pkgs.callPackage ../pkgs/omdrop/package.nix { src = inputs.omdrop-plugin; })
  ];
}
