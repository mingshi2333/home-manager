#!/usr/bin/env bash

set -euo pipefail

sessionValidationLibDir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
sessionValidationRepoRoot=$(cd -- "${sessionValidationLibDir}/.." && pwd)
sessionValidationFlakeConfig='.#homeConfigurations.mingshi.config'
sessionValidationAllowedApps=(qq zotero)
sessionValidationAllowedLaunchPaths=(shell desktop)

sv_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

sv_run_id() {
  date -u +"%Y%m%dT%H%M%SZ"
}

sv_default_log_dir() {
  printf '%s/.planning/phases/02-session-validation/artifacts/%s\n' \
    "$sessionValidationRepoRoot" "$(sv_run_id)"
}

sv_log() {
  local level=$1
  shift
  printf '[%s] [%s] %s\n' "$(sv_timestamp)" "$level" "$*"
}

sv_fail() {
  sv_log ERROR "$*" >&2
  exit 1
}

sv_ensure_dir() {
  local dir=$1
  mkdir -p "$dir"
}

sv_init_log_dir() {
  local logDir=$1
  local metadataFile

  sv_ensure_dir "$logDir"
  metadataFile="$logDir/run-metadata.env"
  : >"$metadataFile"
  sv_write_kv "$metadataFile" run_id "$(basename -- "$logDir")"
  sv_write_kv "$metadataFile" created_at "$(sv_timestamp)"
  sv_write_kv "$metadataFile" repo_root "$sessionValidationRepoRoot"
}

sv_write_kv() {
  local file=$1
  local key=$2
  local value=${3-}

  printf '%s=%q\n' "$key" "$value" >>"$file"
}

sv_write_status() {
  local file=$1
  local status=$2
  shift 2

  : >"$file"
  sv_write_kv "$file" status "$status"
  while (($# >= 2)); do
    sv_write_kv "$file" "$1" "$2"
    shift 2
  done
}

sv_require_commands() {
  local missing=()
  local cmd

  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      missing+=("$cmd")
    fi
  done

  if ((${#missing[@]} != 0)); then
    sv_fail "missing required commands: ${missing[*]}"
  fi
}

sv_run_and_capture() {
  local outputFile=$1
  shift

  {
    printf '# command:'
    printf ' %q' "$@"
    printf '\n'
    "$@"
  } >"$outputFile" 2>&1
}

sv_nix_eval_json() {
  local attr=$1
  (
    cd "$sessionValidationRepoRoot"
    nix eval --json "${sessionValidationFlakeConfig}.${attr}"
  )
}

sv_nix_eval_text() {
  local attr=$1
  (
    cd "$sessionValidationRepoRoot"
    nix eval --raw "${sessionValidationFlakeConfig}.${attr}"
  )
}

sv_capture_nix_eval_json() {
  local attr=$1
  local outputFile=$2

  sv_nix_eval_json "$attr" >"$outputFile"
}

sv_capture_nix_eval_text() {
  local attr=$1
  local outputFile=$2

  sv_nix_eval_text "$attr" >"$outputFile"
}

sv_assert_jq_file() {
  local jqExpr=$1
  local jsonFile=$2
  local message=$3

  if ! jq -e "$jqExpr" "$jsonFile" >/dev/null; then
    sv_fail "$message"
  fi
}

sv_busctl_probe_name() {
  local busName=$1
  local outputFile=$2

  if busctl --user --list | awk '{print $1}' | grep -Fx "$busName" >/dev/null 2>&1; then
    sv_run_and_capture "$outputFile" busctl --user status "$busName"
  else
    sv_write_status "$outputFile" absent bus_name "$busName"
  fi
}

sv_systemctl_probe_user_service() {
  local serviceName=$1
  local outputFile=$2

  if systemctl --user status "$serviceName" >/dev/null 2>&1; then
    sv_run_and_capture "$outputFile" systemctl --user status "$serviceName"
  else
    sv_run_and_capture "$outputFile" systemctl --user show \
      --property=Id,LoadState,ActiveState,SubState "$serviceName"
  fi
}

sv_clipboard_probe() {
  local outputFile=$1
  local probeValue
  local pastedValue

  probeValue="phase2-clipboard-$(sv_run_id)"
  printf '%s' "$probeValue" | wl-copy
  pastedValue=$(wl-paste --no-newline)

  : >"$outputFile"
  sv_write_kv "$outputFile" expected "$probeValue"
  sv_write_kv "$outputFile" observed "$pastedValue"

  if [[ "$probeValue" != "$pastedValue" ]]; then
    sv_write_kv "$outputFile" status mismatch
    sv_fail "clipboard probe mismatch"
  fi

  sv_write_kv "$outputFile" status ok
}

sv_csv_to_lines() {
  local csv=$1
  tr ',' '\n' <<<"$csv" | sed '/^$/d'
}

sv_normalize_apps() {
  local csv=${1:-qq,zotero}
  local item
  local normalized=()

  while IFS= read -r item; do
    case "$item" in
      qq|zotero) normalized+=("$item") ;;
      *) sv_fail "unsupported app '${item}'; allowed: ${sessionValidationAllowedApps[*]}" ;;
    esac
  done < <(sv_csv_to_lines "$csv")

  if ((${#normalized[@]} == 0)); then
    sv_fail "at least one app must be selected"
  fi

  printf '%s\n' "${normalized[@]}"
}

sv_normalize_launch_paths() {
  local csv=${1:-shell,desktop}
  local item
  local normalized=()

  while IFS= read -r item; do
    case "$item" in
      shell|desktop) normalized+=("$item") ;;
      *) sv_fail "unsupported launch path '${item}'; allowed: ${sessionValidationAllowedLaunchPaths[*]}" ;;
    esac
  done < <(sv_csv_to_lines "$csv")

  if ((${#normalized[@]} == 0)); then
    sv_fail "at least one launch path must be selected"
  fi

  printf '%s\n' "${normalized[@]}"
}

sv_for_each_app() {
  local appsCsv=$1
  local callback=$2
  local app

  while IFS= read -r app; do
    "$callback" "$app"
  done < <(sv_normalize_apps "$appsCsv")
}

sv_for_each_launch_path() {
  local launchPathsCsv=$1
  local callback=$2
  local launchPath

  while IFS= read -r launchPath; do
    "$callback" "$launchPath"
  done < <(sv_normalize_launch_paths "$launchPathsCsv")
}

sv_for_each_app_launch_path() {
  local appsCsv=$1
  local launchPathsCsv=$2
  local callback=$3
  shift 3
  local app
  local launchPath

  while IFS= read -r app; do
    while IFS= read -r launchPath; do
      "$callback" "$@" "$app" "$launchPath"
    done < <(sv_normalize_launch_paths "$launchPathsCsv")
  done < <(sv_normalize_apps "$appsCsv")
}
