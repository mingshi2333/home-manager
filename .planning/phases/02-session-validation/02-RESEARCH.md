# Phase 2: Session Validation - Research

**Researched:** 2026-04-02
**Domain:** Fedora KDE Wayland session validation for wrapped app launch paths
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Validation Targets
- **D-01:** Phase 2 uses `QQ` and `Zotero` as the mandatory baseline validation targets.
- **D-02:** For both baseline apps, validation must cover both shell launch and desktop-entry launch paths.

### Evidence Model
- **D-03:** Phase 2 must produce a checklist plus logs, not only shell scripts and not only manual notes.
- **D-04:** Validation evidence should be repeatable and comparable across later phases, so logs and checklist outputs must be structured enough to rerun after app-specific fixes land.

### Clipboard Validation Scope
- **D-05:** Clipboard validation must include both a generic session-level clipboard probe and a `QQ`-specific paste check.
- **D-06:** The purpose of the dual clipboard path is to separate session-level faults from app-specific paste behavior before later repair phases begin.

### Failure Policy
- **D-07:** Any missing key validation path counts as Phase 2 failure.
- **D-08:** Phase 2 is not done unless shell launch and desktop-entry launch both have portal and IME evidence, and clipboard validation is conclusive enough to support later repair phases.

### Validation Artifact Placement
- **D-09:** Reusable validation scripts should live in `tests/`.
- **D-10:** Checklists, log templates, and other phase-specific validation artifacts should live in the Phase 2 directory.

### the agent's Discretion
- The exact script names and file layout inside `tests/`, as long as they are clearly tied to Phase 2 validation goals.
- The exact checklist/log file formats in the phase directory, as long as they are human-readable and can be rerun later.
- The exact commands used to inspect portal, IME, and launch-path state, as long as they are appropriate for the current Fedora KDE Wayland machine and produce stable evidence.

### Deferred Ideas (OUT OF SCOPE)
- Actual runtime fixes for `QQ` clipboard behavior — deferred to Phase 3.
- Actual runtime fixes for `Zotero` startup or crash behavior — deferred to Phase 4.
- Broad validation across every affected app in the wrapped catalog — deferred until later phases or Phase 5 reuse work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SESS-01 | User can verify that KDE portal integration is healthy for wrapped apps launched from desktop entries and shell commands. | Use one reusable session probe plus per-launch-path evidence capture, validate portal bus names/services, and record launch-path-specific runtime environment and logs. |
| SESS-02 | User can propagate and validate input-method environment needed by wrapped apps in the Fedora KDE Wayland session. | Validate `environment.d` exports, `fcitx` bus presence, and runtime env inside shell-launched and desktop-launched app processes. |
| SESS-03 | User can run a repeatable validation path for clipboard behavior affecting wrapped apps under the current session. | Use a generic Wayland clipboard probe plus a separate `QQ` paste check, both recorded in structured logs and checklist artifacts. |
</phase_requirements>

## Summary

Phase 2 should be implemented as a validation harness, not as a repair phase. The repository already has the right ownership boundaries for this: session-global environment is defined in `modules/environment.nix` and `modules/fcitx.nix`, launch artifacts are generated from `nixgl-apps.nix`, and desktop-entry publication is owned by `modules/desktop-entries.nix`. The planner should preserve those boundaries and add evidence-oriented scripts under `tests/` plus rerunnable human artifacts under `.planning/phases/02-session-validation/`.

The strongest validation path on this Fedora KDE Wayland host is to split evidence into three layers: structural evidence from `nix eval`, live session evidence from D-Bus/systemd/clipboard probes, and operator evidence from a checklist covering manual launch and paste observations for `QQ` and `Zotero`. That keeps Phase 2 narrow: it proves whether portal, IME, and clipboard prerequisites are present across shell and desktop-entry launch paths, without modifying app runtime behavior.

Current host evidence is favorable for this approach. The user session already exposes `org.freedesktop.portal.Desktop`, `org.freedesktop.impl.portal.desktop.kde`, `org.freedesktop.portal.Fcitx`, and active `xdg-desktop-portal`, `plasma-xdg-desktop-portal-kde`, and `fcitx5` user services. The machine also has the required probe tools installed: `jq`, `busctl`, `dbus-send`, `systemctl`, `wl-copy`, `wl-paste`, `fcitx5-remote`, `journalctl`, `desktop-file-validate`, and `kbuildsycoca6`.

