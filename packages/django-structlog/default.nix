{ lib
, buildPythonPackage
, django
, django-ipware
, python-ipware
, fetchPypi
, setuptools
, structlog
}:
buildPythonPackage rec {
  pname = "django-structlog";
  version = "8.0.0";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-5DmuFz2NhStfmR/3Uo2M5bCuADzG6lEyFTNLMgSu4Jw=";
  };

  buildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    django
    django-ipware
    python-ipware
    structlog
  ];
}
