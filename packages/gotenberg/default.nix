{ lib
, buildGoModule
, chromium
, exiftool
, fetchFromGitHub
, libreoffice
, makeWrapper
, pdftk
, qpdf
, unoconv
}:

buildGoModule rec {
  pname = "gotenberg";
  version = "8.5.0";

  src = fetchFromGitHub {
    owner = "gotenberg";
    repo = "gotenberg";
    rev = "refs/tags/v${version}";
    hash = "sha256-lOB2oC8xk945HlFbhiOyHrqkY+bu8+Kg2rOBj1ANtZo=";
  };

  vendorHash = "sha256-h/Bd40ZQckw1rpPBxhJYO91Voz3qI8OV2ORg9/z4Stw=";

  doCheck = false;

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/gotenberg/gotenberg/v8/cmd.Version=${version}"
  ];

  preFixup = ''
    wrapProgram $out/bin/gotenberg \
      --set CHROMIUM_BIN_PATH "${chromium}/bin/chromium" \
      --set EXIFTOOL_BIN_PATH "${exiftool}/bin/exiftool" \
      --set LIBREOFFICE_BIN_PATH "${libreoffice}/lib/libreoffice/program/soffice.bin" \
      --set PDFTK_BIN_PATH "${pdftk}/bin/pdftk" \
      --set QPDF_BIN_PATH "${qpdf}/bin/qpdf" \
      --set UNOCONVERTER_BIN_PATH "${unoconv}/bin/unoconv"
  '';

  meta = with lib; {
    description = "Converts numerous document formats into PDF files";
    homepage = "https://github.com/gotenberg/gotenberg";
    license = licenses.mit;
    maintainers = with maintainers; [ elohmeier ];
  };
}
