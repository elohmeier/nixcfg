{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    excelcompare = prev.callPackage ./packages/excelcompare { };
    keywind = prev.callPackage ./packages/keywind { };
    tabula-java = prev.callPackage ./packages/tabula-java { };

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
