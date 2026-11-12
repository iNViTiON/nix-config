# Per-process GPU (xe) and NPU (intel_vpu) usage for the popout, read from DRM fdinfo.
# One tab-separated line per DRM client (a process can own several):
#   driver  pid  comm  client-id  resident_KiB  total_KiB  then for rcs ccs vcs vecs bcs: client_cycles  total_cycles
# plus "NPUMEM<TAB>bytes", the NPU's device-wide memory use. Only the current user's processes are visible
# (system services such as Ollama run as another user).
grep -H -E '^drm-(driver|client-id|total-(system|gtt|vram0|memory)|resident-(system|gtt|vram0|memory)|cycles-|total-cycles-)' /proc/[0-9]*/fdinfo/* 2>/dev/null | awk '
function flush(   i, line) {
  if (rpid != "" && drv != "" && !((rpid SUBSEP cid) in seen)) {
    seen[rpid, cid] = 1
    if (!(rpid in comm)) { c = "?"; getline c < ("/proc/" rpid "/comm"); close("/proc/" rpid "/comm"); comm[rpid] = c }
    line = drv "\t" rpid "\t" comm[rpid] "\t" cid "\t" res "\t" tot
    for (i = 1; i <= 5; i++) line = line "\t" cyc[eng[i]] + 0 "\t" tcy[eng[i]] + 0
    print line
  }
}
BEGIN { split("rcs ccs vcs vecs bcs", eng, " ") }
{
  # "/proc/PID/fdinfo/FD:drm-key:<tab>value"
  split($0, p, "/"); pid = p[3]; fd = p[5]; sub(/:.*/, "", fd)
  fdkey = pid "/" fd
  line = $0; sub(/^[^:]*:/, "", line)
  k = line; sub(/:.*/, "", k); v = line; sub(/^[^:]*:[ \t]*/, "", v)
  if (fdkey != cur) { flush(); cur = fdkey; rpid = pid; drv = ""; cid = ""; res = 0; tot = 0; delete cyc; delete tcy }
  if (k == "drm-driver") drv = v
  else if (k == "drm-client-id") cid = v
  else if (k ~ /^drm-resident-/) { split(v, a, " "); res += a[1] }
  else if (k ~ /^drm-total-(system|gtt|vram0|memory)$/) { split(v, a, " "); tot += a[1] }
  else if (k ~ /^drm-cycles-/) { sub(/^drm-cycles-/, "", k); cyc[k] = v }
  else if (k ~ /^drm-total-cycles-/) { sub(/^drm-total-cycles-/, "", k); tcy[k] = v }
}
END { flush() }'
f=/sys/class/accel/accel0/device/npu_memory_utilization
[ -r "$f" ] && printf 'NPUMEM\t%s\n' "$(cat "$f")"
exit 0