**Primary recommendation:** Build Phase 2 around one reusable shell validation script suite in `tests/`, one phase-local checklist/log template set under `.planning/phases/02-session-validation/`, and explicit pass/fail coverage for both `QQ` and `Zotero` across shell and desktop-entry launch paths.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `bash` | 5.3.0 | Validation script runtime | Matches existing repo tests and supports strict shell mode already used in `tests/`. |
| `jq` | 1.8.1 | Parse `nix eval --json` and probe outputs | Already present on host and necessary for stable machine-readable assertions. |
| `busctl` | systemd 258 | Probe session D-Bus names and portal interfaces | Best host-local tool for confirming live portal and fcitx bus state. |
| `systemctl` | systemd 258 | Verify user services for portal and Plasma session integration | Required to prove portal backend and fcitx processes are active in the user session. |
| `wl-clipboard` (`wl-copy`, `wl-paste`) | 2.2.1 | Generic session clipboard probe under Wayland | Directly tests session clipboard outside app-specific behavior. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `dbus-send` | present | Low-level D-Bus method checks | Use when a simple portal method/property call is enough. |
| `fcitx5-remote` | present | Check fcitx daemon responsiveness/state | Use in IME health probes and operator logs. |
| `desktop-file-validate` | 0.28 | Sanity-check generated desktop files | Use before desktop-entry launch validation to catch broken desktop metadata. |
| `journalctl` | systemd 258 | Capture launch-path-adjacent user service logs | Use to attach portal/fcitx/plasma evidence to checklist runs. |
| `nix eval` | flake-driven | Structural validation of Home Manager outputs | Use to verify exported desktop entries, env files, and wrapper config without side effects. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shell scripts in `tests/` | Python validation harness | Not standard in this repo and adds unnecessary runtime/tooling drift. |
| `busctl`/`dbus-send` probes | GUI-only manual confirmation | Too weak for repeatable evidence and poor fit for later reruns. |
| Checklist plus logs | Pure automation only | Clipboard paste and IME candidate behavior still need human observation in Phase 2. |

**Installation:**
```bash
# No new language runtime is recommended.
# Phase 2 should use host tools already available on this machine.
```

**Version verification:** Verified on this host via direct command probes on 2026-04-02. This phase should prefer host-installed session tools over adding new package dependencies.

## Architecture Patterns

### Recommended Project Structure
```text
tests/
├── session-validation.sh           # Main reusable probe runner
├── session-validation-lib.sh       # Shared helpers for logging/assertions
└── session-launch-capture.sh       # Optional runtime env/process capture helper

.planning/phases/02-session-validation/
├── 02-RESEARCH.md
├── 02-CHECKLIST.md                 # Operator runbook for shell + desktop launches
├── 02-LOG-TEMPLATE.md              # Structured evidence template
└── artifacts/                      # Rerun outputs, if the phase chooses to commit or stage samples
```

### Pattern 1: Separate Structural Validation From Live Session Validation
**What:** Use `nix eval` to assert exported config shape, then use host probes to assert the actual running KDE Wayland session is healthy.
**When to use:** For portal and IME prerequisites that may be correct in config but absent in the running session.
**Example:**
```bash
# Source: local repo pattern from tests/compatibility-boundary.sh + environment.d(5)
nix eval --json .#homeConfigurations.mingshi.config.xdg.configFile \
  | jq 'keys[]' \
  | rg 'environment\.d/(30-xdg-portal|99-fcitx5)\.conf'

systemctl --user --no-pager --type=service --all \
  | rg 'xdg-desktop-portal|plasma-xdg-desktop-portal-kde|fcitx'

busctl --user list \
  | rg 'org\.freedesktop\.portal\.Desktop|org\.freedesktop\.impl\.portal\.desktop\.kde|org\.fcitx\.Fcitx5'
```

### Pattern 2: Capture Launch-Path-Specific Runtime Evidence
**What:** For each baseline app, record evidence separately for shell launch and desktop-entry launch.
**When to use:** Always. The phase explicitly fails if either path is missing.
**Example:**
```bash
# Source: repo launch model from nixgl-apps.nix and modules/desktop-entries.nix
# Shell path
qq >"$run_dir/qq-shell.stdout" 2>"$run_dir/qq-shell.stderr" &

# Desktop-entry path
gtk-launch qq >"$run_dir/qq-desktop.stdout" 2>"$run_dir/qq-desktop.stderr" &

# Then capture runtime process evidence keyed by launch path.
pgrep -af '/qq|zotero'
```

