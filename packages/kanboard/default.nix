{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "kanboard";
  version = "1.2.46";

  src = fetchFromGitHub {
    owner = "kanboard";
    repo = "kanboard";
    rev = "v${version}";
    hash = "sha256-IYnlBNa4f+ZpOttQHlIZi8wsZYJuB/kWWLwhQK8vdQY=";
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
