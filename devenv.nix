{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.pre-commit
  ];

  # https://devenv.sh/languages/
  languages.python.enable = true;

  # https://devenv.sh/processes/
  # https://devenv.sh/services/
  # https://devenv.sh/scripts/

  enterShell = ''
    git --version
  '';

  # https://devenv.sh/tasks/
  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
