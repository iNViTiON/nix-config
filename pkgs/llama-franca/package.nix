# Llama Franca (github.com/Th1nkK1D/llama-franca): translates web pages with a local
# model through an Ollama-compatible API on localhost:11434. Not in nixpkgs and not
# published to a browser store, so it is built here and loaded as an unpacked extension
# (see ../../modules/packages.nix for Vivaldi).
# Output: $out/share/llama-franca/{chrome-mv3,firefox-mv2}. To update: change rev and
# the source hash, then paste the "got: sha256-..." of the pnpmDeps hash it reports.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "llama-franca";
  version = "0.0.1-unstable-2026-10-06";

  src = fetchFromGitHub {
    owner = "Th1nkK1D";
    repo = "llama-franca";
    rev = "fcd9bf2b9d9ee2af5e570d6cf1bf7e2414e5bfad";
    hash = "sha256-ll6NkeEGnFSdR+rU943aFQG+V0nQKavefAR9gXfrM60=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-3Kkao8S7PgSC9yW0BZgt7DWNnsmxkag5bFGUfu942ms=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm build:chrome
    pnpm build:firefox
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/llama-franca
    cp -r dist/chrome-mv3 dist/firefox-mv2 $out/share/llama-franca/
    runHook postInstall
  '';

  meta = {
    description = "Browser extension that translates web pages with a local LLM";
    homepage = "https://github.com/Th1nkK1D/llama-franca";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
