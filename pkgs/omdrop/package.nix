# The `omdrop` command and AirDrop receiver (github:netmojo-systems/omdrop-plugin), made for
# Omarchy/Arch. It finds its own files relative to bin/omdrop (it looks for manifest.json one
# directory up), so the repo layout is kept under share/omdrop and bin/omdrop is a wrapper.
# Only the receiver's unit file is patched: it hardcodes /usr/bin/python3 and relies on a PATH.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  keyutils,
  bash,
  coreutils,
  findutils,
  gawk,
  gnugrep,
  gnused,
  iproute2,
  libnotify,
  openssl,
  procps,
  systemd,
  util-linux,
  writeShellScriptBin,
  wl-clipboard,
  xdg-utils,
  src,
}:

let
  python = python3.withPackages (ps: [
    ps.libarchive-c
    ps.pygobject3
  ]);

  # pacman's `vercmp`, which bin/omdrop uses to compare backend versions: prints -1, 0 or 1.
  vercmp = writeShellScriptBin "vercmp" ''
    if [ "$1" = "$2" ]; then echo 0
    elif [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; then echo -1
    else echo 1; fi
  '';

  runtimePath = lib.makeBinPath [
    python
    vercmp
    openssl
    bash
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    iproute2
    keyutils
    libnotify
    procps
    systemd
    util-linux
    wl-clipboard
    xdg-utils
  ];
in
stdenvNoCC.mkDerivation {
  pname = "omdrop";
  version = (builtins.fromJSON (builtins.readFile "${src}/manifest.json")).version;
  inherit src;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/omdrop $out/bin
    cp -r bin share manifest.json $out/share/omdrop/
    chmod +x $out/share/omdrop/bin/*

    # keyutils is not in /usr/lib or the loader path here. `doctor` and `setup` also probe
    # the receiver's Python for libarchive and libkeyutils, with /usr/bin/python3 by default.
    substituteInPlace $out/share/omdrop/bin/identity.py \
      --replace-fail "'libkeyutils.so.1'" "'${keyutils.lib}/lib/libkeyutils.so.1'"
    substituteInPlace $out/share/omdrop/bin/omdrop \
      --replace-fail ':-/usr/bin/python3}' ':-${python}/bin/python3}' \
      --replace-fail 'ctypes.CDLL("libkeyutils.so.1")' 'ctypes.CDLL("${keyutils.lib}/lib/libkeyutils.so.1")'

    # Run from anywhere (a leftover ~/.local/bin/omdrop symlink goes straight to this
    # script), with the same PATH as the wrapper. And no new such symlink: it would shadow
    # the system one and keep pointing at an old store path after an update.
    substituteInPlace $out/share/omdrop/bin/omdrop \
      --replace-fail '[[ -z "$current" || "$current" == */plugins/*/bin/omdrop ]]' 'false' \
      --replace-fail '  elif [[ "$current" != "$plugin/bin/omdrop" ]]; then' '  elif false; then'
    sed -i '1a export PATH="${runtimePath}:$PATH"' $out/share/omdrop/bin/omdrop

    # The service gets the same PATH as the command, and the Nix python.
    substituteInPlace $out/share/omdrop/share/airdrop-receiver.service \
      --replace-fail "ExecStart=/usr/bin/python3 " \
        "Environment=PATH=${runtimePath}"$'\n'"ExecStart=${python}/bin/python3 "

    makeWrapper $out/share/omdrop/bin/omdrop $out/bin/omdrop --prefix PATH : ${runtimePath}
    runHook postInstall
  '';

  meta = {
    description = "AirDrop send/receive command for the omdrop-owl radio backend";
    homepage = "https://github.com/netmojo-systems/omdrop-plugin";
    license = lib.licenses.mit;
    mainProgram = "omdrop";
  };
}
