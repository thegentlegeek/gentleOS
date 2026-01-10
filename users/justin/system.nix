{
  ...
}:

{
  imports = [
    ../../modules/nixos/browsers/chromium.nix
    ../../modules/nixos/gaming
  ];

  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = true;
  users.users.justin = {
    isNormalUser = true;
    description = "Justin";
    extraGroups = [ "networkmanager" "wheel" "input" ];
  };
}
