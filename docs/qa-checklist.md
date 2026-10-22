# Shakti: hardware QA checklist

These are the checks automated tests can't cover. Run them on real phones running Android 12, 13 and 14, with a SIM inserted and a test contact whose phone you have with you.

Record each run as: device / Android version / pass or fail / notes.

## Triggers
- [ ] **Power x3, screen on.** Press power 3 times quickly. The countdown opens within 1 s.
- [ ] **Power x3, screen locked and in a pocket.** The phone vibrates twice. The SOS screen appears over the lock screen, or a full-screen notification does (Android 14).
- [ ] **Power x3 after a reboot**, with the guard enabled. The guard notification is back and the trigger works.
- [ ] **Permission audit:** run `scripts/verify_android_permissions.py` on the APK. No accessibility service, notification listener or SMS-reading permissions; volume keys retain normal behavior.
- [ ] **Shake.** A hard shake for about 1 s triggers. Walking, running up stairs and putting the phone on a table do **not**. Drop the phone onto a bed 5 times: at most 1 false trigger.
- [ ] **Voice phrase** ("shakti help") with the app open, in a quiet room and in street noise.
- [ ] **Escort timer expiry** with the screen off. The SOS fires.
- [ ] **Decoy PIN.** The notes UI shows, with no sound or vibration. The contact still receives the SOS SMS.

## Dispatch
- [ ] **Airplane mode on with calling re-enabled** (Wi-Fi off, mobile data off). The SMS arrives with a maps link. The cloud channel shows "Will send when back online".
- [ ] Turn data back on during an active SOS. The Telegram alert arrives and the breadcrumbs sync.
- [ ] **Latency.** Measure from the end of the countdown to SMS delivery, 5 runs. Target: SMS handed to the carrier in under 1.2 s. Delivery depends on the carrier.
- [ ] **Location off.** The SMS says "Location unavailable" and the SOS still completes.
- [ ] **No contacts.** The home screen warns, and the SOS checklist shows why SMS failed.
- [ ] The guardian opens the tracker link. The map updates about every 10 s and "I'm safe" turns it green.
- [ ] The audio evidence file appears in the vault and plays back. Reading the raw `.enc` file with a file manager shows gibberish.

## Security and privacy
- [ ] Screenshots are blocked and the recents thumbnail is blank.
- [ ] The app locks after 60 s in the background. 5 wrong PINs trigger a 30 s lockout.
- [ ] An `adb backup` / device transfer does not include the evidence or the database.

## Performance
- [ ] Cold start is under 1.5 s (`adb shell am start -W`). Record TotalTime for 5 runs.
- [ ] **24 h battery** with the guard on and no active escort. Target: under 2.5%. Use Settings → Battery → App usage.
- [ ] Release APK size: record `app-release.apk`. Target: under 24 MB per ABI (`flutter build apk --split-per-abi`).
