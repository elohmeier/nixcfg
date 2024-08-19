{ lib, maven, fetchFromGitHub, makeWrapper, jre, }:

maven.buildMavenPackage {
  pname = "tabula-java";
  version = "1.0.5-unstable-2024-08-12";

  src = fetchFromGitHub {
    owner = "tabulapdf";
    repo = "tabula-java";
    rev = "818c9a2f5a5ea8dc72d3efa775f192381e84b8c1";
    hash = "sha256-3/X1TLKcfdse3seqCe0GNtj9We5gjJ4KZztmikL0X6U=";
  };

  mvnHash = "sha256-lcr4Erq2AFLYHYIv6nl5xS2metKIPYN3+bINbnSS9+g=";
  mvnParameters = "compile assembly:single -Dmaven.test.skip=true";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}
    cp target/tabula-1.0.6-SNAPSHOT-jar-with-dependencies.jar $out/lib/tabula.jar

    makeWrapper ${jre}/bin/java $out/bin/tabula-java \
      --add-flags "-cp $out/lib/tabula.jar" \
      --add-flags "technology.tabula.CommandLineApp"

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
