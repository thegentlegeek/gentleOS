{
  pkgs,
  ...
}:

{

    # For Intel CPUs
    services.thermald.enable = true;

    # For Intel CPUs
    hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt # Quick Sync
    ];
  };

}
