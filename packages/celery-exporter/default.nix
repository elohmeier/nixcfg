{ lib, buildPythonPackage, celery, click, fetchFromGitHub, flask, loguru
, poetry-core, prometheus-client, pythonRelaxDepsHook, redis, waitress }:
buildPythonPackage rec {
  pname = "celery-exporter";
  version = "0.10.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "danihodovic";
    repo = "celery-exporter";
    rev = "refs/tags/v${version}";
    hash = "sha256-2HxadCpNIy0WlRWFIBDeyAMXJ+Fnfc2+MGYdRnB64+I=";
  };

  postPatch = ''
    # Fix folder name to be picked up by poetry
    mv src celery_exporter

    # Remove unnecessary pretty_errors import
    substituteInPlace celery_exporter/cli.py \
      --replace "import pretty_errors" ""

    # add script to pyproject.toml
    cat <<EOF >> pyproject.toml
    [tool.poetry.scripts]
    celery-exporter = "celery_exporter.cli:cli"
    EOF
  '';

  nativeBuildInputs = [ poetry-core pythonRelaxDepsHook ];

  propagatedBuildInputs =
    [ celery click flask loguru prometheus-client waitress redis ];

  pythonRelaxDeps = [ "prometheus-client" "waitress" ];

  pythonRemoveDeps = [ "pretty-errors" ];

  pythonImportsCheck = [ "celery_exporter.cli" ];
}
