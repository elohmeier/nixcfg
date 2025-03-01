{ fetchFromGitHub, maven }:

maven.buildMavenPackage {
  pname = "tabula-java";
  version = "1.0.5-unstable-2024-09-04";

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
}
