# Llama Franca: translates web pages with a local model through an Ollama-compatible API
# on localhost:11434. Built from the iNViTiON fork's `npu` branch (upstream
# github.com/Th1nkK1D/llama-franca + a model/device picker for local-llm-npu-translator). Not in nixpkgs and not
# published to a browser store, so it is built here and loaded as an unpacked extension
# (see ../../modules/packages.nix for Vivaldi).
# Output: $out/share/llama-franca/{chrome-mv3,firefox-mv2}.
# The source is the `llama-franca` flake input (flake.nix, branch npu), passed in by
# ../../modules/nix.nix, so `just up` / `just upp llama-franca` bump it. Only the pnpmDeps
# hash is manual: when pnpm-lock.yaml changed, build once, paste the "got: sha256-..." it
# reports (or set the hash to lib.fakeHash first).
{
  lib,
  stdenv,
  fetchPnpmDeps,
  nodejs,
  pnpm,
  pnpmConfigHook,
  src, # the `llama-franca` flake input
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "llama-franca";
  version = "0.0.1-unstable-${lib.substring 0 8 src.lastModifiedDate}";

  inherit src;

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
    homepage = "https://github.com/iNViTiON/llama-franca/tree/npu";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
