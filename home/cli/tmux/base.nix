{
  ascii ? false,
}:
{ lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    escapeTime = 10;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    reverseSplit = true;

    extraConfig = ''
      set-option -g focus-events on
      set-option -g allow-passthrough on
      set-option -sa terminal-features ',xterm-256color:RGB'
    '';

    plugins = with pkgs; [
      tmuxPlugins.cpu
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = "set -g @resurrect-strategy-nvim 'session'";
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
      {
        plugin = tmuxPlugins.catppuccin.overrideAttrs (_: {
          version = "2.1.0";
          src = fetchFromGitHub {
            owner = "catppuccin";
            repo = "tmux";
            rev = "refs/tags/v2.1.0";
            hash = "sha256-kWixGC3CJiFj+YXqHRMbeShC/Tl+1phhupYAIo9bivE=";
          };
        });
        extraConfig =
          ''
            set -g @catppuccin_flavor 'mocha'
          ''
          + lib.optionalString ascii ''
            set -g @catppuccin_icon_window_last ">"
            set -g @catppuccin_icon_window_current "*"
            set -g @catppuccin_icon_window_zoom "Z"
            set -g @catppuccin_icon_window_mark "M"
            set -g @catppuccin_icon_window_silent "S"
            set -g @catppuccin_icon_window_activity "A"
            set -g @catppuccin_icon_window_bell "B"

            set -g @catppuccin_status_left_separator "null"
            set -g @catppuccin_application_icon "null"
            set -g @catppuccin_session_icon "null"
          '';
      }
      {
        plugin = tmuxPlugins.yank;
        extraConfig = ''
          set -g @yank_selection 'clipboard'
          set -g @yank_selection_mouse 'clipboard'
        '';
      }
      {
        plugin = tmuxPlugins.tilish;
        extraConfig = ''
          set -g @tilish-default 'main-vertical'
        '';
      }
    ];
  };
}
