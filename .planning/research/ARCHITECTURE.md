# Architecture Patterns

**Domain:** Fedora KDE Wayland desktop application compatibility repairs in an existing Home Manager + nixGL repository
**Researched:** 2026-04-02

## Recommended Architecture

Use a four-layer repair architecture:

1. **Generic wrapper primitives** in `nixgl-apps.nix` define how a GUI app is launched under `nixGL`, how platform flags are applied, and how desktop entries and aliases are generated.
2. **Shared runtime export** in `modules/nixgl-runtime.nix` evaluates those wrappers once and exposes a stable internal interface through `config.local.nixgl`.
3. **Session and desktop integration modules** in `modules/environment.nix`, `modules/fcitx.nix`, `modules/desktop-entries.nix`, and optionally a dedicated compatibility module handle repo-wide Wayland/session behavior, XDG portal expectations, IME wiring, and desktop database refresh.
4. **Fedora KDE host policy** should live in a host-specific compatibility module imported only by `hosts/mingshi/home.nix` or a Fedora-only profile, and should only contain fixes that are genuinely specific to this machine, compositor stack, or distro packaging behavior.

This repository already has the right backbone for that split. The key architectural move is to **keep app launch recipes generic by default, but route host-specific override decisions through a separate Fedora KDE compatibility layer** instead of hard-coding Fedora behavior into every wrapper.

Recommended target shape:

