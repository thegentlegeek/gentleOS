{
 pkgs,
 ...
}:

{
  stylix = {
    enable = true;
    polarity = "dark";
    image = ./wallpapers/everforest_wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/papercolor-dark.yaml";
    
    cursor = {
     package = pkgs.bibata-cursors;
     name = "Bibata-Modern-Ice";
     size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Sans Regular";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        applications = 10;
        desktop = 10;
        terminal = 10;
        popups = 10;
      };
    };
  };
}
