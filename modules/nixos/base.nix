{
  ...
}:

{
imports =
    [
      ./cli
    ];

  # Define aliases for all user shells. Can be overridden by individual shell alias definitions (i.e. programs.fish.shellAliases)
  environment.shellAliases = {
    l = "ls -lAh";
    ll = "ls -lAh --group-directories-first";
    ls = "ls --color=tty";
  };

  # Enable Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Numtide binary cache (prebuilt llm-agents.nix packages: opencode, claude-code, claude-desktop, ...)
  nix.settings.extra-substituters = [ "https://cache.numtide.com" ];
  nix.settings.extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

}
