# AirDrop with iPhones and Macs on the Intel BE201, which has no AWDL of its own: Owly
# (github:t4t5/owly) runs AWDL in userspace. owlyd, its radio service, is started by D-Bus on
# the first `owly` command; nothing runs until then. Owly's hardware table doesn't list the
# BE201 (other Intel cards work), hence allow_untested. On Intel it only works in
# "exclusive" mode, which turns Wi-Fi off while the radio is up; wired internet keeps working.
#
#   owly radio up                       start the radio (Wi-Fi goes off), in one terminal
#   owly receive --dir ~/Downloads      receive, in another
#   owly browse                         nearby AirDrop receivers
#   owly send --to "Name's iPhone" f    send a file
#
# The phone's AirDrop must be set to "Everyone for 10 minutes".
{ inputs, ... }:

{
  imports = [ inputs.owly.nixosModules.default ];

  services.owly = {
    enable = true;
    settings.allow_untested = true;
  };
}
