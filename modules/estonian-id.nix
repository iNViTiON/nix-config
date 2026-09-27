# Estonian ID card: DigiDoc4, Web eID browser extension host, OpenSC PKCS#11 module.
{ pkgs, pkgs-unstable, ... }:
{
  # Start EE ID
  environment.systemPackages = with pkgs-unstable; [
    opensc
    p11-kit
    qdigidoc
    web-eid-app
  ];
  # End EE ID

  # Smart card daemon for the ID card reader.
  services.pcscd.enable = true;

  # EE ID
  # NOTE: carried over as-is: these paths use stable `pkgs`, while the packages above
  # come from `pkgs-unstable`.
  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";
  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';
}
