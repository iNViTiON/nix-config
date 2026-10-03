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

# Dry run of `just up`: list the inputs that have an update (flake.lock stays untouched),
# then update the ones you want with `just upp <inputs>` or `just upi`
upc:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    nix flake update --output-lock-file "$tmp" 2>/dev/null
    # Top-level input name -> revision (nested inputs such as nixpkgs_6 can't be named in `nix flake update`)
    rev='. as $l | .nodes.root.inputs | to_entries[] | select(.value | type == "string") | "\(.key) \($l.nodes[.value].locked.rev // "-" | .[0:8])"'
    join -a1 -a2 -e - -o 0,1.2,2.2 \
        <(jq -r "$rev" flake.lock | sort) <(jq -r "$rev" "$tmp" | sort) |
        awk '$2 != $3 { print $1 ": " $2 " -> " $3; n++ } END { if (!n) print "all inputs up to date" }'

# Interactive `just upp`: check what has an update, tick the inputs to update
# (space = tick, enter = go, esc = cancel)
upi:
    #!/usr/bin/env bash
    set -euo pipefail
    list=$(just --quiet upc)
    if [[ $list == "all inputs up to date" ]]; then echo "$list"; exit 0; fi
    picked=$(nix shell nixpkgs#gum -c gum choose --no-limit --header "Update which inputs?" <<< "$list") || exit 0
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
