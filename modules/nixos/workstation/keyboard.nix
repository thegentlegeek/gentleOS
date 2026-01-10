{
  pkgs, 
  ... 
}:

{
  # Enable VIA and add the package to udev.
  environment.systemPackages = with pkgs; [
     via
     qmk
     qmk-udev-rules
  ];
  services.udev.packages = [ pkgs.via ];

  # Enable QMK
  hardware.keyboard.qmk.enable = true;

}
