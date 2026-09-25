# ADR-023: Design from the documentation, never from conjecture — and leave machines as found: the m5-notify-deck withdrawal

| Field | Value |
|-------|-------|
| Status | **Accepted** |
| Date | 2026-09-25 |
| Binds | organization |
| Decision makers | nlink-jp maintainers |
| Triggered by | The withdrawal of m5-notify-deck on 2026-09-25 after two days that did not converge, and the retrospective the maintainer asked for |

## Context

m5-notify-deck (lab-series, `_wip`, never published) was to make an M5Stack
BASIC a Bluetooth sub-display for a Mac: the Mac renders notifications and
status and sends them over BLE; the device's buttons act as an HID keyboard
with a key map stored on the device; a CLI, GUI and MCP server drive it. In two
days it went through an RFP, a Phase 0 measurement ADR, an accepted wire
contract, a Phase 1 implementation and on-device testing. On 2026-09-25 the
maintainer judged it a failure and withdrew it — the code was discarded:

> The main purpose is a sub-display for notifications and status, but the
> content grew far too complex and its basic behaviour as a Bluetooth device
> broke down. Pairing and PIN entry in particular pushed the internals to the
> front and did not behave like an ordinary Bluetooth device.

What went wrong, and why the rules and knowledge already in place did not stop
it:

