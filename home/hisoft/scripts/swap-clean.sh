# Give memory back after a heavy job (a big Ollama model, a build): cycle swap, so whatever
# was pushed out is pulled back in. With -a, drop the page cache first as well (it throws
# away useful cache too, so it is opt-in). Needs root, so it re-runs itself through sudo.
# `sudo` is the setuid wrapper, see ../scripts.nix.
purge_cache=false
while getopts "ah" opt; do
  case "$opt" in
    a) purge_cache=true ;;
    *)
      echo "Usage: swap-clean [-a]" >&2
      echo "  -a  also drop the page cache and compact memory before cycling swap" >&2
      [ "$opt" = h ] && exit 0
      exit 2
      ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

meminfo_kb() {
  awk -v key="$1:" '$1 == key { print $2 }' /proc/meminfo
}

echo "Before:"
free -h

if $purge_cache; then
  # Write dirty pages first, then free the clean page cache and slab (3 = both).
  sync
  echo 3 >/proc/sys/vm/drop_caches
  # Defragment free memory, so huge pages are available again.
  echo 1 >/proc/sys/vm/compact_memory
fi

# swapoff reads every swapped page back into RAM. If they do not fit, it would push the
# machine into the OOM killer, so check first and leave swap alone when it is too tight.
swap_used_kb=$(($(meminfo_kb SwapTotal) - $(meminfo_kb SwapFree)))
mem_avail_kb=$(meminfo_kb MemAvailable)
margin_kb=$((1024 * 1024)) # keep 1 GiB free

if [ "$swap_used_kb" -gt 0 ]; then
  if [ "$swap_used_kb" -gt $((mem_avail_kb - margin_kb)) ]; then
    echo "Swap in use ($((swap_used_kb / 1024)) MiB) does not fit in free RAM" \
      "($((mem_avail_kb / 1024)) MiB). Close something and try again." >&2
    exit 1
  fi
  echo "Moving $((swap_used_kb / 1024)) MiB back from swap..."
  swapoff -a
  swapon -a
fi

echo "After:"
free -h
