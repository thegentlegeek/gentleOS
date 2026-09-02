{
  ...
}:

{
  # ReGreet greeter, hosted by cage inside greetd.
  # programs.regreet automatically enables greetd and sets the
  # default session to `cage -s -- regreet` run as the `greeter` user.
  # Theming (GTK + wallpaper) is handled automatically by Stylix.
  programs.regreet.enable = true;
}
