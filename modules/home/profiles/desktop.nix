# The gentleOS desktop, user side. Pairs with modules/nixos/profiles/desktop.nix.
{ gentleInputs, lib, ... }:

{
  imports = [
    gentleInputs.stylix.homeModules.stylix
    ../../shared/stylix.nix
    ../cli
    ../window-managers/hyprland
  ];

  # Qt via qtct + generated Kvantum theme. Not auto-enabled for standalone HM
  # (home-manager#6565 only affects non-NixOS hosts); matches the NixOS target's qt5ct.
  stylix.targets.qt.enable = true;

  # Fontconfig doesn't look in the Home Manager profile without this, so a font
  # set only on this side, or gentleOS.shellFont, would never be found.
  fonts.fontconfig.enable = lib.mkDefault true;

  # Wayland session variables for Electron apps
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.home-manager.enable = true;
}
