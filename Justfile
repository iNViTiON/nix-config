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

# Build, activate and make it the boot default
switch:
    nixos-rebuild switch --sudo

alias deploy := switch

# Same as switch, with full traces and build logs
debug:
    nixos-rebuild switch --sudo --show-trace --print-build-logs --verbose

# Build and make it the boot default, but don't activate until reboot
boot:
    nixos-rebuild boot --sudo

# Activate without adding a boot entry (reverts on reboot)
test:
    nixos-rebuild test --sudo

# Build only (./result), then list what would change compared to the running system
diff:
    nixos-rebuild build
    nix store diff-closures /run/current-system ./result

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
