# gentle-theme: preview a scheme and wallpaper on the live desktop, then keep
# or revert it. The choice lives in gentleOS.themeFile: preview writes it
# and activates the Home Manager generation built from it; keep commits it and
# switches the system (through polkit); restore puts the old file and
# generation back. Progress goes to a state file the shell's theme picker
# watches (shell/ThemePicker.qml). A preview in the scheme the active generation
# was built with only swaps the wallpaper in hyprpaper; keep then activates the
# generation that goes with it. Packaged by default.nix, which sets SWITCH_SYSTEM
# (the root helper pkexec runs), QUICKSHELL and THEME_PICKER (the picker), and
# DEFAULT_FLAKE and THEME_FILE (where the flake and the choice are).

usage() {
  cat <<EOF
Usage: gentle-theme COMMAND

  open                      open the theme picker, or focus it if it's open
  preview SCHEME WALLPAPER  build and activate a theme, e.g. base16/nord contours
  restore                   go back to the theme from before the preview
  keep                      commit the previewed theme and switch the system
  push                      push the branch (refuses if origin has new commits)
  thumb WALLPAPER SCHEME    build a wallpaper and print its path

The flake is \$GENTLEOS_FLAKE or gentleOS.flakePath. preview, restore, keep and push
run as the systemd user unit gentle-theme (journalctl --user -u gentle-theme),
so they survive the shell restarting.
EOF
}

# Also a notification: from a keybind or the picker, nobody sees stderr.
die() {
  echo "gentle-theme: $*" >&2
  notify-send -u critical -a gentleOS "Theme picker" "$*" 2>/dev/null || true
  exit 1
}

cmd=${1:-}
[[ -n $cmd ]] || { usage >&2; exit 1; }
shift

flake=$(realpath "${GENTLEOS_FLAKE:-$DEFAULT_FLAKE}")
nix=/run/current-system/sw/bin/nix
hyprctl=/run/current-system/sw/bin/hyprctl
rel=$THEME_FILE
themeFile=$flake/$rel
# The picker opens regardless, so you can browse the themes and see this when you
# try one.
case $cmd in
  open | -h | --help | help) ;;
  *)
    [[ -f $flake/flake.nix ]] || die "no flake at $flake (set gentleOS.flakePath)"
    [[ -f $themeFile ]] || die "no theme file at $themeFile (set gentleOS.themeFile to one in your flake)"
    ;;
esac
state=${XDG_STATE_HOME:-$HOME/.local/state}/gentle-theme.json
currentHome=${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots/current-home
generationTheme=${XDG_CONFIG_HOME:-$HOME/.config}/gentle-theme/current.json

# The desktop-changing commands run in their own unit: activation restarts the
# shell, and with it everything the shell started. A fixed unit name also keeps
# two runs from overlapping. From a terminal, output streams back.
case $cmd in
  preview | restore | keep | push)
    if [[ -z ${GENTLE_THEME_UNIT:-} ]]; then
      run=(--user --collect --quiet --unit gentle-theme -E GENTLE_THEME_UNIT=1 -E "GENTLEOS_FLAKE=$flake")
      [[ -t 1 ]] && run+=(--pipe --wait)
      exec systemd-run "${run[@]}" "$(realpath "$0")" "$cmd" "$@"
    fi
    ;;
esac

# State: status is idle, building, previewing, keeping or kept. original and
# previous (theme.json and the Home Manager generation from before the first
# preview) are what restore goes back to; error is the last failure; ahead is
# the commits not yet pushed (-1 without an upstream branch).
status=idle scheme='' wallpaper='' original=null previous='' message='' error='' ahead=0
if [[ -f $state ]]; then
  for key in status scheme wallpaper previous message error ahead; do
    printf -v "$key" '%s' "$(jq -r ".$key" "$state")"
  done
  original=$(jq -c .original "$state")
fi
save() {
  mkdir -p "$(dirname "$state")"
  jq -n --arg status "$status" --arg scheme "$scheme" --arg wallpaper "$wallpaper" \
    --argjson original "$original" --arg previous "$previous" --arg message "$message" \
    --arg error "$error" --argjson ahead "$ahead" \
    '{$status, $scheme, $wallpaper, $original, $previous, $message, $error, $ahead}' >"$state.tmp"
  mv "$state.tmp" "$state"
}

log=$(mktemp)
trap 'rm -f "$log"' EXIT
# Record a failure (keeping the status from before the attempt) and stop.
fail() {
  status=$1 message=''
  error="$2${3:+: $(tail -n "$3" "$log")}"
  save
  notify-send -u critical -a gentleOS "Theme: $2" "$(tail -n 5 "$log")"
  echo "gentle-theme: $2" >&2
  exit 1
}

# Uncommitted edits to anything but theme.json would be built into the desktop
# and the system; untracked files don't matter (flakes ignore them).
check_clean() {
  local dirty
  dirty=$(git -C "$flake" status --porcelain --untracked-files=no -- . ":!$rel")
  [[ -z $dirty ]] || fail "$1" "commit or stash these first: $(awk '{print $2}' <<<"$dirty" | paste -sd ' ')"
}

# The flake attribute of a wallpaper (first argument) in a scheme (second).
wallpaper_attr() { echo "$flake#wallpapers.\"$1\".${2%%/*}.\"${2#*/}\""; }

