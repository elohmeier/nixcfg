{ ... }:

{
  imports = [ ./fish.nix ./packages.nix ];

  programs.command-not-found.enable = false;
}
