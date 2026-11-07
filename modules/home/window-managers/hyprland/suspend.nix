# `gentle-suspend`: sleep, then hibernate if this machine can. Without enough swap
# suspend-then-hibernate fails, and the machine wouldn't sleep at all.
{ pkgs }:

pkgs.writeShellApplication {
  name = "gentle-suspend";
  runtimeInputs = [ pkgs.systemd ];
  text = ''
    can=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
      org.freedesktop.login1.Manager CanSuspendThenHibernate 2>/dev/null) || can=""
    case $can in
      *yes* | *challenge*) exec systemctl suspend-then-hibernate ;;
      *) exec systemctl suspend ;;
    esac
  '';
}
