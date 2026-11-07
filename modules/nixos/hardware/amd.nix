{
  ...
}:

{

  # AMD CPU and integrated or discrete GPU. Mesa ships radeonsi (OpenGL), RADV
  # (Vulkan) and radeonsi VA-API out of the box, so no extraPackages are needed.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Plymouth (boot/silent-boot.nix) ignores simpledrm/EFI-framebuffer devices
  # until its 8s DeviceTimeout expires, so the GPU driver has to be up before
  # stage 2 or the splash is black for the entire boot. Costs ~34MiB of amdgpu
  # firmware in the initrd (see boot.loader.systemd-boot.configurationLimit vs.
  # the size of the ESP).
  boot.initrd.kernelModules = [ "amdgpu" ];

}
