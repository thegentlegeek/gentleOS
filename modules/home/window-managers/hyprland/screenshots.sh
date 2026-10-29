# gentle-screenshots: capture the README screenshots, once per theme.
#
# For each theme in the flake's screenshotHomes it activates that Home Manager
# generation, reloads the desktop, stages each scene on an empty workspace and
# grabs it with grim. Your own generation is restored at the end (also on
# failure or Ctrl+C). Packaged by hyprland-config.nix, which sets KITTY, MENU,
# CHEATSHEET, QUICKSHELL (empty when the Quickshell shell is off) and
# RELOAD_UNITS (the desktop's user services to restart after a theme switch).

usage() {
  cat <<EOF
Usage: gentle-screenshots [-f FLAKE] [-s SECONDS] [THEME...]

Capture the README screenshots into FLAKE/media/screenshots/THEME/ and
rewrite the README's screenshot section. Run it from the Hyprland session.

  -f FLAKE    gentleOS checkout (default: \$GENTLEOS_FLAKE or ~/gentleOS)
  -s SECONDS  settle time before each capture, for animations (default: 2)
  THEME...    themes to capture (default: every screenshotHomes theme)
EOF
}

flake=${GENTLEOS_FLAKE:-$HOME/gentleOS}
settle=2
while getopts "f:s:h" opt; do
  case $opt in
    f) flake=$OPTARG ;;
    s) settle=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

die() { echo "gentle-screenshots: $*" >&2; exit 1; }

