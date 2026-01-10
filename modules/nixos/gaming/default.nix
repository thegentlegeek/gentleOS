{
... 
}:

{
    imports =
    [
      ./steam.nix
      ./minecraft.nix
      #./emulation.nix # doesn't work. Relies on "freeimage" pkg which is marked insecure
    ];
}