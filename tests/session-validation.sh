#!/usr/bin/env bash

set -euo pipefail

scriptDir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=tests/session-validation-lib.sh
source "$scriptDir/session-validation-lib.sh"

checkMode=all
appsCsv=qq,zotero
launchPathsCsv=shell,desktop
probeOnly=false
logDir=$(sv_default_log_dir)

usage() {
  cat <<'EOF'
Usage: session-validation.sh [--check portal|ime|clipboard|all] [--apps qq,zotero] [--launch-paths shell,desktop] [--probe-only] [--log-dir DIR]
EOF
}

parse_args() {
  while (($# > 0)); do
    case "$1" in
      --check)
        checkMode=$2
        shift 2
        ;;
      --apps)
        appsCsv=$2
        shift 2
        ;;
      --launch-paths)
        launchPathsCsv=$2
        shift 2
        ;;
      --probe-only)
        probeOnly=true
        shift
        ;;
      --log-dir)
        logDir=$2
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        sv_fail "unknown argument: $1"
        ;;
    esac
  done
}

selected_checks() {
  case "$checkMode" in
    all) printf 'portal\nime\nclipboard\n' ;;
    portal|ime|clipboard) printf '%s\n' "$checkMode" ;;
    *) sv_fail "unsupported check '${checkMode}'" ;;
  esac
}

portal_structural_checks() {
  local outputDir=$1
  local sessionVarsJson="$outputDir/session-variables.json"
  local portalEnvText="$outputDir/environment-portal.conf"
  local desktopEntriesJson="$outputDir/desktop-entries-fallback.json"

  sv_capture_nix_eval_json 'home.sessionVariables' "$sessionVarsJson"
  sv_assert_jq_file '.GTK_USE_PORTAL == "1" and .NIXOS_XDG_OPEN_USE_PORTAL == "1"' \
    "$sessionVarsJson" 'portal session variables are missing expected values'
  sv_capture_nix_eval_text 'xdg.configFile."environment.d/30-xdg-portal.conf".text' "$portalEnvText"

  if (
    cd "$sessionValidationRepoRoot"
    nix eval --json '.#homeConfigurations.mingshi.config.xdg.desktopEntries'
  ) >"$desktopEntriesJson" 2>"$outputDir/desktop-entries-eval.stderr"; then
    sv_write_status "$outputDir/desktop-entries-eval.env" ok mode nix-eval
  else
    sv_write_status "$outputDir/desktop-entries-eval.env" fallback \
      mode local-desktop-files \
      reason unrelated-xdg.desktopEntries-evaluation-failure
  fi
}

portal_live_checks() {
  local outputDir=$1

  sv_systemctl_probe_user_service xdg-desktop-portal.service "$outputDir/xdg-desktop-portal.service"
  sv_systemctl_probe_user_service plasma-xdg-desktop-portal-kde.service "$outputDir/plasma-xdg-desktop-portal-kde.service"
  sv_busctl_probe_name org.freedesktop.portal.Desktop "$outputDir/org.freedesktop.portal.Desktop"
  sv_busctl_probe_name org.freedesktop.impl.portal.desktop.kde "$outputDir/org.freedesktop.impl.portal.desktop.kde"

  if gdbus call --session \
    --dest org.freedesktop.portal.Desktop \
    --object-path /org/freedesktop/portal/desktop \
    --method org.freedesktop.portal.Settings.ReadAll "['org.freedesktop.appearance']" \
    >"$outputDir/portal-settings-readall.txt" 2>"$outputDir/portal-settings-readall.stderr"; then
    sv_write_status "$outputDir/portal-readall.env" ok method ReadAll
  else
    sv_write_status "$outputDir/portal-readall.env" failed method ReadAll
    return 1
  fi
}

ime_structural_checks() {
  local outputDir=$1
  local sessionVarsJson="$outputDir/session-variables.json"
  local fcitxEnvText="$outputDir/environment-fcitx.conf"

  sv_capture_nix_eval_json 'home.sessionVariables' "$sessionVarsJson"
  sv_capture_nix_eval_text 'xdg.configFile."environment.d/99-fcitx5.conf".text' "$fcitxEnvText"
  sv_assert_jq_file '.GTK_IM_MODULE == "fcitx" and .QT_IM_MODULE == "fcitx" and .XMODIFIERS == "@im=fcitx" and .SDL_IM_MODULE == "fcitx" and .INPUT_METHOD == "fcitx"' \
    "$sessionVarsJson" 'fcitx session variables are missing required values'
}

