{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.kernelModules = [ "uinput" ];
  hardware.uinput.enable = true;

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = [ ];
        extraDefCfg = ''
          process-unmapped-keys yes
          linux-device-detect-mode keyboard-only
          linux-unicode-u-code i
          concurrent-tap-hold yes
        '';

        config = ''
          (defsrc
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
            caps a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    rsft
            lctl lmet lalt           spc            ralt rmet rctl
          )

          ;; Caps Lock -> Backspace in every layout. XKB's Colemak already does this, but
          ;; Thai (Manoonchai) doesn't, so do it here, below XKB and fcitx5.
          (deflayer base
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    @bsl
            bspc a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    @rsf
            lctl lmet lalt           spc            ralt rmet rctl
          )

          (defchordsv2
            ;; Copilot key -> Ctrl + Win + Space: fcitx5 switches back to the previous
            ;; language (./japanese.nix). Win + Space cycles through all of them.
            (lsft lmet f23) (multi lctl lmet spc) 200 all-released ()
          )

          (deflayer symbols
            @grv _    _    _    _    @fve _    _    _    _    _    _    @eql _
            _    _    _    _    @p-k _    _    _    _    _    _    _    _    _
            _    _    @r-k @s-k @t-k @d-k _    @n-k _    _    _    _    _
            _    _    _    @c-k _    _    _    @m-k @cma @dot @bbs _
            _    _    _              _              _    _    _
          )

          (defalias
            rsf (tap-hold 200 200 - rsft)
            bsl (tap-hold 200 200 \ (layer-toggle symbols))

            ;; Colemak special characters
            c-k (unicode ©)
            r-k (unicode ®)
            t-k (unicode ™)
            d-k (unicode °)
            m-k (unicode µ)
            n-k (unicode №)
            p-k (unicode ¶)
            s-k (unicode §)
            cma (unicode ≤)
            dot (switch ((or lsft rsft)) (unicode ≥) break () (unicode …) break)
            eql (switch ((or lsft rsft)) (unicode ±) break () (unicode ≠) break)
            grv (unicode ≈)
            fve (unicode ‰)
            bbs (unicode ¦)
          )
        '';
      };
    };
  };
}
