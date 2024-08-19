{ lib, stdenv, runCommand, buildPythonPackage, fetchFromGitHub, fetchurl
, callPackage, build, numpy, pillow, pytest, setuptools-scm, }:
let
  # TODO: Ideally we would build pdfium from source (libreoffice also uses it),
  # but it's quite complicated as it's a Chromium project.

  # Full version as published on https://github.com/bblanchon/pdfium-binaries/releases
  pdfiumVersion = "128.0.6611.0";

  supportedPdfiumBinVersions = {
    # keyed by nixpkgs platform name, also used in `meta.platforms` below
    aarch64-darwin = {
      platformFileInfix = "mac-arm64";
      hash = "sha256-5gjJ075JAGlNCRssLllF7fh92NLP34mixtx95CT4Hn0=";
    };
    aarch64-linux = {
      platformFileInfix = "linux-arm64";
      hash = "sha256-jy0TAl0dH71+XfsGyFAqwQwqRpnFgwJ6NLlPf2E5gZM=";
    };
    x86_64-linux = {
      platformFileInfix = "linux-x64";
      hash = "sha256-LK++NrBipWJ6spc2x1pT7HpBR+B4FT3OE2UyMUsTnyM=";
    };
  };

  pdfium = if !builtins.hasAttr stdenv.hostPlatform.system
  supportedPdfiumBinVersions then
    throw
    "Unsupported platform for pypdfium2 (please add it if it's available)."
  else
    supportedPdfiumBinVersions.${stdenv.hostPlatform.system};

  parsedNumericVersionComponents = # Turns e.g. `"121.9.6110.0"` into `[121 9 6110 0]`.
    let jsonList = map builtins.fromJSON (lib.splitVersion pdfiumVersion);
    in assert lib.length jsonList == 4;
    assert lib.all lib.isInt jsonList;
    jsonList;
  pdfiumVersion_major = lib.elemAt parsedNumericVersionComponents 0;
  pdfiumVersion_minor = lib.elemAt parsedNumericVersionComponents 1;
  pdfiumVersion_build = lib.elemAt parsedNumericVersionComponents 2;
  pdfiumVersion_patch = lib.elemAt parsedNumericVersionComponents 3;

  # Contains more than a single dir; `builtins.fetchTarball` and `fetchzip` cannot handle that yet,
  # so we need to manually unpack it below.
  pdfiumPrebuiltTar = (fetchurl {
    url =
      "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/${
        toString pdfiumVersion_build
      }/pdfium-${pdfium.platformFileInfix}.tgz";
    hash = pdfium.hash;
  });

  pdfium-bin = runCommand "pdfium-bin" { } ''
    mkdir "$out"
    tar xf "${pdfiumPrebuiltTar}" --directory "$out"
  '';

  ctypesgen_pypdfium_fork_package =
    { lib, buildPythonApplication, fetchFromGitHub, toml, setuptools-scm, }:
    buildPythonApplication rec {
      pname = "ctypesgen";
      version = "ebd495b1733b60132151154d6358fd1eb336a36a";
      format = "pyproject";

      src = fetchFromGitHub {
        owner = "pypdfium2-team"; # fork needed for `pypdfium2`
        repo = "ctypesgen";
        rev = version;
        hash = "sha256-cfEXv7L1syoua0ptDSNKMoqg2WwS0P9PqpRf3rqz42k=";
      };

      # This package uses setuptools-scm to derive the version from the git repo (which we don't have),
      # so use this environment variable to set it manually instead.
      SETUPTOOLS_SCM_PRETEND_VERSION =
        "1.1.1+g${version}"; # we use the most recent tag and append the git version

      doCheck = false;

      propagatedBuildInputs = [ toml setuptools-scm ];
    };
  ctypesgen_pypdfium_fork = callPackage ctypesgen_pypdfium_fork_package { };

in buildPythonPackage rec {
  pname = "pypdfium2";
  version = "4.30.0";

  src = fetchFromGitHub {
    owner = "pypdfium2-team";
    repo = "pypdfium2";
    rev = version;
    hash = "sha256-zr17BsXtQkCZ9eQwke2AiqY84rox5ZOJ/mJTHdinjxw=";
  };

  # Following instructions from section
  # > With caller-built data files (this is expected to work offline)
  # https://github.com/pypdfium2-team/pypdfium2/tree/30c60af438b7cd90e22d42dd2ba5bffdeb568c42#install-source-caller
  # with the addition of `--compile-libdirs`, which fixes `ctypesgen` warning:
  #     WARNING: Could not load library 'pdfium'. Okay, I'll try to load it at runtime instead.
  preConfigure = ''
    "${ctypesgen_pypdfium_fork}/bin/ctypesgen" \
      --library pdfium \
      --compile-libdirs "${pdfium-bin}/lib" \
      --runtime-libdirs "${pdfium-bin}/lib" \
      --headers "${pdfium-bin}"/include/fpdf*.h \
      -o src/pypdfium2_raw/bindings.py

    cat > src/pypdfium2_raw/version.json <<END
    {
      "major": ${toString pdfiumVersion_major},
      "minor": ${toString pdfiumVersion_minor},
      "build": ${toString pdfiumVersion_build},
      "patch": ${toString pdfiumVersion_patch},
      "n_commits": 0,
      "hash": null,
      "origin": "pdfium-binaries/nixos",
      "flags": []
    }
    END

    export PDFIUM_PLATFORM='prepared!system:${toString pdfiumVersion_build}'

    # The `setup.py` invocation uses the `export`ed variables above.
  '';

  propagatedBuildInputs = [ build setuptools-scm numpy pytest pillow ];

  # doCheck = false;

  pythonImportsCheck = [ "pypdfium2" ];

  meta = with lib; {
    description = "Python bindings to PDFium";
    homepage = "https://pypdfium2.readthedocs.io/";
    license = with licenses; [
      asl20 # or
      bsd3
    ];
    maintainers = with maintainers; [ chpatrick nh2 ];
    platforms = builtins.attrNames supportedPdfiumBinVersions;
  };
}
