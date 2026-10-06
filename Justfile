# Command runner for this flake (https://just.systems). `just` lists the recipes.
# Adapted from the NixOS & Flakes book, "Simplify NixOS-related Commands".
#
# Rebuilds need no path: /etc/nixos is a symlink to this repo (see README), and the
# hostname selects nixosConfigurations.mix-nixos.
# `--sudo` evaluates and builds as you and only activates as root. `sudo nixos-rebuild`
# would evaluate as root, and if flake.lock changes, root writes a root-owned
# flake.lock into this repo.

default:
    @just --list

# The rebuild recipes use nh (programs.nh in modules/programs.nix): like
# `nixos-rebuild --sudo`, it evaluates and builds as you and only activates as root, and
# it also prints which packages changed. Without nh installed (the first switch that
# adds it, or a rollback to before it) they fall back to nixos-rebuild. `debug` stays on
# plain nixos-rebuild.

# Build, activate and make it the boot default
switch:
    if command -v nh >/dev/null; then nh os switch --quiet; else nixos-rebuild switch --sudo; fi

alias deploy := switch

# Same as switch, with full traces and build logs
debug:
    nixos-rebuild switch --sudo --show-trace --print-build-logs --verbose

# Build and make it the boot default, but don't activate until reboot
boot:
    if command -v nh >/dev/null; then nh os boot --quiet; else nixos-rebuild boot --sudo; fi

# Activate without adding a boot entry (reverts on reboot)
test:
    if command -v nh >/dev/null; then nh os test --quiet; else nixos-rebuild test --sudo; fi

# Build only, then list what would change compared to the running system
diff:
    if command -v nh >/dev/null; then nh os build --quiet; else nixos-rebuild build \
        && nix store diff-closures /run/current-system ./result; fi

# Shared by upc and upi: one line per input that has an update, tab separated:
# input, the revisions that change, and, with `diff` as the argument, the package versions
# that change in this host's system when only that input is updated (derivations are
# evaluated, nothing is built; about 45 s per input)
[private]
_up-changes mode="":
    #!/usr/bin/env bash
    set -euo pipefail
    mode="{{mode}}"
    d=$(mktemp -d)
    trap 'rm -rf "$d"' EXIT
    drv=".#nixosConfigurations.mix-nixos.config.system.build.toplevel.drvPath"
    nix flake update --output-lock-file "$d/all.lock" 2>/dev/null
    # Per top-level input: revisions that change in it or in its own inputs (updating an input
    # also moves what it pulls in, e.g. claude-desktop-extra's own nixpkgs), tab separated
    jq -nr --slurpfile a flake.lock --slurpfile b "$d/all.lock" '
        def reach($n): [$n] + ([$a[0].nodes[$n].inputs // {} | .[] | select(type == "string")] | map(reach(.)) | add // []);
        def rev($l; $n): $l.nodes[$n].locked.rev // null | if . then .[0:8] else "-" end;
        $a[0].nodes.root.inputs | to_entries[] | select(.value | type == "string") | .key as $k | .value as $r
        | [reach($r) | unique[] | select(rev($a[0]; .) != rev($b[0]; .))
            | (if . == $r then "" else . + " " end) + rev($a[0]; .) + " -> " + rev($b[0]; .)]
        | select(length > 0) | [$k, join("; ")] | @tsv' > "$d/changed"
    [[ -s $d/changed ]] || exit 0
    if [[ $mode != diff ]]; then cat "$d/changed"; exit 0; fi
    old=$(nix eval --raw "$drv" 2>/dev/null)
    while IFS=$'\t' read -r input revs; do
        nix flake update "$input" --output-lock-file "$d/$input.lock" 2>/dev/null
        new=$(nix eval --raw --reference-lock-file "$d/$input.lock" "$drv" 2>/dev/null)
        # "name: 1.0.drv, 1.0.tar.xz.drv -> 1.1.drv, ..." -> "name 1.0 -> 1.1"; the system derivation
        # itself and unnamed sources are noise
        pkgs=$(nix store diff-closures "$old" "$new" 2>/dev/null | sed -E 's/\x1b\[[0-9;]*m//g' |
            grep -vE '^(nixos-system|source)' |
            sed -E 's/\.drv//g; s/, [^,→]*\.tar\.[a-z0-9]+//g; s/: / /; s/ → / -> /' || true)
        n=$(grep -c . <<< "$pkgs" || true)
        if [[ $n -eq 0 ]]; then
            pkgs="no package version changes (only what it is built from)"
        else
            pkgs=$(head -n "${UP_PKGS:-8}" <<< "$pkgs" | paste -sd, | sed 's/,/, /g')
            if [[ $n -gt ${UP_PKGS:-8} ]]; then pkgs="$pkgs, ... ($n changed)"; fi
        fi
        printf '%s\t%s\t%s\n' "$input" "$revs" "$pkgs"
    done < "$d/changed"

# Dry run of `just up`: list the inputs that have an update (flake.lock stays untouched).
# `just upc --show-diff` also lists the packages each one would change (slow, ~45 s per input).
# Update with `just upp <inputs>` or `just upi`.
upc *flags:
    #!/usr/bin/env bash
    set -euo pipefail
    mode=""
    for f in {{flags}}; do
        case $f in
            --show-diff) mode=diff ;;
            *) echo "upc: unknown option $f (only --show-diff)" >&2; exit 1 ;;
        esac
    done
    out=$(just --quiet _up-changes $mode)
    if [[ -z $out ]]; then echo "all inputs up to date"; exit 0; fi
    while IFS=$'\t' read -r input revs pkgs; do
        printf '%s: %s\n' "$input" "$revs"
        if [[ -n $pkgs ]]; then printf '    %s\n' "$pkgs"; fi
    done <<< "$out"

