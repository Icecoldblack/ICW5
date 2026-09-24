# Activity 05 Test Log

**Student:** Uyiosa Nehikhuere
**Device / emulator:** Pixel 5 emulator, Android 17 (API 37). Automated cases run with `flutter test` (Flutter 3.47.2); raw output in `test_output.txt`.
**Build tested:** debug (`flutter run`) and release (`Nehikhuere_Uyiosa_Activity05.apk`)

> Fill the **Observed ending value**, **Observed message** and **Pass/Fail** columns from your own run. The "expected" text below is traced from main.dart so you know exactly what you should see. The rubric does not accept expected only results.

## Required cases

| # | Case | Start value | Increment | Action | Expected ending value | Expected message / feedback | History after | Observed ending value | Observed message | Pass/Fail | Note |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Lower boundary | 0 | 1 | Press **Decrease by 1** | 0 | SnackBar: "Decrease by 1 blocked: already at the min of 0. You can Increase or move the slider." | none (unchanged) | 0 (widget test) | SnackBar: "Decrease by 1 blocked: already at the min of 0. You can Increase or move the slider." (widget test) | Pass | History stayed "none". |
| 2 | Upper boundary | 100 (drag slider to 100) | 1 | Press **Increase by 1** | 100 | SnackBar: "Increase by 1 blocked: already at the max of 100. You can Decrease, Undo, or Reset." | unchanged | 100 (widget test) | SnackBar: "Increase by 1 blocked: already at the max of 100. You can Decrease, Undo, or Reset." (widget test) | Pass | Slider drag to 100 added one entry (History: 0); the rejected press added none. |
| 3 | Overshoot | 80 | 30 | Press **Increase by 30** | 80 | SnackBar: "Increase by 30 blocked: 110 is above the max of 100. Still at 80. Use an increment of 20 or less." | unchanged | 80 (widget test) | SnackBar: "Increase by 30 blocked: 110 is above the max of 100. Still at 80. Use an increment of 20 or less." (widget test) | Pass | Same message also seen on the emulator (shots/q2_boundary_snackbar.png). |
| 4a | Invalid input: blank | any | 5 | Select all in field, delete | same | Field error: "Empty. Enter a whole number from 1 to 100. Still using 5." | unchanged | same, 0 (widget test) | Field error: "Empty. Enter a whole number from 1 to 100. Still using 5." (widget test) | Pass | Button still read "Increase by 5". |
| 4b | Invalid input: -2 | any | 5 | Type `-2` | same | Field error: "Must be at least 1. Enter a whole number from 1 to 100. Still using 5." | unchanged | same, 0 (widget test) | Field error: "Must be at least 1. Enter a whole number from 1 to 100. Still using 5." (widget test) | Pass | Button still read "Increase by 5". |
| 4c | Invalid input: 2.5 | any | 5 | Paste `2.5` (see note) | same | Field error: "No decimals. Enter a whole number from 1 to 100. Still using 5." | unchanged | same, 0 (widget test) | Field error: "No decimals. Enter a whole number from 1 to 100. Still using 5." (widget test) | Pass | The test replaces the whole field at once (like a paste), so the keystroke issue in the note did not apply. |
| 4d | Invalid input: hello | any | 5 | Type `hello` | same | Field error: ""hello" is not a number. Use digits only, 1 to 100. Still using 5." | unchanged | same, 0 (widget test) | Field error: ""hello" is not a number. Use digits only, 1 to 100. Still using 5." (widget test) | Pass | Same message also seen on the emulator (shots/q2_invalid_input.png). |
| 5 | Undo chain | 0 | 5 | Increase, Increase, drag slider to 40 and release, then Undo x4 | 40 → 10 → 5 → 0 → 0 | 4th Undo: "Nothing to undo. 0 is the earliest value." No crash | [0,5,10] → [0,5] → [0] → none → none | 40 → 10 → 5 → 0 → 0 (widget test) | 4th Undo: "Nothing to undo. 0 is the earliest value." No exception (widget test) | Pass | History matched [0,5,10] → [0,5] → [0] → none → none. |
| 6 | Slider consistency | 10 | 5 | Drag slider to 40, release, then Undo | 10 | none | after drag: [..,10]; after undo: 10 removed | 10 (widget test) | none (widget test) | Pass | Drag added exactly one entry (History: 0, 5, 10); after Undo the number was 10, `Slider.value` was 10.0 and History was 0, 5. |

**Note for 4c:** the field validates on every keystroke. If you type `2`, `.`, `5` one at a time, `2` is a valid value on its own, so the increment becomes 2 before the `.` arrives and the error then says "Still using 2". Paste `2.5` (or type it into an empty field and read the message) to test the case cleanly. If you see this during testing, record it here as your correction note; it is a true observation about keystroke validation.

**Corrections observed during testing:**
- First test run: 4 tests failed because the test looked up the counter with `find.text('100')`, which also matched the increment field holding "100". The test was wrong, not the app; the finder was changed to target only the counter display, and all tests then passed with no app changes.
- On the emulator, deleting "30" one character at a time passed through "3", which is valid, so the increment silently became 3 and a later `hello` error said "Still using 3". This matches the keystroke note above: every keystroke is validated.

## Release APK recheck (after `flutter build apk --release` and install)

| Case | Action | Expected | Observed | Pass/Fail |
|---|---|---|---|---|
| Upper boundary | Slider to 100, press Increase | Stays 100, max message shows | Reached 100 with increment 100 (not the slider), then pressed Increase by 100: stayed 100, History: 0, SnackBar "Increase by 100 blocked: already at the max of 100. You can Decrease, Undo, or Reset." (shots/release_upper_boundary.png) | Pass |
| Undo chain | 3 valid changes, Undo x4 | Reverse order restore, 4th Undo shows "Nothing to undo" | Increment 5: Increase, Increase, slider to 40 (History: 0, 5, 10). Undo x4 showed 10, 5, 0, 0; 4th Undo SnackBar "Nothing to undo. 0 is the earliest value." No crash (shots/release_undo_chain_end.png) | Pass |

## Color rule spot check

| Value | Expected color | Observed |
|---|---|---|
| 0 | red | red (widget test) |
| 30 | black | black (widget test) |
| 50 | black | black (widget test) |
| 51 | green | green (widget test) |
