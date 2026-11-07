# The gentleOS desktop, system side. Add a bootloader and a GPU module in your
# host. Pairs with modules/home/profiles/desktop.nix.
{ gentleInputs, ... }:

{
  imports = [
    gentleInputs.stylix.nixosModules.stylix
    ../base.nix
    ../boot/silent-boot.nix
    ../workstation
    ../window-managers/hyprland
    ../../shared/stylix.nix
  ];
}