case $cmd in
  open)
    window=$("$hyprctl" -j clients | jq -r 'first(.[] | select(.class == "org.quickshell" and .title == "Theme Picker")).address // empty')
    rm -f "$log"
    [[ -z $window ]] || exec "$hyprctl" eval "hl.dispatch(hl.dsp.focus({ window = \"address:$window\" }))"
    exec uwsm app -- "$QUICKSHELL" -p "$THEME_PICKER"
    ;;

  thumb)
    (( $# == 2 )) || { usage >&2; exit 1; }
    rm -f "$log"
    exec "$nix" build --no-link --print-out-paths "$(wallpaper_attr "$1" "$2")"
    ;;

  preview)
    (( $# == 2 )) || { usage >&2; exit 1; }
    before=$status
    check_clean "$before"
    if [[ $before != previewing ]]; then
      original=$(jq -c . "$themeFile")
      previous=$(readlink -f "$currentHome")
    fi
    oldTheme=$(<"$themeFile")
    generationScheme=$(jq -r .scheme "$generationTheme" 2>/dev/null) || generationScheme=''
    status=building message="Building $1 with $2" error=''
    [[ $1 != "$generationScheme" ]] || message="Switching to $2"
    save
    jq -n --arg scheme "$1" --arg wallpaper "$2" '{$scheme, $wallpaper}' >"$themeFile"
    if [[ $1 == "$generationScheme" ]]; then
      image=$("$nix" build --no-link --print-out-paths "$(wallpaper_attr "$2" "$1")" 2> >(tee "$log" >&2)) \
        && "$hyprctl" hyprpaper wallpaper ",$image" > >(tee -a "$log") 2>&1
    else
      generation=$("$nix" build --no-link --print-out-paths \
        "$flake#homeConfigurations.$USER.activationPackage" 2> >(tee "$log" >&2)) \
        && "$generation/activate" > >(tee -a "$log") 2>&1
    fi || {
      printf '%s\n' "$oldTheme" >"$themeFile"
      [[ $before == previewing ]] || { original=null previous=''; }
      fail "$before" "building $1 with $2 failed" 8
    }
    status=previewing scheme=$1 wallpaper=$2 message=''
    save
    ;;

  restore)
    [[ $status == previewing ]] || die "no preview to restore"
    status=building message="Restoring the previous theme" error=''
    save
    jq . <<<"$original" >"$themeFile"
    # With the generation unchanged (only the wallpaper was previewed), activating
    # does nothing; hyprpaper goes back to the wallpaper in its config on a restart.
    if [[ $(readlink -f "$currentHome") == "$previous" ]]; then
      systemctl --user restart hyprpaper.service
    else
      "$previous/activate"
    fi > >(tee "$log") 2>&1 || fail previewing "restoring failed" 8
    rm -f "$state"
    ;;

  keep)
    [[ $status == previewing ]] || die "no preview to keep"
    check_clean previewing
    git -C "$flake" diff --quiet HEAD -- "$rel" \
      || git -C "$flake" commit --quiet --only "$rel" -m "theme: $scheme with $wallpaper wallpaper" 2> >(tee "$log" >&2) \
      || fail previewing "committing the theme failed" 5
    status=keeping message="Rebuilding the system" error=''
    save
    # On failure the commit stays and the preview stays open, so keep can be
    # retried (it skips the commit then). The home activates last: it can restart
    # the shell, which has to answer pkexec's polkit prompt.
    host=$(</proc/sys/kernel/hostname)
    generation=$("$nix" build --no-link --print-out-paths \
      "$flake#homeConfigurations.$USER.activationPackage" 2> >(tee "$log" >&2)) \
      || fail previewing "committed; building the home failed" 8
    system=$("$nix" build --no-link --print-out-paths \
      "$flake#nixosConfigurations.$host.config.system.build.toplevel" 2> >(tee "$log" >&2)) \
      || fail previewing "committed; building the system failed" 8
    /run/wrappers/bin/pkexec "$SWITCH_SYSTEM" "$system" > >(tee -a "$log") 2>&1 \
      || fail previewing "committed; switching the system failed" 8
    "$generation/activate" > >(tee -a "$log") 2>&1 \
      || fail previewing "committed; activating the home failed" 8
    ahead=$(git -C "$flake" rev-list --count '@{u}..HEAD' 2>/dev/null || echo -1)
    original=null previous='' status=kept message=''
    save
    notify-send -a gentleOS "Theme kept" "$scheme with $wallpaper is committed and applied."
    ;;

  push)
    git -C "$flake" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 || fail "$status" "no upstream branch to push to"
    git -C "$flake" fetch --quiet 2> >(tee "$log" >&2) || fail "$status" "fetching failed" 5
    behind=$(git -C "$flake" rev-list --count 'HEAD..@{u}')
    (( behind == 0 )) || fail "$status" "origin has $behind new commit(s); pull and review them first"
    git -C "$flake" push --quiet 2> >(tee "$log" >&2) || fail "$status" "pushing failed" 5
    rm -f "$state"
    notify-send -a gentleOS "Theme pushed" "$(git -C "$flake" log -1 --format=%s)"
    ;;

  -h | --help | help) usage ;;
  *) usage >&2; exit 1 ;;
esac
