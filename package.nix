# Derivations for Node applications (built using Nx)
{
  buildNpmPackage,
  # https://github.com/hercules-ci/gitignore.nix
  gitignore,
  lib,
  nodejs,
  pname,
}: let
  inherit (gitignore.lib) gitignoreSource;

  npmDepsHash = "sha256-92k971DZJp4Ve1BL1eXbMT3NL5rDD7LoIJX1PL/tKZg=";

  nodeFilter = path: type: let
    baseName = baseNameOf path;
  in
    # exclude files that are not part of the Nx build to improve caching
    !(
      # ignore */.github/, */.idea/, */.vscode/
      (type == "directory" && baseName == ".github")
      # ignore Markdown files
      || lib.hasSuffix ".md" baseName
      # ignore direnv
      || baseName == ".envrc"
      # ignore Nix
      || lib.hasSuffix ".nix" baseName
      || baseName == "flake.lock"
    );

  src = lib.cleanSourceWith {
    filter = nodeFilter;
    # `gitignoreSource` returns `cleanSourceWith` and can be composed
    src = gitignoreSource ./.;
    name = "${pname}-source";
  };

  configureNx = ''
    # add node_modules/.bin to PATH
    export PATH="$PWD/node_modules/.bin:$PATH"

    export NX_CACHE_DIRECTORY=$NIX_BUILD_TOP/nx-cache
    export NX_PROJECT_GRAPH_CACHE_DIRECTORY=$NIX_BUILD_TOP/nx-cache
  '';
in {
  check = buildNpmPackage {
    name = "${pname}-check";

    inherit npmDepsHash src;

    checkPhase = ''
      runHook preCheck

      echo "Configuring Nx"
      ${configureNx}

      nx run-many -t lint --all --output-style=static
      nx run-many -t test --all --output-style=static
      nx run-many -t build --all --output-style=static

      runHook postCheck
    '';

    doCheck = true;

    dontNpmBuild = true;

    # shim the install phase so check can run
    installPhase = ''
      runHook preInstall

      mkdir $out

      runHook postInstall
    '';
  };
}
