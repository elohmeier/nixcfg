{
  config,
  lib,
  pkgs,
  ...
}:

let
  vividGen =
    theme:
    builtins.readFile (
      pkgs.runCommand "vivid-${theme}" { } ''${pkgs.vivid}/bin/vivid generate "${theme}" >$out''
    );

  colorConfig =
    isDark:
    let
      # fishThemeName = if isDark then "Rosé Pine" else "Rosé Pine Dawn";
      fishThemeName = if isDark then "TokyoNight Night" else "TokyoNight Day";
      batThemeName = if isDark then "tokyonight_night" else "tokyonight_day";
      deltaThemeName = if isDark then "tokyonight_night" else "tokyonight_day";
      vividThemeName = if isDark then "tokyonight-night" else "ayu";
    in
    ''
      fish_config theme choose "${fishThemeName}"
      set -gx AICHAT_LIGHT_THEME "${if isDark then "0" else "1"}"
      set -gx DELTA_FEATURES "+${deltaThemeName}"
      set -gx LS_COLORS "${vividGen vividThemeName}"
    ''
    + lib.optionalString config.programs.bat.enable ''
      set -gx BAT_THEME "${batThemeName}"
    '';

  configureColors =
    if pkgs.stdenv.isDarwin then
      # read AppleInterfaceStyle from defaults
      # for Dark mode, the exit code is 0 and the content is "Dark"
      # for Light mode, the exit code is 1 and a error message is shown
      ''
        defaults read -g AppleInterfaceStyle &>/dev/null
        if test $status -eq 0
        ${colorConfig true}
        else
        ${colorConfig false}
        end
      ''
    else
      colorConfig true; # just use dark theme on other OS
in
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -U fish_greeting

      fzf_configure_bindings --directory=\ct

      if test -e /proc/sys/fs/binfmt_misc/WSLInterop
          # WSL may not have an icon font available
          set -gx hydro_symbol_prompt \$
      end

      ${configureColors}
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
      cg = "cd (git rev-parse --show-toplevel)";

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
        name = "hydro";
        src = hydro.src;
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

  # install themes from ./themes directory
  home.file = builtins.mapAttrs (name: _: {
    source = ./themes + "/${name}";
    target = ".config/fish/themes/${name}";
  }) (lib.filterAttrs (_: type: type == "regular") (builtins.readDir ./themes));
}
