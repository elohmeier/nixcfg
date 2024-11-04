{
  fetchFromGitHub,
  jdk_headless,
  jre_minimal,
  lib,
  makeWrapper,
  maven,
  stdenvNoCC,
}:

let
  pname = "tabula-java";
  version = "1.0.5-unstable-2024-09-04";

  mvnPkg = maven.buildMavenPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "tabulapdf";
      repo = "tabula-java";
      rev = "5d91f1d733c4895d31854a641c152220f8c5f341";
      hash = "sha256-Vy9m8XjmoG1PiELK7MXnEgJYy3Dr3HvdgP4minc9ENU=";
    };

    mvnHash = "sha256-MZ9aIy2vrgoHa/Me0ju2uvoIFcJSVBzmRWnqGJlmULw=";
    mvnParameters = "compile assembly:single -Dmaven.test.skip=true";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib
      cp target/tabula-1.0.6-SNAPSHOT-jar-with-dependencies.jar $out/lib/tabula.jar

      runHook postInstall
    '';
  };

  jre = jre_minimal.override {
    jdk = jdk_headless;

    # tabula uses the java/awt/geom/Rectangle2D class
    # java.awt is included in java.desktop
    modules = [ "java.desktop" ];
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    makeWrapper ${jre}/bin/java tabula-java \
      --add-flags "-cp ${mvnPkg}/lib/tabula.jar" \
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
