# first-login with every setting in customized.nix, checking they take effect.
# Not in `nix flake check`, to save a second VM on every run. Run it after changing
# what these settings touch, and look at the screenshots in ./result:
#   nix build --impure --expr 'let f = builtins.getFlake (toString ./.);
#     in import ./checks/customized-vm.nix { self = f; pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; }'
{ self, pkgs }:

let
  customized = import ./customized.nix;
  homeConfig = self.homeConfigurations.demo.extendModules {
    modules = [ customized.style customized.home ];
  };
  hm = homeConfig.config;
in
import ./first-login.nix {
  inherit self pkgs homeConfig;
  name = "gentleos-customized";
  machineModule = {
    imports = [ customized.style customized.system ];
  };
  extraScript = ''
    def check_option(name, expected):
        value = machine.succeed(hyprctl(f"getoption {name}"))
        assert expected in value, f"{name}: {value}"

    machine.screenshot("picker-and-bar")

    with subtest("Hyprland settings override gentleOS's"):
        check_option("decoration:rounding", "3")
        check_option("general:gaps_out", "20")
        check_option("decoration:active_opacity", "1")
        check_option("input:touchpad:natural_scroll", "false")
        check_option("input:kb_options", "caps:escape")
        check_option("input:kb_variant", "intl")

    with subtest("your binds run, one on used keys replaces that bind, and the cheat sheet follows"):
        machine.send_key("meta_l-g")
        machine.wait_until_succeeds("test -f /home/demo/new-bind", timeout=30)
        machine.send_key("meta_l-t")
        machine.wait_until_succeeds("test -f /home/demo/rebound", timeout=30)
        machine.fail("pgrep -u demo slurp")
        binds = machine.succeed(demo("cat $XDG_RUNTIME_DIR/gentle-binds.json"))
        for present in ["Apps: Mine", "Tools: Rebound"]:
            assert present in binds, f"{present} isn't in the cheat sheet"
        assert "Screenshots: Region to clipboard" not in binds

    with subtest("the terminal and file manager binds run your commands"):
        machine.wait_until_succeeds("test -f /home/demo/custom-terminal", timeout=30)
        machine.send_key("meta_l-f")
        machine.wait_until_succeeds("test -f /home/demo/custom-files", timeout=30)

    with subtest("autostart ran, in its own scope"):
        machine.succeed("test -f /home/demo/autostarted")
        machine.succeed(demo("systemctl --user list-units --type=scope --no-legend | grep -q app-Hyprland-sh"))

    with subtest("the idle timers are yours, and a null one is gone"):
        hypridle = machine.succeed("cat /home/demo/.config/hypr/hypridle.conf")
        assert "timeout=900" in hypridle and "timeout=1000" in hypridle, hypridle
        assert "timeout=150" not in hypridle and "timeout=300" not in hypridle, hypridle

    with subtest("fontconfig finds fonts from both sides"):
        assert "FiraCode Nerd Font Mono" in machine.succeed(demo("fc-match monospace"))
        assert "Liberation Sans" in machine.succeed(demo("fc-match sans-serif"))
        assert "Hack Nerd Font Propo" in machine.succeed(demo("fc-match \"Hack Nerd Font Propo\""))

    with subtest("the desktop uses your wallpaper"):
        machine.succeed("grep -q '${hm.stylix.image}' /home/demo/.config/hypr/hyprpaper.conf")
  '';
}
