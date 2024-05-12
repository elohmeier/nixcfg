{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.sqlite.override { interactive = true; })
    config.boot.kernelPackages.perf
    pkgs.bpftrace
    pkgs.btop
    pkgs.ethtool
    pkgs.eza
    pkgs.fd
    pkgs.msr-tools
    pkgs.ncdu
    pkgs.nmap
    pkgs.nnn
    pkgs.numactl
    pkgs.sysstat
    pkgs.tiptop
    pkgs.trace-cmd
    pkgs.wireguard-tools
  ] ++ lib.optionals pkgs.stdenv.isx86_64 [
    config.boot.kernelPackages.turbostat
    pkgs.cpuid
  ];
}
