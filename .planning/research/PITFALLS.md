# Domain Pitfalls

**Domain:** Fedora KDE Wayland desktop application compatibility repairs in a Home Manager + nixGL codebase
**Researched:** 2026-04-02

## Critical Pitfalls

### Pitfall 1: Forcing Wayland globally instead of deciding per app
**What goes wrong:** Projects set global `ELECTRON_OZONE_PLATFORM_HINT=wayland`, `NIXOS_OZONE_WL=1`, or `QT_QPA_PLATFORM=wayland` and then assume every GUI app should run natively on Wayland.
**Why it happens:** The first success with one Electron or Qt app gets generalized to the whole desktop. In this repo, Wayland defaults are already set globally in `modules/environment.nix`, while wrappers in `nixgl-apps.nix` also override platform per app.
**Consequences:** Proprietary or bundled-runtime apps regress in harder-to-debug ways: clipboard bugs, IME breakage, crashes, missing window decorations, or apps that only stabilize under XWayland.
**Warning signs:**
- One app improves after enabling Wayland while another starts crashing or losing input.
- The same app behaves differently when launched from shell alias, desktop file, and D-Bus activation.
- `qq`-style clipboard behavior or `zotero`-style startup instability appears after broad env changes.
**Prevention strategy:**
- Keep global Wayland variables minimal and treat wrapper-level platform choice as the source of truth.
- For each app, explicitly classify it as `native-wayland`, `xwayland`, or `needs-validation`.
- Store that classification beside the wrapper definition, not in scattered shell snippets.
- Add a smoke matrix for each target app: shell launch, desktop launch, file-open launch, copy/paste, IME, and second launch.
**Which phase should address it:** Phase 1 - App inventory and launch-mode classification.

### Pitfall 2: Mixing multiple input-method strategies at the same time
**What goes wrong:** Projects enable Fcitx through global `GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS`, GTK plugin paths, and Wayland text-input assumptions simultaneously, without separating native Wayland clients from XWayland clients.
**Why it happens:** IME fixes are often cargo-culted from X11-era guides. On KDE Wayland, Fcitx integration is more sensitive because KWin is expected to own the virtual keyboard path, while some clients still need classic IM modules.
**Consequences:** Paste and composition behave inconsistently, candidate popups misalign, preedit flickers, shortcuts stop working, or some apps accept stale clipboard/input state.
**Warning signs:**
- IME works in one app class but fails in Electron, Qt WebEngine, or XWayland apps.
- `fcitx5-diagnose` suggests env settings that conflict with how Plasma Wayland wants Fcitx launched.
- Users report that text entry, paste, and composition regress only in wrapped apps.
**Prevention strategy:**
- Treat IME as a matrix: `Wayland text-input`, `Qt/GTK IM module`, and `XIM` fallback are different paths.
- On Plasma Wayland, verify Fcitx is launched through KWin Virtual Keyboard before changing wrapper env.
- Keep global Fcitx env focused on XWayland compatibility; add app-specific overrides only when native protocol support is proven insufficient.
- Test copy, paste, Chinese input, and candidate popup placement separately.
**Which phase should address it:** Phase 2 - Input/clipboard compatibility validation.

### Pitfall 3: Treating clipboard bugs as app-only bugs instead of Wayland ownership bugs
**What goes wrong:** Teams patch only app flags when clipboard behavior is actually shaped by Wayland clipboard ownership, portal behavior, IME interaction, or app runtime mismatch.
**Why it happens:** X11 habits assume clipboard is globally persistent. Under Wayland, clipboard data belongs to the source client unless another component persists it.
**Consequences:** Copy/paste appears to work briefly, then pastes old data, disappears after focus changes, or breaks after the source app stalls.
**Warning signs:**
- Pasting returns older content rather than failing cleanly.
- Clipboard failures correlate with long-running sessions, source app restarts, or focus changes.
- Logs show client saturation or repeated clipboard/data-control warnings while the app remains otherwise usable.
**Prevention strategy:**
- Debug clipboard at the session layer first: app, compositor, clipboard manager, Fcitx, and portal path.
- Reproduce with both native Wayland and XWayland launch modes before changing wrappers.
- Capture journal logs during copy/paste loops and compare behavior after restarting the source app.
- Only ship an app-specific fix after ruling out session-wide clipboard persistence and IME conflicts.
**Which phase should address it:** Phase 2 - Input/clipboard compatibility validation.

