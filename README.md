# iNViTiON Nix Config

> [!NOTE]
> This is my personal NixOS setup. For now it targets a single machine (host `mix-nixos`),
> so hardware, disk UUIDs, user name and paths are all specific to it. Borrow ideas freely,
> but it's not meant to be used as-is on another machine.

A flake-based NixOS + Home Manager config for the ThinkPad X1 Carbon Gen 13. It replaces:

- the channel-based `/etc/nixos`
- `~/.bashrc`, `~/.bash_profile`, `~/.profile` and `~/.gitconfig`
- the scripts in `~/.local/bin`
- the imperative `nix profile` installs

The structure follows the [NixOS & Flakes book](https://nixos-and-flakes.thiscute.world/)
([source](https://github.com/ryan4yin/nixos-and-flakes-book)).  
`/etc/nixos` becomes a symlink to this repo, as the book describes, so rebuild commands
need no path.

## Components

|                         | mix-nixos (Wayland)                                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Hardware**            | ThinkPad X1 Carbon Gen 13 (Intel, with NPU), via [nixos-hardware][nixos-hardware]                                   |
| **Display Manager**     | SDDM                                                                                                                       |
| **Desktops**            | [KDE Plasma 6][Plasma] (legacy), plus a [niri][niri] session (default; [niri-spicy][niri-spicy] fork, for HDR)                     |
| **Desktop Shell**       | Plasma's own; in niri, [DankMaterialShell][DMS]: bar, launcher, notifications, OSD, lock screen, [KDE Connect plugin][DankKDEConnect] |
| **Terminal**            | Konsole (Plasma), [Alacritty][Alacritty] (niri)                                                                            |
| **Shell**               | Bash, with [zoxide][zoxide], [bat][bat], [eza][eza], [ripgrep][ripgrep], [fd][fd] and other Rust replacements              |
| **Editors / IDE**       | [Zed][Zed], VS Code                                                                                                  |
| **Browser**             | [Vivaldi][Vivaldi] (Wayland, KWallet passwords)                                                          |
| **Input**               | [kanata][kanata] key remapping; [Fcitx5][Fcitx5] + [Mozc][Mozc]: English (Colemak), Thai (Manoonchai), Japanese          |
| **File Manager**        | Dolphin (Plasma), [Strata][Strata] (niri, also its file picker; Nix package by [Th1nkK1D][strata-nix])                                                            |
| **Phone**               | [KDE Connect][KDEConnect] (remote input in niri via [hypr-kdeconnect-fix][hypr-kdeconnect-fix]), [RQuickShare][RQuickShare], LocalSend, scrcpy |
| **Secrets**             | KDE Wallet in every session, [Bitwarden][Bitwarden]                                                                        |
| **Networking**          | NetworkManager, nftables, systemd-resolved with DNS over TLS                                                               |
| **Fonts**               | IBM Plex, Nerd Font symbols, Material Symbols                                                                              |
| **Containers / Android** | rootless Docker, [Waydroid][Waydroid]                                                                                     |
| **Filesystem & Encryption** | [Btrfs][Btrfs] subvolumes on [LUKS][LUKS], unlocked by TPM2                                                           |
| **Secure Boot**         | [lanzaboote][lanzaboote]                                                                                                   |
| **Tooling**             | [Home Manager][home-manager], [nh][nh] + [just][just] for rebuilds                                                         |

[nixos-hardware]: https://github.com/NixOS/nixos-hardware
[Plasma]: https://kde.org/plasma-desktop/
[niri]: https://github.com/YaLTeR/niri
[niri-spicy]: https://github.com/losnoco/niri/tree/spicy-main
[DMS]: https://github.com/AvengeMedia/DankMaterialShell
[DankKDEConnect]: https://github.com/AvengeMedia/dms-plugins/tree/master/DankKDEConnect
[Alacritty]: https://github.com/alacritty/alacritty
[zoxide]: https://github.com/ajeetdsouza/zoxide
[bat]: https://github.com/sharkdp/bat
[eza]: https://github.com/eza-community/eza
[ripgrep]: https://github.com/BurntSushi/ripgrep
[fd]: https://github.com/sharkdp/fd
[Zed]: https://zed.dev/
[Vivaldi]: https://vivaldi.com/
[kanata]: https://github.com/jtroo/kanata
[Fcitx5]: https://github.com/fcitx/fcitx5
[Mozc]: https://github.com/google/mozc
[Strata]: https://github.com/lgse/strata
[strata-nix]: https://github.com/Th1nkK1D/nixos-config
[KDEConnect]: https://kdeconnect.kde.org/
[hypr-kdeconnect-fix]: https://github.com/gfhdhytghd/hypr-kdeconnect-fix
[RQuickShare]: https://github.com/Martichou/rquickshare
[Bitwarden]: https://bitwarden.com/
[Waydroid]: https://waydro.id/
[Btrfs]: https://btrfs.readthedocs.io/
[LUKS]: https://gitlab.com/cryptsetup/cryptsetup
[lanzaboote]: https://github.com/nix-community/lanzaboote
[home-manager]: https://github.com/nix-community/home-manager
[nh]: https://github.com/nix-community/nh
[just]: https://github.com/casey/just

## Layout

```
flake.nix                    inputs, nixosConfigurations.mix-nixos, overlay, packages, formatter
Justfile                     rebuild/update/gc recipes (`just`)
hosts/mix-nixos/
  default.nix                host entry (was configuration.nix): imports, hostname, hardware bits, stateVersion
  boot.nix                   lanzaboote (max 2 boot entries, since my /boot is just 256MB and too lazy to handle it), LUKS+TPM2, systemd initrd, swap, kernel, sbctl
  hardware-configuration.nix copied unchanged
modules/                     NixOS modules
  nix.nix                    flakes, allowUnfree, overlay, channels off, registry, GC
  locale.nix                 time zone, locales, xkb layout
  networking.nix             NetworkManager, nftables, nameservers, resolved (DoT)
  desktop.nix                Plasma 6/SDDM, printing, PipeWire, NIXOS_OZONE_WL
  graphics.nix               graphics on, VA-API/HDR env vars (the rest comes from nixos-hardware)
  fonts.nix                  IBM Plex defaults, icon fonts (Font Awesome, Nerd Font symbols, Material Symbols)
  users.nix                  users.users.hisoft
  programs.nix               programs.* block, system shell aliases (zed, zudoedit)
  services.nix               misc services.* block
  packages.nix               system packages (root/boot/hardware-level only)
  power.nix                  auto-cpufreq module, power-profiles-daemon off
  estonian-id.nix            EE ID packages, pcscd, web-eid/opensc /etc entries
  browser-integration.nix    Plasma/Bitwarden native messaging, Vivaldi activation script
  quickshare.nix             rquickshare + LocalSend, firewall ports
  waydroid.nix               Waydroid, GPU fix, restricted firewall/forwarding
  compositors.nix            niri (niri-spicy) session, KDE Wallet for it, DankMaterialShell
  docker.nix                 rootless Docker
  faster-boot.nix            boot-time tweaks
  boot-animation/ kanata.nix rust-replacement.nix tunnel.nix      (unchanged from /etc/nixos)
  japanese.nix               fcitx5 + Mozc (Japanese), and EN/TH/JA switching on Super+Space
  podman.nix                 (unchanged, not imported, as before)
  vr.nix                     not imported; uses a `nixpkgs-xr` input (commented in flake.nix)
home/hisoft/                 Home Manager (NixOS module)
  default.nix                imports, home.stateVersion = "26.05"
  bash.nix                   everything from ~/.bashrc, ~/.bash_profile, ~/.profile
  git.nix                    everything from ~/.gitconfig and ~/.config/git/ignore
  packages.nix               personal apps and dev tools, the former `nix profile` packages, just
  scripts.nix, scripts/      the ~/.local/bin scripts, via writeShellApplication
  plasma.nix                 pre-authorizes KDE Connect remote input (no portal prompt)
  niri.nix                   niri: laptop panel + HDR (and its brightness service), DMS launcher, volume/brightness keys
overlays/default.nix         usbeehive
pkgs/usbeehive/              moved from ~/Documents/usbeehive-flake
```

## Where the old config went

| Old | New |
| --- | --- |
| `configuration.nix` `let` block: `<nixos-unstable>`, `import ~/Documents/nixpkgs`, lon lanzaboote, `builtins.getFlake` auto-cpufreq | flake inputs; `pkgs-unstable` via `specialArgs` |
| `<nixos-hardware/lenovo/thinkpad/x1/13th-gen>` | `inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-13th-gen` (hosts/mix-nixos/default.nix) |
| bootloader, lanzaboote, LUKS, swap, initrd, kernel | hosts/mix-nixos/boot.nix |
| hostname, bluetooth, CPU/NPU, ZSA, `snd_intel_dspcfg`, fprintd, powerDownCommands, stateVersion | hosts/mix-nixos/default.nix |
| time zone, i18n, xkb | modules/locale.nix |
| networkmanager, nftables, nameservers, `services.resolved` | modules/networking.nix |
| xserver, sddm, plasma6, printing, pipewire, `NIXOS_OZONE_WL` | modules/desktop.nix |
| `users.users.hisoft` | modules/users.nix |
| `programs = { ... }` (minus auto-cpufreq), firefox, `environment.shellAliases` | modules/programs.nix |
| `services = { ... }` (minus pcscd, resolved, power-profiles-daemon) | modules/services.nix |
| `environment.systemPackages` | split: system-level tools → modules/packages.nix (sbctl → boot.nix, EE ID → estonian-id.nix); apps and dev tools → home/hisoft/packages.nix |
| `users.users.hisoft.packages` (kate) | home/hisoft/packages.nix |
| `ms-edge.nix` | modules/graphics.nix (Microsoft Edge and duplicated/dead GPU settings dropped) |
| `unstable.foo` | `pkgs-unstable.foo` |
| `unstable.spacedrive` | **dropped** (marked broken on nixos-unstable) |
| `local.github-copilot-cli` | `pkgs-unstable.github-copilot-cli` (nixpkgs has caught up: 26.05 already had 1.0.61 vs local 1.0.44) |
| `local.pritunl-client` + its systemd service | **dropped** |
| EE ID packages, pcscd, `eu.webeid.json`, `opensc-pkcs11` | modules/estonian-id.nix |
| Plasma/Bitwarden native messaging, `vivaldiBitwardenNativeMessaging` | modules/browser-integration.nix |
| `nix.settings.experimental-features`, `allowUnfree` | modules/nix.nix |
| `claude-desktop.nix`, `claude-desktop_old_non-official.nix` | dropped: superseded by the claude-desktop-extra input (they stay in /etc/nixos.bak) |
| `lon.nix`, `lon.lock`, `configuration.nix.ori` | dropped (lanzaboote is pinned to a commit in flake.nix) |
| `~/.bashrc` aliases, `CLAUDE_PACKAGE_MANAGER`, `history -r; unset HISTFILE` | home/hisoft/bash.nix |
| `~/.bash_profile` / `~/.profile` PATH (`~/.volta/bin`, `~/.local/bin`) and `VOLTA_HOME` | home/hisoft/bash.nix (`home.sessionPath`, `home.sessionVariables`) |
| `~/.gitconfig`, `~/.config/git/ignore` | home/hisoft/git.nix |
| `~/.local/bin/{boot-next,bu,refprintd,scrcpy-connect,scrcpy-nd,soff,usbmon}` | home/hisoft/scripts.nix (+ scripts/*.sh) |
| `nix profile`: claude-desktop-extra, MangaMeeyaCE, usbeehive-flake | home/hisoft/packages.nix |

## Inputs

| Input | Replaces | Pinned to | Notes |
| --- | --- | --- | --- |
| `nixpkgs` | `nixos` channel | branch `nixos-26.05` | |
| `nixpkgs-unstable` | `nixos-unstable` channel | branch `nixos-unstable` | the old channel was stale (older than 26.05); the lock will be fresh |
| `nixos-hardware` | `nixos-hardware` channel | `master` | |
| `home-manager` | new | branch `release-26.05` | follows `nixpkgs` |
| `lanzaboote` | lon pin (`lon.nix` + `lon.lock`) | **commit** of tag v1.0.0 | follows `nixpkgs`, as lanzaboote's docs recommend |
| `auto-cpufreq` | `builtins.getFlake` (master) | **tag** v3.1.0 | builds with the nixpkgs lock upstream ships |
| `claude-desktop-extra` | `nix profile` | `master` | upstream has no flake.lock, so its nixpkgs is resolved when you lock/update |
| `mangameeya-rush` (`github:iNViTiON/MangaMeeyaRush`) | `nix profile` (local `git+file:` MangaMeeyaCE) | `main` | builds with its own flake.lock; only pushed commits count |
| `th1nkk1d` (`github:Th1nkK1D/nixos-config`) | vendored `pkgs/strata` | `main` | Th1nkK1D's config; `flake = false`: only its `pkgs/strata/package.nix` is used, built with our `nixpkgs-unstable` (its flake output is blocked as unfree), plus a VA-API sandbox tweak (modules/nix.nix) |
| `niri-spicy` (`github:losnoco/niri/spicy-main`) | new | `spicy-main` | niri fork with experimental HDR (modules/compositors.nix); built from source |
| `niri-spicy-smithay` (`github:losnoco/smithay/spicy-master`, `flake = false`) | new | `spicy-master` | the fork's Smithay (where the HDR code lives), copied to `../smithay` at build time; update together with `niri-spicy` |

`follows` is kept only where the input plugs into the system itself (home-manager,
lanzaboote). The app inputs build with their own nixpkgs, which costs an extra nixpkgs
download and some duplicated dependencies.

## Updating pinned inputs

Two inputs are pinned, because they run as root or in the boot chain:

| Input | Pinned to (in `flake.nix`) | Upgrade when |
| --- | --- | --- |
| `lanzaboote` | commit `e8c096ade12ec9130ff931b0f0e25d2f1bc63607` (= release tag v1.0.0) | you choose to; boot-critical |
| `auto-cpufreq` | release tag `v3.1.0` | you choose to |

`just up` (update everything) and `just upp <input>` **never** move these pins. A commit
can't move, and a tag resolves to the same commit every time, so these two only change
when you edit `flake.nix`. Everything else moves normally with `just up`.

Both helper recipes need network access and `gh`, which is logged in already:

- `just releases`: the 3 latest releases of lanzaboote and of auto-cpufreq.
- `just lanzaboote-rev <tag>`: the commit behind a lanzaboote release tag.

### lanzaboote (commit pin, boot-critical)

Upgrade it on its own, never together with other updates. Keep a NixOS USB stick and your
LUKS passphrase at hand.

1. See what's new, then read the release notes and the
   [CHANGELOG](https://github.com/nix-community/lanzaboote/blob/master/CHANGELOG.md).
   ```bash
   just releases
   ```
   ```bash
   gh release view v1.2.0 --repo nix-community/lanzaboote
   ```
2. Get the commit behind the tag you want:
   ```bash
   just lanzaboote-rev v1.2.0
   ```
3. Put that commit into `flake.nix` and update the comment. For example:
   ```nix
   # before
   url = "github:nix-community/lanzaboote/e8c096ade12ec9130ff931b0f0e25d2f1bc63607"; # v1.0.0
   # after
   url = "github:nix-community/lanzaboote/c1c5edd31802d181c8aa2c71588995d93425d650"; # v1.2.0
   ```
4. Lock only that input, and review what changes:
   ```bash
   just upp lanzaboote
   ```
   ```bash
   just diff
   ```
5. Install it for the next boot only, then reboot:
   ```bash
   just boot
   ```
6. After the reboot, check that Secure Boot is still active and the new stub is in use:
   ```bash
   sbctl status
   ```
   ```bash
   bootctl status
   ```
7. Commit the change:
   ```bash
   git commit -am "lanzaboote: v1.0.0 -> v1.2.0"
   ```

If it doesn't boot, pick the previous entry in the boot menu (hold a key while booting to
show it). Then undo the change and rebuild:
```bash
git checkout HEAD -- flake.nix flake.lock
```
```bash
just boot
```
If no entry boots, boot the NixOS USB stick, or temporarily turn Secure Boot off in the
firmware settings.

### auto-cpufreq (tag pin)

1. See the latest releases, and read what changed:
   ```bash
   just releases
   ```
   ```bash
   gh release view v3.2.0 --repo AdnanHodzic/auto-cpufreq
   ```
2. Change the tag in `flake.nix`. For example:
   ```nix
   auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq/v3.2.0";
   ```
3. Lock only that input, review, and switch:
   ```bash
   just upp auto-cpufreq
   ```
   ```bash
   just diff
   ```
   ```bash
   just switch
   ```
4. Check the daemon, then commit:
   ```bash
   systemctl status auto-cpufreq
   ```
   ```bash
   git commit -am "auto-cpufreq: v3.1.0 -> v3.2.0"
   ```

If something breaks, undo the change and switch back:
```bash
git checkout HEAD -- flake.nix flake.lock
```
```bash
just switch
```

## Switching

Run these yourself, in order. Inputs are fetched fresh, so the first build needs network
access and compiles a few local things (usbeehive, auto-cpufreq, the scripts, lanzaboote's
tool). The first switch also brings a kernel update (7.2.6 → 7.2.7).

1. **Put the repo under git and commit.** Flakes ignore files that git doesn't track.
   ```bash
   cd ~/nixos-config && git init && git add -A && git commit -m "Initial flake config"
   ```
2. **Create `flake.lock`, then commit it.** MangaMeeya is fetched from GitHub
   (`iNViTiON/MangaMeeyaRush`, `main`), so only pushed commits count.
   ```bash
   nix flake lock
   ```
   ```bash
   git add flake.lock && git commit -m "Add flake.lock"
   ```
3. **Pre-flight checks.**
   1. Write down your old channels. After the switch the `nix-channel` command is removed.
      ```bash
      sudo nix-channel --list
      ```
   2. Check what the TPM key is bound to, and have your LUKS passphrase ready. Look for
      `tpm2-pcrs`. If it's only `7`, new kernels and boot files won't affect auto-unlock.
      ```bash
      sudo cryptsetup luksDump /dev/disk/by-uuid/44c43796-65a5-4ade-aee4-e697321fb2f4
      ```
4. **Symlink `/etc/nixos`** (book: ["Other useful tips"](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/other-useful-tips)). From now on `nixos-rebuild`
   finds `/etc/nixos/flake.nix`, follows the symlink, and picks
   `nixosConfigurations.mix-nixos` by hostname.
   ```bash
   sudo mv /etc/nixos /etc/nixos.bak
   ```
   ```bash
   sudo ln -s /home/hisoft/nixos-config /etc/nixos
   ```
   To undo, if the flake doesn't build and you want the old setup back:
   ```bash
   sudo rm /etc/nixos && sudo mv /etc/nixos.bak /etc/nixos
   ```
5. **Build without activating, then review.** Run this from `~/nixos-config`, where it
   creates `./result`.
   ```bash
   cd ~/nixos-config && nixos-rebuild build
   ```
   ```bash
   nix store diff-closures /run/current-system ./result
   ```
   If a script fails shellcheck, the error names the SC code: fix the line, or add the
   code to that script's `excludeShellChecks`. Optionally, to separate the structural
   changes from package updates, also build once against the exact nixpkgs the system
   runs today. The override is not written to `flake.lock`.
   ```bash
   nixos-rebuild build --override-input nixpkgs github:NixOS/nixpkgs/1e8bc658fc985ef27ccd66d107d767b32bb7ef98
   ```
6. **Test run (recommended).** This activates the new system right away, without touching
   the boot menu: the running system changes, but the next boot still starts the old one.
   Home Manager runs as well, so your dotfiles are replaced (the old ones are kept as
   `*.hm-backup`).
   ```bash
   nixos-rebuild test --sudo
   ```
   Then:
   1. Rename the old git config (step 8 explains why):
      ```bash
      mv ~/.gitconfig ~/.gitconfig.pre-hm
      ```
   2. Log out and back in (don't reboot), so the session reads the new `~/.profile`.
   3. Check that:
      - a new terminal has your aliases (`alias so`)
      - `echo $CLAUDE_PACKAGE_MANAGER` prints `bun`
      - `which claude` finds `~/.local/bin/claude`
      - Wi-Fi and DNS work
      - `git pull` in a GitHub repo works
      - Plasma, KDE Connect and Waydroid behave

   `test` can't check the boot chain (lanzaboote, the new kernel, TPM unlock); the reboot
   in step 11 does. If something is wrong now, reboot to get the old system back, then
   follow "Rolling back" → "Restore your home directory".
7. **Switch.** Use `nixos-rebuild … --sudo`, not `sudo nixos-rebuild …`: `--sudo`
   evaluates as you and uses sudo only for activation, so a lock-file update can't leave
   a root-owned `flake.lock` in your repo. This stops and removes the running
   `pritunl-client` service, so any Pritunl VPN session drops.
   ```bash
   nixos-rebuild switch --sudo
   ```
   **Don't run `switch` or `boot` again until the reboot in step 11 works.** The boot menu
   keeps only 2 generations: right now the old one (your fallback) and the new one. Another
   rebuild before you've booted the new one would push the old one out of the menu.
8. **Rename the old git config**, unless you did it in step 6. Do it before touching
   GitHub: it would override the new config, and its `gh` path no longer exists.
   ```bash
   mv ~/.gitconfig ~/.gitconfig.pre-hm
   ```
9. **Check Home Manager.** `~/.bashrc`, `~/.bash_profile`, `~/.profile`,
   `~/.config/git/config` and `~/.config/git/ignore` should now be symlinks into the store.
   Files that existed before are kept as `*.hm-backup`.
   ```bash
   systemctl status home-manager-hisoft.service
   ```
10. **Move the replaced copies out of the way.** `~/.local/bin` and `~/.nix-profile/bin`
    come before the Home Manager profile on PATH, so the old copies would shadow the new
    ones. Everything here stays restorable until step 13 ("Rolling back" has the commands).
    1. Remove the old `nix profile` apps:
       ```bash
       nix profile remove claude-desktop-extra MangaMeeyaCE usbeehive-flake
       ```
    2. Move the old scripts aside. Only these seven; `claude` and `python3.12` stay:
       ```bash
       mkdir -p ~/.local/bin.pre-hm && mv ~/.local/bin/{boot-next,bu,refprintd,scrcpy-connect,scrcpy-nd,soff,usbmon} ~/.local/bin.pre-hm/
       ```
11. **Reboot.** This checks Secure Boot, TPM unlock and the Plasma login with the new
    kernel, and starts a session with the new `~/.profile`, i.e. the PATH additions,
    `VOLTA_HOME` and `CLAUDE_PACKAGE_MANAGER`. If it doesn't come up, see "Rolling back".
    Once this boot works, the new generation is your proven fallback, and further
    rebuilds are safe.
12. **Check the things that changed.** If something is badly broken, see "Rolling back".
    - **Waydroid:** does it still have internet? Its interface is no longer fully trusted,
      and forwarding is filtered.
    - **rquickshare:** does discovery work? Its ports are really open now.
    - **KDE Connect:** does remote input work without a prompt?
    - **Bitwarden in Vivaldi:** does the desktop integration work? The review suggested
      moving its link to Home Manager; decide after testing.
    - **`claude-update`:** it now only updates and shows the `flake.lock` diff. Rebuild
      yourself afterwards.
13. **Final cleanup**, once everything works and you're staying on the new config. After
    this you can no longer go back to the channel-based config (see "Rolling back").
    1. Remove the old channels. The activation warns about them while they exist.
       ```bash
       sudo rm -rf /root/.nix-channels /root/.nix-defexpr/channels /nix/var/nix/profiles/per-user/root/channels /nix/var/nix/profiles/per-user/root/channels-*-link
       ```
       ```bash
       rm -rf ~/.nix-defexpr/channels ~/.nix-defexpr/channels_root ~/.local/state/nix/profiles/channels ~/.local/state/nix/profiles/channels-*-link
       ```
    2. Remove the moved-aside scripts and the old usbeehive flake:
       ```bash
       rm -rf ~/.local/bin.pre-hm ~/Documents/usbeehive-flake
       ```
    3. Optional, whenever you like: remove the dotfile backups and the old config copy:
       ```bash
       rm -f ~/.bashrc.hm-backup ~/.bash_profile.hm-backup ~/.profile.hm-backup ~/.config/git/ignore.hm-backup ~/.gitconfig.pre-hm
       ```
       ```bash
       sudo rm -rf /etc/nixos.bak
       ```
14. **Update the curated `~/.bash_history`.** It isn't managed here, and its entries are
    stale now. Suggested replacements:
    - `sudoedit /etc/nixos/configuration.nix` → `zed ~/nixos-config`
    - `time nixos-rebuild switch --upgrade --sudo` →
      `nix flake update --flake /etc/nixos && time nixos-rebuild switch --sudo`.
      `--upgrade` updates channels, which no longer exist.
    - `sudo nix-collect-garbage -d && nix-collect-garbage -d` → `just gc` from `~/nixos-config`
15. **Later, when convenient:**
    - Run `just optimise` once. `auto-optimise-store` only deduplicates paths added from
      now on; this also covers everything that was in the store before the switch.
    - Run `just fmt` in its own commit. It reformats the whole tree, including files that
      were copied unchanged, so the diff is large but harmless.
    - Upgrade lanzaboote on its own (see "Updating pinned inputs").

## Rolling back

Going back to the old **generation** restores the system itself: packages, services,
kernel, boot. Your home directory needs its own step, because the old generation doesn't
know about Home Manager.

### The system

| Where it went wrong | What to do |
| --- | --- |
| `nix flake lock` or `nixos-rebuild build` fails (steps 2, 5) | Nothing on the system changed. Fix the error, or undo the `/etc/nixos` symlink (step 4). |
| After `nixos-rebuild test` (step 6) | Reboot: the boot menu still starts the old system. |
| After `switch` (step 7), still running | Roll back to the previous generation; it becomes the boot default too: `nixos-rebuild switch --rollback --sudo` |
| After the reboot (step 11): doesn't boot, or login is broken | Pick the older entry in the boot menu. The menu is hidden: press any key right after the Lenovo logo. Once booted, make it the default again: `nixos-rebuild switch --rollback --sudo` |
| The disk asks for the LUKS passphrase instead of unlocking | Type the passphrase and boot continues. Then see "TPM auto-unlock" below. |
| Secure Boot refuses the new entry ("security violation") | Pick the older entry. If no entry boots, use a NixOS USB stick, or temporarily turn Secure Boot off in the firmware setup. |

The generation before the migration stays available for 7 days (automatic GC), and in the
boot menu until your second rebuild after the switch.

### Restore your home directory

Do this after going back to the old generation. The Home Manager dotfiles would keep
working there, but they're read-only, and the apps and scripts moved in step 10 would be
missing.

1. Put the old dotfiles and git config back:
   ```bash
   for f in ~/.bashrc ~/.bash_profile ~/.profile ~/.config/git/ignore; do [ -e "$f.hm-backup" ] && mv -f "$f.hm-backup" "$f"; done
   ```
   ```bash
   [ -L ~/.config/git/config ] && rm ~/.config/git/config; [ -e ~/.gitconfig.pre-hm ] && mv ~/.gitconfig.pre-hm ~/.gitconfig
   ```
2. Put the old scripts back, if step 10 moved them.
   ```bash
   mv ~/.local/bin.pre-hm/* ~/.local/bin/ && rmdir ~/.local/bin.pre-hm
   ```
3. Reinstall the old `nix profile` apps, if step 10 removed them:
   ```bash
   nix profile add --no-write-lock-file github:patrickjaja/claude-desktop-extra
   ```
   ```bash
   nix profile add git+file:///home/hisoft/Documents/MangaMeeyaCE
   ```
   ```bash
   nix profile add path:/home/hisoft/Documents/usbeehive-flake
   ```
4. Log out and back in.

A few other Home Manager files, such as the KDE Connect permission service under
`~/.config/systemd/user`, stay behind. They're harmless.

### Back to the channel-based config for good

This only works until step 13, because it needs the old channels. After rolling the system
back, restore `/etc/nixos`; plain `nixos-rebuild switch --sudo` then builds the old config
again.
```bash
sudo rm /etc/nixos && sudo mv /etc/nixos.bak /etc/nixos
```

### TPM auto-unlock

If the disk asks for the passphrase after the switch, the TPM key is bound to something
that changed, i.e. a PCR other than 7. Boot with the passphrase, then bind the TPM key to
PCR 7 only (the Secure Boot state), which survives kernel and bootloader updates. The
command asks for your passphrase and doesn't touch the passphrase slot.
```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-uuid/44c43796-65a5-4ade-aee4-e697321fb2f4
```

## Optional leftover cleanup (Pritunl)

The config no longer contains Pritunl. These remove its leftover state:

- Your Pritunl profiles:
  ```bash
  rm -rf ~/.config/pritunl
  ```
- The service's state:
  ```bash
  sudo rm -rf /var/lib/pritunl-client
  ```
- The uncommitted version bump in your nixpkgs checkout:
  ```bash
  git -C ~/Documents/nixpkgs restore pkgs/by-name/pr/pritunl-client/package.nix
  ```

## Day to day

Run from `~/nixos-config`; `just` with no arguments lists the recipes. Plain
`nixos-rebuild switch --sudo` works from anywhere.

| Task | Command |
| --- | --- |
| rebuild + activate | `just switch` or `nixos-rebuild switch --sudo` |
| build and show the diff first | `just diff` (nh prints added/removed/changed packages; `switch`, `boot`, `test` print it too) |
| update everything (except the two pins) | `just up`, then `just diff` and `just switch` |
| update one or more inputs | `just upp <input>…` (for Claude Desktop: the `claude-update` alias) |
| after pushing MangaMeeyaRush `main` | `just upp mangameeya-rush` |
| try unpushed MangaMeeya work | `nixos-rebuild build --override-input mangameeya-rush git+file:///home/hisoft/Documents/MangaMeeyaCE` |
| upgrade lanzaboote / auto-cpufreq | see "Updating pinned inputs" |
| format | `just fmt` |
| garbage-collect | `just gc` |
| deduplicate the store (hard links) | `just optimise` (or `just optimize`) |

New files must be `git add`ed before a rebuild will see them. Commit `flake.lock`
changes so updates can be rolled back with git.

`~/.bashrc`, `~/.bash_profile`, `~/.profile` and the global git config are now
read-only symlinks into the Nix store. Change aliases, environment variables and git
settings in `home/hisoft/` and rebuild, rather than editing those files.

niri's `~/.config/niri/config.kdl` stays your own file. Only the laptop panel settings (with
HDR) and some binds come from here, set in `home/hisoft/niri.nix`: config.kdl includes
`~/.config/niri/nix-outputs.kdl` (written by a small user service, since the HDR brightness
changes at runtime) and `nix-binds.kdl` (read-only, from Home Manager). See "niri session".

## niri session

`modules/compositors.nix` adds a niri session next to Plasma, and Plasma stays the
default. Pick **Niri** in SDDM's session menu; to go back, log out and pick
**Plasma (Wayland)**. (Hyprland was tried too and removed on 2026-09-27.)

HDR support:

| Session | HDR desktop (SDR and HDR together) | Fullscreen HDR (games, video) | Status |
| --- | --- | --- | --- |
| Plasma 6.6 | yes | yes | mature |
| niri 26.04 (mainline) | no | no | 10-bit output only; upstream plans to follow cosmic-comp later |
| niri-spicy (fork, used here) | `hdr mode="on"` | `hdr` (auto) | experimental community fork |

SDDM only reads its session list when it starts, and NixOS never restarts it during a
switch, so a session added or removed shows up (or disappears) after a reboot.

**Config.** `~/.config/niri/config.kdl` is your own file; niri applies edits when you save.
Some settings come from this repo instead, set in `home/hisoft/niri.nix`; config.kdl
includes two files for them. The keyboard layout comes from `localectl` automatically;
Super+Space switches it.

- `nix-outputs.kdl`: the laptop panel (`eDP-1`) with HDR. `hdr mode="on"` keeps the desktop
  in HDR like Plasma, so windowed HDR content (e.g. HDR video in Vivaldi) shows as HDR; the
  default `mode="auto"` only switches for a fullscreen HDR app. Peak is 950 nits, as in
  Plasma. It's included *before* `dms/outputs.kdl`, because niri uses the first `output`
  block for a name and ignores later ones. So the panel's resolution, refresh rate and scale
  are set in `niri.nix`, and DMS's display settings no longer change them; DMS still
  handles other monitors.
- `nix-binds.kdl`: key binds (below), read-only from Home Manager.

**HDR brightness.** In HDR the panel ignores its backlight, so brightness is done in
software, as Plasma does: the SDR white level (niri-spicy's `reference-luminance`) follows
the backlight level, 100% = 400 nits (Plasma's "SDR brightness"). The user service
`niri-hdr-brightness` (started and stopped with niri) watches the backlight and rewrites
`nix-outputs.kdl` with the matching value, which niri applies with a redraw, no mode
switch. So the brightness keys, DMS's slider and DMS's idle dimming all keep working, and
DMS's on-screen number stays right. The lowest level in HDR is 1 nit, not 0: niri tells
apps this value, and 0 would break their color math. Without HDR, 0% really is off.
Check it with `systemctl --user status niri-hdr-brightness`. If brightness ever changes
much faster at mid levels than it should, the panel is also partly following the backlight
and the two stack.

Check HDR in Vivaldi: open the dev tools console (F12) and run
`matchMedia('(dynamic-range: high)').matches`; it's `true` when Vivaldi sees an HDR display.
Restart Vivaldi if it was open before HDR was turned on. If HDR is more trouble than it's
worth, `hdr mode="auto"` in `niri.nix` keeps the desktop in SDR with the real backlight;
only fullscreen HDR apps switch the screen to HDR, and windowed Vivaldi won't report HDR.

**Bar and shell: DankMaterialShell (DMS).** niri's default config starts `waybar` with
waybar's stock config; its icons were empty boxes because no icon font was installed (now
fixed in `modules/fonts.nix`). DMS, a Quickshell-based shell, replaces waybar, fuzzel, mako
and swaylock with a bar, launcher, notification center, control center and lock screen.

DMS starts by itself: `modules/compositors.nix` ties its user service to `niri.service`,
the declarative form of `systemctl --user add-wants niri.service dms` from DMS's install
docs. It starts and stops with niri, and systemd restarts it if it crashes. It never runs
in Plasma; the service's usual target, `graphical-session.target`, would start it there
too. So config.kdl has no `spawn-at-startup "waybar"`, and must not get
`spawn-at-startup "dms" "run"`: a second copy opens a second bar.

**Binds.**
- In config.kdl's `binds { … }` block (`Mod+V` replaced floating, which moved to
  `Mod+Alt+V`):
  ```kdl
  Mod+V       { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
  Mod+N       { spawn "dms" "ipc" "call" "notifications" "toggle"; }
  Mod+X       { spawn "dms" "ipc" "call" "powermenu" "toggle"; }
  Super+Alt+L { spawn "dms" "ipc" "call" "lock" "lock"; }
  ```
- From `home/hisoft/niri.nix`: Home Manager writes them to `~/.config/niri/nix-binds.kdl`,
  and config.kdl ends with `include optional=true "nix-binds.kdl"`. niri lets
  a later bind replace an earlier one for the same key, so keep the include after the
  `binds` block. Change these in `niri.nix` and `just switch`.
  - `Mod+D` and `Alt+Space` (as in KRunner and PowerToys Run): DMS launcher, replacing
    fuzzel. Not `Mod+Space`, DMS's usual key, because Super+Space switches the keyboard
    layout (`grp:win_space_toggle`).
  - Volume and brightness keys: 5% per press, 1% with Shift (like Plasma), 10% with Ctrl.
    DMS's on-screen bar shows the value; "Always Show Percentage" (DMS Settings → OSD) adds
    the number. Volume goes through DMS. Brightness uses `brightnessctl`, because DMS's own
    command never goes below 1%; DMS still shows the bar since it watches the backlight. In
    HDR, the backlight level drives the software brightness (see "HDR brightness").

Check for missing pieces:
```bash
dms doctor
```
Expected leftovers:
- **power-profiles-daemon: Not available** (warning). It's off because auto-cpufreq
  manages CPU power (`modules/power.nix`), so DMS has no power-profile switch.
- **danksearch: Not installed.** Optional: indexed file search in the launcher (type `/`).
  nixpkgs has it as `dsearch`.

`systemctl --user status dms` shows whether DMS is running, and
`journalctl --user -u dms -b` shows its log. A rebuild that updates DMS restarts it (the
bar blinks). Apps opened from the DMS launcher keep running, because DMS starts each one
in its own systemd scope. If the bar is missing, e.g. after rolling back to a generation
from before this setup, start it by hand:
```bash
niri msg action spawn -- dms run
```
DMS's default UI font (Google Sans Flex) isn't in nixpkgs, so it falls back to your
system font. Pick another one under DMS Settings → Typography if you like.

**KDE Wallet** works in niri and holds the same secrets as in Plasma:
- The wallet unlocks with your login password. SDDM's PAM (`pam_kwallet5`) starts the
  wallet daemon for every session, and an autostart entry (`NotShowIn=KDE`) runs
  `pam_kwallet_init` in niri. Plasma does that step itself.
- gnome-keyring stays off, although the niri module would turn it on, so KWallet is the
  only Secret Service.
- The portal's Secret backend points to KWallet (for sandboxed apps).
- Vivaldi always uses `--password-store=kwallet6`. Chromium-based apps pick KWallet on
  their own only under Plasma; elsewhere they'd switch stores and lose saved passwords and
  cookies.
- **Other Electron apps** have the same problem and may ask you to log in again there. For
  VS Code, add `"password-store": "kwallet6"` to `~/.vscode/argv.json`.
- To check after logging into niri, run the command below. It should show `ksecretd`:
  ```bash
  busctl --user status org.freedesktop.secrets | grep -E '^(Comm|CommandLine)='
  ```

Caveats:
- **niri-spicy** is a one-person community fork that rolls unmerged branches together.
  Its docs warn that HDR is experimental and only guaranteed correct for a single
  fullscreen app. Screenshots of HDR content come out in SDR.
- **Plasma-only things** don't carry over: KDE's display and HDR settings, Plasma widgets.
  niri uses its own portals.
- **KDE Connect remote input** (phone as mouse and keyboard) works through a small
  RemoteDesktop portal bridge (`pkgs/hypr-kdeconnect-portal`), without a permission
  prompt.
- **"Share input devices"** (push the pointer past a screen edge to drive the phone) works
  through the InputCapture backend
  [xdg-desktop-portal-layercapture](https://github.com/iNViTiON/xdg-desktop-portal-layercapture)
  (flake input `layercapture`, own project; niri itself has none, niri issue #823).
  Leave a capture by moving off the phone's edge, with Mod+Escape, or from a TTY with
  `pkill -KILL -x layercapture`. Niri's mouse-wheel binds, 3/4-finger gestures and Super
  shortcuts stay on the laptop. After a switch that adds or updates it, restart
  xdg-desktop-portal (it picks its backends only at startup) and then kdeconnectd:
  `systemctl --user restart xdg-desktop-portal.service app-org.kde.kdeconnect.daemon@autostart.service`. If the backend restarts, KDE Connect needs a restart
  (`systemctl --user restart app-org.kde.kdeconnect.daemon@autostart.service`).

To update niri-spicy, update both of its inputs together, so niri and its Smithay fork
stay in step:
```bash
just upp niri-spicy niri-spicy-smithay
```

To uninstall, remove the `compositors.nix` import from `hosts/mix-nixos/default.nix` and
the `niri-spicy` and `niri-spicy-smithay` inputs from `flake.nix`, then `just switch`.
`~/.config/niri` stays behind.

## Behavior changes compared with the old config

- **Dropped:** Pritunl (package, service, local nixpkgs override); Microsoft Edge;
  spacedrive, which nixos-unstable marks broken; the unused git-lfs filter.
- **Automatic GC** (`nix.gc`, weekly, older than 7 days) and `auto-optimise-store`
  (modules/nix.nix). This replaces running `nix-collect-garbage -d` by hand.
- **The boot menu holds at most 2 generations** (`boot.lanzaboote.configurationLimit`),
  because the EFI partition is 256M and each kernel + initrd takes ~69M. Older generations
  can still be activated from a running system until GC removes them.
- **Channels are disabled** (`nix.channel.enable = false`). `<nixpkgs>`,
  `nix-shell -p` and `nixpkgs#` now resolve to the locked flake nixpkgs, which NixOS does
  automatically for flake systems. `nixpkgs-unstable#` is registered as well.
- **`command-not-found` turns itself off.** It needs `programs.sqlite`, which only
  channel tarballs ship. If you want it back, use nix-index or point `nixpkgs.url` at
  `https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz`.
- **All `pkgs-unstable.*` packages move to a fresh nixos-unstable.** The old channel was
  months behind. github-copilot-cli goes from 1.0.44 (local checkout) to current unstable.
- **auto-cpufreq is pinned to release v3.1.0**, instead of following whatever `master` was.
- **Home Manager now owns `~/.bashrc`, `~/.bash_profile` and `~/.profile`.** Its defaults
  also add `HISTSIZE=10000`, `HISTFILESIZE=100000` and `shopt -s histappend extglob
  globstar checkjobs`. `HISTCONTROL=ignoreboth` still comes from the system. The
  interactive guard also fixes the `history: HISTFILE: parameter null or not set` error
  in non-interactive shells.
- **`CLAUDE_PACKAGE_MANAGER`** is now a login-session variable instead of a per-shell
  export, so apps started from the Plasma menu see it too.
- **`claude-update`** now updates the input and shows the `flake.lock` diff. It doesn't
  rebuild.
- **Git:** the global config is read-only, so `git config --global` and
  `gh auth setup-git` fail. The credential helper uses gh's store path instead of
  `/run/current-system/sw/bin/gh`.
- **Scripts:**
  - They now run with `errexit`, `nounset` and `pipefail`, and are shellchecked at build
    time.
  - `boot-next`: dropped a duplicate `2>&1`.
  - `scrcpy-connect`:
    - calls `adb` from android-tools instead of globbing `/nix/store/*-android-tools-*`
    - drops the duplicated if-block, so "Connecting to …" prints once
    - uses `${1:-}` so running it without an address still works under `nounset`
- **Firewall and networking:**
  - rquickshare's ports (UDP 5353, TCP 47983) are really open now, on every network. The
    old nftables table never opened them.
  - `waydroid0` is no longer a trusted interface: only DNS and DHCP are allowed from it.
    `networking.firewall.filterForward` is on, and only traffic from `waydroid0` (plus
    replies) is forwarded. If you ever share a connection through NetworkManager
    (hotspot), add that interface to `extraForwardRules` in modules/waydroid.nix.
  - docker.nix no longer sets `ip_forward`, IPv6 forwarding or
    `kernel.unprivileged_userns_clone`. Rootless Docker doesn't need them, and IPv4
    forwarding for Waydroid is set in waydroid.nix.
  - Steam's dedicated-server port (27015) is closed. Remote Play stays open.
- **Removed settings that did nothing:**
  - `i915.enable_guc=3`: the GPU uses `xe`.
  - The GPU packages: nixos-hardware adds them.
  - `enableRedistributableFirmware`: already set by `not-detected.nix`.
  - `services.keyd.enable = false`: that's the default.
  - `networking.dhcpcd.wait`: dhcpcd is unused with NetworkManager.
  - `home.username` / `home.homeDirectory`: set by the NixOS module.
- **usbeehive** is built with nixos-26.05 instead of 25.11. Its `cargoHash` stays valid.

## Carried over as-is, worth a look

- **Bitwarden in Vivaldi**, to revisit after the switch:
  - `bitwarden-desktop` stays a *system* package on purpose. Biometric ("system
    authentication") unlock goes through polkit, and polkit only reads
    `com.bitwarden.Bitwarden.policy` from the system profile. Installed through Home
    Manager, biometric unlock stops working.
  - The Vivaldi link is created by a root activation script inside your home folder.
    Home Manager could do it as your user.
  - The `/etc/chromium` Bitwarden JSON (proxy from unstable) is shadowed by the
    user-level one, so it's probably unused.
- The web-eid and opensc `/etc` entries point at stable `pkgs`, while the installed EE ID
  packages come from unstable.
- The nixos-hardware X1 module enables `thermald` with `mkDefault`. The "not supported on
  Lenovo" override is still commented out.
- `~/tmux.conf` (`set -g mouse on`) is never read, because tmux looks for
  `~/.tmux.conf`. `programs.tmux.extraConfig` would be the declarative place for it.

## Accepted trade-offs

- **`sudo` uses your PATH**, which starts with the user-writable `~/.volta/bin` and
  `~/.local/bin`. So anything that can write there as you can get commands run as root
  by a rebuild. Fixing it would take a `secure_path` in
  `security.sudo.extraConfig`.
- **KDE Connect remote input is pre-authorized**, so a paired device controls keyboard
  and mouse without a prompt. Unpair lost devices right away.
- **The fingerprint reader also unlocks `sudo` and polkit** (NixOS default with fprintd),
  which makes it single-factor for root.
- **`/etc/nixos` points at your user-owned repo**, so a program running as you can change
  the next system build. Review `git diff` / `just diff` before switching.
