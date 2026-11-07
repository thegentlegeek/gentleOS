# Flake checks: run with `nix flake check`, or one at a time with
# `nix build .#checks.x86_64-linux.<name>`.
{ self, pkgs }:

let
  hm = self.homeConfigurations.demo.config;
  customized = import ./customized.nix;
  customizedHm = (self.homeConfigurations.demo.extendModules {
    modules = [ customized.style customized.home ];
  }).config;
  # Same package programs.hyprland deploys (modules/nixos/window-managers/hyprland),
  # taken from the flake input directly: reading it via nixosConfigurations would
  # evaluate the whole NixOS system just for one store path. Revisit if the
  # NixOS module ever overrides/patches the package.
  hyprland = self.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  verifyHyprland = config: host: pkgs.runCommand "hyprland-verify-config-${host}" { } ''
    export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
    export GENTLEOS_HOST=${host}
    ${hyprland}/bin/Hyprland --verify-config \
      -c ${config.xdg.configFile."hypr/hyprland.lua".source} > log 2>&1 || true
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
  verifyQuickshell = config: pkgs.runCommand "quickshell-verify-config" { } ''
    export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
    export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
    echo "output HEADLESS-1 resolution 1920x1080" > sway.conf
    # Unwrapped: the wrapper starts sway under dbus-run-session.
    ${pkgs.sway-unwrapped}/bin/sway -c sway.conf > sway.log 2>&1 &
    for _ in $(seq 100); do [ -S $XDG_RUNTIME_DIR/wayland-1 ] && break; sleep 0.1; done
    # The shell, then the theme picker, which runs as its own process.
    config=${config.xdg.configFile."quickshell/gentle".source}
    for entry in $config $config/theme-picker.qml; do
      WAYLAND_DISPLAY=wayland-1 timeout 10 ${config.programs.quickshell.package}/bin/quickshell \
        -p $entry > log 2>&1 || true
      sed -i 's/\x1b\[[0-9;]*m//g' log
      if ! grep -q "Configuration Loaded" log \
          || grep -qE 'Failed to load|\.qml(\.json)?(\[[0-9]+:-?[0-9]+\]|:[0-9]+)' log; then
        echo "Quickshell config $entry failed to load cleanly:" >&2
        cat log >&2
        echo "sway:" >&2
        cat sway.log >&2
        exit 1
      fi
    done
    kill %1 || true
    touch $out
  '';

  # Evaluates only, so it doesn't build a whole system.
  evaluateWith = module:
    let
      system = self.nixosConfigurations.demo.extendModules { modules = [ module ]; };
    in
    pkgs.writeText "evaluated" (builtins.unsafeDiscardStringContext system.config.system.build.toplevel.drvPath);
in
{
  # Parse the generated hyprland.lua with the deployed Hyprland. Catches unknown
  # options/fields, bad dispatchers and Lua errors at build time instead of at
  # login. --verify-config exits 0 even on errors, so judge it by its output.
  # GENTLEOS_HOST exercises a host's monitor rules (no /etc/hostname in the sandbox).
  hyprland-config = verifyHyprland hm "demo";

  # The hardware modules evaluate on a real system. No Intel machine tests this.
  hardware-amd = evaluateWith ../modules/nixos/hardware/amd.nix;
  hardware-intel = evaluateWith ../modules/nixos/hardware/intel.nix;

  first-login = import ./first-login.nix { inherit self pkgs; };

  # `nix flake init`'s template evaluates against this flake, as someone's own
  # flake would. Evaluates only, like the hardware checks.
  template =
    let
      template = (import ../templates/default/flake.nix).outputs { gentleOS = self; };
    in
    pkgs.writeText "evaluated-template" (builtins.unsafeDiscardStringContext (
      template.nixosConfigurations.my-computer.config.system.build.toplevel.drvPath
      + template.homeConfigurations.me.activationPackage.drvPath
    ));

  quickshell-config = verifyQuickshell hm;

  # Everything customized.nix changes, set the plain way, still evaluates and loads.
  customized-hyprland = verifyHyprland customizedHm "demo";
  customized-quickshell = verifyQuickshell customizedHm;
  customized-system = evaluateWith {
    imports = [ customized.style customized.system ];
  };
}
