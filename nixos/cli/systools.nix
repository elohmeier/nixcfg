{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages =
    [
      (pkgs.sqlite.override { interactive = true; })
      config.boot.kernelPackages.perf
      pkgs.bpftrace
      pkgs.ethtool
      pkgs.msr-tools
      pkgs.nmap
      pkgs.numactl
      pkgs.sysstat
      pkgs.tiptop
      pkgs.trace-cmd
      pkgs.wireguard-tools
    ]
    ++ lib.optionals pkgs.stdenv.isx86_64 [
      config.boot.kernelPackages.turbostat
      pkgs.cpuid
    ];
}