1. **A security mechanism was built on a premise read, not observed.** The
   design refused pairing outside a pairing window through the BLE library's
   security callback — a behaviour inferred from reading the library source and
   the stack's disassembly. It was never observed. The library in fact sends a
   Security Request to every central that connects (a default nobody
   inspected), the stack then accepts the pairing without calling the callback,
   and any Mac that connected got a passkey prompt the device never answered.
   The release gate "passed" the refusal because the passkey was not displayed
   and the device dropped unencrypted links after 10 s — another defence
   producing the same observation. Two knowledge entries describe exactly this
   (testing.md: "A gate that cannot name the layer it observes has only proved
   the layer below"; "When two defences cover one failure, an observation
   explained by either is evidence for neither"). They were not consulted: designing a test was not
   recognised as a decision point, and no rule asked for a premise to be
   observed before it is relied on.
2. **The device's externally visible behaviour was never set against the
   specifications and the host OS.** Phase 1 item 7 (external platform
   constraints) was applied to throughput and memory, not to what the Bluetooth
   specifications and macOS expect of a device of this kind in each state. A
   state machine with the requirements (Core GAP/SMP, HOGP, HIDS, Apple's
   Accessory Design Guidelines) came only after the maintainer asked for it,
   more than 30 hours in; once written it exposed the deviations within hours.
   The item's examples (API limits, rate limits, UI rendering) did not read as
   covering "what the OS expects of the device".
3. **On-device trial and error had no stop condition, and the maintainer
   became the test harness.** Each fix was a flash, a manual test by the
   maintainer and a patch that added a mechanism (a persistent pairing flag, a
   10 s drop, a quiet state, nameless advertising, switching IO capabilities).
   The maintainer toggled Bluetooth, re-paired and drove two Macs many times.
   "Three of a kind → fix the class" never fired, because every symptom looked
   different.
4. **The scope buried the purpose.** The display worked early. What consumed
   the time was the HID keyboard role and the OS behaviour that comes with it
   (automatic reconnection, the Keyboard Setup Assistant, keyboard types, HOGP
   and HIDS mandatory items, Apple's keyboard rules). Nothing in planning asks
   what an OS-managed role brings along.
5. **Internals reached the user.** The device's screen told the user to delete
   "m5-notify-deck" in the Mac's settings (it cannot know which entry is its
   own); pairing depended on a hidden flag; a PIN was requested and never shown.
6. **Machine state was changed and left behind, locally and on a borrowed
   machine.** Launch Services registrations, Bluetooth permissions (TCC), a
   keyboard-type record in `/Library/Preferences`, and on the test MacBook Air a
   signed app, its logs, its registration and its permission — none announced
   beforehand, none recorded, found only because the withdrawal forced a
   clean-up. The clean-up itself erred: permissions were to be reset after the
   registrations were removed (`tccutil` resolves the bundle id through Launch
   Services, so it failed), an app placed in `/tmp` could not be resolved at
   all, and a lookup meant as a check launched the app. The leftovers were
   first called harmless; the maintainer's correction: a record left behind can
   change behaviour for whatever later matches it, and a discarded project
   leaves no trail to diagnose it by.
7. **An unobserved claim was published as knowledge.** The refusal method of
   point 1 was written to `nlink-jp/knowledge` as an instruction, and later had
   to be corrected; an over-generalisation ("re-read on every connection") was
   caught only by an independent review.
8. **Independent verification never looked outside.** Design reviews checked
   the knowledge base, memory and internal consistency. A premise contradicted
   only by a specification or by the real stack is invisible to that.

What worked: what was measured (lost write lengths on the link, notification
pacing, the backlight's response, macOS re-reading the PnP ID) was recorded
with evidence and is reusable; independent reviews found real defects; the
specification research, once done, took hours and settled the picture.

## Decision

The rule at the centre, in the maintainer's words: **development that uses an
API or a standard always checks that API's or standard's documentation; design
and implementation never proceed on conjecture.** Every failure in points 1, 2,
5 and 7 above began where a design filled a gap with a guess — the pairing
behaviour without reading the Bluetooth specifications, the library's
behaviour from a partial reading of its source.

CONVENTIONS.md changes:

1. **Development Policy — design from the documentation, not from conjecture
   (the central rule, with B).** Before designing or implementing against an
   API, a protocol or a standard, read its documentation (specification, API
   reference, platform guidelines) and name what the design relies on. Where
   the documentation is silent, or whether an implementation behaves as
   documented is uncertain — a library's defaults, a stack's callbacks, an OS's
   reactions — observe it on the real system with the actual events logged
   before relying on it; a reading of source code is a hypothesis until then.
   A test or gate names the mechanism it observes and rules out any other
   mechanism that would produce the same observation.
2. **Phase 1, item 7 — protocol and host-OS conformance (A).** A tool that
   plays a role in a protocol or appears to an OS as a device or service lists
   the governing specifications and the host OS's documented expectations,
   writes its externally visible behaviour as a state machine (state × event →
   what the OS and the user see) with each row's source, and has it reviewed
   before implementation. "Behave like an ordinary device or service of its
   kind" is the default requirement; every deviation carries a reason.
3. **Phase 1, item 3 — the cost of an OS-managed role (G).** Taking on a role
   the OS manages (keyboard/HID, audio, input methods, …) lists what OS
   behaviour comes with it and asks whether the main purpose needs it.
4. **Security — machine state is borrowed (C).** Placed in the Security
   section at the maintainer's direction, of the same rank as never committing
   protected information: an unannounced change to a machine's state is a
   security concern, not hygiene. Trying files
   anywhere, `/tmp` included, is fine. Anything that changes settings or
   registers something — local or remote — is announced first with a removal
   method that has been checked to work, recorded when made, and removed and
   verified at the end of the test (for macOS apps: permissions, then Launch
   Services, then files). "Harmless" is not a reason to leave something.
5. **Verify with an independent pass — against the specification (D).** A
   design that implements a protocol role is also checked against the fetched
   specification and the platform's guidelines, not only the knowledge base.
6. **Root cause before patch — stop on-device iteration (E).** The second
   on-device fix in the same behaviour area (connection, pairing, …) stops the
   patching and returns to the design. Making the maintainer repeat manual
   test procedures is itself treated as a sign of a design problem.
7. **Knowledge feed — evidence per claim (F).** An entry says of each claim
   whether it was measured, read in a source, or inferred; an unmeasured
   behaviour is not written as an instruction.

AGENTS.md summarises 1 and 4 among the rules most often missed. The general
lessons go to `nlink-jp/knowledge` (`development-process.md`).

## Consequences

- Planning a device or protocol project costs a state machine and a
  requirements table up front — the work that, done late here, took hours and
  would have prevented days.
- Some tests grow an instrumentation step (logging the events a mechanism
  depends on) before they can count.
- Using a borrowed machine or changing system state takes a sentence of
  announcement and a removal plan; the clean-up happens per test, not at the
  end of a project.
- None of this is mechanically enforced; `check-org.sh` cannot see a missing
  state machine or an unannounced permission. Revisit if the pattern recurs.

## Alternatives considered

| Alternative | Why not |
|---|---|
| Record the lessons only in knowledge | The failures were not missing knowledge — two applicable entries existed and were not consulted. The gap was in when the rules make one look. |
| A project-level ADR in m5-notify-deck | The project is withdrawn and deleted, and the lessons bind every project that talks to a device, a protocol or a borrowed machine. |
| Forbid device/protocol projects until tooling exists | The failure was process, not domain; the measurements that were done held up. |
| A mechanical gate (e.g. require `docs/*/states.md` for BLE projects) | Only the presence of a file could be checked, not whether its rows were set against the specification. |

## References

- `nlink-jp/knowledge` embedded.md: "The Arduino-ESP32 BLE library asks every
  connecting central to pair, by default"; "Before building a BLE HID
  peripheral: what the specs require in each state" (2026-09-25).
- `nlink-jp/knowledge` testing.md: "A gate that cannot name the layer it
  observes has only proved the layer below"; "When two defences cover one
  failure, an observation explained by either is evidence for neither".
- `nlink-jp/knowledge` development-process.md: the entries added with this ADR.
