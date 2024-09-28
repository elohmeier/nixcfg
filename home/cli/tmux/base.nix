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

    shortcut = "a";

    extraConfig = ''
      set-option -g focus-events on
      set-option -sa terminal-features ',xterm-256color:RGB'

      # bind alt-1..9 to switch windows (iterm2 like)
      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9
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
          version = "0.2.0";
          src = fetchFromGitHub {
            owner = "catppuccin";
            repo = "tmux";
            rev = "refs/tags/v0.2.0";
            hash = "sha256-XikYIryhixheyI3gmcJ+AInDBzCq2TXllfarnrRifEo=";
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
    ];
  };
}
