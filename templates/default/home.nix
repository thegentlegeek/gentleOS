{ pkgs, username, ... }:

{
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    # The same as system.stateVersion in host.nix, then leave it alone.
    stateVersion = "26.05";
    packages = [ ]; # your apps, for example [ pkgs.vlc ]
  };

  gentleOS = {
    themeFile = ./theme.json;
    # Where you keep this flake, for the theme picker.
    flakePath = "/home/${username}/nix-config";
    browser.personal = [ "firefox" ];
    # See the README's Options section for monitors, keyboard layout and more.
  };

  programs.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "default" ];

  # The theme picker commits your choice, which needs a git identity.
  programs.git = {
    enable = true;
    settings.user = {
      name = "Your Name";
      email = "you@example.com";
    };
  };
}
