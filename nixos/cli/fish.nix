{ ... }:

{
  programs.fish = {
    enable = true;
    useBabelfish = true;
    interactiveShellInit = ''
      set -U fish_greeting
    '';
    shellAbbrs = {
      jc = "journalctl";
      sc = "systemctl";
      scc = "systemctl status";
      sce = "systemctl stop";
      scr = "systemctl restart";
      scs = "systemctl start";
    };
    shellAliases = {
      l = "eza -al";
      la = "eza -al";
      lg = "eza -al --git";
      ll = "eza -l";
      ls = "eza";
      tree = "eza --tree";
    };
  };
}
