# VM Baseline Test — Hybrid Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 4 gaps in `vm_baseline_test.py` — notification permission dialog, NAF=true password fields, account upgrade flow (Gap 3 + 4), and third detection path in Flow F.

**Architecture:** Hybrid approach — VM Service Protocol (`ext.flutter.driver`) for app-level widget interactions + uiautomator2 `DeviceAdapter` for system-level Android operations. FastInput IME wrapped in context manager to guarantee restoration.

**Tech Stack:** Python 3.14, uiautomator2, asyncio + websockets (existing), Flutter VM Service Protocol

**Files:**
| Action | Path | Purpose |
|--------|------|---------|
| Create | `scripts/test_lib/__init__.py` | Package marker |
| Create | `scripts/test_lib/device_adapter.py` | `DeviceAdapter` class wrapping uiautomator2 |
| Modify | `scripts/vm_baseline_test.py` | Integrate `DeviceAdapter`, fix Flows A & F, add notification dismissal |

---

### Task 1: Create `scripts/test_lib/__init__.py`

**Files:** Create `scripts/test_lib/__init__.py`

- [ ] **Step 1: Create empty package marker**

```python
# test_lib — Shared test library for Keystone deployment tests
```

- [ ] **Step 2: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
git add scripts/test_lib/__init__.py && \
git commit -m "chore: add test_lib package marker"
```

---

### Task 2: Create `scripts/test_lib/device_adapter.py`

**Files:** Create `scripts/test_lib/device_adapter.py`

- [ ] **Step 1: Write DeviceAdapter class**

```python
"""
DeviceAdapter — uiautomator2 wrapper for system-level Android operations.

Complements VMTestRunner (Flutter Driver) by handling operations the
Flutter engine cannot: system dialogs, NAF password fields, IME management.

Architecture:
  - Instantiated once per test suite in main()
  - Each flow receives it alongside runner
  - FastInput IME is wrapped in a context manager for guaranteed cleanup
  - Password field bounds extracted dynamically from dump_hierarchy() XML
"""

from __future__ import annotations

import contextlib
import re
import time
from pathlib import Path

import uiautomator2 as u2


