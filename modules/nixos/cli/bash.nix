{ 
  ... 
}:

{
  programs.bash = {
    #blesh.enable = true; # enabled for starship right side prompt 
    # Interactive shells only: shellInit lands in /etc/profile *before* PATH is
    # set up, so every login shell (greeter, UWSM's env loader) printed
    # "starship: command not found". starship comes from Home Manager, so it
    # may also be absent (servers, other users).
    interactiveShellInit = ''
      if command -v starship >/dev/null 2>&1; then
        eval "$(starship init bash)"
      fi
    '';
  };
}