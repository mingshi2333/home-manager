# Fix Nix Daemon Proxy Configuration for Sandbox Builds

## TL;DR

> **Quick Summary**: Fix Nix sandbox build failures (Spotify SSL error) by updating nix-daemon proxy configuration from localhost to LAN IP, enabling proxy access from within isolated build environment.
> 
> **Deliverables**:
> - Updated systemd override: `/etc/systemd/system/nix-daemon.service.d/override.conf` (LAN IP proxy)
> - Configured clash-verge: allow-lan enabled
> - Successfully built: `home-manager switch` completes without Spotify SSL errors
> 
> **Estimated Effort**: Quick (15-30 minutes)
> **Parallel Execution**: NO - sequential (networking config → systemd → verification)
> **Critical Path**: Task 1 → Task 2 → Task 3 → Task 4

---

## Context

### Original Request
User encountered home-manager build failure with SSL certificate error when building Spotify package:
```
curl: (16) SSL certificate OpenSSL verify result: unable to get local issuer certificate (20)
error: cannot download spotify-1.2.74.477.g3be53afe-89.snap from any mirror
```

### Interview Summary
**Key Discussions**:
- **Root Cause Identified**: Nix sandbox creates isolated network namespace. Existing proxy config uses `127.0.0.1:7890`, which is inaccessible from sandbox (sandbox's `127.0.0.1` ≠ host's `127.0.0.1`)
- **User Environment**: Uses clash-verge proxy temporarily (in China), will switch to singbox when in Russia
- **User Requirements**: Must fix proxy properly, no workarounds (no removing Spotify, no disabling sandbox, no binary cache tricks)

**Research Findings**:
- **Librarian**: Nix official docs confirm sandbox isolation requires LAN IP for external proxy access. Cannot use `extra-sandbox-paths` for TCP ports (Unix sockets only). Must keep `sandbox = true` for security/reproducibility.
- **Explore**: Found existing systemd override at `/etc/systemd/system/nix-daemon.service.d/override.conf` with incorrect configuration:
  ```
  Environment=HTTP_PROXY=http://127.0.0.1:7890   ← WRONG!
  Environment=HTTPS_PROXY=http://127.0.0.1:7890  ← WRONG!
  ```

### Gap Analysis (Self-Review)
**Identified Gaps Addressed**:
1. **Backup/Rollback Plan**: Must preserve original override.conf before changes
2. **clash-verge Config Location**: Need to verify exact config file path (may vary between clash-verge versions)
3. **Multi-Interface Scenario**: System might have multiple network interfaces (WiFi, Ethernet, VPN) - must detect correct active LAN IP
4. **Proxy Persistence**: clash-verge changes won't persist if config is generated (need to check if manual edits are supported)
5. **Permission Requirements**: User needs sudo for systemd file edits
6. **Verification Strategy**: Must test actual Spotify build, not just generic nix-build

---

## Work Objectives

### Core Objective
Enable Nix sandbox builds to access external internet through user's local proxy by configuring nix-daemon to use LAN IP-based proxy URL instead of localhost.

### Concrete Deliverables
- **File Modified**: `/etc/systemd/system/nix-daemon.service.d/override.conf` → proxy URLs use LAN IP
- **clash-verge Config**: `allow-lan: true`, `bind-address: "*"` enabled
- **Verification**: `home-manager switch` completes successfully, Spotify package builds

### Definition of Done
- [ ] nix-daemon can reach proxy from sandbox environment
- [ ] home-manager builds complete without SSL/download errors
- [ ] Spotify package successfully installed
- [ ] Configuration survives systemd daemon reload

### Must Have
- Preserve existing override.conf as backup
- Use dynamic LAN IP detection (not hardcoded IP)
- Verify clash-verge accepts LAN connections before restarting nix-daemon