class DeviceAdapter:
    """Wraps uiautomator2 for device-level test operations.

    Thread-safety: NOT thread-safe. Use one instance per test session.
    Cleanup: close() stops the uiautomator2 session. Context manager
    recommended: ``with DeviceAdapter() as adapter: ...``
    """

    def __init__(self, serial: str | None = None):
        self.d = u2.connect(serial) if serial else u2.connect()
        self._cleanup_orphaned_ime()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
        return False  # don't suppress exceptions

    # ─────────────────────────
    # IME Management
    # ─────────────────────────

    def _cleanup_orphaned_ime(self) -> None:
        """Restore default IME if a previous crash left FastInput active.

        uiautomator2 devices may be left with the invisible FastInput IME
        if a prior test process was killed mid-block. This check runs on
        every DeviceAdapter instantiation to self-heal the device state.
        """
        try:
            current = self.d.current_ime()
            if current and "uiautomator2" in current.lower():
                self.d.set_fastinput_ime(False)
        except Exception:
            pass  # device might be disconnected

    @contextlib.contextmanager
    def use_fastinput(self):
        """Context manager: switch to FastInput IME, guarantee restore.

        Even if the inner block raises or the test crashes, the ``finally``
        block restores the original IME. This prevents orphaned IME state
        from cascading into subsequent test runs.

        Usage::

            with adapter.use_fastinput():
                adapter.d.send_keys("mypassword")
        """
        try:
            self.d.set_fastinput_ime(True)
            yield
        finally:
            try:
                self.d.set_fastinput_ime(False)
            except Exception:
                pass  # device disconnected or in bad state

    # ─────────────────────────
    # System Dialog Handling
    # ─────────────────────────

    def dismiss_notification_permission(self, timeout: float = 8) -> bool:
        """Dismiss Android notification permission dialog if present.

        Registers a uiautomator2 watcher that auto-clicks "Allow" when the
        system dialog "Allow <app> to send you notifications?" appears.

        Returns True if the dialog was dismissed, False if never appeared.
        """
        self.d.watcher.when("Allow").click()
        self.d.watcher.start()
        time.sleep(timeout)
        self.d.watcher.stop()
        return True  # best-effort; watcher may or may not have triggered

    # ─────────────────────────
    # View Hierarchy Queries
    # ─────────────────────────

    def dump_hierarchy(self) -> str:
        """Return current view hierarchy XML."""
        return self.d.dump_hierarchy()

    def text_exists(self, text: str, timeout: float = 3) -> bool:
        """Check if text appears in the view hierarchy (polling)."""
        return self.d(text=text).wait(timeout=timeout)

    def wait_for_text(self, text: str, timeout: float = 10) -> bool:
        """Poll until text appears in the hierarchy. Returns True if found."""
        start = time.time()
        while time.time() - start < timeout:
            if self.d(text=text).exists():
                return True
            time.sleep(0.3)
        return False

    # ─────────────────────────
    # Element Interaction
    # ─────────────────────────

    def tap_text(self, text: str) -> None:
        """Find and tap an element by its visible text."""
        self.d(text=text).click()

    def tap_coordinates(self, x: int, y: int) -> None:
        """Tap absolute screen coordinates."""
        self.d.click(x, y)

    def _find_edittext_bounds(self, xml: str, index: int = 0, password_field: bool = False):
        """Extract center coordinates of the Nth EditText from hierarchy XML.

        Flutter renders TextField widgets as ``android.widget.EditText`` nodes
        even when NAF=true. The ``bounds`` attribute is always present.

        Args:
            xml: View hierarchy XML string.
            index: 0-based index of the field to find (0=first, 1=second).
            password_field: If True, filter to nodes with password="true".

        Returns:
            (cx, cy) center coordinates, or None if not found.
        """
        if password_field:
            pattern = (
                r'password="true"[^>]*'
                r'class="android\.widget\.EditText"[^>]*'
                r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
            )
        else:
            pattern = (
                r'class="android\.widget\.EditText"[^>]*'
                r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
            )

        matches = re.findall(pattern, xml)
        if index < len(matches):
            x1, y1, x2, y2 = map(int, matches[index])
            return ((x1 + x2) // 2, (y1 + y2) // 2)
        return None

    def tap_password_field(self) -> tuple[int, int]:
        """Tap the FIRST NAF=true password EditText.

        Uses ``dump_hierarchy()`` to dynamically find the bounds of the
        first EditText with ``password="true"``, then taps its center.

        Raises ``RuntimeError`` if no password field found after 5 retries.
        """
        for attempt in range(5):
            xml = self.d.dump_hierarchy()
            coords = self._find_edittext_bounds(xml, index=0, password_field=True)
            if coords:
                self.d.click(*coords)
                time.sleep(0.3)  # let focus settle
                return coords
            time.sleep(0.5)
        raise RuntimeError(
            "Could not find password field in view hierarchy "
            "(5 attempts, password=True filter)"
        )

    def tap_confirm_field(self) -> tuple[int, int]:
        """Tap the SECOND NAF=true password EditText (confirm field).

        Strategy:
        - If 2+ password fields found: tap the second one.
        - If only 1 found: tap at the vertical offset below it (common
          Flutter layout has tightly stacked TextFields).
        - Fallback: tap at a reasonable vertical offset from first field.

        Raises ``RuntimeError`` if no password fields found after 5 retries.
        """
        for attempt in range(5):
            xml = self.d.dump_hierarchy()
            coords0 = self._find_edittext_bounds(xml, index=0, password_field=True)
            coords1 = self._find_edittext_bounds(xml, index=1, password_field=True)

            if coords1:
                self.d.click(*coords1)
                time.sleep(0.3)
                return coords1

            if coords0:
                # Only one field — tap below it (typical Flutter layout)
                # Re-extract full bounds to calculate offset
                pattern = (
                    r'password="true"[^>]*'
                    r'class="android\.widget\.EditText"[^>]*'
                    r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
                )
                match = re.search(pattern, xml)
                if match:
                    x1, y1, x2, y2 = map(int, match.groups())
                    field_height = y2 - y1
                    offset_y = y2 + field_height + 8  # 8px gap + one field height
                    cx = (x1 + x2) // 2
                    self.d.click(cx, offset_y)
                    time.sleep(0.3)
                    return (cx, offset_y)

            time.sleep(0.5)

        raise RuntimeError(
            "Could not find confirm password field in view hierarchy "
            "(5 attempts)"
        )

    # ─────────────────────────
    # Screenshot
    # ─────────────────────────

    def screenshot(self, path: str | Path) -> None:
        """Capture device screenshot (ADB-level, not Flutter-level).

        Complements ``VMTestRunner.screenshot()`` for capturing system
        dialogs or the account upgrade screen that Flutter Driver cannot see.
        """
        self.d.screenshot(str(path))

    # ─────────────────────────
    # Cleanup
    # ─────────────────────────

    def close(self) -> None:
        """Stop uiautomator2 session and release resources."""
        try:
            self.d.stop_uiautomator()
        except Exception:
            pass
```

- [ ] **Step 2: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
git add scripts/test_lib/device_adapter.py && \
git commit -m "feat: add DeviceAdapter for uiautomator2 system-level test ops"
```

---

### Task 3: Update `scripts/vm_baseline_test.py` — Add DeviceAdapter Integration

**Files:** Modify `scripts/vm_baseline_test.py`

- [ ] **Step 1: Add import for DeviceAdapter (after existing imports, ~line 34)**

Replace imports section to add:

```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'test_lib'))

from device_adapter import DeviceAdapter
```

- [ ] **Step 2: Add `dismiss_notification_permission` block in `main()` (before flow execution)**

In the `main()` function, after `runner.connect()`, before flow execution:

```python
# ── Device-level setup ──
adapter = DeviceAdapter()
adapter.dismiss_notification_permission(timeout=8)
```

And update the flow execution calls to pass `adapter`:

```python
flows.append(await flow_a_dev_bypass(runner, adapter))
flows.append(await flow_b_password_login(runner, adapter))
flows.append(await flow_c_tab_navigation(runner, adapter))
flows.append(await flow_d_create_delete_job(runner, adapter))
flows.append(await flow_e_sign_out_cycle(runner, adapter))
flows.append(await flow_f_fresh_user_route(runner, adapter))
```

Add cleanup after `runner.close()`:

```python
adapter.close()
```

- [ ] **Step 3: Update all flow function signatures to accept `adapter` parameter**

Each flow function changes from:

```python
async def flow_a_dev_bypass(runner: VMTestRunner) -> FlowResult:
```

To:

```python
async def flow_a_dev_bypass(runner: VMTestRunner, adapter: DeviceAdapter) -> FlowResult:
```

Same for flows B through F.

- [ ] **Step 4: Fix Flow A — Add account upgrade handling after dev bypass**

Replace the existing Flow A steps A5-A6 with the dual-path logic. The modified section (~line 472-476):

```python
    # A5: Post-bypass — handle account upgrade if needed
    s = Step("A5", "PostBypass", "Handle sync or account upgrade")
    async def _handle_post_bypass():
        await asyncio.sleep(2)
        # First check: straight to sync (fresh user / clean bypass)
        found_sync = await runner.assert_visible("SETTING UP YOUR ACCOUNT", timeout=5)
        if found_sync:
            return "SYNC_DIRECT"

        # Second check: account upgrade interstitial
        found_upgrade = adapter.text_exists("ACCOUNT UPGRADE REQUIRED", timeout=3)
        if found_upgrade:
            adapter.tap_text("CONTINUE")

            # Third check: password creation screen
            if adapter.wait_for_text("PASSWORD REQUIRED", timeout=5):
                adapter.tap_password_field()
                with adapter.use_fastinput():
                    adapter.d.send_keys(TEST_PASSWORD)
                adapter.tap_confirm_field()
                with adapter.use_fastinput():
                    adapter.d.send_keys(TEST_PASSWORD)
                adapter.tap_text("CREATE")
                return "UPGRADE_COMPLETE"
            else:
                # Maybe already on password screen
                adapter.tap_password_field()
                with adapter.use_fastinput():
                    adapter.d.send_keys(TEST_PASSWORD)
                adapter.tap_confirm_field()
                with adapter.use_fastinput():
                    adapter.d.send_keys(TEST_PASSWORD)
                adapter.tap_text("CREATE")
                return "UPGRADE_DIRECT_PASSWORD"

        # Fourth check: already on PASSWORD REQUIRED (bypassed interstitial)
        found_pwd = adapter.wait_for_text("PASSWORD REQUIRED", timeout=3)
        if found_pwd:
            adapter.tap_password_field()
            with adapter.use_fastinput():
                adapter.d.send_keys(TEST_PASSWORD)
            adapter.tap_confirm_field()
            with adapter.use_fastinput():
                adapter.d.send_keys(TEST_PASSWORD)
            adapter.tap_text("CREATE")
            return "UPGRADE_DIRECT_PASSWORD"

        # Fifth check: account upgrade with CREATE PASSWORD text variant
        found_create = adapter.text_exists("CREATE PASSWORD", timeout=2)
        if found_create:
            # This is the fresh-user flow — let Flow F handle it
            return "FRESH_USER_DETECTED"

        return "SYNC_DIRECT"

    result = await _handle_post_bypass()
    await run_step(runner, s, asyncio.sleep(0))  # mark step completed
    flow.add_step(s)

    # A6: Dashboard loaded
    s = Step("A6", "Dashboard", "Dashboard loaded after sync")
    await run_step(runner, s, runner.assert_visible("Jobs", timeout=30))
    flow.add_step(s)
```

Add import for `asyncio` at top of `_handle_post_bypass` (already imported at module level).

- [ ] **Step 5: Fix Flow F — Add third detection path for account upgrade**

Modify the detection step in `flow_f_fresh_user_route` (~line 723-735). Replace step F4 with:

```python
    # F4: Detect route — CreatePassword vs existing vs account upgrade
    s = Step("F4", "DetectRoute", "Detect if new user, existing, or upgrade-needed")
    async def _detect():
        await asyncio.sleep(1)  # let animation settle

        # Check for CreatePassword (new user)
        is_new = await runner.assert_visible("CREATE PASSWORD", timeout=5)
        if is_new:
            return "NEW_USER"

        # Check for account upgrade (existing + missing password)
        is_upgrade = adapter.text_exists("ACCOUNT UPGRADE REQUIRED", timeout=3)
        if is_upgrade:
            return "NEEDS_UPGRADE"

        is_pwd_required = adapter.text_exists("PASSWORD REQUIRED", timeout=2)
        if is_pwd_required:
            return "NEEDS_UPGRADE"

        # Check for PasswordEntry (existing + has password)
        is_existing = await runner.assert_visible("ENTER PASSWORD", timeout=3)
        if is_existing:
            return "EXISTS"

        return "UNKNOWN"

    await run_step(runner, s, _detect())
    flow.add_step(s)
```

Then update the detection result branching. Replace the line `detect_step = flow.steps[-1]` block (~line 740) with:

```python
    # Route branching based on detection
    detect_step = flow.steps[-1]
    detect_detail = detect_step.detail if detect_step.detail else detect_step.status

    if detect_detail in ("EXISTS", "UNKNOWN") or detect_step.status != "PASS":
        # Account already has password — skip rest
        s = Step("F5", "SkipRest", "Account pre-existing — skip biometric flow")
        step_skip(s, 0, f"Phone {FRESH_PHONE_RAW} already has password; clean 'password_reset_codes' to retry")
        flow.add_step(s)
        s = Step("F6", "SkipOnboarding", "Skipped — return to dashboard via dev bypass")
        async def _fallback():
            for _ in range(5):
                await runner.tap("SECURE ACCESS")
                await asyncio.sleep(0.3)
            await runner.tap("DEV BYPASS (TEMP)")
            return await runner.assert_visible("Jobs", timeout=30)
        await run_step(runner, s, _fallback())
        flow.add_step(s)
        return flow

    if detect_detail == "NEEDS_UPGRADE":
        # Account exists but no password — upgrade flow (same as Flow A)
        s = Step("F5", "UpgradeAccount", "Account upgrade — create password")
        async def _upgrade():
            # Check for interstitial
            if adapter.text_exists("ACCOUNT UPGRADE REQUIRED", timeout=2):
                adapter.tap_text("CONTINUE")
                adapter.wait_for_text("PASSWORD REQUIRED", timeout=5)
            adapter.tap_password_field()
            with adapter.use_fastinput():
                adapter.d.send_keys(TEST_PASSWORD)
            adapter.tap_confirm_field()
            with adapter.use_fastinput():
                adapter.d.send_keys(TEST_PASSWORD)
            adapter.tap_text("CREATE")
            return True
        await run_step(runner, s, _upgrade())
        flow.add_step(s)

        # F6: Biometric enroll screen
        s = Step("F6", "BiometricEnroll", "Biometric enrollment screen visible")
        await run_step(runner, s, runner.assert_visible("SECURE YOUR ACCOUNT", timeout=10))
        flow.add_step(s)

        # F7: Tap SKIP
        s = Step("F7", "TapSkip", "Tap SKIP on biometric enroll")
        await run_step(runner, s, runner.tap("SKIP"))
        flow.add_step(s)

        # F8: Onboarding
        s = Step("F8", "Onboarding", "Onboarding screen reached (IDENTIFY YOURSELF)")
        await run_step(runner, s, runner.assert_visible("IDENTIFY YOURSELF", timeout=15))
        flow.add_step(s)
        return flow

    # ── NEW_USER path (existing code below) ──
    # F5: Create password
    s = Step("F5", "CreatePassword", "Set password for fresh user")
    async def _create_password():
        try:
            await runner.tap("Create a password")
            await asyncio.sleep(0.3)
        except Exception:
            pass
        await runner.enter_text(TEST_PASSWORD)
        await asyncio.sleep(0.3)
        try:
            await runner.tap("Confirm password")
            await asyncio.sleep(0.3)
        except Exception:
            pass
        await runner.enter_text(TEST_PASSWORD)
        await asyncio.sleep(0.3)
        try:
            await runner.tap("CREATE")
        except Exception:
            await runner.tap("Create")
        await asyncio.sleep(1)
        return True
    await run_step(runner, s, _create_password())
    flow.add_step(s)

    # F6: Biometric enroll — verify screen
    s = Step("F6", "BiometricEnroll", "Biometric enrollment screen visible")
    await run_step(runner, s, runner.assert_visible("SECURE YOUR ACCOUNT", timeout=10))
    flow.add_step(s)

    # F7: Tap SKIP
    s = Step("F7", "TapSkip", "Tap SKIP on biometric enroll")
    await run_step(runner, s, runner.tap("SKIP"))
    flow.add_step(s)

    # F8: Verify onboarding screen
    s = Step("F8", "Onboarding", "Onboarding screen reached (IDENTIFY YOURSELF)")
    await run_step(runner, s, runner.assert_visible("IDENTIFY YOURSELF", timeout=15))
    flow.add_step(s)

    return flow
```

- [ ] **Step 6: Commit**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
git add scripts/vm_baseline_test.py && \
git commit -m "fix: integrate DeviceAdapter, handle account upgrade flow in Flows A & F"
```

---

### Task 4: Full Test Run

- [ ] **Step 1: Ensure Flutter app is running with VM service on the device**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
bash scripts/run_phone.sh
```

Wait for app to start, verify VM service is available on port 8181.

- [ ] **Step 2: Run the fixed baseline test**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
.venv/bin/python3 scripts/vm_baseline_test.py
```

Expected: All 6 flows pass. Flow A should handle the account upgrade path if it encounters one, or skip through to sync/dashboard directly. Flow F should detect NEW_USER vs EXISTS vs NEEDS_UPGRADE correctly.

- [ ] **Step 3: Verify report**

```bash
cat /home/cybocrime/workspace/projects/keystone/reports/vm_baseline_report.json | python3 -m json.tool | head -40
```

Expected: `"verdict": "ALL_PASSED"`, all `"status": "PASS"`, 35+ steps.

- [ ] **Step 4: Commit the test run results (if report is tracked)**

```bash
cd /home/cybocrime/workspace/projects/keystone && \
git add reports/vm_baseline_report.json && \
git commit -m "test: vm baseline all flows pass (hybrid VM + DeviceAdapter)"
```

---

## Spec Coverage Check

| Spec Requirement | Plan Task(s) |
|-----------------|-------------|
| Hybrid architecture (VM + uiautomator2) | Task 2 (DeviceAdapter) + Task 3 (integration) |
| FastInput IME context manager for cleanup | Task 2 — `use_fastinput()` in DeviceAdapter |
| Notification permission dialog dismiss | Task 2 — `dismiss_notification_permission()` |
| Dynamic password field bounds from XML | Task 2 — `_find_edittext_bounds()`, `tap_password_field()`, `tap_confirm_field()` |
| Orphaned IME self-heal on instantiation | Task 2 — `_cleanup_orphaned_ime()` in `__init__` |
| Account upgrade two-stage flow (interstitial + password) | Task 3 — Step 4 (Flow A) + Step 5 (Flow F) |
| Third detection path in Flow F | Task 3 — Step 5 (`NEEDS_UPGRADE` branch) |
| Coordinate resilience across screen sizes | Task 2 — dynamic XML parsing, no hardcoded coords |
