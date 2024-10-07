{ pkgs, ... }:

{
  programs.bat = {
    enable = true;

    themes = {
      tokyonight_day = {
        inherit (pkgs.vimPlugins.tokyonight-nvim) src;
        file = "extras/sublime/tokyonight_day.tmTheme";
      };
      tokyonight_night = {
        inherit (pkgs.vimPlugins.tokyonight-nvim) src;
        file = "extras/sublime/tokyonight_night.tmTheme";
      };
    };
  };
}
