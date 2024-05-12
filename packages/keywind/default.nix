{ lib, stdenv, fetchFromGitHub, stdenvNoCC, jq, moreutils, nodePackages, cacert }:

stdenv.mkDerivation rec {
  pname = "keywind";
  version = "2023-12-13";

  src = fetchFromGitHub {
    owner = "lukin";
    repo = "keywind";
    rev = "bdf966fdae0071ccd46dab4efdc38458a643b409";
    hash = "sha256-8N+OQ6Yg9RKxqGd8kgsbvrYuVgol49bo/iJeIJXr3Sg=";
  };

  pnpm-deps = stdenvNoCC.mkDerivation {
    pname = "${pname}-pnpm-deps";
    inherit src version;

    nativeBuildInputs = [
      jq
      moreutils
      nodePackages.pnpm
      cacert
    ];

    installPhase = ''
      export HOME=$(mktemp -d)
      pnpm config set store-dir $out
      # use --ignore-script and --no-optional to avoid downloading binaries
      # use --frozen-lockfile to avoid checking git deps
      pnpm install --frozen-lockfile --no-optional --ignore-script

      # Remove timestamp and sort the json files
      rm -rf $out/v3/tmp
      for f in $(find $out -name "*.json"); do
        sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
        jq --sort-keys . $f | sponge $f
      done
    '';

    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-D/UMLX4WYBHMNywEU54RevG4a4ruATeUeOQmlTlQ7yg=";
  };

  nativeBuildInputs = [
    nodePackages.pnpm
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    pnpm config set store-dir ${pnpm-deps}
    pnpm install --offline --frozen-lockfile --no-optional --ignore-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r theme/keywind/* $out

    runHook postInstall
  '';
}