### Must NOT Have (Guardrails)
- **No sandbox disabling**: `sandbox = true` must remain (security requirement)
- **No package removal**: Spotify must stay in packages.nix (user wants it installed)
- **No hardcoded IPs**: Must auto-detect LAN IP (user switches networks/locations)
- **No global proxy env vars**: Only nix-daemon should use proxy (don't pollute user shell)
- **No clash-verge replacement**: Work with existing clash-verge, don't suggest switching proxy tools

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> ALL tasks in this plan MUST be verifiable WITHOUT any human action.
> This is NOT conditional — it applies to EVERY task.
>
> **FORBIDDEN** — acceptance criteria that require:
> - "User manually tests..."
> - "User visually confirms..."
> - "User interacts with..."
> - ANY step where a human must perform an action
>
> **ALL verification is executed by the agent** using tools (Bash, interactive_bash, etc.). No exceptions.

### Test Decision
- **Infrastructure exists**: NO (system configuration, not code project)
- **Automated tests**: None (testing via Agent QA scenarios only)
- **Framework**: N/A

### Agent-Executed QA Scenarios (MANDATORY — ALL tasks)

> These describe how the executing agent DIRECTLY verifies the deliverable
> by running commands, checking files, and validating service states.

**Verification Tool**: Bash (for system commands and file inspection)

**Overall Success Criteria**:
After all tasks complete, agent must verify:
1. `systemctl status nix-daemon` → active (running), no errors
2. `systemctl show nix-daemon -p Environment` → contains LAN IP (not 127.0.0.1)
3. `curl --proxy http://<LAN_IP>:7890 https://api.snapcraft.io` → 200 OK (from agent's shell)
4. `home-manager switch` → exit code 0, no SSL errors in output

---

## Execution Strategy

### Parallel Execution Waves

> Sequential execution required (each step depends on previous).

```
Wave 1 (Sequential):
  Task 1: Detect LAN IP → $LAN_IP
  ↓
  Task 2: Configure clash-verge with $LAN_IP
  ↓
  Task 3: Update systemd override with $LAN_IP
  ↓
  Task 4: Test build with updated config
  ↓
  Task 5: (Optional) Rollback if failed

Critical Path: 1 → 2 → 3 → 4 (all blocking)
Parallel Speedup: None (sequential)
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2, 3 | None (must know IP first) |
| 2 | 1 | 3 | None (must verify proxy works) |
| 3 | 2 | 4 | None (must update before test) |
| 4 | 3 | None | None (final verification) |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 1 | 1-4 | task(category="quick", load_skills=[], run_in_background=false) |

---

## TODOs

> This is system configuration work (no code tests). Every task uses Agent QA for verification.

- [x] 1. Detect Active LAN IP Address

  **What to do**:
  - Use `ip route get 1.1.1.1` to find the primary network interface and its source IP
  - Validate IP is in private range (10.x, 172.16-31.x, 192.168.x)
  - Export to shell variable for use in subsequent tasks

  **Must NOT do**:
  - Hardcode IP address (user travels, switches networks)
  - Use first network interface without checking routing table (might pick wrong interface)
  - Use hostname resolution (may not be configured correctly)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple command execution, no complex logic
  - **Skills**: None needed
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1, first task)
  - **Blocks**: Tasks 2, 3 (they need the detected IP)
  - **Blocked By**: None (can start immediately)

  **References**:
  - Official command: `ip route get 1.1.1.1 | grep -oP 'src \K\S+'` - extracts source IP from routing decision
  - Validation: IP must match regex `^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)` for private ranges

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Detect LAN IP and validate it's a private address
    Tool: Bash
    Preconditions: System has network connectivity
    Steps:
      1. Run: LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
      2. Assert: $LAN_IP is not empty (exit code check: [ -n "$LAN_IP" ])
      3. Assert: $LAN_IP matches private IP regex:
         echo "$LAN_IP" | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'
      4. Log: echo "Detected LAN IP: $LAN_IP"
    Expected Result: LAN_IP variable contains valid private IP (e.g., 192.168.1.100)
    Failure Indicators: Empty variable, public IP detected, command failure
    Evidence: stdout showing "Detected LAN IP: X.X.X.X"
  ```

  **Commit**: NO (grouped with Task 3)

---

- [x] 2. Configure clash-verge for LAN Access

  **What to do**:
  - Locate clash-verge config file: `~/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml`
  - Check current `allow-lan` and `bind-address` settings
  - If not already set, update to: `allow-lan: true`, `bind-address: "*"`
  - Verify proxy responds on LAN IP:7890 using curl

  **Must NOT do**:
  - Modify core routing rules or proxy nodes (only touch LAN access settings)
  - Restart clash-verge service (user may be actively using it for browsing)
  - Change port number (must keep 7890)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple YAML config edit + verification curl
  - **Skills**: None needed
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1, after Task 1)
  - **Blocks**: Task 3 (must verify proxy works before updating systemd)
  - **Blocked By**: Task 1 (needs $LAN_IP for testing)

  **References**:
  - clash-verge config location: `~/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml`
  - Required settings:
    ```yaml
    allow-lan: true
    bind-address: "*"  # or "0.0.0.0" - both work
    ```
  - Test command: `curl --proxy http://$LAN_IP:7890 https://www.google.com -I` (should return 200)

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Enable LAN access in clash-verge config
    Tool: Bash
    Preconditions: clash-verge config file exists, $LAN_IP is set from Task 1
    Steps:
      1. Read current config: grep "allow-lan" ~/.local/share/.../clash-verge.yaml
      2. If "allow-lan: false" or missing:
         - Backup: cp clash-verge.yaml clash-verge.yaml.backup
         - Use sed or yq to set: allow-lan: true, bind-address: "*"
      3. Wait 2 seconds (let clash-verge reload config)
      4. Test proxy: curl --max-time 10 --proxy http://$LAN_IP:7890 https://www.google.com -I
      5. Assert: HTTP status 200 or 301/302 (any successful response)
    Expected Result: curl succeeds via LAN IP proxy
    Failure Indicators: Connection refused, timeout, curl exit code != 0
    Evidence: stdout showing "HTTP/1.1 200 OK" or "HTTP/2 200"
  
  Scenario: Proxy rejects connection when allow-lan is disabled
    Tool: Bash (negative test - verify current behavior if not yet fixed)
    Preconditions: allow-lan still false (before changes)
    Steps:
      1. curl --max-time 5 --proxy http://$LAN_IP:7890 https://www.google.com 2>&1
      2. Assert: Connection refused or timeout
    Expected Result: Connection fails (confirms LAN access was disabled)
    Evidence: stderr containing "Connection refused" or timeout
  ```

  **Commit**: NO (grouped with Task 3)

---

- [ ] 3. Update nix-daemon Systemd Override

  **What to do**:
  - Backup existing override.conf: `sudo cp /etc/systemd/system/nix-daemon.service.d/override.conf{,.backup}`
  - Edit override.conf to replace `127.0.0.1` with `$LAN_IP` in proxy URLs
  - Reload systemd: `sudo systemctl daemon-reload`
  - Restart nix-daemon: `sudo systemctl restart nix-daemon`
  - Verify service is active and environment variables are updated

  **Must NOT do**:
  - Remove the override.conf file entirely (may have other settings)
  - Change nix.conf settings (only systemd service env vars)
  - Use hardcoded IP (must use the detected $LAN_IP from Task 1)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple file edit + service restart
  - **Skills**: None needed
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1, after Task 2)
  - **Blocks**: Task 4 (must complete before testing build)
  - **Blocked By**: Tasks 1, 2 (needs $LAN_IP and working proxy)

  **References**:
  - Target file: `/etc/systemd/system/nix-daemon.service.d/override.conf`
  - Current content (WRONG):
    ```
    [Service]
    Environment=HTTP_PROXY=http://127.0.0.1:7890
    Environment=HTTPS_PROXY=http://127.0.0.1:7890
    ```
  - Fixed content (template):
    ```
    [Service]
    Environment=HTTP_PROXY=http://$LAN_IP:7890
    Environment=HTTPS_PROXY=http://$LAN_IP:7890
    ```
  - Reload commands:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart nix-daemon
    systemctl status nix-daemon  # verify active
    ```

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Update systemd override with LAN IP and restart daemon
    Tool: Bash
    Preconditions: $LAN_IP is set, sudo access available, proxy verified working (Task 2)
    Steps:
      1. Backup: sudo cp /etc/systemd/system/nix-daemon.service.d/override.conf{,.backup}
      2. Create new content: echo "[Service]
         Environment=HTTP_PROXY=http://$LAN_IP:7890
         Environment=HTTPS_PROXY=http://$LAN_IP:7890" | sudo tee /etc/systemd/system/nix-daemon.service.d/override.conf
      3. Reload: sudo systemctl daemon-reload
      4. Restart: sudo systemctl restart nix-daemon
      5. Wait 2 seconds (service stabilization)
      6. Assert: systemctl is-active nix-daemon → "active"
      7. Assert: systemctl show nix-daemon -p Environment | grep "HTTP_PROXY.*$LAN_IP"
    Expected Result: nix-daemon running with LAN IP in proxy environment variables
    Failure Indicators: Service failed to start, environment vars not updated, 127.0.0.1 still present
    Evidence: Output of `systemctl status nix-daemon` showing active state + proxy env vars
  
  Scenario: Verify backup file was created
    Tool: Bash
    Preconditions: After backup command executed
    Steps:
      1. Assert: [ -f /etc/systemd/system/nix-daemon.service.d/override.conf.backup ]
      2. Assert: diff shows changes (not identical to new file)
    Expected Result: Backup file exists with old content (127.0.0.1)
    Evidence: ls output showing .backup file
  ```

  **Commit**: YES
  - Message: `fix(nix): update nix-daemon proxy to use LAN IP for sandbox builds`
  - Files: `/etc/systemd/system/nix-daemon.service.d/override.conf`
  - Pre-commit: `systemctl is-active nix-daemon` → active

---

- [ ] 4. Verify home-manager Build Success

  **What to do**:
  - Run `home-manager switch` (or `home-manager build` for safety)
  - Monitor output for Spotify package build progress
  - Verify no SSL certificate errors appear
  - Confirm build completes with exit code 0

  **Must NOT do**:
  - Skip this verification (must prove fix works end-to-end)
  - Use `nix-build` with simplified expression (must test actual home-manager workflow)
  - Accept warnings as success (must be clean build)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Command execution + output validation
  - **Skills**: None needed
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1, final task)
  - **Blocks**: None (terminal task)
  - **Blocked By**: Task 3 (needs updated nix-daemon config)

  **References**:
  - Build command: `home-manager switch` (or `home-manager build` for dry-run)
  - Success indicators:
    - Exit code: 0
    - No "SSL certificate" errors in output
    - No "cannot download spotify" messages
    - Final output: "Activating..." or "Built successfully"
  - Failure patterns to check for:
    - `curl: (16) SSL certificate`
    - `curl: (60) SSL certificate problem`
    - `error: cannot download spotify`

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: home-manager builds successfully with Spotify package
    Tool: Bash
    Preconditions: nix-daemon restarted with LAN IP proxy (Task 3), clash-verge allowing LAN (Task 2)
    Steps:
      1. Run: home-manager switch 2>&1 | tee /tmp/hm-build-log.txt
      2. Wait for completion (may take 5-15 minutes for full build)
      3. Assert: Exit code is 0 ($? -eq 0)
      4. Assert: No SSL errors: ! grep -i "SSL certificate" /tmp/hm-build-log.txt
      5. Assert: No download failures: ! grep "cannot download spotify" /tmp/hm-build-log.txt
      6. Assert: Success marker: grep -E "(Activating|generation.*created)" /tmp/hm-build-log.txt
      7. Verify Spotify installed: which spotify || ls ~/.nix-profile/bin/spotify
    Expected Result: Build completes, Spotify package successfully built and installed
    Failure Indicators: Non-zero exit, SSL errors in log, Spotify binary not found
    Evidence: /tmp/hm-build-log.txt showing successful build, `which spotify` returns path
  
  Scenario: Previous SSL error no longer occurs
    Tool: Bash (negative test - verify error is gone)
    Preconditions: After successful build
    Steps:
      1. grep "curl: (16) SSL certificate" /tmp/hm-build-log.txt
      2. Assert: Exit code 1 (pattern NOT found)
    Expected Result: Old SSL error pattern absent from new build log
    Evidence: grep exits with 1 (pattern not found)
  ```

  **Commit**: NO (verification task only)

