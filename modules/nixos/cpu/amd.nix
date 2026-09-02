{
  ...
}:

{

  # AMD Phoenix APU (RDNA3 iGPU). Mesa ships radeonsi (OpenGL), RADV
  # (Vulkan) and radeonsi VA-API out of the box, so no extraPackages
  # are needed here.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

}
