{ opencodePackage, opencodeDesktopPackage }:

{
  pkgs,
  lib,
  ...
}:

# OpenCode 2. Home Manager's programs.opencode (and Stylix's opencode target)
# still generate OpenCode 1 config/theme files, so this module installs the
# packages directly instead.
let
  # llm-agents installs the v2 CLI as `opencode2` so it can coexist with v1.
  # Expose it as `opencode` too, and default the CLI theme to `system`, which
  # derives colors from the (Stylix-themed) terminal palette. The inline config
  # is merged over ~/.config/opencode/cli.json, so that file stays writable.
  cliConfig = builtins.toJSON {
    theme.name = "system";
  };

  opencode = pkgs.symlinkJoin {
    name = "opencode-${opencodePackage.version}";
    paths = [ opencodePackage ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      makeWrapper $out/bin/opencode2 $out/bin/opencode \
        --set-default OPENCODE_CLI_CONFIG_CONTENT ${lib.escapeShellArg cliConfig}
    '';
    meta.mainProgram = "opencode";
  };
in
{
  home.packages = [
    opencode
    opencodeDesktopPackage
  ];

  # Global config. Nix manages updates, so disable OpenCode's own update checks.
  xdg.configFile."opencode/opencode.jsonc".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    update = "disable";
  };
}
