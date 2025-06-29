{
  pkgs,
  ... }:
{
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  gamescopeSession.enable = true; # Compositor focused on gaming; login to the "steam" desktop session for a console-like experience
};

environment.systemPackages = [
    pkgs.protontricks
  ];

# Enable kernel modules for xBox controllers
#hardware.xpadneo.enable = true; # bluetooth
#hardware.xone.enable = true; # wired

security.wrappers.gamescope = {
  owner = "root";
  group = "root";
  source = "${pkgs.gamescope}/bin/gamescope";
  capabilities = "cap_sys_nice+pie";
  };

boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = true;
}
