{ buildPythonPackage, django, django-ipware, python-ipware, fetchPypi
, setuptools, structlog, }:
buildPythonPackage rec {
  pname = "django-structlog";
  version = "8.1.0";
  format = "pyproject";

  src = fetchPypi {
    pname = "django_structlog";
    inherit version;
    hash = "sha256-Aim5ou+9JKTjUAFpeI5TkVwkKVIeNOQd1YzMVgOb7z8=";
  };

  buildInputs = [ setuptools ];

  propagatedBuildInputs = [ django django-ipware python-ipware structlog ];
}
