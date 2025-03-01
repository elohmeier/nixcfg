{ fetchFromGitHub, maven }:

maven.buildMavenPackage {
  pname = "tabula-java";
  version = "1.0.5-unstable-2025-02-23";

  src = fetchFromGitHub {
    owner = "tabulapdf";
    repo = "tabula-java";
    rev = "971ae765e84f09ed83f5808b66f764590146e923";
    hash = "sha256-vJHydFQ9AdGTL1NpexGJTvx3w9+1eqkGbko7fredyJQ=";
  };

  mvnHash = "sha256-H9XkMImCjluHU+q+r0Y0ZyAnE1DEGr7iQMThKbEbhbU=";
  mvnParameters = "compile assembly:single -Dmaven.test.skip=true";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp target/tabula-1.0.6-SNAPSHOT-jar-with-dependencies.jar $out/lib/tabula.jar

    runHook postInstall
  '';
}
