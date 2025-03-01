{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    kanboard = prev.callPackage ./packages/kanboard { };
    realise-symlink = prev.callPackage ./packages/realise-symlink { };
    tabula-java = prev.callPackage ./packages/tabula-java { };
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