# Interactive `just upp`: tick the inputs to update (space = tick, enter = go, esc = cancel).
# `just upi --show-diff` shows the changed packages next to each input (slow, ~45 s per input).
upi *flags:
    #!/usr/bin/env bash
    set -euo pipefail
    mode=""
    for f in {{flags}}; do
        case $f in
            --show-diff) mode=diff ;;
            *) echo "upi: unknown option $f (only --show-diff)" >&2; exit 1 ;;
        esac
    done
    out=$(just --quiet _up-changes $mode)
    if [[ -z $out ]]; then echo "all inputs up to date"; exit 0; fi
    lines=$(awk -F'\t' '{ printf "%s: %s%s\n", $1, $2, ($3 == "" ? "" : " | " $3) }' <<< "$out")
    picked=$(nix shell nixpkgs#gum -c gum choose --no-limit --header "Update which inputs?" <<< "$lines") || exit 0
    [[ -n $picked ]] || exit 0
    inputs=$(cut -d: -f1 <<< "$picked" | tr '\n' ' ')
    # shellcheck disable=SC2086
    just upp $inputs

# Update all inputs (replaces `nixos-rebuild switch --upgrade`)
up:
    nix flake update

# Update one or more inputs, e.g. `just upp claude-desktop-extra` or
# `just upp niri-spicy niri-spicy-smithay`
upp +inputs:
    nix flake update {{inputs}}

# Latest releases of the inputs pinned to a release. Upgrading one means editing its
# tag/commit in flake.nix first, because `nix flake update` never moves a pin.
releases:
    gh release list --repo nix-community/lanzaboote --limit 3
    gh release list --repo AdnanHodzic/auto-cpufreq --limit 3

# Commit of a lanzaboote release tag, for its pin in flake.nix, e.g. `just lanzaboote-rev v1.2.0`
lanzaboote-rev tag:
    git ls-remote https://github.com/nix-community/lanzaboote 'refs/tags/{{tag}}' 'refs/tags/{{tag}}^{}' | sort -k2 | tail -n 1 | cut -f1

# Evaluate the flake and run its checks
check:
    nix flake check

# Format all Nix files
fmt:
    nix fmt

# List system generations
history:
    nix profile history --profile /nix/var/nix/profiles/system

repl:
    nix repl -f flake:nixpkgs

# Remove system generations older than 7 days
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Delete all old generations and garbage-collect the store (root + your Home Manager/user profiles)
gc:
    sudo nix-collect-garbage --delete-old
    nix-collect-garbage --delete-old

# Deduplicate identical files in the store with hard links. auto-optimise-store only does
# this for paths added from now on, so run it once for everything that was already there.
# It reads the whole store, so it can take a while.
optimise:
    sudo nix store optimise

alias optimize := optimise
