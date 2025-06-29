{
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Define the users for this machine using Home Manager
  home-manager.users.justin = import ../../home/users/justin {
    inherit pkgs lib inputs;  # Pass necessary arguments to the user config
  };
}