```text
flake.nix
  -> hosts/mingshi/home.nix
    -> home.nix
      -> modules/nixgl-runtime.nix        # computes app catalog outputs
      -> profiles/base.nix                # shared session env and IME
      -> profiles/gui.nix                 # desktop integration and Plasma hooks
      -> profiles/packages.nix            # package install surface
      -> profiles/fedora-kde-wayland.nix  # host-only compatibility policy (new) OR host imports module directly
        -> modules/compat/
          -> fedora-kde-wayland.nix       # host-specific toggles and repair policy
          -> app-overrides.nix            # optional typed per-app overrides schema
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `flake.nix` | Selects the active host and evaluation root | `hosts/mingshi/home.nix` |
| `hosts/mingshi/home.nix` | Declares machine identity and imports host-only repair policy | `home.nix`, Fedora compatibility module |
| `home.nix` | Assembles shared repo modules and profiles | `profiles/*.nix`, `modules/*.nix` |
| `nixgl-apps.nix` | Declares per-app wrapper recipes, desktop metadata, aliases, and MIME handlers | `modules/nixgl-runtime.nix` |
| `modules/nixgl-runtime.nix` | Produces `config.local.nixgl` as the single source of truth for wrapped GUI app outputs | `nixgl-apps.nix`, consumer modules |
| `modules/environment.nix` | Sets shared Wayland/XDG/session variables that are safe repo-wide | GUI apps, systemd user environment |
| `modules/fcitx.nix` and `modules/fcitx-env.nix` | Centralize IME env needed by Electron/Qt apps | `nixgl-apps.nix`, session environment |
| `modules/desktop-entries.nix` | Publishes desktop entries, MIME defaults, and KDE refresh actions | `config.local.nixgl.desktopEntries`, KDE caches |
| `modules/packages.nix` | Installs wrapped applications and nixGL runtime package | `config.local.nixgl.appPackages`, `config.local.nixgl.package` |
| `modules/plasma.nix` | Handles post-switch Plasma lifecycle actions | KDE Plasma session |
| `modules/compat/fedora-kde-wayland.nix` | Owns Fedora KDE Wayland repair toggles, host-only defaults, and routing of app-specific compatibility decisions | host import path, wrapper override inputs, session modules |
| Optional `modules/compat/app-overrides.nix` | Defines structured per-app compatibility data such as backend, flags, env, and diagnostic switches | `modules/compat/fedora-kde-wayland.nix`, `nixgl-apps.nix` |

## Data Flow

The repair system should be **data-driven from host policy down to wrappers**, then **artifact-driven from wrappers out to packages and desktop integration**.

### Config Flow

```text
Host identity and Fedora KDE policy
  -> shared Home Manager module graph
  -> compatibility override data for specific apps
  -> nixGL app catalog rendering
  -> config.local.nixgl exported values
  -> packages / aliases / desktop entries / activation hooks
  -> running app process under Wayland or XWayland
```

### Runtime Flow

```text
User launches app
  -> generated desktop entry or alias
  -> wrapped binary from nixgl-apps.nix
  -> nixGL launcher
  -> per-app env and flags applied
  -> app selects native Wayland, fallback Wayland, or XWayland backend
  -> KDE/portal/IME/session services provide integration at runtime
```

### Boundary Rule: Generic vs Fedora-Specific

**Generic wrappers belong in `nixgl-apps.nix` when:**
- The fix is intrinsic to the app family, not Fedora.
- The app consistently needs a launch mode regardless of host, such as Electron Wayland flags or a Qt `xcb` fallback.
- The output should affect aliases, desktop entries, and generated scripts uniformly.

Examples:
- `QQ` needing Electron/Ozone flags belongs in the wrapper recipe.
- `Zotero` needing an explicit backend choice belongs in the wrapper recipe.
- MIME and desktop metadata stay with the app recipe.

**Fedora KDE host fixes belong in a dedicated compatibility module when:**
- The fix depends on Fedora package layout, KDE portal behavior, or this machine's Wayland session constraints.
- The fix should apply to several apps at once through shared environment or session policy.
- The fix may be temporary and should be easy to remove without rewriting app definitions.

Examples:
- Forcing or validating KDE portal usage.
- Enabling environment variables for Plasma/Wayland integration only on this host.
- Setting host-wide clipboard persistence, diagnostic logging, or fallback mode defaults.
- Declaring that certain apps should run via XWayland on Fedora KDE until verified stable.

**System integration belongs outside wrappers when:**
- It manages the desktop session rather than a single app process.
- It concerns XDG portal backends, user services, clipboard persistence, or Plasma cache refresh.
- It should keep working even if individual apps are replaced later.

## Recommended Repair Pattern

### Pattern 1: Host Policy Feeds App Overrides
**What:** Create a host-scoped compatibility attrset that declares backend decisions and extra env/flags per app, then merge it into generic app definitions during `nixgl-apps.nix` evaluation.
**When:** Use this for Fedora KDE Wayland instability where some apps should stay on native Wayland and others should deliberately fall back to XWayland.
**Example:**

```nix
# modules/compat/fedora-kde-wayland.nix
{ lib, ... }:
{
  options.local.compat = {
    appOverrides = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          platform = lib.mkOption {
            type = lib.types.enum [ "wayland" "x11" "auto" ];
            default = "auto";
          };
          extraEnv = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
          extraFlags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }));
      default = {
        qq = {
          platform = "wayland";
          extraFlags = [ "--enable-wayland-ime" ];
        };
        zotero = {
          platform = "x11";
        };
      };
    };
  };
}
```

This keeps app declarations centralized while allowing host repair policy to choose the final launch mode.

### Pattern 2: Session Integration Stays Shared, But Is Gated
**What:** Keep XDG portal, IME, and shared session variables in normal modules, but gate Fedora-only additions with an explicit host/module import rather than putting them in the global environment module.
**When:** Use this for settings like portal requirements, clipboard helpers, or KDE-specific runtime workarounds.
**Example:**

```nix
{ lib, pkgs, ... }:
{
  systemd.user.services.wl-clip-persist = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Persist Wayland clipboard content";
    Service.ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
    Install.WantedBy = [ "default.target" ];
  };
}
```

This belongs in compatibility/system integration, not inside an individual `qq` wrapper.

### Pattern 3: Wrapper Recipes Stay Declarative
**What:** App recipes should only describe backend, env, flags, aliases, and metadata. They should not contain large shell decision trees about Fedora/KDE detection.
**When:** Always. If conditional complexity grows, move the condition into override data or a compatibility helper function.
**Example:**

```nix
qq = standardApp {
  pkg = pkgs.qq;
  platform = override.platform;
  extraEnv = override.extraEnv;
  extraFlags = override.extraFlags;
  desktopName = "QQ (nixGL)";
  comment = "QQ Instant Messaging (nixGL)";
  categories = [ "Network" "InstantMessaging" ];
  icon = "qq";
};
```

## Anti-Patterns To Avoid

### Anti-Pattern 1: Hard-code Fedora KDE Logic Into Every App Wrapper
**What:** Putting host checks, Plasma assumptions, or distro-specific env directly into multiple app definitions.
**Why bad:** It duplicates repair logic, makes later cleanup difficult, and turns the app catalog into a pile of special cases.
**Instead:** Keep app wrappers generic and inject host policy through a compatibility module or override attrset.

### Anti-Pattern 2: Put Session-Level Fixes In Per-App Launchers
**What:** Solving clipboard, portal, or desktop cache issues by adding ad-hoc commands to app startup wrappers.
**Why bad:** The app appears fixed, but the real system boundary remains wrong and other apps will fail the same way.
**Instead:** Put session services, portal expectations, and desktop refresh behavior in dedicated Home Manager modules.

### Anti-Pattern 3: Assume Wayland Is Always Better Than XWayland
**What:** Forcing native Wayland for every Electron or Qt app.
**Why bad:** Some proprietary apps remain more stable on XWayland, especially with clipboard and IME edge cases. Qt upstream explicitly documents `wayland` and `xcb` backend selection, and Wayland docs still treat XWayland as the normal compatibility layer for legacy applications.
**Instead:** Treat backend choice as a per-app policy decision, validated by runtime testing.

## Suggested Build Order

The roadmap should build the repair system in this order because each step reduces uncertainty for the next one.

1. **Introduce compatibility policy boundary**
   - Add a Fedora KDE Wayland compatibility module or profile.
   - Do not change app behavior yet.
   - Goal: create a clean place for host-only fixes.

2. **Move backend decisions into structured override data**
   - Teach `nixgl-apps.nix` or `modules/nixgl-runtime.nix` to consume host overrides.
   - Keep current defaults for all apps first.
   - Goal: make later repairs data changes, not wrapper rewrites.

3. **Repair shared session integration**
   - Validate XDG portal path, IME env, desktop entry refresh, and any clipboard persistence service.
   - Goal: fix cross-app Wayland integration before blaming individual apps.

4. **Repair Electron apps**
   - Start with `qq` and other Electron-based apps.
   - Use wrapper flags/env for Ozone/Wayland selection and route unstable apps to XWayland if needed.
   - Goal: stabilize the most sensitive app family first.

5. **Repair Qt and mixed-toolkit apps**
   - Handle `zotero` and similar apps with backend selection and any app-specific env.
   - Goal: isolate apps that need `xcb` fallback or Qt-specific tuning.

6. **Add diagnostics and verification hooks**
   - Optional logging flags, wrapper variants, or testable launch modes.
   - Goal: make future regressions observable without re-architecting.

## Build Order Implications

- If host compatibility policy is not created first, Fedora fixes will leak into generic modules and be harder to unwind.
- If override data is not added before per-app repairs, each new fix will require editing wrapper logic directly.
- If session integration is not validated before app-specific work, clipboard and portal failures will be misdiagnosed as app bugs.
- Electron should come before Qt in this milestone because the current known issue set is dominated by Wayland/clipboard/process-model behavior that is more sensitive in Electron apps.

## Where Fedora Fixes Should Live

| Repair Type | Best Location | Reason |
|-------------|---------------|--------|
| App metadata, aliases, desktop entries | `nixgl-apps.nix` | App identity should be declared once |
| Generic per-app backend defaults | `nixgl-apps.nix` | These are part of the app launch recipe |
| Host overrides for backend/env/flags | `modules/compat/fedora-kde-wayland.nix` | Keeps Fedora KDE policy separate from app catalog |
| Shared Wayland/XDG env safe on all hosts | `modules/environment.nix` | Repo-wide session policy |
| IME variables reused by many apps | `modules/fcitx-env.nix` and `modules/fcitx.nix` | Single source of truth for input method integration |
| KDE desktop refresh / Plasma restart | existing GUI modules | They are desktop-session concerns, not app concerns |
| Clipboard persistence or portal user services | compatibility/system integration module | They fix session boundaries, not one launcher |
| Machine identity and import of Fedora-only policy | `hosts/mingshi/home.nix` | Correct host boundary |

## Scalability Considerations

| Concern | At 1 host | At 2-3 hosts | At many hosts |
|---------|-----------|--------------|---------------|
| App backend policy | Inline defaults are manageable | Need override attrset by host | Need host profiles plus reusable policy groups |
| Session compatibility fixes | One Fedora module is enough | Split Fedora-only from generic Linux Wayland fixes | Need distro and DE specific compatibility modules |
| Wrapper maintenance | Direct edits are tolerable | Repetition becomes risky | Must be data-driven |
| Regression diagnosis | Manual launch testing works | Need optional logging wrappers | Need explicit per-app diagnostics matrix |

## Sources

- Official Qt docs, "Wayland and Qt": https://doc.qt.io/qt-6/wayland-and-qt.html — HIGH confidence for Qt backend selection and Wayland/X11 boundary
- Official Electron docs, "Supported Command Line Switches": https://www.electronjs.org/docs/latest/api/command-line-switches — HIGH confidence for Electron switch support and portal-related flags
- Official XDG Desktop Portal docs: https://flatpak.github.io/xdg-desktop-portal/docs/ — HIGH confidence for portal/system integration boundary
- Repository context: `/home/mingshi/.config/home-manager/.planning/PROJECT.md` — HIGH confidence for milestone scope
- Repository context: `/home/mingshi/.config/home-manager/.planning/codebase/ARCHITECTURE.md` — HIGH confidence for current composition model
- Repository context: `/home/mingshi/.config/home-manager/.planning/codebase/STRUCTURE.md` — HIGH confidence for current file ownership and module layout
- Current repository implementation: `flake.nix`, `home.nix`, `hosts/mingshi/home.nix`, `modules/nixgl-runtime.nix`, `nixgl-apps.nix`, `modules/environment.nix`, `modules/fcitx.nix`, `modules/desktop-entries.nix`, `modules/packages.nix`, `modules/plasma.nix` — HIGH confidence for actual boundaries
- ArchWiki Wayland page, 2026-03-24 revision: https://wiki.archlinux.org/title/Wayland — MEDIUM confidence for Linux desktop operational guidance; useful for ecosystem practice, not authoritative over upstream docs
