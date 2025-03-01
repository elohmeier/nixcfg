{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "kanboard";
  version = "1.2.41";

  src = fetchFromGitHub {
    owner = "kanboard";
    repo = "kanboard";
    rev = "v${version}";
    hash = "sha256-USH9shG7tzsbljYTSE2Xvd1cdFjM7qs5UwTgfNrEiFo=";
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
