# Offline chatbot: Ollama (Vulkan, Intel Arc iGPU) + Gemma 4 + Open WebUI.
# Ollama comes from nixpkgs-unstable (0.40.0): on 26.05's 0.32.3 the Vulkan runner died with
# xe "Timedout job" / ErrorDeviceLost, which also resets the display GPU. On 0.40.0 that
# still happens with the default batch size on long prompts; num_batch 256 avoided it in
# testing (num_batch 64 fails to load Gemma 4's vision encoder).
# Ollama listens on 11435 because the NPU translator (local-llm-npu-translator,
# used by the Llama Franca extension) owns 11434.
# Open WebUI: http://localhost:3000 (localhost only). Start/stop: see `llm-start` / `llm-stop`.
{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  ollamaPort = 11435;
  baseModel = "gemma4:12b-it-q4_K_M"; # ~8 GB; Ollama's default 4K context is too small
  localModel = "gemma4-local";
  numCtx = 32768; # tested on the GPU: no xe timeouts, ~15 GiB RAM used with it loaded

  # Embeddings for Open WebUI's document search: embeddinggemma-2 (text, image, audio) on
  # llama.cpp. Ollama can't serve it: its tags need MLX and its llama.cpp is too old.
  # Versions and hashes are in ../pkgs/local-llm/pins.json; refresh with `just llm-update`.
  pins = (builtins.fromJSON (builtins.readFile ../pkgs/local-llm/pins.json)).embeddingGemma;
  embedPort = 8089;
  llamaCpp = pkgs-unstable.callPackage ../pkgs/local-llm/llama-cpp.nix { };
  embedFile =
    part:
    pkgs.fetchurl {
      name = pins.${part}.file;
      url = "https://huggingface.co/${pins.repo}/resolve/${pins.rev}/${pins.${part}.file}";
      inherit (pins.${part}) sha256;
    };

  modelfile = pkgs.writeText "gemma4-local.Modelfile" ''
    FROM ${baseModel}
    PARAMETER num_ctx ${toString numCtx}
    PARAMETER num_batch 256
  '';
in
{
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-vulkan;
    environmentVariables = {
      OLLAMA_VULKAN = "1";
      OLLAMA_IGPU_ENABLE = "1"; # Ollama skips integrated GPUs by default; the Arc 140V is one
    };
    host = "127.0.0.1";
    port = ollamaPort;
    loadModels = [ baseModel ];
  };

  # Builds gemma4-local from the Modelfile once the base model is pulled.
  systemd.services.ollama-gemma4-local = {
    description = "Create ${localModel} (num_ctx ${toString numCtx})";
    after = [ "ollama-model-loader.service" ];
    requires = [ "ollama-model-loader.service" ];
    wantedBy = [ "ollama.service" ];
    bindsTo = [ "ollama.service" ];
    environment = {
      OLLAMA_HOST = "127.0.0.1:${toString ollamaPort}";
      HOME = "/tmp"; # the CLI panics without $HOME; it only talks to the server
    };
    path = [ pkgs-unstable.ollama-vulkan ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      DynamicUser = true;
      TimeoutStartSec = "infinity"; # first start waits for the model download
    };
    # The loader unit returns before the pull ends, so wait for the base model.
    script = ''
      until ollama show ${baseModel} >/dev/null 2>&1; do sleep 5; done
      ollama create ${localModel} -f ${modelfile}
    '';
  };

  # Text, image and audio embeddings (768-d) for Open WebUI's RAG, on the iGPU. Inputs are
  # limited to the model's 8192 tokens; -ub must cover the longest input or llama-server
  # rejects it, and also sets the image token budget.
  systemd.services.llama-embed = {
    description = "embeddinggemma-2 embedding server (llama.cpp, Vulkan)";
    serviceConfig = {
      ExecStart = lib.concatStringsSep " " [
        "${llamaCpp}/bin/llama-server"
        "--model ${embedFile "model"}"
        "--mmproj ${embedFile "mmproj"}"
        "--alias embeddinggemma-2"
        "--embedding"
        "--host 127.0.0.1 --port ${toString embedPort}"
        "-ngl 99 -c 32768 -b 8192 -ub 8192"
      ];
      DynamicUser = true;
      SupplementaryGroups = [ "render" ];
      PrivateDevices = false; # the iGPU
      Restart = "on-failure";
    };
  };

  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 3000;
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      OLLAMA_BASE_URL = "http://127.0.0.1:${toString ollamaPort}";
      DEFAULT_MODELS = localModel;
      RAG_EMBEDDING_ENGINE = "openai"; # llama-server's OpenAI-style /v1/embeddings
      RAG_OPENAI_API_BASE_URL = "http://127.0.0.1:${toString embedPort}/v1";
      RAG_OPENAI_API_KEY = "none"; # llama-server has no key; the field must not be empty
      RAG_EMBEDDING_MODEL = "embeddinggemma-2";
      # embeddinggemma-2 is asymmetric: queries and documents get different prompts (model
      # card). Open WebUI has no UI field for these. Changing them means re-indexing.
      RAG_EMBEDDING_QUERY_PREFIX = "task: search result | query: ";
      RAG_EMBEDDING_CONTENT_PREFIX = "title: none | text: ";
      # Background tasks queue extra generations behind each chat.
      ENABLE_TITLE_GENERATION = "False";
      ENABLE_TAGS_GENERATION = "False";
      ENABLE_FOLLOW_UP_GENERATION = "False";
      ENABLE_SEARCH_QUERY_GENERATION = "False";
      ENABLE_RETRIEVAL_QUERY_GENERATION = "False";
    };
  };

  # Neither service starts at boot; use these to run the chatbot on demand.
  systemd.services.ollama.wantedBy = lib.mkForce [ ];
  systemd.services.open-webui.wantedBy = lib.mkForce [ ];
  # (llama-embed has no wantedBy at all)
  systemd.services.ollama-model-loader.wantedBy = lib.mkForce [ "ollama.service" ];
  environment.shellAliases = {
    llm-start = "sudo systemctl start ollama llama-embed open-webui";
    llm-stop = "sudo systemctl stop open-webui llama-embed ollama";
  };
}
