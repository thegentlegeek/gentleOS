{
  ...
}:

{
  # Silent, graphical boot: no kernel/systemd chatter on the VTs, and a
  # Plymouth splash covering the whole kernel -> greeter window.
  #
  # This is bootloader-agnostic; hosts still pick systemd-boot or grub
  # separately. Note that each host must also load its KMS driver from the
  # initrd (boot.initrd.kernelModules = [ "amdgpu" | "i915" | ... ]),
  # otherwise the splash is black -- see the comment on
  # boot.plymouth.enable below.

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    # Kill the blinking VT cursor so nothing flashes when cage's framebuffer
    # is destroyed after login. The parameter is `global_cursor_default`;
    # `global_cursor_state` does not exist and is silently ignored.
    "vt.global_cursor_default=0"
  ];

  # Graphical boot splash for a polished boot-to-greeter transition.
  # Theming is handled automatically by Stylix (stylix.targets.plymouth).
  #
  # Plymouth >= 22 refuses to render on simpledrm / EFI-framebuffer devices
  # until DeviceTimeout (8s) has elapsed, so if the real KMS driver only
  # loads in stage 2 the splash never appears. Hosts importing this module
  # must put their GPU driver in boot.initrd.kernelModules.
  boot.plymouth.enable = true;
}