---

- [ ] 5. (Conditional) Rollback on Failure

  **What to do**:
  - IF Task 4 fails (home-manager build errors):
    - Restore backup: `sudo cp /etc/systemd/system/nix-daemon.service.d/override.conf.backup override.conf`
    - Reload and restart: `sudo systemctl daemon-reload && sudo systemctl restart nix-daemon`
    - Document failure reason for troubleshooting
  - ELSE (if Task 4 succeeds):
    - Remove backup file: `sudo rm override.conf.backup`
    - Log success

  **Must NOT do**:
  - Rollback if build succeeds (keep the fix)
  - Delete backup before verifying success

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Conditional logic + simple file operations
  - **Skills**: None needed
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 1, conditional final step)
  - **Blocks**: None
  - **Blocked By**: Task 4 (outcome determines action)

  **References**:
  - Rollback command: `sudo cp /etc/systemd/system/nix-daemon.service.d/override.conf.backup override.conf`
  - Success cleanup: `sudo rm override.conf.backup`

  **Acceptance Criteria**:

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Rollback if build failed
    Tool: Bash
    Preconditions: Task 4 completed (regardless of success/failure)
    Steps:
      1. Check Task 4 result: if [ ! -f /tmp/hm-build-success ]; then
      2.   Rollback: sudo cp override.conf.backup override.conf
      3.   Reload: sudo systemctl daemon-reload && sudo systemctl restart nix-daemon
      4.   Log: echo "Rolled back due to build failure"
      5. else
      6.   Cleanup: sudo rm override.conf.backup
      7.   Log: echo "Fix successful, backup removed"
      8. fi
    Expected Result: System in safe state (either fixed or rolled back)
    Evidence: Log message indicating action taken
  ```

  **Commit**: NO (cleanup task only)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 3 | `fix(nix): update nix-daemon proxy to use LAN IP for sandbox builds` | `/etc/systemd/system/nix-daemon.service.d/override.conf` | `systemctl is-active nix-daemon` |

---

## Success Criteria

### Verification Commands
```bash
# 1. Check nix-daemon is running with correct proxy
systemctl is-active nix-daemon  # Expected: active
systemctl show nix-daemon -p Environment | grep HTTP_PROXY  # Expected: contains LAN IP

# 2. Test proxy from command line (simulates sandbox behavior)
LAN_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
curl --proxy http://$LAN_IP:7890 https://api.snapcraft.io -I  # Expected: 200 OK

# 3. Verify home-manager build
home-manager switch  # Expected: exit code 0, no SSL errors

# 4. Confirm Spotify installed
which spotify  # Expected: path to spotify binary
```

### Final Checklist
- [ ] All "Must Have" present:
  - [ ] Backup of original override.conf created
  - [ ] LAN IP auto-detected (not hardcoded)
  - [ ] clash-verge verified accepting LAN connections before nix-daemon restart
- [ ] All "Must NOT Have" absent:
  - [ ] sandbox=true still set (not disabled)
  - [ ] Spotify still in packages.nix (not removed)
  - [ ] No hardcoded IPs in config files
  - [ ] No global proxy env vars in shell rc files
  - [ ] No suggestion to replace clash-verge
- [ ] home-manager switch completes without errors
- [ ] Spotify package successfully built and installed
