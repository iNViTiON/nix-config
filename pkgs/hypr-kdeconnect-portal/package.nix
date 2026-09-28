# KDE Connect remote input (the phone as this PC's mouse and keyboard) in niri. niri has no
# xdg-desktop-portal "RemoteDesktop" backend, which KDE Connect needs on Wayland; this is
# one, injecting input through the wlr virtual-pointer and virtual-keyboard protocols that
# niri supports. Written for Hyprland, works on any compositor with those protocols.
# Not in nixpkgs. Wired up in ../../modules/compositors.nix.
# Update: change `rev` to a newer commit and `hash` to lib.fakeHash, build, and paste the
# hash from the error.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  wayland-scanner,
  kdePackages,
  wayland,
  libxkbcommon,
  libei,
}:

stdenv.mkDerivation {
  pname = "hypr-kdeconnect-portal";
  version = "0-unstable-2026-09-24";

  src = fetchFromGitHub {
    owner = "gfhdhytghd";
    repo = "hypr-kdeconnect-fix";
    rev = "362b904235c1b1d679eef73cbd5ad08d313d8954";
    hash = "sha256-fswdn3iq1iCXALLWC/p5EgRYbHIMgNHWEhxEtbHtCFY=";
  };

  # Normally the bridge accepts KDE Connect by the app id the portal reports
  # (org.kde.kdeconnect.daemon, from its autostart unit). Its fallback for callers without
  # an app id checks the daemon's executable path, and only knows FHS paths; add ours.
  postPatch = ''
    substituteInPlace src/security_policy.hpp \
      --replace-fail 'return executablePath == QStringLiteral("/usr/bin/kdeconnectd") ||' \
        'return executablePath == QStringLiteral("${kdePackages.kdeconnect-kde}/bin/.kdeconnectd-wrapped") || executablePath == QStringLiteral("/usr/bin/kdeconnectd") ||'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    wayland-scanner
    kdePackages.wrapQtAppsNoGuiHook
  ];

  buildInputs = [
    kdePackages.qtbase
    wayland
    libxkbcommon
    libei
  ];

  doCheck = true;

  # NixOS installs user units from lib/systemd/user (systemd.packages, which
  # xdg.portal.extraPortals feeds); CMake puts it in share/. The D-Bus activation file starts
  # the portal through this unit. (stdenv then keeps the file in share/ and links lib/ to it.)
  postInstall = ''
    mkdir -p $out/lib/systemd
    mv $out/share/systemd/user $out/lib/systemd/user
    rmdir $out/share/systemd
  '';

  meta = {
    description = "xdg-desktop-portal RemoteDesktop backend for KDE Connect remote input on virtual-input Wayland compositors";
    homepage = "https://github.com/gfhdhytghd/hypr-kdeconnect-fix";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "hypr-kdeconnect-portal";
  };
}
