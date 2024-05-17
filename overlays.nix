{ self, inputs, ... }:
{
  flake.overlays.default = _self: super: {
    attic-client = super.callPackage ./packages/attic { clientOnly = true; };
    attic-server = super.callPackage ./packages/attic { };
    celery-exporter = super.callPackage ./packages/celery-exporter { };
    gotenberg = super.callPackage ./packages/gotenberg { };
    keywind = super.callPackage ./packages/keywind { };
    pizauth = super.callPackage ./packages/pizauth { inherit (super.pkgs.darwin.apple_sdk.frameworks) Security; };
    tika-server-standard = super.callPackage ./packages/tika-server-standard { };
  };

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        self.overlays.default
      ];
    };
  };
}

