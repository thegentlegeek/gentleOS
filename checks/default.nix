# Flake checks: run with `nix flake check`, or one at a time with
# `nix build .#checks.x86_64-linux.<name>`.
{ self, pkgs }:

let
  hm = self.homeConfigurations.justin.config;
  # The compositor actually deployed on zbook, so the check matches what runs.
  hyprland = self.nixosConfigurations.zbook.config.programs.hyprland.package;
in
{
  # Parse the generated hyprland.lua with the deployed Hyprland. Catches unknown
  # options/fields, bad dispatchers and Lua errors at build time instead of at
  # login. --verify-config exits 0 even on errors, so judge it by its output.
  hyprland-config = pkgs.runCommand "hyprland-verify-config" { } ''
    export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR
    ${hyprland}/bin/Hyprland --verify-config \
      -c ${hm.xdg.configFile."hypr/hyprland.lua".source} > log 2>&1 || true
    if ! sed -n '/Config parsing result/,$p' log | grep -qx 'config ok'; then
      echo "hyprland.lua failed Hyprland --verify-config:" >&2
      sed -n '/Config parsing result/,$p' log >&2
      exit 1
    fi
    touch $out
  '';
}
