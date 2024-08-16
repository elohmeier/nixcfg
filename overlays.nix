{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    attic-client = prev.callPackage ./packages/attic { clientOnly = true; };
    attic-server = prev.callPackage ./packages/attic { };
    excelcompare = prev.callPackage ./packages/excelcompare { };
    gotenberg = prev.callPackage ./packages/gotenberg { };
    keywind = prev.callPackage ./packages/keywind { };
    pizauth = prev.callPackage ./packages/pizauth {
      inherit (prev.pkgs.darwin.apple_sdk.frameworks) Security;
    };
    tabula-java = prev.callPackage ./packages/tabula-java { };
    tika-server-standard = prev.callPackage ./packages/tika-server-standard { };

    nixcfg-python3 = prev.python3.override {
      packageOverrides = self: _super: {
        celery-exporter = self.callPackage ./packages/celery-exporter { };
        pypdfium = self.callPackage ./packages/pypdfium { };
      };
    };

    celery-exporter = with final.nixcfg-python3.pkgs; toPythonApplication celery-exporter;

    link-paperless-docs = prev.writers.writePython3Bin "link-paperless-docs"
      {
        flakeIgnore = [
          "E265"
          "E501"
        ];
        libraries = with prev.python3Packages; [
          click
          httpx
          pydantic
          structlog
        ];
      } ./scripts/link-paperless-docs.py;
  };

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
        overlays = [ self.overlays.default ];
      };
    };
}