[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || die "run this from the Hyprland session"
[[ -f $flake/flake.nix ]] || die "no flake at $flake (use -f)"
flake=$(realpath "$flake")
out=$flake/media/screenshots

mapfile -t allThemes < <(nix eval --json "$flake#screenshotHomes" --apply builtins.attrNames | jq -r '.[]')
themes=("$@")
(( ${#themes[@]} )) || themes=("${allThemes[@]}")
for theme in "${themes[@]}"; do
  [[ " ${allThemes[*]} " == *" $theme "* ]] || die "unknown theme '$theme' (have: ${allThemes[*]})"
done

current=$(readlink -f "${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/current-home")
[[ -x $current/activate ]] || die "can't find the active Home Manager generation"

# Everything happens on the focused monitor, on the lowest-numbered workspace
# without windows, so none of yours end up in the shots.
monitor=$(hyprctl monitors -j | jq -c 'first(.[] | select(.focused))')
output=$(jq -r .name <<<"$monitor")
startWorkspace=$(jq -r .activeWorkspace.id <<<"$monitor")
workspace=$(hyprctl workspaces -j | jq '[.[] | select(.windows > 0) | .id] as $used
  | first(range(1; 100) | select(. as $i | $used | index($i) | not))')

dispatch() { hyprctl dispatch "$1" >/dev/null; }
ipc() { "$QUICKSHELL" ipc -c gentle call shell "$1" >/dev/null; }

# Apps started for a scene; closed when the scene is done.
pids=()
launch() {
  "$@" >/dev/null 2>&1 &
  pids+=("$!")
}
close_all() {
  (( ${#pids[@]} )) && kill "${pids[@]}" 2>/dev/null
  pids=()
  pkill -x rofi || true
  sleep 1
}

# Wait (up to 20 s) for a window matching a jq filter over `hyprctl clients -j`.
wait_window() {
  for _ in $(seq 40); do
    hyprctl clients -j | jq -e "any(.[]; $1)" >/dev/null && return
    sleep 0.5
  done
  die "timed out waiting for a window: $1"
}
wait_pid() { wait_window ".pid == $1"; }

# Re-read everything the theme touches: compositor colors, the shell's theme
# JSON and the wallpaper. Apps started afterwards read their own config.
reload_desktop() {
  hyprctl reload >/dev/null
  # shellcheck disable=SC2086 # a list of unit names
  systemctl --user try-restart $RELOAD_UNITS
  sleep 3
}

restore() {
  close_all
  if [[ -n ${switched:-} ]]; then
    echo "Restoring your Home Manager generation..."
    "$current/activate" >/dev/null
    reload_desktop
  fi
  dispatch "hl.dsp.focus({ workspace = $startWorkspace })"
}
trap restore EXIT

# Numbered so the README keeps scene order.
shot() {
  sleep "$settle"
  shots=$((shots + 1))
  grim -o "$output" "$dir/$shots-$1.png"
  echo "  $1"
}

# Scenes. Each starts on the empty workspace and cleans up after itself.
scene_desktop() {
  shot desktop
}

scene_launcher() {
  launch gnome-calculator
  wait_window '.class == "org.gnome.Calculator"'
  # Float it to the right of the launcher, vertically centered.
  local geo
  geo=$(hyprctl clients -j | jq -r --argjson m "$monitor" '
    first(.[] | select(.class == "org.gnome.Calculator"))
    | [ .pid,
        ($m.x + $m.width / $m.scale - .size[0] - 120 | floor),
        ($m.y + ($m.height / $m.scale - .size[1]) / 2 | floor) ] | @tsv')
  local pid x y
  read -r pid x y <<<"$geo"
  dispatch "hl.dsp.window.move({ x = $x, y = $y, window = 'pid:$pid' })"
  launch "$MENU"
  shot launcher
  close_all
}

scene_tiled() {
  launch "$KITTY" fish -C fastfetch
  wait_pid "${pids[-1]}"
  launch "$KITTY" yazi "$flake"
  wait_pid "${pids[-1]}"
  launch "$KITTY" nvim "$flake/README.md"
  wait_pid "${pids[-1]}"
  shot tiled
  close_all
}

# Quickshell panels, over the bare desktop.
scene_panels() {
  [[ -n $QUICKSHELL ]] || return 0
  ipc toggleQuickSettings
  shot quick-settings
  ipc toggleQuickSettings
  notify-send -a gentleOS -i nix-snowflake "Rebuild finished" "home-manager switch activated a new generation"
  notify-send -a kitty -i kitty "Command finished" "nix flake check: all checks passed"
  notify-send -a Thunar -i drive-removable-media "USB drive mounted" "Opened in Thunar"
  # Popups hide while the center is open.
  ipc toggleNotifications
  shot notifications
  ipc toggleNotifications
}

scene_cheatsheet() {
  launch "$CHEATSHEET"
  sleep 2
  shot cheatsheet
  close_all
}

scenes=(desktop launcher tiled panels cheatsheet)

for theme in "${themes[@]}"; do
  echo "Theme $theme: building..."
  generation=$(nix build --no-link --print-out-paths "$flake#screenshotHomes.$theme.activationPackage")
  switched=1
  "$generation/activate" >/dev/null
  reload_desktop
  dispatch "hl.dsp.focus({ workspace = $workspace })"

  dir=$out/$theme
  shots=0
  rm -rf "$dir"
  mkdir -p "$dir"
  for scene in "${scenes[@]}"; do
    "scene_$scene"
  done
done

# Regenerate the README section between the screenshot markers from what's on disk.
readme=$flake/README.md
if grep -q '<!-- screenshots:start -->' "$readme"; then
  section=$(mktemp)
  {
    echo '<!-- screenshots:start -->'
    echo '<!-- Generated by gentle-screenshots; edit the script, not this section. -->'
    for dir in "$out"/*/; do
      theme=$(basename "$dir")
      echo
      echo "#### $theme"
      for png in "$dir"*.png; do
        echo
        name=$(basename "$png" .png)
        echo "![$theme: ${name#*-}](media/screenshots/$theme/$name.png)"
      done
    done
    echo
    echo '<!-- screenshots:end -->'
  } >"$section"
  awk -v section="$section" '
    /<!-- screenshots:start -->/ { while ((getline line < section) > 0) print line; skip = 1; next }
    /<!-- screenshots:end -->/ { skip = 0; next }
    !skip' "$readme" >"$readme.tmp"
  mv "$readme.tmp" "$readme"
  rm "$section"
fi

echo "Saved to $out"
