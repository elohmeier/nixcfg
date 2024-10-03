{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,
  google-api-core,
  google-auth,
  proto-plus,
  protobuf,
  grpc-google-iam-v1,
}:

buildPythonPackage rec {
  pname = "google-cloud-documentai";
  version = "2.32.0";
  pyproject = true;

  src = fetchPypi {
    pname = "google_cloud_documentai";
    inherit version;
    hash = "sha256-cLs4UBc0+oBlhdNeR13egnbhy6ryVUN0Bgt5s+PEYJ4=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    google-api-core
    google-auth
    proto-plus
    protobuf
    grpc-google-iam-v1
  ];

  pythonImportsCheck = [
    "google.cloud.documentai"
  ];

  meta = {
    description = "Google Cloud Documentai API client library";
    homepage = "https://pypi.org/project/google-cloud-documentai/";
    license = lib.licenses.asl20;
  };
}
