{
  pkgs,
  ...
}:

{
  # Enable SDDM Login
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "chili";
    };

  environment.systemPackages = with pkgs; [
    sddm-chili-theme
    libsForQt5.qt5.qtbase
    libsForQt5.qt5.qtquickcontrols
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
