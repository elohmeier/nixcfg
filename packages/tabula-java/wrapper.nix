{
  jdk_headless,
  jre_minimal,
  lib,
  makeWrapper,
  stdenvNoCC,

  tabula-java-jar,
}:

let
  jre = jre_minimal.override {
    jdk = jdk_headless;

    # tabula uses the java/awt/geom/Rectangle2D class
    # java.awt is included in java.desktop
    modules = [ "java.desktop" ];
  };
in
stdenvNoCC.mkDerivation {
  inherit (tabula-java-jar) pname version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    makeWrapper ${jre}/bin/java tabula-java \
      --add-flags "-cp ${tabula-java-jar}/lib/tabula.jar" \
      --add-flags "technology.tabula.CommandLineApp"

    # run a quick test to see if all required jre classes can be imported
    ./tabula-java --help >/dev/null

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp tabula-java $out/bin/tabula-java

    runHook postInstall
  '';

  meta = with lib; {
    description = "Library for extracting tables from PDF files";
    longDescription = ''
      tabula-java is the table extraction engine that powers
      Tabula. You can use tabula-java as a command-line tool to
      programmatically extract tables from PDFs.
    '';
    homepage = "https://tabula.technology/";
    license = licenses.mit;
    maintainers = [ maintainers.jakewaksbaum ];
    platforms = platforms.all;
    mainProgram = "tabula-java";
  };
}
