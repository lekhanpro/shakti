"""One-off generator for placeholder screens so the router compiles before
feature work lands. Each feature owner replaces its file wholesale."""
import os

STUBS = {
    "onboarding/presentation/onboarding_screen.dart": ("OnboardingScreen", "Welcome"),
    "lock/presentation/lock_screen.dart": ("LockScreen", "Unlock"),
    "lock/presentation/decoy_notes_screen.dart": ("DecoyNotesScreen", "Notes"),
    "home/presentation/home_screen.dart": ("HomeScreen", "Shield"),
    "safety_map/presentation/safety_map_screen.dart": ("SafetyMapScreen", "Safety map"),
    "escort/presentation/escort_screen.dart": ("EscortScreen", "Walk with me"),
    "ai_guard/presentation/ai_guard_screen.dart": ("AiGuardScreen", "AI Guardian"),
    "settings/presentation/settings_screen.dart": ("SettingsScreen", "Settings"),
    "panic/presentation/sos_screen.dart": ("SosScreen", "SOS"),
    "contacts/presentation/contacts_screen.dart": ("ContactsScreen", "Trusted contacts"),
    "de_escalation/presentation/fake_call_screen.dart": ("FakeCallScreen", "Fake call"),
    "de_escalation/presentation/siren_screen.dart": ("SirenScreen", "Siren"),
    "evidence_vault/presentation/evidence_screen.dart": ("EvidenceScreen", "Evidence vault"),
    "ai_guard/presentation/fir_screen.dart": ("FirScreen", "FIR draft"),
    "settings/presentation/safe_places_screen.dart": ("SafePlacesScreen", "Safe places"),
    "panic/presentation/history_screen.dart": ("HistoryScreen", "Incident history"),
}

TEMPLATE = """import 'package:flutter/material.dart';

class {cls} extends StatelessWidget {{
  const {cls}({{super.key}});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('{title}')), body: const SizedBox.shrink());
}}
"""

root = os.path.join(os.path.dirname(__file__), "..", "lib", "features")
for rel, (cls, title) in STUBS.items():
    path = os.path.join(root, rel)
    if os.path.exists(path):
        continue
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(TEMPLATE.format(cls=cls, title=title))
    print("stub", rel)
