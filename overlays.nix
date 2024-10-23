{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    excelcompare = prev.callPackage ./packages/excelcompare { };
    kanboard = prev.callPackage ./packages/kanboard { };
    keywind = prev.callPackage ./packages/keywind { };
    realise-symlink = prev.callPackage ./packages/realise-symlink { };
    tabula-java = prev.callPackage ./packages/tabula-java { };

    nixcfg-python3 = prev.python3.override {
      packageOverrides = self: _super: {
        celery-exporter = self.callPackage ./packages/celery-exporter { };
        django-structlog = self.callPackage ./packages/django-structlog { };
        google-cloud-documentai = self.callPackage ./packages/google-cloud-documentai { };
        google-cloud-documentai-toolbox = self.callPackage ./packages/google-cloud-documentai-toolbox { };
        pypdfium = self.callPackage ./packages/pypdfium { };
      };
    };

    celery-exporter = with final.nixcfg-python3.pkgs; toPythonApplication celery-exporter;

    link-paperless-docs = prev.writers.writePython3Bin "link-paperless-docs" {
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

    google-ocr = prev.writers.writePython3Bin "google-ocr" {
      flakeIgnore = [
        "E226"
        "E265"
        "E501"
      ];
      libraries = with final.nixcfg-python3.pkgs; [
        click
        google-cloud-documentai
        google-cloud-documentai-toolbox
        ocrmypdf
        pikepdf
      ];
    } ./scripts/google-ocr.py;
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
