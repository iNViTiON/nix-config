# Llama Franca: translates web pages with a local model through an Ollama-compatible API
# on localhost:11434. Built from the iNViTiON fork's `npu` branch (upstream
# github.com/Th1nkK1D/llama-franca + a model/device picker for local-llm-npu-translator). Not in nixpkgs and not
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
  version = "0.0.1-unstable-2026-10-13";

  src = fetchFromGitHub {
    owner = "iNViTiON";
    repo = "llama-franca";
    rev = "8c64950659dd8640e104af259eb00c5066b7bbb0"; # branch npu
    hash = "sha256-HGR4skL2HIYb1xkPA3qR/bHd2bTAHoyZiibk4KtIIoU=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-FfN1rthqbywCvM3zT/Epej8iUNFRTi1CsEmSWJaxAZo=";
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
    homepage = "https://github.com/iNViTiON/llama-franca/tree/npu";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