### Pitfall 4: Assuming nixGL fixes only GPU issues
**What goes wrong:** Projects use `nixGL` wrappers as if they are transparent, but wrapper behavior also affects environment propagation, library precedence, desktop launch paths, and packaged runtime expectations.
**Why it happens:** `nixGL` is introduced to solve graphics, then quietly becomes the launch path for every GUI app.
**Consequences:** A fix that works from `~/.local/bin/app` fails from the desktop entry, D-Bus activation, or MIME launch because the actual runtime environment differs.
**Warning signs:**
- Apps launch from shell but not from KDE menu or file association.
- Launch behavior changes when started from alias versus desktop icon.
- A wrapper change unexpectedly affects unrelated apps in the catalog.
**Prevention strategy:**
- Treat wrapper code as compatibility infrastructure, not a thin shim.
- Validate every repaired app through all relevant entrypoints: shell alias, desktop entry, MIME association, and D-Bus service if present.
- Isolate app-specific environment overrides so a change for `qq` or `zotero` cannot silently affect the whole catalog.
- Add assertions or tests for generated desktop files and service rewrites.
**Which phase should address it:** Phase 1 - Wrapper surface audit and app entrypoint mapping.

### Pitfall 5: Shell-rewriting desktop files without verifying the result
**What goes wrong:** Projects patch `.desktop` or D-Bus service files with broad `sed` rules and assume all upstream package formats match the rewrite patterns.
**Why it happens:** It is fast and usually works for the first few apps. This repo already rewrites `Exec=` and service entries in `nixgl-apps.nix` using shell substitutions.
**Consequences:** Wrong executable paths, missing `%U`/`%F` semantics, broken D-Bus activation, duplicate menu entries, or KDE launching the wrong binary.
**Warning signs:**
- App opens from terminal but not from file association or URL handler.
- KDE shows duplicate or stale launchers after activation.
- Desktop entry content differs from the actual wrapped binary name or arguments.
**Prevention strategy:**
- After each wrapper change, inspect generated `.desktop` and `.service` outputs, not just Nix evaluation.
- Add checks for missing `Exec=` rewrites and preserve explicit file/URL placeholders.
- For critical apps, snapshot the generated launcher output in tests.
- Prefer structured generation where possible instead of regex replacement across third-party desktop files.
**Which phase should address it:** Phase 3 - Desktop integration hardening.

### Pitfall 6: Ignoring portal/backend mismatches on KDE
**What goes wrong:** Projects enable `GTK_USE_PORTAL=1` or `NIXOS_XDG_OPEN_USE_PORTAL=1` and assume file dialogs, open-uri, and clipboard-adjacent flows will behave correctly without verifying the KDE portal backend path.
**Why it happens:** Portal env flags look harmless and are often copied from generic Linux guidance.
**Consequences:** File pickers, link opening, and sandbox-adjacent integration fail intermittently or behave differently between terminal launch and desktop launch.
**Warning signs:**
- Apps can start but fail on file-open, export, attach-file, or browser handoff flows.
- Behavior differs between GTK/Electron/Qt apps despite similar wrappers.
- Journal output references portal service resolution or backend selection problems.
**Prevention strategy:**
- Verify portal-dependent workflows explicitly on Plasma Wayland: file chooser, URL open, attachment import, and save dialogs.
- Confirm the user session sees the same `XDG_CURRENT_DESKTOP`, `XDG_SESSION_TYPE`, and `XDG_DATA_DIRS` when launched from KDE as when launched from shell.
- Do not treat portal env flags as a fix by themselves; pair them with functional tests.
**Which phase should address it:** Phase 3 - Desktop integration hardening.

### Pitfall 7: Restarting Plasma or rebuilding desktop caches as part of every repair iteration
**What goes wrong:** Teams fold session restarts, `kbuildsycoca`, or aggressive desktop-entry cleanup into the normal apply path and then confuse activation side effects with actual app fixes.
**Why it happens:** KDE menu refresh issues are real, so restart logic gets added early and then left on for every switch.
**Consequences:** The desktop session becomes unstable, investigations become noisy, and successful fixes are hard to distinguish from transient session resets.
**Warning signs:**
- Problems appear only immediately after `home-manager switch`.
- `plasmashell` restarts are needed often, but the app remains unstable later.
- Menu/database refresh work changes perceived app behavior without changing wrappers.
**Prevention strategy:**
- Separate repair work into two layers: app runtime fixes and desktop refresh logic.
- Make Plasma restart opt-in for debugging, not the default path for every activation.
- Log when refresh operations actually run and when they were skipped due to unchanged desktop outputs.
- Re-test target apps in a steady-state session after activation noise is gone.
**Which phase should address it:** Phase 1 - Stabilize the test/apply loop.

### Pitfall 8: Not checking whether the app is actually running under Wayland or XWayland
**What goes wrong:** Teams discuss a "Wayland fix" without verifying the window backend actually in use.
**Why it happens:** Wrapper env and flags are assumed to be decisive, but proprietary apps can ignore them, partially support them, or fall back silently.
**Consequences:** Repairs are misattributed, regressions are hard to reproduce, and the wrong flags keep getting added.
**Warning signs:**
- An app labeled Wayland still behaves like an X11 client.
- Screen-sharing, clipboard, scaling, or IME behavior does not match the expected backend.
- Small flag changes have no observable effect across launches.
**Prevention strategy:**
- For every target app, record the observed backend during testing using KDE/KWin diagnostics or XWayland detection tools.
- Keep the backend result in the repair notes so later changes are grounded in evidence.
- Refuse to classify a repair as complete until backend, launch path, and user-visible behavior all line up.
**Which phase should address it:** Phase 1 - App inventory and launch-mode classification.

