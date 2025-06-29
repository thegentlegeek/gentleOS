{ config, lib, pkgs, ... }:

{

  services.minecraft-server = {
    enable = true;
    eula = true; # set to true if you agree to Mojang's EULA: https://account.mojang.com/documents/minecraft_eula
    declarative = true;

  # see here for more info: https://minecraft.gamepedia.com/Server.properties#server.properties
  serverProperties = {
    server-port = 25565;
    openFirewall = true;
    gamemode = "survival";
    motd = "Geigley Minecraft Server!";
    max-players = 4;
    enable-rcon = true;
    # This password can be used to administer your minecraft server.
    # Exact details as to how will be explained later. If you want
    # you can replace this with another password.
    "rcon.password" = "PreciousMoments42";
    level-seed = "10292992";
  };
};

# enable closed source packages such as the minecraft server
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    ferium
  ];
}
