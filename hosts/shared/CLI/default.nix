{ 
  ... 
}:

{
  imports =
    [
      ./bash.nix
      ./bitwarden.nix
      ../../../modules/CLI/starship.nix
      ./yazi.nix
      ./lazygit.nix
      ./fzf.nix
      ./neovim.nix
      ./tmux.nix
    ];
}
