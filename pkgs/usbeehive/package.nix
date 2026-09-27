# Moved here from ~/Documents/usbeehive-flake (was installed with `nix profile add`).
# That flake built against nixos-25.11; this builds against the system's nixos-26.05.
# If the build reports a cargoHash mismatch, paste the "got: sha256-..." value below.
# Test on its own with `nix build .#usbeehive`.
{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  udev,
}:

rustPlatform.buildRustPackage rec {
  pname = "usbeehive";
  version = "0.8.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-9NQ94xzS/3enifcjBKRpMvAbCOFNbuOmIdUcs7qgJx0=";
  };

  cargoHash = "sha256-buLcPGwkMVLjI5czpxehWBV9f8AED/fXXwECzRpCvmg=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ udev ]; # libudev for the default watch (hotplug) feature

  meta = {
    description = "Tells you what each USB cable / device on Linux can actually do";
    homepage = "https://github.com/abrauchli/usbeehive";
    license = lib.licenses.mit;
    mainProgram = "usbeehive";
  };
}
