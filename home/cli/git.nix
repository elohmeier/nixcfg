{ lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    package = pkgs.git;

    userName = lib.mkDefault "Enno Richter";
    userEmail = lib.mkDefault "enno@nerdworks.de";

    ignores = [
      "*.sqlite3-journal"
      "*.swp"
      "*~"
      ".DS_Store"
      ".aider*"
      ".direnv/"
      ".ipynb_checkpoints/"
    ];

    extraConfig = {
      init.defaultBranch = "master";
      pull = {
        rebase = false;
        ff = "only";
      };
    };

    delta = {
      enable = true;
      options = {
        whitespace-error-style = "22 reverse";

        # https://github.com/folke/tokyonight.nvim/blob/main/extras/delta/tokyonight_night.gitconfig
        minus-style = lib.mkDefault "syntax \"#37222c\"";
        minus-non-emph-style = lib.mkDefault "syntax \"#37222c\"";
        minus-emph-style = lib.mkDefault "syntax \"#713137\"";
        minus-empty-line-marker-style = lib.mkDefault "syntax \"#37222c\"";
        line-numbers-minus-style = lib.mkDefault "#b2555b";
        plus-style = lib.mkDefault "syntax \"#20303b\"";
        plus-non-emph-style = lib.mkDefault "syntax \"#20303b\"";
        plus-emph-style = lib.mkDefault "syntax \"#2c5a66\"";
        plus-empty-line-marker-style = lib.mkDefault "syntax \"#20303b\"";
        line-numbers-plus-style = lib.mkDefault "#266d6a";
        line-numbers-zero-style = lib.mkDefault "#3b4261";

        # # https://github.com/folke/tokyonight.nvim/blob/main/extras/delta/tokyonight_day.gitconfig
        # minus-style = lib.mkDefault "syntax \"#dfccd4\"";
        # minus-non-emph-style = lib.mkDefault "syntax \"#dfccd4\"";
        # minus-emph-style = lib.mkDefault "syntax \"#d99ea2\"";
        # minus-empty-line-marker-style = lib.mkDefault "syntax \"#dfccd4\"";
        # line-numbers-minus-style = lib.mkDefault "#c25d64";
        # plus-style = lib.mkDefault "syntax \"#aecde6\"";
        # plus-non-emph-style = lib.mkDefault "syntax \"#aecde6\"";
        # plus-emph-style = lib.mkDefault "syntax \"#57a7bc\"";
        # plus-empty-line-marker-style = lib.mkDefault "syntax \"#aecde6\"";
        # line-numbers-plus-style = lib.mkDefault "#399a96";
        # line-numbers-zero-style = lib.mkDefault "#a8aecb";
      };
    };

    lfs.enable = true;
  };

  home.packages = [ pkgs.gitAndTools.git-absorb ];
}
