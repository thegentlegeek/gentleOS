{
... 
}:

{

  imports =
    [
      ./shared/browsers/chromium.nix
      ./shared/gaming
    ];

  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = true;
  users.users.justin = {
    isNormalUser = true;
    description = "Justin";
    extraGroups = [ "networkmanager" "wheel" "input" ];
  };

}
