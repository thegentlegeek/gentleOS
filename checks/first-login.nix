# A new user's first login on a fresh machine, in a VM: the greeter starts the
# desktop, Home Manager's first activation works after Hyprland has already
# written its own config, and then the shell, binds and lock screen work.
{ self, pkgs }:

let
  home = self.homeConfigurations.demo.activationPackage;
in
pkgs.testers.runNixOSTest {
  name = "gentleos-first-login";
  skipTypeCheck = true;
  skipLint = true;
  node.pkgsReadOnly = false;
  node.specialArgs.gentleInputs = self.inputs;

  nodes.machine = { lib, ... }: {
    imports = [ ../hosts/demo ];
    boot.loader.systemd-boot.enable = lib.mkForce false;
    users.users.demo.initialPassword = "demo";
    system.extraDependencies = [ home ];
    virtualisation = {
      memorySize = 3072;
      cores = 4;
      diskSize = 4096;
      qemu.options = [ "-vga none" "-device virtio-gpu-pci" ];
    };
  };

  testScript = ''
    import time

    # The test framework exports DISPLAY, which isn't there for a real user.
    def demo(cmd):
        return f"su - demo -c 'unset DISPLAY; export XDG_RUNTIME_DIR=/run/user/$(id -u demo); {cmd}'"

    def hyprctl(args):
        return demo(f"for s in $XDG_RUNTIME_DIR/hypr/*; do HYPRLAND_INSTANCE_SIGNATURE=$(basename $s) /run/current-system/sw/bin/hyprctl {args}; done")

    def login():
        time.sleep(25)  # the greeter takes a while with software rendering
        machine.send_chars("demo\n")
        time.sleep(4)
        machine.send_chars("demo\n")
        machine.wait_until_succeeds("pgrep -u demo Hyprland", timeout=120)

    machine.wait_for_unit("greetd.service", timeout=400)

    with subtest("the greeter starts the desktop, not a bare shell"):
        machine.succeed("grep -q 'Hyprland (quiet)' /var/lib/regreet/state.toml")
        login()
        machine.wait_until_succeeds("test -f /home/demo/.config/hypr/hyprland.lua", timeout=60)

    with subtest("Home Manager's first activation keeps Hyprland's generated config"):
        machine.succeed(demo("${home}/activate"), timeout=300)
        machine.succeed("test -L /home/demo/.config/hypr/hyprland.lua")
        machine.succeed("test -f /home/demo/.config/hypr/hyprland.lua.pre-gentleos")

    with subtest("the greeter can still record the user's choice"):
        machine.succeed("test \"$(stat -c '%U %a' /var/lib/regreet/state.toml)\" = 'greeter 644'")

    # systemd refuses the stop while activation's services are still starting.
    machine.wait_until_succeeds(demo("/run/current-system/sw/bin/uwsm stop"), timeout=60)
    machine.execute("loginctl terminate-user demo")
    machine.wait_until_succeeds("! pgrep -u demo Hyprland", timeout=60)
    login()

    with subtest("the desktop comes up with a valid config"):
        machine.wait_until_succeeds(demo("systemctl --user is-active quickshell hypridle"), timeout=120)
        machine.wait_until_succeeds(demo("journalctl --user -u quickshell | grep -q \"Configuration Loaded\""), timeout=60)
        errors = machine.succeed(hyprctl("configerrors")).strip()
        assert errors == "", f"config errors: {errors}"
        assert "Virtual-1" in machine.succeed(hyprctl("monitors"))

    with subtest("apps that aren't set have no binds"):
        binds = machine.succeed(hyprctl("binds"))
        for missing in ["Apps: Editor", "Apps: Music", "Apps: Browser"]:
            assert missing not in binds, f"{missing} is bound"
        assert "Apps: Terminal" in binds

    # Published screenshots rely on this, and nothing in this repo calls it.
    with subtest("the shell accepts its redact mode"):
        machine.succeed(demo("WAYLAND_DISPLAY=wayland-1 quickshell ipc -c gentle call shell setRedact true"))
        machine.succeed(demo("WAYLAND_DISPLAY=wayland-1 quickshell ipc -c gentle call shell setRedact false"))

    with subtest("the terminal bind works"):
        machine.send_key("meta_l-c")
        machine.wait_until_succeeds(hyprctl("clients") + " | grep -q 'class: kitty'", timeout=60)

    with subtest("the theme picker opens as a floating window at its own size"):
        machine.send_key("meta_l-w")
        machine.wait_until_succeeds(hyprctl("-j clients") + " | jq -e 'any(.[]; .title == \"Theme Picker\" and .floating and .size == [860, 600])'", timeout=60)

    with subtest("the lock screen locks, and stays locked"):
        machine.send_key("meta_l-l")
        machine.wait_until_succeeds("pgrep -u demo hyprlock", timeout=30)
        time.sleep(5)
        machine.succeed("pgrep -u demo hyprlock")

    with subtest("without swap, the lid suspends instead of failing to hibernate"):
        machine.succeed("grep -q '^HandleLidSwitch=suspend$' /etc/systemd/logind.conf")
  '';
}
