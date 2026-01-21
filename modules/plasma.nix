{ config, pkgs, lib, ... }:

{
  home.activation.restartPlasma = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    LOG="$HOME/.cache/hm-restart-plasma.log"
    mkdir -p "$(dirname "$LOG")"

    # Log rotation: keep last 100 lines if file is too large
    if [ -f "$LOG" ] && [ $(wc -l < "$LOG") -gt 200 ]; then
      tail -n 100 "$LOG" > "$LOG.tmp"
      mv "$LOG.tmp" "$LOG"
    fi

    date +"[%F %T] start restartPlasma" >> "$LOG"

    if [ "''${HM_PLASMA_RESTART:-0}" != "1" ]; then
      date +"[%F %T] HM_PLASMA_RESTART not set, skip" >> "$LOG"
      exit 0
    fi

    # Prefer systemd user service if present
    if systemctl --user list-units --type=service 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q plasma-plasmashell.service; then
      systemctl --user restart plasma-plasmashell.service >>"$LOG" 2>&1 || true
      date +"[%F %T] systemctl restart plasma-plasmashell.service done" >> "$LOG"
      exit 0
    fi

    PGREP=${pkgs.procps}/bin/pgrep
    if $PGREP plasmashell >/dev/null 2>&1; then
      # pick a running plasmashell binary path
      PID=$(${pkgs.procps}/bin/pgrep -n plasmashell || true)
      PLASMA_BIN=""
      if [ -n "$PID" ] && [ -e "/proc/$PID/exe" ]; then
        PLASMA_BIN="$(readlink -f /proc/$PID/exe || true)"
      fi
      if [ -z "$PLASMA_BIN" ] && [ -x /usr/bin/plasmashell ]; then
        PLASMA_BIN=/usr/bin/plasmashell
      fi

      if [ -n "$PLASMA_BIN" ]; then
        # Kill all plasmashell processes
        ${pkgs.procps}/bin/pkill plasmashell || true

        # Wait for processes to fully terminate (with timeout)
        for i in {1..10}; do
          if ! ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
            break
          fi
          sleep 0.2
        done

        # Force kill if still running
        if ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
          ${pkgs.procps}/bin/pkill -9 plasmashell || true
          sleep 0.5
        fi

        # Use setsid to completely detach plasmashell from the parent session
        # This prevents SIGHUP when the activation script exits
        # The --replace flag ensures only one instance runs
        ${pkgs.util-linux}/bin/setsid "$PLASMA_BIN" --replace </dev/null >>"$LOG" 2>&1 &

        # Verify it started successfully
        sleep 1
        if ${pkgs.procps}/bin/pgrep plasmashell >/dev/null 2>&1; then
          date +"[%F %T] plasmashell restarted successfully with setsid" >> "$LOG"
        else
          date +"[%F %T] WARNING: plasmashell failed to start" >> "$LOG"
        fi
      else
        date +"[%F %T] plasmashell binary not found for --replace" >> "$LOG"
      fi
    else
      date +"[%F %T] plasmashell not running, skip" >> "$LOG"
    fi
  '';
}
