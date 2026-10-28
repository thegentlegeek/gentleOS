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
  # Hyprland binary cache (upstream flake builds; avoids compiling the compositor locally)
  nix.settings.extra-substituters = [
    "https://cache.numtide.com"
    "https://hyprland.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];

}