### Pattern 3: Treat Clipboard As Two Distinct Validations
**What:** Run one generic session probe with `wl-copy` and `wl-paste`, then one manual `QQ` paste check.
**When to use:** Always for `SESS-03`.
**Example:**
```bash
# Source: wl-clipboard host tools + Phase 2 locked decision D-05
probe_value="phase2-clipboard-$(date +%s)"
printf '%s' "$probe_value" | wl-copy
actual_value=$(wl-paste --no-newline)
test "$actual_value" = "$probe_value"
```

### Pattern 4: Make Manual Evidence Structured, Not Freeform
**What:** Use a checklist with required fields per app and per launch path, then attach logs captured by the reusable scripts.
**When to use:** For portal dialogs, IME candidate behavior, and `QQ` paste behavior that cannot be trusted to a noninteractive script alone.
**Example:**
```text
App: QQ
Launch path: desktop-entry
Portal evidence attached: yes/no
IME env captured: yes/no
Clipboard session probe run ID: 2026-04-02T...
QQ paste result: pass/fail/inconclusive
Notes:
```

### Anti-Patterns to Avoid
- **App repair inside validation scripts:** Do not add launch flags, environment overrides, or wrapper edits in Phase 2. Validation scripts may inspect state, not repair it.
- **Single combined "session is healthy" check:** Portal, IME, and clipboard must remain separable so later phases can identify which layer improved or regressed.
- **Desktop-entry assumptions without proof:** `xdg.desktopEntries` generation is not enough. The planner must require a real desktop-entry launch path and evidence from that path.
- **Using only manual notes:** The phase requires logs and checklist output. Manual-only evidence is insufficient.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| D-Bus/session inspection | Custom parsers for bus state | `busctl`, `dbus-send`, `systemctl --user` | These already expose the authoritative session state. |
| Clipboard probing | App-specific clipboard scripts first | `wl-copy` and `wl-paste` | Separates session clipboard health from app behavior. |
| Desktop entry discovery | Ad hoc filesystem guessing | `nix eval` for `xdg.desktopEntries` plus `desktop-file-validate` and `gtk-launch` | Matches repo ownership and real launch path. |
| Evidence storage | Unstructured notes in issue text | Phase-local checklist and log templates | Required for reruns in later phases. |

**Key insight:** The hard part in this domain is not generating more scripts. It is preserving a clean diagnostic boundary between exported config, live session state, and app-observed behavior.

## Common Pitfalls

### Pitfall 1: Confusing Config Export With Live Session Health
**What goes wrong:** `environment.d` files and desktop entries evaluate correctly, but the running session does not reflect them.
**Why it happens:** `environment.d` affects services started by the systemd user instance, and launch provenance still matters.
**How to avoid:** Record both `nix eval` evidence and live `systemctl --user`/`busctl` evidence in the same run.
**Warning signs:** Files exist in `xdg.configFile`, but portal or fcitx bus names are absent.

### Pitfall 2: Treating Wayland IME Advice As Globally Uniform
**What goes wrong:** Validation logic assumes one universal expected IME variable set for all toolkits.
**Why it happens:** KDE Wayland, XWayland, Electron, and X11 Qt apps have different IME expectations.
**How to avoid:** Validate propagation of the repo's chosen session env and wrapper env separately; do not interpret Phase 2 failures as proof that the chosen runtime policy is correct or incorrect yet.
**Warning signs:** `fcitx5` is running, but one launch path still shows missing input behavior.

### Pitfall 3: Using Portal Health As A Pure Service-Up Check
**What goes wrong:** Planner counts `xdg-desktop-portal.service` as sufficient evidence.
**Why it happens:** Service presence is easy to check, but backend binding and method responsiveness are the real requirement.
**How to avoid:** Probe D-Bus names and at least one benign portal interface call such as `org.freedesktop.portal.Settings.ReadAll` or `ReadOne`.
**Warning signs:** `xdg-desktop-portal.service` is active, but desktop-launched apps still behave as if portal integration is absent.

