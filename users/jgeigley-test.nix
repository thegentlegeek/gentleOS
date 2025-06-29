{
  ...
}:

{

users.users.jgeigley-test = {
  isNormalUser = true;
  home = "/home/jgeigley-test";
  description = "Test User for Home Manager";
  extraGroups = [ "wheel" "networkmanager" ]; # Add groups as needed
  hashedPassword = "$6$MiybQYtTOKPQvleZ$/xp3DnMts7hC9FDIItysvIUChYeEE8QrxTjIIghl6xn6nfBpJ7sXeSQedAnTDM18E0cXf0yj1Fish9aS8XtuX1";
};

}
