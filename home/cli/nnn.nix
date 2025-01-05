{ pkgs, ... }:
{
  programs.nnn = {
    enable = true;
    package = pkgs.nnn.override {
      extraMakeFlags = [ "O_GITSTATUS=1" ];
      withNerdIcons = true;
    };
    plugins = {
      src = "${pkgs.nnn.src}/plugins";
      mappings = {
        f = "fzcd";
        z = "autojump";
      };
    };
  };
}
