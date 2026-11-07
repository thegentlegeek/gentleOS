{
  lib,
  ...
}:

{
imports =
    [
      ./cli
    ];

  # Define aliases for all user shells. Can be overridden by individual shell alias definitions (i.e. programs.fish.shellAliases)
  # nixpkgs sets these with mkDefault, so these need a stronger default of their own.
  environment.shellAliases = lib.mapAttrs (_: lib.mkOverride 900) {
    l = "ls -lAh";
    ll = "ls -lAh --group-directories-first";
    ls = "ls --color=tty";
  };

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
