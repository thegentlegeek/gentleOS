{
  ...
}:

{
  boot.loader.systemd-boot = {
    enable = true;
    netbootxyz.enable = true;
    configurationLimit = 6;
    editor = false; # this disables the ability to gain root access by passing init=/bin/sh as a kernel parameter. Enable this if you have a specific use-case, otherwise it should remain disabled for security.
  };
}