# The desktop with nothing added: no browser, editor or music app, so their binds
# don't exist. Used by the checks in checks/.
{
  ...
}:

{
  imports = [ ../../modules/home/profiles/desktop.nix ];

  gentleOS.monitors.demo = [ { output = "Virtual-1"; scale = 1; } ];

  home = {
    username = "demo";
    homeDirectory = "/home/demo";
    stateVersion = "26.05";
  };
}
