{
  pkgs,
  ...
}:

{

    # Intel CPU and integrated GPU. No host in this repo uses this module, so
    # it's untested.
    services.thermald.enable = true;

    # Plymouth needs real KMS in the initrd, as in amd.nix.
    boot.initrd.kernelModules = [ "i915" ];

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
