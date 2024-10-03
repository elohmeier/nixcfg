{
  buildPythonPackage,
  fetchPypi,
  google-api-core,
  google-auth,
  google-cloud-bigquery,
  google-cloud-documentai,
  google-cloud-storage,
  google-cloud-vision,
  grpc-google-iam-v1,
  immutabledict,
  intervaltree,
  jinja2,
  numpy,
  pandas,
  pikepdf,
  pillow,
  proto-plus,
  protobuf,
  pyarrow,
  setuptools,
  tabulate,
  wheel,
  pythonRelaxDepsHook,
}:

buildPythonPackage rec {
  pname = "google-cloud-documentai-toolbox";
  version = "0.14.0a0";
  pyproject = true;

  src = fetchPypi {
    pname = "google_cloud_documentai_toolbox";
    inherit version;
    hash = "sha256-5lyp7gL2JDwNSErECjVGFlGhFjqvYCCtTnM13vKLChg=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    google-api-core
    google-auth
    google-cloud-bigquery
    google-cloud-documentai
    google-cloud-storage
    google-cloud-vision
    grpc-google-iam-v1
    immutabledict
    intervaltree
    jinja2
    numpy
    pandas
    pikepdf
    pillow
    proto-plus
    protobuf
    pyarrow
    tabulate
  ];

  nativeBuildInputs = [ pythonRelaxDepsHook ];

  pythonRelaxDeps = [
    "pyarrow"
    "pikepdf"
  ];
}
