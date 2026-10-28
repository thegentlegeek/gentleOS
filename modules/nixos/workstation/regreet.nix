{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ReGreet greeter, hosted by cage inside greetd.
  # programs.regreet automatically enables greetd and sets the
  # default session to `cage -s -- regreet` run as the `greeter` user.
  # Theming (GTK + wallpaper) is handled automatically by Stylix.
  programs.regreet.enable = true;

  # Boot-time console silencing and the Plymouth splash itself live in
  # ../boot/silent-boot.nix.

  # plymouth-quit runs at multi-user.target, roughly a second before cage
  # has its first frame on screen. Without --retain-splash Plymouth blanks
  # the framebuffer on exit, which is a visible black flash between the
  # splash and the greeter; with it the last splash frame stays up until
  # cage modesets. ExecStart is reset with "" first because this is a
  # drop-in over the unit shipped by the plymouth package.
  systemd.services.plymouth-quit = lib.mkIf config.boot.plymouth.enable {
    serviceConfig.ExecStart = [
      ""
      "-${lib.getExe' config.boot.plymouth.package "plymouth"} quit --retain-splash"
    ];
  };

  # Keep cage/regreet log output off the greeter VT by sending it to the
  # journal instead (`journalctl -t greeter`); discarding it hid a greeter
  # crash-loop once. nixpkgs sets this with mkDefault, so a plain override
  # wins; cageArgs/package are reused so the command stays in sync with the
  # upstream module.
  services.greetd.settings.default_session.command =
    lib.getExe (pkgs.writeShellScriptBin "greeter-cage" ''
      exec ${config.systemd.package}/bin/systemd-cat -t greeter \
        ${pkgs.dbus}/bin/dbus-run-session \
        ${lib.getExe pkgs.cage} \
        ${lib.escapeShellArgs config.programs.regreet.cageArgs} -- \
        ${lib.getExe config.programs.regreet.package}
    '');
}
