_: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  xdg.configFile."direnv/lib/python_uv.sh".source = ./layouts/python_uv.sh;
}
