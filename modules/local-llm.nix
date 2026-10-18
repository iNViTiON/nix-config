# Offline chatbot: Ollama (Vulkan, Intel Arc iGPU) + Gemma 4 + Open WebUI.
# Ollama comes from nixpkgs-unstable (0.40.0): on 26.05's 0.32.3 the Vulkan runner died with
# xe "Timedout job" / ErrorDeviceLost, which also resets the display GPU. On 0.40.0 that
# still happens on long prompts (a 9.7K-token one killed the GPU at 89% of the prefill):
# the xe driver resets any compute job that runs over 5 s, and prefill batches get slower as
# the prompt grows. So batches are small (num_batch 64 fails to load Gemma 4's vision
# encoder), and while Ollama runs the compute engine's limit is raised to the maximum.
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
  numBatch = 128; # tokens per GPU job; 256 timed out on a 9.7K-token prompt, 64 doesn't load

  # Models in Open WebUI's selector. Ollama's default 4K context is too small for both.
  localModels = {
    # Context is cheap: most Gemma 4 layers only attend to the last 1024 tokens, so the KV
    # cache at 32K is ~0.9 GiB for either model. RAM goes to the weights.
    # Dense 12B, ~8 GB: ~20 tokens/s; a 10K-token prompt took ~9 min (19 tokens/s).
    gemma4-local = {
      base = "gemma4:12b-it-q4_K_M";
      ctx = 32768;
    };
    # Mixture-of-experts, 4B active per token, 17 GB: ~14 tokens/s, faster prefill than the 12B
    # (~30 tokens/s on 7.5K tokens). Leaves ~4.5 GiB of RAM free when loaded.
    gemma4-moe-local = {
      base = "gemma4:26b-a4b-it-q4_K_M";
      ctx = 32768;
    };
  };
  localModel = "gemma4-local"; # Open WebUI's default

  modelfile =
    name: m:
    pkgs.writeText "${name}.Modelfile" ''
      FROM ${m.base}
      PARAMETER num_ctx ${toString m.ctx}
      PARAMETER num_batch ${toString numBatch}
    '';

  # xe compute-engine job limit (default 5000 ms, driver maximum 10000). Only the compute
  # engine, not the display's; set while Ollama runs, put back after.
  jobTimeout = "/sys/devices/pci0000:00/0000:00:02.0/tile0/gt0/engines/ccs/job_timeout_ms";
  setJobTimeout = ms: "+${pkgs.runtimeShell} -c 'echo ${ms} > ${jobTimeout}'";

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
in
{
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-vulkan;
    environmentVariables = {
      OLLAMA_VULKAN = "1";
      OLLAMA_IGPU_ENABLE = "1"; # Ollama skips integrated GPUs by default; the Arc 140V is one
      OLLAMA_MAX_LOADED_MODELS = "1"; # both models together don't fit in RAM
    };
    host = "127.0.0.1";
    port = ollamaPort;
    loadModels = lib.mapAttrsToList (_: m: m.base) localModels;
  };

  systemd.services.ollama.serviceConfig = {
    ExecStartPre = setJobTimeout "10000"; # "+": runs as root, the service itself is a dynamic user
    ExecStopPost = setJobTimeout "5000";
  };

  # Builds the local models from their Modelfiles once the base models are pulled.
  systemd.services.ollama-gemma4-local = {
    description = "Create ${lib.concatStringsSep ", " (lib.attrNames localModels)}";
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
    # The loader unit returns before the pulls end, so wait for each base model.
    script = lib.concatStrings (
      lib.mapAttrsToList (name: m: ''
        until ollama show ${m.base} >/dev/null 2>&1; do sleep 5; done
        ollama create ${name} -f ${modelfile name m}
      '') localModels
    );
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
      # Document search. Query generation: the model writes the search queries from the chat,
      # so a message with several questions gets several searches (one extra generation per
      # answer that uses files).
      ENABLE_RETRIEVAL_QUERY_GENERATION = "True";
      RAG_TOP_K = "8"; # chunks per search (default 3; ~3K tokens at 8)
      # Keyword (BM25) plus vector search, so exact IDs like KW-0173 match. No reranker model:
      # candidates are re-scored with embeddinggemma-2, and this caps them like RAG_TOP_K.
      ENABLE_RAG_HYBRID_SEARCH = "True";
      RAG_TOP_K_RERANKER = "8";
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
