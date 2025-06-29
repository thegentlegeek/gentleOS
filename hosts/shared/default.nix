{
  ...
}:

{
imports =
    [
      ./CLI
    ];

  # Define aliases for all user shells. Can be overridden by individual shell alias definitions (i.e. programs.fish.shellAliases)
  environment.shellAliases = {
    l = "ls -lAh";
    ll = "ls -lAh --group-directories-first";
    ls = "ls --color=tty";
  };

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
