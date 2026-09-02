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

  # Hide kernel/systemd console output and the blinking cursor on VTs so
  # nothing flashes when cage's framebuffer is destroyed after login.
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "vt.global_cursor_state=0"
  ];

  # Keep cage/regreet log output off the greeter VT. nixpkgs sets this with
  # mkDefault, so a plain override wins; cageArgs/package are reused so the
  # command stays in sync with the upstream module.
  services.greetd.settings.default_session.command =
    lib.getExe (pkgs.writeShellScriptBin "greeter-cage" ''
      exec ${pkgs.dbus}/bin/dbus-run-session \
        ${lib.getExe pkgs.cage} \
        ${lib.escapeShellArgs config.programs.regreet.cageArgs} -- \
        ${lib.getExe config.programs.regreet.package} >/dev/null 2>&1
    '');
}
