# llama.cpp with Vulkan, built from a pinned master commit (pins.json).
# nixpkgs-unstable's llama-cpp (0.6.0) predates embeddinggemma-2 support (llama.cpp PR
# #30054, merged a day after v0.6.0): it fails with "unknown model architecture:
# 'gemma-embedding2'". Once nixpkgs ships a release that has it, delete this file and use
# `pkgs-unstable.llama-cpp.override { vulkanSupport = true; }` in ../../modules/local-llm.nix.
# Update with `just llm-update`.
{ llama-cpp, fetchFromGitHub }:

let
  pin = (builtins.fromJSON (builtins.readFile ./pins.json)).llamaCpp;
in
(llama-cpp.override { vulkanSupport = true; }).overrideAttrs {
  version = "master-${builtins.substring 0 8 pin.rev}";
  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    inherit (pin) rev hash;
  };
  # nixpkgs' patches are for 0.6.0 and already part of master.
  patches = [ ];
  # Hash of tools/ui's package-lock.json; changes when the web UI's dependencies do.
  inherit (pin) npmDepsHash;
}
