{ 
  pkgs, 
  ... 
}:

{
  environment.systemPackages = with pkgs; [
    (retroarch.override {
      cores = with libretro; [
        mupen64plus
        mgba
        mesen
        bsnes-hd
      ];
    })
      emulationstation
  ];
}