## Moderate Pitfalls

### Pitfall 1: Using one-off shell experiments as final fixes
**What goes wrong:** A launch command with temporary exports fixes the problem, but the final Home Manager wrapper does not reproduce the exact same environment.
**Prevention strategy:** Capture successful experiments as structured wrapper fields: platform, flags, env, launch path, and expected behavior. Re-test through Home Manager outputs before declaring success.
**Warning signs:** Works in an interactive shell but not after `home-manager switch`.
**Which phase should address it:** Phase 1 - Wrapper surface audit and app entrypoint mapping.

### Pitfall 2: Letting global environment drift across modules
**What goes wrong:** `PATH`, `XDG_DATA_DIRS`, Wayland vars, and IME vars are assembled in multiple modules and diverge over time.
**Prevention strategy:** Centralize shared GUI environment construction, then import it into wrapper generation, `environment.d`, and activation logic from one place.
**Warning signs:** Systemd user services, desktop launches, and interactive shells see different behavior.
**Which phase should address it:** Phase 3 - Desktop integration hardening.

### Pitfall 3: Assuming crashes are always graphics crashes
**What goes wrong:** Teams blame GPU wrapping first and overlook bundled Qt/WebEngine, sandbox, portal, or IME interactions.
**Prevention strategy:** For each crash, collect `coredumpctl` metadata, backend mode, launch path, and whether the same build survives under XWayland. Only then narrow to graphics.
**Warning signs:** Segfaults persist after renderer toggles or disappear only when switching platform mode.
**Which phase should address it:** Phase 2 - Per-app crash triage.

## Minor Pitfalls

### Pitfall 1: Overusing fallback flags without expiry
**What goes wrong:** Temporary flags accumulate and stay forever, even after upstream Electron, Qt, or Plasma behavior changes.
**Prevention strategy:** Document why each non-default flag exists, which app needs it, and what condition removes it.
**Warning signs:** No one can explain whether a flag is still required.
**Which phase should address it:** Phase 4 - Cleanup and regression-proofing.

### Pitfall 2: Repairing only the primary app while ignoring adjacent apps in the same runtime family
**What goes wrong:** `qq` gets a special fix, but `wechat`, `element-desktop`, or other Electron-family apps share the same class of problem and remain untested.
**Prevention strategy:** After fixing one Electron or Qt app, run a targeted regression sweep across sibling apps that use the same wrapper helpers.
**Warning signs:** A helper change lands for one app and nobody verifies the others.
**Which phase should address it:** Phase 4 - Cleanup and regression-proofing.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Launch-mode inventory | Misclassifying apps as native Wayland when they are actually on XWayland | Record observed backend per app before changing flags |
| Wrapper audit | Fixing shell launch only and forgetting desktop/D-Bus/MIME launch paths | Test every repaired app through each real entrypoint |
| Clipboard and IME triage | Treating stale paste as a simple app bug | Validate session clipboard, Fcitx path, and backend mode first |
| Crash triage | Blaming GPU wrapping before checking runtime/backend mismatch | Collect coredumps and compare native Wayland versus XWayland behavior |
| Desktop integration | Rewriting `.desktop` files without checking generated output | Inspect generated launchers and add assertions/tests |
| Activation hardening | Using Plasma restart as a hidden dependency for app stability | Make refresh/restart logic opt-in and observable |
| Cleanup | Leaving workaround flags undocumented | Track owner, reason, and removal trigger for every flag |

## Sources

- Project context: `/home/mingshi/.config/home-manager/.planning/PROJECT.md`
- Project concerns: `/home/mingshi/.config/home-manager/.planning/codebase/CONCERNS.md`
- Project stack: `/home/mingshi/.config/home-manager/.planning/codebase/STACK.md`
- Local implementation: `/home/mingshi/.config/home-manager/nixgl-apps.nix`
- Local implementation: `/home/mingshi/.config/home-manager/modules/environment.nix`
- Local implementation: `/home/mingshi/.config/home-manager/modules/fcitx.nix`
- Local implementation: `/home/mingshi/.config/home-manager/modules/desktop-entries.nix`
- Electron command-line documentation: https://www.electronjs.org/docs/latest/api/command-line-switches
- Qt Wayland documentation: https://doc.qt.io/qt-6/wayland-and-qt.html
- XDG Desktop Portal documentation: https://flatpak.github.io/xdg-desktop-portal/docs/
- ArchWiki Wayland reference, retrieved 2026-04-02: https://wiki.archlinux.org/title/Wayland
- ArchWiki Fcitx5 reference, retrieved 2026-04-02: https://wiki.archlinux.org/title/Fcitx5
