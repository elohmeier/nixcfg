{ lib, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit =
      let
        # generate tide config into a file containing key-value pairs
        # example output:
        # tide_aws_bg_color normal
        # tide_aws_color yellow
        # ...
        tidecfg =
          let
            script = pkgs.writeText "tide-configure-fish.fish" ''
              set fish_function_path ${pkgs.fishPlugins.tide}/share/fish/vendor_functions.d $fish_function_path

              tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Few icons' --transient=No
            '';
          in
          pkgs.runCommandNoCC "tidecfg" { } ''
            HOME=$(mktemp -d)
            ${pkgs.fish}/bin/fish ${script}
            ${pkgs.fish}/bin/fish -c "set -U --long" > $out
          '';

        # cache vivid output in the store
        ls_colors_dark = pkgs.runCommandNoCC "ls_colors_dark" { } ''
          ${pkgs.vivid}/bin/vivid generate tokyonight-night > $out
        '';
        ls_colors_light = pkgs.runCommandNoCC "ls_colors_light" { } ''
          ${pkgs.vivid}/bin/vivid generate ayu > $out
        '';
      in
      ''
        set -U fish_greeting

        fzf_configure_bindings --directory=\ct

        # Check if tide is configured by checking one of the variables
        if not set -q tide_aws_bg_color
          # Load the tide configuration from the generated file
          echo "Loading tide configuration (only once)" >&2
          for line in (cat ${tidecfg})
            # tide only works with universal variables
            eval "set -U $line"
          end
        end

        set -l DARK_MODE 1
      ''
      + lib.optionalString pkgs.stdenv.isDarwin ''
        # read AppleInterfaceStyle from defaults
        # for Dark mode, the exit code is 0 and the content is "Dark"
        # for Light mode, the exit code is 1 and a error message is shown
        defaults read -g AppleInterfaceStyle &>/dev/null
        if test $status -eq 0
          set -l DARK_MODE 1
        else
          set -l DARK_MODE 0
        end
      ''
      + ''
        if [ $DARK_MODE -eq 1 ]
          # fish_config theme choose "Rosé Pine"
          fish_config theme choose "TokyoNight Night"
          set -gx LS_COLORS (cat ${ls_colors_dark})
          set -gx AICHAT_LIGHT_THEME 0
        else
          # fish_config theme choose "Rosé Pine Dawn"
          fish_config theme choose "TokyoNight Day"
          set -gx LS_COLORS (cat ${ls_colors_light})
          set -gx AICHAT_LIGHT_THEME 1
        end
      '';

    shellAbbrs = {
      "cd.." = "cd ..";

      # git
      "ga." = "git add .";
      ga = "git add";
      gb = "git branch";
      gc = "git commit";
      gcf = "git commit --fixup";
      gco = "git checkout";
      gcp = "git cherry-pick";
      gd = "git diff";
      gf = "git fetch";
      gl = "git log";
      gp = "git pull";
      gpp = "git push";
      gst = "git status";

      kc = "kubectl";

      # nix
      nb = "nix build";
      nf = "nix flake";
      nfl = "nix flake lock";
      nfu = "nix flake update";
      nr = "nix run";
    };

    shellAliases = {
      gg = "lazygit";
      lgg = "lazygit";

      # eza
      l = "eza -al";
      la = "eza -al";
      lg = "eza -al --git";
      ll = "eza -l";
      ls = "eza";
      tree = "eza --tree";
    };

    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf";
        inherit (fzf-fish) src;
      }
      {
        name = "tide";
        src = tide.src;
      }
    ];
  };

  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    eza
    fd
    (fzf.overrideAttrs (old: {
      postInstall =
        old.postInstall
        + ''
          rm -r $out/share/fish
          rm $out/share/fzf/*.fish
        '';
    }))
  ];

  home.file =
    let
      rose-pine-fish = pkgs.fetchFromGitHub {
        owner = "rose-pine";
        repo = "fish";
        rev = "38aab5baabefea1bc7e560ba3fbdb53cb91a6186";
        hash = "sha256-bSGGksL/jBNqVV0cHZ8eJ03/8j3HfD9HXpDa8G/Cmi8=";
      };
    in
    {
      ".config/fish/themes/Rosé Pine.theme".source = "${rose-pine-fish}/themes/Rosé Pine.theme";
      ".config/fish/themes/Rosé Pine Dawn.theme".source = "${rose-pine-fish}/themes/Rosé Pine Dawn.theme";

      ".config/fish/themes/TokyoNight Night.theme".text = ''
        # Upstream: https://github.com/folke/tokyonight.nvim/blob/main/extras/fish/tokyonight_night.fish
        # Syntax Highlighting Colors
        fish_color_normal c0caf5
        fish_color_command 7dcfff
        fish_color_keyword bb9af7
        fish_color_quote e0af68
        fish_color_redirection c0caf5
        fish_color_end ff9e64
        fish_color_error f7768e
        fish_color_param 9d7cd8
        fish_color_comment 565f89
        fish_color_selection --background=283457
        fish_color_search_match --background=283457
        fish_color_operator 9ece6a
        fish_color_escape bb9af7
        fish_color_autosuggestion 565f89

        # Completion Pager Colors
        fish_pager_color_progress 565f89
        fish_pager_color_prefix 7dcfff
        fish_pager_color_completion c0caf5
        fish_pager_color_description 565f89
        fish_pager_color_selected_background --background=283457
      '';

      ".config/fish/themes/TokyoNight Day.theme".text = ''
        # Upstream: https://github.com/folke/tokyonight.nvim/blob/main/extras/fish/tokyonight_day.fish
        # Syntax Highlighting Colors
        fish_color_normal 3760bf
        fish_color_command 007197
        fish_color_keyword 9854f1
        fish_color_quote 8c6c3e
        fish_color_redirection 3760bf
        fish_color_end f52a65
        fish_color_error f52a65
        fish_color_param 7847bd
        fish_color_comment 848cb5
        fish_color_selection --background=b7c1e3
        fish_color_search_match --background=b7c1e3
        fish_color_operator 587539
        fish_color_escape 9854f1
        fish_color_autosuggestion 848cb5

        # Completion Pager Colors
        fish_pager_color_progress 848cb5
        fish_pager_color_prefix 007197
        fish_pager_color_completion 3760bf
        fish_pager_color_description 848cb5
        fish_pager_color_selected_background --background=b7c1e3
      '';
    };
}
