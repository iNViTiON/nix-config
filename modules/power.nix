# CPU frequency/power management with auto-cpufreq.
{ inputs, ... }:
{
  imports = [
    # Was `(builtins.getFlake "github:AdnanHodzic/auto-cpufreq").nixosModules.default`.
    inputs.auto-cpufreq.nixosModules.default
  ];

  programs.auto-cpufreq.enable = true;

  # KDE Plasma 6 built-in power is conflict with auto-cpufreq
  services.power-profiles-daemon.enable = false;
}