### Pitfall 4: Letting Clipboard Validation Drift Into QQ Repair
**What goes wrong:** The phase starts testing ad hoc flags or runtime restarts to "fix" QQ paste.
**Why it happens:** Clipboard failures are tempting to triage immediately.
**How to avoid:** Keep the generic session probe and the QQ-specific paste check as pure observation steps with evidence capture only.
**Warning signs:** Validation scripts start exporting new env vars, changing desktop files, or altering launch commands.

## Code Examples

Verified patterns from official sources and current host capabilities:

### Probe Portal Service And Backend
```bash
# Source: XDG Desktop Portal docs + current host observation
busctl --user list \
  | rg 'org\.freedesktop\.portal\.Desktop|org\.freedesktop\.impl\.portal\.desktop\.kde'

systemctl --user --no-pager --type=service --all \
  | rg 'xdg-desktop-portal|plasma-xdg-desktop-portal-kde'
```

### Call A Read-Only Portal Method
```bash
# Source: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.ReadAll \
  "['org.freedesktop.appearance']"
```

### Validate IME-Related Session Exports
```bash
# Source: modules/fcitx.nix, modules/fcitx-env.nix, environment.d(5)
nix eval --json .#homeConfigurations.mingshi.config.home.sessionVariables \
  | jq '{GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS, SDL_IM_MODULE, INPUT_METHOD}'

systemctl --user show-environment \
  | rg '^(GTK_IM_MODULE|QT_IM_MODULE|XMODIFIERS|SDL_IM_MODULE|INPUT_METHOD)='

fcitx5-remote
```

### Generic Wayland Clipboard Probe
```bash
# Source: wl-clipboard host tools
probe="phase2-clipboard-$(date +%s)"
printf '%s' "$probe" | wl-copy
wl-paste --no-newline
```

