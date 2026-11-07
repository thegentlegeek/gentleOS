{ 
  lib,
  ...
}:

{
  # rtkit is optional but recommended
  #sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable= true;
    alsa.enable = true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = true;
    jack.enable = lib.mkDefault true;
    wireplumber.enable = true;
  };
}
