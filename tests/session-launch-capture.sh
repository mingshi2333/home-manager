#!/usr/bin/env bash

set -euo pipefail

scriptDir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=tests/session-validation-lib.sh
source "$scriptDir/session-validation-lib.sh"

app=""
launchPath=""
outputDir=""
probeOnly=false
launchTimeout=15

usage() {
  cat <<'EOF'
Usage: session-launch-capture.sh --app qq|zotero --launch-path shell|desktop --output-dir DIR [--probe-only] [--timeout SEC]
EOF
}

resolve_shell_command() {
  local appName=$1
  printf '%s\n' "$appName"
}

resolve_desktop_file() {
  local appName=$1
  local desktopFile="$HOME/.local/share/applications/${appName}.desktop"

  if [[ ! -f "$desktopFile" ]]; then
    sv_fail "desktop file not found for ${appName}: ${desktopFile}"
  fi

  printf '%s\n' "$desktopFile"
}

resolve_desktop_exec() {
  local appName=$1
  local desktopFile

  desktopFile=$(resolve_desktop_file "$appName")
  awk -F= '/^Exec=/{print $2; exit}' "$desktopFile"
}

write_probe_only_capture() {
  local appName=$1
  local pathName=$2
  local targetDir=$3
  local metadataFile="$targetDir/capture.env"
  local desktopFile=""
  local desktopExec=""
  local gtkLaunchStatus=unknown
  local launchCommand

  sv_ensure_dir "$targetDir"
  : >"$metadataFile"
  sv_write_kv "$metadataFile" app "$appName"
  sv_write_kv "$metadataFile" launch_path "$pathName"
  sv_write_kv "$metadataFile" probe_only true
  sv_write_kv "$metadataFile" captured_at "$(sv_timestamp)"

  if [[ "$pathName" == "shell" ]]; then
    launchCommand=$(resolve_shell_command "$appName")
    sv_write_kv "$metadataFile" launch_command "$launchCommand"
    sv_write_kv "$metadataFile" pid_detected false
    sv_write_kv "$metadataFile" environ_snapshot false
    return
  fi

  desktopFile=$(resolve_desktop_file "$appName")
  desktopExec=$(resolve_desktop_exec "$appName")
  if gtk-launch "$appName" --help >/dev/null 2>&1; then
    gtkLaunchStatus=available
  else
    gtkLaunchStatus=unverified
  fi

  sv_write_kv "$metadataFile" desktop_file "$desktopFile"
  sv_write_kv "$metadataFile" desktop_exec "$desktopExec"
  sv_write_kv "$metadataFile" gtk_launch_status "$gtkLaunchStatus"
  sv_write_kv "$metadataFile" fallback_strategy "desktop-exec-from-generated-file"
  sv_write_kv "$metadataFile" pid_detected false
  sv_write_kv "$metadataFile" environ_snapshot false

  cp "$desktopFile" "$targetDir/desktop-entry.desktop"
}

capture_live_process_state() {
  local appName=$1
  local pathName=$2
  local targetDir=$3
  local metadataFile="$targetDir/capture.env"
  local commandFile="$targetDir/command.txt"
  local pgrepFile="$targetDir/pgrep.txt"
  local pid=""
  local pattern

  sv_ensure_dir "$targetDir"
  : >"$metadataFile"
  sv_write_kv "$metadataFile" app "$appName"
  sv_write_kv "$metadataFile" launch_path "$pathName"
  sv_write_kv "$metadataFile" probe_only false
  sv_write_kv "$metadataFile" captured_at "$(sv_timestamp)"

  if [[ "$pathName" == "shell" ]]; then
    printf '%s\n' "$(resolve_shell_command "$appName")" >"$commandFile"
  else
    printf '%s\n' "$(resolve_desktop_exec "$appName")" >"$commandFile"
  fi

  pattern="${appName}"
  pgrep -af "$pattern" >"$pgrepFile" || true
  pid=$(awk 'NR==1 {print $1}' "$pgrepFile")

  if [[ -z "$pid" ]]; then
    sv_write_kv "$metadataFile" pid_detected false
    return
  fi

  sv_write_kv "$metadataFile" pid_detected true
  sv_write_kv "$metadataFile" pid "$pid"
  if [[ -r "/proc/${pid}/cmdline" ]]; then
    tr '\0' ' ' </proc/"${pid}"/cmdline >"$targetDir/cmdline.txt"
  fi
  if [[ -r "/proc/${pid}/environ" ]]; then
    tr '\0' '\n' </proc/"${pid}"/environ >"$targetDir/environ.txt"
    sv_write_kv "$metadataFile" environ_snapshot true
  else
    sv_write_kv "$metadataFile" environ_snapshot false
  fi
}

while (($# > 0)); do
  case "$1" in
    --app)
      app=$2
      shift 2
      ;;
    --launch-path)
      launchPath=$2
      shift 2
      ;;
    --output-dir)
      outputDir=$2
      shift 2
      ;;
    --probe-only)
      probeOnly=true
      shift
      ;;
    --timeout)
      launchTimeout=$2
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

[[ -n "$app" ]] || sv_fail "--app is required"
[[ -n "$launchPath" ]] || sv_fail "--launch-path is required"
[[ -n "$outputDir" ]] || sv_fail "--output-dir is required"

sv_normalize_apps "$app" >/dev/null
sv_normalize_launch_paths "$launchPath" >/dev/null
sv_require_commands awk pgrep

if [[ "$probeOnly" == true ]]; then
  write_probe_only_capture "$app" "$launchPath" "$outputDir"
else
  sv_ensure_dir "$outputDir"
  sv_write_status "$outputDir/runtime-mode.env" live timeout "$launchTimeout"
  capture_live_process_state "$app" "$launchPath" "$outputDir"
fi
