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

    # Make a newly connected output (a Bluetooth speaker, a USB headset) the
    # default, so the volume keys and the shell follow it. Otherwise
    # WirePlumber keeps the saved default whenever that device is still around.
    # When the new device goes away, the previous default comes back. HDMI
    # (monitors) and virtual sinks don't take over.
    extraConfig.pipewire-pulse."91-switch-on-connect" = {
      "pulse.cmd" = [
        { cmd = "load-module"; args = "module-switch-on-connect"; flags = [ "nofail" ]; }
      ];
    };
  };
}
