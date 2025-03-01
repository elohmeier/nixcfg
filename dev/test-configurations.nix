# We use the nixosConfigurations to test all the modules below.
#
# This is not optimal, but it gets the job done
{ self, pkgs }:
let
  lib = pkgs.lib;
  system = pkgs.system;

  nixosSystem =
    args: import "${toString pkgs.path}/nixos/lib/eval-config.nix" ({ inherit lib system; } // args);

  # some example configuration to make it eval
  dummy =
    { config, ... }:
    {
      networking.hostName = "example-common";
      system.stateVersion = config.system.nixos.version;
      users.users.root.initialPassword = "fnord23";
      boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
      fileSystems."/".device = lib.mkDefault "/dev/sda";

      # Don't reinstantiate nixpkgs for every nixos eval.
      # Also important to have nixpkgs config which allows for some required insecure packages
      nixpkgs = {
        inherit pkgs;
      };
    };
in
{
  example-common = nixosSystem {
    modules = [
      dummy
      self.nixosModules.cli
    ];
  };
}
