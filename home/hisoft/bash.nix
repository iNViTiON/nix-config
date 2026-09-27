# Replaces the hand-written ~/.bashrc, ~/.bash_profile and ~/.profile.
# Home Manager generates all three. The first activation renames the old files to
# *.hm-backup (flake.nix: home-manager.backupFileExtension).
{ ... }:
{
  programs.bash = {
    enable = true;

    # From ~/.bashrc
    shellAliases = {
      ls = "eza";
      rc = "(claude -p /exit)";
      rcc = "(cd /home/hisoft/Documents/store-dashboard && claude exit)";
      so = "kscreen-doctor --dpms off";
      bu = "sudo bu";
      # Was `nix profile upgrade claude-desktop-extra --no-write-lock-file`. Claude Desktop
      # is now a flake input: this updates that input and shows what changed in
      # flake.lock. Review it, then rebuild with `nixos-rebuild switch --sudo`
      # (/etc/nixos is a symlink to ~/nixos-config, so no path is needed).
      claude-update = "nix flake update claude-desktop-extra --flake /etc/nixos && git -C /etc/nixos diff flake.lock";
      claude-exit = "systemctl --user stop 'app-com.anthropic.Claude*'";
      copilot = "COPILOT_RUN_APP=1 copilot";
      # claude-cowork = "nix run --no-write-lock-file github:patrickjaja/claude-cowork-service";
      # claude-desktop = "nix run --no-write-lock-file github:patrickjaja/claude-desktop-bin";
    };

    # From ~/.bashrc. initExtra runs after Home Manager's interactive-shell guard, so
    # this no longer fails in non-interactive shells ("history: HISTFILE: parameter
    # null or not set"). It loads the curated ~/.bash_history and then stops bash from
    # writing it back. HISTCONTROL=ignoreboth stays system-wide in modules/programs.nix.
    initExtra = ''
      history -r
      unset HISTFILE
    '';
  };

  # From ~/.bashrc, ~/.bash_profile and ~/.profile. Written to hm-session-vars.sh, which
  # the generated ~/.profile sources at login. Changes need a re-login.
  home.sessionVariables = {
    CLAUDE_PACKAGE_MANAGER = "bun";
    # CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
    # CLAUDE_ENABLE_STREAM_WATCHDOG = "1";
    VOLTA_HOME = "$HOME/.volta";
  };

  # Prepended to PATH in this order, matching the old files: volta shims first, then
  # ~/.local/bin (claude, bu, boot-next, ...).
  home.sessionPath = [
    "$HOME/.volta/bin"
    "$HOME/.local/bin"
  ];
}
