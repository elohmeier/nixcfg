{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "kanboard";
  version = "1.2.43";

  src = fetchFromGitHub {
    owner = "kanboard";
    repo = "kanboard";
    rev = "v${version}";
    hash = "sha256-pKWn6CZZu/iHnHLIY/6fMBDvAGXmBmsiFNdIyjSI98w=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/kanboard
    cp -rv . $out/share/kanboard
  '';

  meta = with lib; {
    description = "Kanban project management software";
    homepage = "https://kanboard.org";
    license = licenses.mit;
  };
}
