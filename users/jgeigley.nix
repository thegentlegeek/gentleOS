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

  users.mutableUsers = false;
  users.users.jgeigley = {
    isNormalUser = true;
    description = "Justin";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    hashedPassword = "$6$qCRuN6hyOTNlVKJA$QV70poZla/Fi3AO0KdCSBa3Fb9RrzNsUbqyys2j8yZDapn2fmRbCpZLFP8lRHRFZ/TUYXElSja2EZpakM6n8x1";
  };

}
