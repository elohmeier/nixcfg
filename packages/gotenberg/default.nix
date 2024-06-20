{ buildGoModule
, chromium
, exiftool
, fetchFromGitHub
, fontconfig
, lib
, libreoffice
, makeWrapper
, pdftk
, qpdf
, unoconv
}:

buildGoModule rec {
  pname = "gotenberg";
  version = "8.7.0";

  src = fetchFromGitHub {
    owner = "gotenberg";
    repo = "gotenberg";
    rev = "refs/tags/v${version}";
    hash = "sha256-hAcN1TdAkfppvHs1q2JSiUfi4uR2lpwiwfzE/47BIu8=";
  };

  vendorHash = "sha256-nOSUB2Dk2DRWI9cdzi1t2pVjUvzz+C4oDVnBE1HCVII=";

  # tests require files in /tests directory
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/gotenberg/gotenberg/v8/cmd.Version=${version}"
  ];

  nativeBuildInputs = [ makeWrapper ];

  FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  preFixup = ''
    wrapProgram $out/bin/gotenberg \
      --set-default CHROMIUM_BIN_PATH "${chromium}/bin/chromium" \
      --set-default EXIFTOOL_BIN_PATH "${exiftool}/bin/exiftool" \
      --set-default FONTCONFIG_FILE "${FONTCONFIG_FILE}" \
      --set-default LIBREOFFICE_BIN_PATH "${libreoffice}/lib/libreoffice/program/soffice.bin" \
      --set-default PDFTK_BIN_PATH "${pdftk}/bin/pdftk" \
      --set-default QPDF_BIN_PATH "${qpdf}/bin/qpdf" \
      --set-default UNOCONVERTER_BIN_PATH "${unoconv}/bin/unoconv"
  '';

  meta = with lib; {
    description = "Converts numerous document formats into PDF files";
    homepage = "https://github.com/gotenberg/gotenberg";
    license = licenses.mit;
    mainProgram = "gotenberg";
    maintainers = with maintainers; [ elohmeier ];
  };
}
