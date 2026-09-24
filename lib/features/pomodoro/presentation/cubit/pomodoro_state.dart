enum PomodoroMode {
  focus,
  shortBreak,
  longBreak;

  int get defaultMinutes {
    switch (this) {
      case PomodoroMode.focus:
        return 25;
      case PomodoroMode.shortBreak:
        return 5;
      case PomodoroMode.longBreak:
        return 15;
    }
  }

  String get labelAr {
    switch (this) {
      case PomodoroMode.focus:
        return 'جلسة تركيز 🎯';
      case PomodoroMode.shortBreak:
        return 'استراحة قصيرة ☕';
      case PomodoroMode.longBreak:
        return 'استراحة طويلة 🌴';
    }
  }
}

class PomodoroState {
  final PomodoroMode mode;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final int completedSessions;
  final int streakDays;
  final int xpPoints;
  final String? selectedTaskId;
  final int focusDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const PomodoroState({
    this.mode = PomodoroMode.focus,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.isRunning = false,
    this.completedSessions = 0,
    this.streakDays = 1,
    this.xpPoints = 150,
    this.selectedTaskId,
    this.focusDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
  });

  double get progress => totalSeconds == 0 ? 0.0 : (totalSeconds - remainingSeconds) / totalSeconds;

  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get userLevel => (xpPoints ~/ 100) + 1;

  String get levelTitle {
    if (userLevel <= 1) return 'مبتدئ الإنتاجية';
    if (userLevel == 2) return 'مُنجز نشط ⭐';
    if (userLevel == 3) return 'محارب التركيز 🔥';
    return 'خبير الإتقان 👑';
  }

  PomodoroState copyWith({
    PomodoroMode? mode,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    int? completedSessions,
    int? streakDays,
    int? xpPoints,
    String? selectedTaskId,
    bool clearSelectedTask = false,
    int? focusDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) {
    return PomodoroState(
      mode: mode ?? this.mode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
      completedSessions: completedSessions ?? this.completedSessions,
      streakDays: streakDays ?? this.streakDays,
      xpPoints: xpPoints ?? this.xpPoints,
      selectedTaskId: clearSelectedTask ? null : (selectedTaskId ?? this.selectedTaskId),
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    );
  }
}
