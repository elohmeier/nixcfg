{ self, inputs, ... }:
{
  flake.overlays.default = _self: super: {
    attic-client = super.callPackage ./packages/attic { clientOnly = true; };
    attic-server = super.callPackage ./packages/attic { };
    excelcompare = super.callPackage ./packages/excelcompare { };
    gotenberg = super.callPackage ./packages/gotenberg { };
    keywind = super.callPackage ./packages/keywind { };
    pizauth = super.callPackage ./packages/pizauth { inherit (super.pkgs.darwin.apple_sdk.frameworks) Security; };
    tika-server-standard = super.callPackage ./packages/tika-server-standard { };

    nixcfg-python3 = super.python3.override {
      packageOverrides = self: _super: {
        celery-exporter = self.callPackage ./packages/celery-exporter { };
      };
    };

    celery-exporter = with _self.nixcfg-python3.pkgs; toPythonApplication celery-exporter;

    link-paperless-docs = super.writers.writePython3Bin "link-paperless-docs"
      {
        flakeIgnore = [ "E265" "E501" ];
        libraries = with super.python3Packages; [ click httpx pydantic structlog ];
      } ./scripts/link-paperless-docs.py;
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

