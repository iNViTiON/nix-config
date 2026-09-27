# Was ~/.gitconfig plus ~/.config/git/ignore. Home Manager writes ~/.config/git/config
# and ~/.config/git/ignore. Rename ~/.gitconfig after the first switch (README): git
# still reads it, after this file, so it would keep overriding these values.
# The global git config is read-only from then on, so `git config --global ...` and
# `gh auth setup-git` fail; change settings here instead.
# System-wide git (gitFull, init.defaultBranch) stays in ../../modules/programs.nix.
#
# gh is not managed with `programs.gh`: its ~/.config/gh/config.yml only has gh's
# defaults, so managing it would just make it read-only. Only the credential helper
# from ~/.gitconfig is carried over, below.
{ lib, pkgs, ... }:
let
  # The empty entry resets any helper configured earlier, as `gh auth setup-git` writes it.
  ghCredentialHelper = [
    ""
    "!${lib.getExe pkgs.gh} auth git-credential"
  ];
in
{
  programs.git = {
    enable = true;
    # Don't install a second git; keep using the system-wide gitFull.
    package = null;

    ignores = [ "**/.claude/settings.local.json" ];

    # Same keys as the old ~/.gitconfig. Signing is set directly rather than through
    # `programs.git.signing`, whose signByDefault would also turn on tag.gpgSign.
    settings = {
      user = {
        name = "MiX";
        email = "13241662+iNViTiON@users.noreply.github.com";
        signingkey = "6358BD2329237069";
      };
      commit.gpgsign = true;
      core = {
        autocrlf = "input";
        eol = "lf";
      };
      init.defaultBranch = "main";
      credential."https://github.com".helper = ghCredentialHelper;
      credential."https://gist.github.com".helper = ghCredentialHelper;
    };
  };
}
