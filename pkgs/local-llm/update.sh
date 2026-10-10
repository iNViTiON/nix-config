#!/usr/bin/env bash
# Refresh pkgs/local-llm/pins.json: latest llama.cpp master, latest embeddinggemma-2 GGUF.
# Run as `just llm-update`, then `just diff` / `just switch`. Nothing is built here.
set -euo pipefail
cd "$(dirname "$0")"
pins=pins.json

# --- llama.cpp master ---
rev=$(curl -fsS https://api.github.com/repos/ggml-org/llama.cpp/commits/master | jq -r .sha)
if [[ $rev == "$(jq -r .llamaCpp.rev $pins)" ]]; then
  echo "llama.cpp: already at ${rev:0:8}"
else
  echo "llama.cpp: -> ${rev:0:8}"
  base32=$(nix-prefetch-url --unpack --print-path "https://github.com/ggml-org/llama.cpp/archive/$rev.tar.gz" 2>/dev/null)
  path=$(tail -n1 <<<"$base32")
  hash=$(nix hash path --sri "$path")
  npm=$(nix run nixpkgs#prefetch-npm-deps -- "$path/tools/ui/package-lock.json" 2>/dev/null | tail -n1)
  jq --arg r "$rev" --arg h "$hash" --arg n "$npm" \
    '.llamaCpp = {rev: $r, hash: $h, npmDepsHash: $n}' $pins >$pins.tmp && mv $pins.tmp $pins
fi

# --- embeddinggemma-2 GGUF (Hugging Face): the LFS ETag is the file's sha256 ---
repo=$(jq -r .embeddingGemma.repo $pins)
hf=$(curl -fsS "https://huggingface.co/api/models/$repo" | jq -r .sha)
if [[ $hf == "$(jq -r .embeddingGemma.rev $pins)" ]]; then
  echo "embeddinggemma-2: already at ${hf:0:8}"
else
  echo "embeddinggemma-2: -> ${hf:0:8}"
  for part in model mmproj; do
    file=$(jq -r ".embeddingGemma.$part.file" $pins)
    sum=$(curl -fsSI "https://huggingface.co/$repo/resolve/$hf/$file" | tr -d '\r' \
      | awk 'tolower($1)=="x-linked-etag:" {gsub(/"/,"",$2); print $2}')
    [[ ${#sum} -eq 64 ]] || { echo "no sha256 for $file (renamed or not an LFS file?)" >&2; exit 1; }
    jq --arg p "$part" --arg s "$sum" '.embeddingGemma[$p].sha256 = $s' $pins >$pins.tmp && mv $pins.tmp $pins
  done
  jq --arg r "$hf" '.embeddingGemma.rev = $r' $pins >$pins.tmp && mv $pins.tmp $pins
fi
echo "done; if a file was renamed upstream, edit \"file\" in $pins and re-run."
