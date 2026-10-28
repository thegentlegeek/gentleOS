# Flake checks: run with `nix flake check`, or one at a time with
# `nix build .#checks.x86_64-linux.<name>`.
{ self, pkgs }:

let
  hm = self.homeConfigurations.justin.config;
  # Same package programs.hyprland deploys (modules/nixos/window-managers/hyprland),
  # taken from the flake input directly: reading it via nixosConfigurations would
  # evaluate the whole NixOS system just for one store path. Revisit if the
  # NixOS module ever overrides/patches the package.
  hyprland = self.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
in
{
  # Parse the generated hyprland.lua with the deployed Hyprland. Catches unknown
  # options/fields, bad dispatchers and Lua errors at build time instead of at
  # login. --verify-config exits 0 even on errors, so judge it by its output.
  hyprland-config = pkgs.runCommand "hyprland-verify-config" { } ''
    export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
    # Exercise zbook's per-host monitor rules (no /etc/hostname in the sandbox).
    export GENTLEOS_HOST=zbook
    ${hyprland}/bin/Hyprland --verify-config \
      -c ${hm.xdg.configFile."hypr/hyprland.lua".source} > log 2>&1 || true
    if ! sed -n '/Config parsing result/,$p' log | grep -qx 'config ok'; then
      echo "hyprland.lua failed Hyprland --verify-config:" >&2
      sed -n '/Config parsing result/,$p' log >&2
      exit 1
    fi
    touch $out
  '';

  # Load the Quickshell shell in a headless sway (layer-shell needs a real
  # compositor; there's no D-Bus, PipeWire or Hyprland). Catches QML
  # syntax/type errors and broken bindings at build time instead of at login.
  # Missing services only produce non-QML warnings; anything pointing at a
  # .qml file and line is a real problem.
  quickshell-config = pkgs.runCommand "quickshell-verify-config" { } ''
    export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
    export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
    echo "output HEADLESS-1 resolution 1920x1080" > sway.conf
    # Unwrapped: the wrapper starts sway under dbus-run-session.
    ${pkgs.sway-unwrapped}/bin/sway -c sway.conf > sway.log 2>&1 &
    for _ in $(seq 100); do [ -S $XDG_RUNTIME_DIR/wayland-1 ] && break; sleep 0.1; done
    WAYLAND_DISPLAY=wayland-1 timeout 10 ${hm.programs.quickshell.package}/bin/quickshell \
      -p ${hm.xdg.configFile."quickshell/gentle".source} > log 2>&1 || true
    kill %1 || true
    sed -i 's/\x1b\[[0-9;]*m//g' log
    if ! grep -q "Configuration Loaded" log \
        || grep -qE 'Failed to load|\.qml(\.json)?(\[[0-9]+:-?[0-9]+\]|:[0-9]+)' log; then
      echo "Quickshell config failed to load cleanly:" >&2
      cat log >&2
      echo "sway:" >&2
      cat sway.log >&2
      exit 1
    fi
    touch $out
  '';
}
