# Phase 2 Session Validation Log Template

Use one copy of this template per validation run.
Keep field names stable so later Phase 3 and Phase 4 reruns remain comparable.

## Run Header

- Run ID:
- Date:
- Operator:
- Host:
- Session type:
- Validation mode: baseline / after-repair / regression
- Working tree commit:
- Probe command:
- Probe log directory:

## Session Assumptions

- Desktop session:
- Wayland compositor session evidence:
- Portal backend assumption:
- IME daemon assumption:
- Clipboard tool assumption:
- Notes:

## Commands Executed

```bash
bash tests/session-validation.sh --probe-only --apps qq,zotero --launch-paths shell,desktop --log-dir <run-dir>
bash tests/session-validation.sh --check all --apps qq,zotero --launch-paths shell,desktop --log-dir <run-dir>
```

Additional commands:

```bash
# Add any targeted reruns or inspection commands here.
```

## Structural Evidence

| Evidence Area | File or Path | Outcome (`pass` / `fail` / `inconclusive`) | Notes |
| --- | --- | --- | --- |
| Portal session variables |  |  |  |
| Portal environment.d export |  |  |  |
| Desktop entry structural evaluation or fallback |  |  |  |
| IME session variables |  |  |  |
| IME environment.d export |  |  |  |

## Live Session Evidence

| Evidence Area | File or Path | Outcome (`pass` / `fail` / `inconclusive`) | Notes |
| --- | --- | --- | --- |
| `org.freedesktop.portal.Desktop` probe |  |  |  |
| KDE portal backend probe |  |  |  |
| Portal settings `ReadAll` call |  |  |  |
| `fcitx5` user-service status |  |  |  |
| `org.fcitx.Fcitx5` D-Bus probe |  |  |  |
| `systemctl --user show-environment` capture |  |  |  |
| `fcitx5-remote` capture |  |  |  |
| Generic clipboard probe |  |  |  |

## Launch Capture References

| App | Launch Path | Launch Capture Dir | Runtime Env File | PID or `pgrep` Evidence | Desktop Metadata or Fallback | Outcome | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| QQ | shell |  |  |  | N/A |  |  |
| QQ | desktop |  |  |  |  |  |  |
| Zotero | shell |  |  |  | N/A |  |  |
| Zotero | desktop |  |  |  |  |  |  |

## Journal Excerpts

| Scope | File or Path | Outcome (`pass` / `fail` / `inconclusive`) | Notes |
| --- | --- | --- | --- |
| Portal services journal excerpt |  |  |  |
| Fcitx service journal excerpt |  |  |  |
| App launch journal excerpt |  |  |  |

## Clipboard Results

- Generic clipboard probe input value:
- Generic clipboard probe output value:
- Generic clipboard probe outcome: `pass` / `fail` / `inconclusive`

### QQ Paste Checks

| Launch Path | Expected pasted content | Observed pasted content | Outcome (`pass` / `fail` / `inconclusive`) | Notes |
| --- | --- | --- | --- | --- |
| shell |  |  |  |  |
| desktop |  |  |  |  |

## Operator Notes

### QQ

- Shell launch notes:
- Desktop launch notes:
- Portal behavior notes:
- IME behavior notes:
- Clipboard or paste notes:

### Zotero

- Shell launch notes:
- Desktop launch notes:
- Portal behavior notes:
- IME behavior notes:

## Summary

- Overall portal outcome: `pass` / `fail` / `inconclusive`
- Overall IME outcome: `pass` / `fail` / `inconclusive`
- Overall generic clipboard outcome: `pass` / `fail` / `inconclusive`
- Overall QQ paste outcome: `pass` / `fail` / `inconclusive`
- Validation-only confirmation: no repair steps were applied during this run.
- Follow-up notes for later repair phases:
