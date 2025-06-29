{ 
  ... 
}:

{
  programs.bash = {
    #blesh.enable = true; # enabled for starship right side prompt 
    shellInit = ''
      eval "$(starship init bash)"
    '';
  };
}