### Capture Relevant User-Session Logs
```bash
# Source: systemd/journalctl host tools
journalctl --user --since '5 minutes ago' --no-pager \
  -u xdg-desktop-portal.service \
  -u plasma-xdg-desktop-portal-kde.service \
  -u app-org.fcitx.Fcitx5@autostart.service
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat portal checks as "service is active" | Probe D-Bus name plus interface method responsiveness | Current XDG portal docs | Better signal that the KDE backend is usable, not just installed. |
| Treat IME validation as a single env dump | Distinguish session-global env, wrapper env, and actual launch-path runtime evidence | Current Fedora/KDE Wayland reality | Prevents false confidence from one layer passing. |
| Treat clipboard problems as app-only | Split generic session clipboard health from QQ-specific paste behavior | Locked decision in Phase 2 | Makes later app-specific repair phases diagnosable. |

**Deprecated/outdated:**
- "Validation is complete if one launch path works": invalid for this phase because D-02 and D-07 make both shell and desktop-entry paths mandatory.
- "Portal health can be inferred from environment variables alone": invalid because live user services and bus registration must also be checked.

## Open Questions

1. **What is the best repo-local command for desktop-entry launch?**
   - What we know: Generated desktop files are published through `xdg.desktopEntries` and synchronized into `~/.local/share/applications`.
   - What's unclear: Whether `gtk-launch <desktop-id>` is sufficient for every generated desktop entry on this host, or whether a KDE-specific launcher command is more reliable.
   - Recommendation: Plan a Wave 0 spike that validates `gtk-launch qq` and `gtk-launch zotero`; keep fallback to explicit desktop-file `Exec=` extraction if needed.

2. **How should runtime env be captured from a launched GUI process?**
   - What we know: Structural exports and wrapper definitions are visible via `nix eval`, but real process env capture requires matching the live PID.
   - What's unclear: Which baseline app process tree is most stable to inspect after launch on this host.
   - Recommendation: Add a small helper that records `pgrep -af` output and, if stable, `/proc/$pid/environ` snapshots for target app processes.

3. **How much of portal health should be automated versus checklist-only?**
   - What we know: Read-only portal D-Bus methods are automatable; app-observed portal behavior may still need manual confirmation.
   - What's unclear: Whether the planner wants a strict automated gate or a mixed evidence gate.
   - Recommendation: Treat portal bus/method checks as automated gate and any app-observed dialog behavior as checklist evidence only.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | All test scripts | ✓ | 5.3.0 | — |
| `jq` | JSON assertions from `nix eval` | ✓ | 1.8.1 | — |
| `busctl` | Session D-Bus probing | ✓ | systemd 258 | `dbus-send` or `gdbus` for limited calls |
| `dbus-send` | D-Bus method/property probe | ✓ | present | `busctl call` or `gdbus call` |
| `systemctl` | User service and environment inspection | ✓ | systemd 258 | none practical |
| `wl-copy` / `wl-paste` | Generic clipboard validation | ✓ | 2.2.1 | none practical for Wayland clipboard proof |
| `fcitx5-remote` | Fcitx daemon health probe | ✓ | present | D-Bus name probe only |
| `desktop-file-validate` | Desktop artifact validation | ✓ | 0.28 | manual desktop-file inspection |
| `journalctl` | Evidence logs | ✓ | systemd 258 | per-command stdout/stderr logs only |
| `kbuildsycoca6` | KDE desktop database context | ✓ | present | none needed for Phase 2 probes |

**Missing dependencies with no fallback:**
- None.

**Missing dependencies with fallback:**
- `gdbus --version` does not report a version cleanly, but the binary exists and can still be used for `gdbus call` if needed.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | POSIX/Bash shell tests plus manual checklist evidence |
| Config file | none — direct executable scripts in `tests/` |
| Quick run command | `bash tests/session-validation.sh --probe-only` |
| Full suite command | `bash tests/session-validation.sh --apps qq,zotero --launch-paths shell,desktop --log-dir .planning/phases/02-session-validation/artifacts/latest` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESS-01 | Portal integration is healthy for shell and desktop-entry launches | integration + manual evidence | `bash tests/session-validation.sh --check portal --apps qq,zotero --launch-paths shell,desktop` | ❌ Wave 0 |
| SESS-02 | IME env is propagated and observable in session/runtime evidence | integration + manual evidence | `bash tests/session-validation.sh --check ime --apps qq,zotero --launch-paths shell,desktop` | ❌ Wave 0 |
| SESS-03 | Clipboard validation is repeatable and split into generic + QQ-specific probes | integration + manual evidence | `bash tests/session-validation.sh --check clipboard --apps qq --launch-paths shell,desktop` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash tests/session-validation.sh --probe-only`
- **Per wave merge:** `bash tests/session-validation.sh --apps qq,zotero --launch-paths shell,desktop`
- **Phase gate:** Full suite completed with logs plus checklist filled for both apps and both launch paths before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/session-validation.sh` — orchestrates structural checks, live session probes, and log collection for Phase 2
- [ ] `tests/session-validation-lib.sh` — shared shell helpers for assertions, timestamped logs, and run directories
- [ ] `.planning/phases/02-session-validation/02-CHECKLIST.md` — operator evidence for shell and desktop-entry launches
- [ ] `.planning/phases/02-session-validation/02-LOG-TEMPLATE.md` — stable evidence format for reruns after later phases
- [ ] Launch-path feasibility check — confirm `gtk-launch qq` and `gtk-launch zotero` work on this KDE host, or document the launcher fallback

## Sources

### Primary (HIGH confidence)
- Local repository files read on 2026-04-02: `modules/environment.nix`, `modules/fcitx.nix`, `modules/fcitx-env.nix`, `modules/desktop-entries.nix`, `modules/plasma.nix`, `nixgl-apps.nix`, `tests/compatibility-boundary.sh`, `tests/hms-aliases.sh`
- Live host inspection on 2026-04-02 via `busctl --user list`, `systemctl --user --type=service --all`, command availability probes, and `nix eval` of `xdg.configFile`
- XDG Desktop Portal docs: <https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html>
- XDG Desktop Portal docs: <https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.OpenURI.html>
- XDG Desktop Portal docs: <https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Clipboard.html>
- `environment.d(5)`: <https://man7.org/linux/man-pages/man5/environment.d.5.html>

### Secondary (MEDIUM confidence)
- Fcitx Wiki: <https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland>

### Tertiary (LOW confidence)
- Fcitx Wiki historical env var page: <https://fcitx-im.org/wiki/Input_method_related_environment_variables>

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Based on existing repo test style and verified host tool availability.
- Architecture: HIGH - Based on direct reading of module boundaries and launch/export ownership in the repo.
- Pitfalls: MEDIUM - Backed by current docs and repo structure, but some GUI runtime behaviors still need live app confirmation.

**Research date:** 2026-04-02
**Valid until:** 2026-05-02
