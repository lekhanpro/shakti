/// All user-tunable behaviour. Persisted as JSON in the local key/value table.
class SafetySettings {
  const SafetySettings({
    this.onboardingComplete = false,
    this.userName = '',
    this.bloodGroup = '',
    this.medicalNotes = '',
    this.countdownSeconds = 5,
    this.sirenOnSos = true,
    this.recordAudio = true,
    this.shakeTrigger = true,
    this.powerTrigger = true,
    this.voiceTrigger = false,
    this.voicePhrases = const ['shakti help', 'help me now'],
    this.stealthMode = false,
    this.secureScreen = true,
    this.biometricUnlock = false,
    this.lockTimeoutSeconds = 60,
    this.cloudEnabled = true,
    this.telegramChatId = '',
    this.fakeCallerName = 'Amma',
    this.fakeCallDelaySeconds = 10,
  });

  final bool onboardingComplete;
  final String userName;
  final String bloodGroup;
  final String medicalNotes;
  final int countdownSeconds;
  final bool sirenOnSos;
  final bool recordAudio;
  final bool shakeTrigger;
  final bool powerTrigger;
  final bool voiceTrigger;
  final List<String> voicePhrases;

  /// Stealth: SOS runs silently (no siren, minimal UI) even from the HUD.
  final bool stealthMode;
  final bool secureScreen;
  final bool biometricUnlock;
  final int lockTimeoutSeconds;
  final bool cloudEnabled;

  /// Optional family Telegram group chat id (the bot must be a member).
  final String telegramChatId;
  final String fakeCallerName;
  final int fakeCallDelaySeconds;

  SafetySettings copyWith({
    bool? onboardingComplete,
    String? userName,
    String? bloodGroup,
    String? medicalNotes,
    int? countdownSeconds,
    bool? sirenOnSos,
    bool? recordAudio,
    bool? shakeTrigger,
    bool? powerTrigger,
    bool? voiceTrigger,
    List<String>? voicePhrases,
    bool? stealthMode,
    bool? secureScreen,
    bool? biometricUnlock,
    int? lockTimeoutSeconds,
    bool? cloudEnabled,
    String? telegramChatId,
    String? fakeCallerName,
    int? fakeCallDelaySeconds,
  }) =>
      SafetySettings(
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        userName: userName ?? this.userName,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        medicalNotes: medicalNotes ?? this.medicalNotes,
        countdownSeconds: countdownSeconds ?? this.countdownSeconds,
        sirenOnSos: sirenOnSos ?? this.sirenOnSos,
        recordAudio: recordAudio ?? this.recordAudio,
        shakeTrigger: shakeTrigger ?? this.shakeTrigger,
        powerTrigger: powerTrigger ?? this.powerTrigger,
        voiceTrigger: voiceTrigger ?? this.voiceTrigger,
        voicePhrases: voicePhrases ?? this.voicePhrases,
        stealthMode: stealthMode ?? this.stealthMode,
        secureScreen: secureScreen ?? this.secureScreen,
        biometricUnlock: biometricUnlock ?? this.biometricUnlock,
        lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
        cloudEnabled: cloudEnabled ?? this.cloudEnabled,
        telegramChatId: telegramChatId ?? this.telegramChatId,
        fakeCallerName: fakeCallerName ?? this.fakeCallerName,
        fakeCallDelaySeconds: fakeCallDelaySeconds ?? this.fakeCallDelaySeconds,
      );

  Map<String, Object?> toJson() => {
        'onboardingComplete': onboardingComplete,
        'userName': userName,
        'bloodGroup': bloodGroup,
        'medicalNotes': medicalNotes,
        'countdownSeconds': countdownSeconds,
        'sirenOnSos': sirenOnSos,
        'recordAudio': recordAudio,
        'shakeTrigger': shakeTrigger,
        'powerTrigger': powerTrigger,
        'voiceTrigger': voiceTrigger,
        'voicePhrases': voicePhrases,
        'stealthMode': stealthMode,
        'secureScreen': secureScreen,
        'biometricUnlock': biometricUnlock,
        'lockTimeoutSeconds': lockTimeoutSeconds,
        'cloudEnabled': cloudEnabled,
        'telegramChatId': telegramChatId,
        'fakeCallerName': fakeCallerName,
        'fakeCallDelaySeconds': fakeCallDelaySeconds,
      };

  /// Tolerant decoder: unknown, missing or mistyped keys fall back to defaults.
  factory SafetySettings.fromJson(Map<String, Object?> j) {
    const d = SafetySettings();
    T pick<T>(String k, T fallback) {
      final v = j[k];
      return v is T ? v : fallback;
    }

    final phrases = j['voicePhrases'];
    return SafetySettings(
      onboardingComplete: pick('onboardingComplete', d.onboardingComplete),
      userName: pick('userName', d.userName),
      bloodGroup: pick('bloodGroup', d.bloodGroup),
      medicalNotes: pick('medicalNotes', d.medicalNotes),
      countdownSeconds: pick<int>('countdownSeconds', d.countdownSeconds).clamp(3, 15),
      sirenOnSos: pick('sirenOnSos', d.sirenOnSos),
      recordAudio: pick('recordAudio', d.recordAudio),
      shakeTrigger: pick('shakeTrigger', d.shakeTrigger),
      powerTrigger: pick('powerTrigger', d.powerTrigger),
      voiceTrigger: pick('voiceTrigger', d.voiceTrigger),
      voicePhrases: phrases is List ? phrases.whereType<String>().toList() : d.voicePhrases,
      stealthMode: pick('stealthMode', d.stealthMode),
      secureScreen: pick('secureScreen', d.secureScreen),
      biometricUnlock: pick('biometricUnlock', d.biometricUnlock),
      lockTimeoutSeconds: pick<int>('lockTimeoutSeconds', d.lockTimeoutSeconds).clamp(0, 3600),
      cloudEnabled: pick('cloudEnabled', d.cloudEnabled),
      telegramChatId: pick('telegramChatId', d.telegramChatId),
      fakeCallerName: pick('fakeCallerName', d.fakeCallerName),
      fakeCallDelaySeconds: pick<int>('fakeCallDelaySeconds', d.fakeCallDelaySeconds).clamp(0, 300),
    );
  }
}
