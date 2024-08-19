{ pkgs, ... }:

{
  imports = [ ./fish.nix ];

  environment.systemPackages = [
    pkgs.btop
    pkgs.eza
    pkgs.fd
    pkgs.ncdu
    pkgs.nnn
  ];

  programs.command-not-found.enable = false;
}
