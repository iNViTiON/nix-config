# Quick Accents: fcitx5's word hints (Ctrl+Alt+H, or Ctrl+Alt+J for one word) also offer the
# accented forms of the last typed letter, from PowerToys Quick Accent's list
# (./characters.json, all its languages). Type `a` and the list has ä å æ and so on.
# Pick with Alt+1..0, or highlight with Tab/Shift+Tab and keep typing.
# Fcitx5 has no setting for this: ./hint-list.patch adds it, applied in ../../overlays. The
# patch reads the table fcitx5 keeps for its long-press feature, which stays off.
# After a switch: `fcitx5 -r`, or log in again.
{ pkgs, ... }:

{
  environment.etc."xdg/fcitx5/conf/keyboard-longpress.conf".source =
    pkgs.runCommand "keyboard-longpress.conf"
      {
        nativeBuildInputs = [ pkgs.python3 ];
        # The characters are not ASCII
        env.PYTHONIOENCODING = "utf-8";
      }
      ''
        python3 ${./generate.py} ${./characters.json} > "$out"
      '';
}