ime_live_checks() {
  local outputDir=$1

  sv_systemctl_probe_user_service app-org.fcitx.Fcitx5@autostart.service "$outputDir/fcitx5.service"
  sv_busctl_probe_name org.fcitx.Fcitx5 "$outputDir/org.fcitx.Fcitx5"
  sv_run_and_capture "$outputDir/systemctl-user-environment.txt" systemctl --user show-environment
  sv_run_and_capture "$outputDir/fcitx5-remote.txt" fcitx5-remote
}

clipboard_checks() {
  local outputDir=$1
  local qqPlaceholder="$outputDir/qq-paste-check.env"

  sv_clipboard_probe "$outputDir/wl-clipboard-probe.env"
  sv_write_status "$qqPlaceholder" pending \
    app qq \
    reason manual-paste-evidence-required \
    probe_only "$probeOnly"
}

launch_capture_for_pair() {
  local checkName=$1
  local baseDir=$2
  local app=$3
  local launchPath=$4
  local pairDir="$baseDir/${app}/${launchPath}"

  sv_ensure_dir "$pairDir"
  sv_run_and_capture "$pairDir/journal.txt" journalctl --user --since '-5 min' --no-pager \
    -u xdg-desktop-portal.service \
    -u plasma-xdg-desktop-portal-kde.service \
    -u app-org.fcitx.Fcitx5@autostart.service
  sv_run_and_capture "$pairDir/desktop-file-validate.txt" desktop-file-validate \
    "$HOME/.local/share/applications/${app}.desktop"
  local captureArgs=(
    "$scriptDir/session-launch-capture.sh"
    --app "$app"
    --launch-path "$launchPath"
    --output-dir "$pairDir/capture"
  )
  if [[ "$probeOnly" == true ]]; then
    captureArgs+=(--probe-only)
  fi
  bash "${captureArgs[@]}"
  sv_write_status "$pairDir/summary.env" ok check "$checkName" app "$app" launch_path "$launchPath"
}

run_portal_checks() {
  local outputDir=$1
  local appLaunchDir="$outputDir/launch-paths"

  sv_log INFO "running portal checks"
  portal_structural_checks "$outputDir/structural"
  portal_live_checks "$outputDir/live"
  sv_for_each_app_launch_path "$appsCsv" "$launchPathsCsv" \
    launch_capture_for_pair portal "$appLaunchDir"
}

run_ime_checks() {
  local outputDir=$1
  local appLaunchDir="$outputDir/launch-paths"

  sv_log INFO "running IME checks"
  ime_structural_checks "$outputDir/structural"
  ime_live_checks "$outputDir/live"
  sv_for_each_app_launch_path "$appsCsv" "$launchPathsCsv" \
    launch_capture_for_pair ime "$appLaunchDir"
}

run_clipboard_checks() {
  local outputDir=$1
  local appLaunchDir="$outputDir/launch-paths"

  sv_log INFO "running clipboard checks"
  clipboard_checks "$outputDir/live"
  sv_for_each_app_launch_path "$appsCsv" "$launchPathsCsv" \
    launch_capture_for_pair clipboard "$appLaunchDir"
}

main() {
  local check
  local checkDir

  parse_args "$@"
  sv_normalize_apps "$appsCsv" >/dev/null
  sv_normalize_launch_paths "$launchPathsCsv" >/dev/null
  sv_require_commands nix jq busctl gdbus systemctl wl-copy wl-paste fcitx5-remote journalctl desktop-file-validate
  sv_init_log_dir "$logDir"

  while IFS= read -r check; do
    checkDir="$logDir/$check"
    sv_ensure_dir "$checkDir"
    sv_ensure_dir "$checkDir/structural"
    sv_ensure_dir "$checkDir/live"

    case "$check" in
      portal) run_portal_checks "$checkDir" ;;
      ime) run_ime_checks "$checkDir" ;;
      clipboard) run_clipboard_checks "$checkDir" ;;
    esac
  done < <(selected_checks)

  sv_write_status "$logDir/run-result.env" ok \
    check "$checkMode" \
    apps "$appsCsv" \
    launch_paths "$launchPathsCsv" \
    probe_only "$probeOnly"
}

main "$@"
