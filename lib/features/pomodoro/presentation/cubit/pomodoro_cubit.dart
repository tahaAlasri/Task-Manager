import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/ambient_audio_service.dart';
import '../../../../core/services/notification_service.dart';
import 'pomodoro_state.dart';

class PomodoroCubit extends Cubit<PomodoroState> {
  Timer? _timer;
  final Box? _box;
  final INotificationService _notificationService;
  final IAmbientAudioService _ambientAudioService;

  static const String boxName = 'pomodoro_box';
  static const String keyXpPoints = 'xp_points';
  static const String keyCompletedSessions = 'completed_sessions';
  static const String keyStreakDays = 'streak_days';
  static const String keyLastActiveDate = 'last_active_date';
  static const String keyFocusMinutes = 'focus_minutes';
  static const String keyShortBreakMinutes = 'short_break_minutes';
  static const String keyLongBreakMinutes = 'long_break_minutes';
  static const String keySessionHistory = 'session_history';

  PomodoroCubit({
    Box? box,
    INotificationService? notificationService,
    IAmbientAudioService? ambientAudioService,
  })  : _box = box ?? (Hive.isBoxOpen(boxName) ? Hive.box(boxName) : null),
        _notificationService = notificationService ?? NotificationService.instance,
        _ambientAudioService = ambientAudioService ?? AmbientAudioService.instance,
        super(const PomodoroState()) {
    _loadPersistedStats();
  }

  void _loadPersistedStats() {
    if (_box == null) return;

    final xp = _box.get(keyXpPoints, defaultValue: 150) as int;
    final sessions = _box.get(keyCompletedSessions, defaultValue: 0) as int;
    final focusMins = _box.get(keyFocusMinutes, defaultValue: 25) as int;
    final shortBreakMins = _box.get(keyShortBreakMinutes, defaultValue: 5) as int;
    final longBreakMins = _box.get(keyLongBreakMinutes, defaultValue: 15) as int;

    int streak = _box.get(keyStreakDays, defaultValue: 1) as int;
    final lastActiveStr = _box.get(keyLastActiveDate) as String?;

    if (lastActiveStr != null) {
      final lastDate = DateTime.tryParse(lastActiveStr);
      if (lastDate != null) {
        final now = DateTime.now();
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (diffDays > 1) {
          streak = 1; // إعادة تعيين سلسلة الأيام في حال الانقطاع
          _box.put(keyStreakDays, streak);
        }
      }
    }

    final initialSeconds = focusMins * 60;

    emit(state.copyWith(
      xpPoints: xp,
      completedSessions: sessions,
      streakDays: streak,
      focusDurationMinutes: focusMins,
      shortBreakMinutes: shortBreakMins,
      longBreakMinutes: longBreakMins,
      totalSeconds: initialSeconds,
      remainingSeconds: initialSeconds,
    ));
  }

  /// تحديث أوقات الجلسات وحفظها في التخزين المحلي
  void updateDurations({
    required int focusMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
  }) {
    _box?.put(keyFocusMinutes, focusMinutes);
    _box?.put(keyShortBreakMinutes, shortBreakMinutes);
    _box?.put(keyLongBreakMinutes, longBreakMinutes);

    int newTotal = focusMinutes * 60;
    if (state.mode == PomodoroMode.shortBreak) {
      newTotal = shortBreakMinutes * 60;
    } else if (state.mode == PomodoroMode.longBreak) {
      newTotal = longBreakMinutes * 60;
    }

    emit(state.copyWith(
      focusDurationMinutes: focusMinutes,
      shortBreakMinutes: shortBreakMinutes,
      longBreakMinutes: longBreakMinutes,
      totalSeconds: newTotal,
      remainingSeconds: state.isRunning ? state.remainingSeconds : newTotal,
    ));
  }

  /// بدء أو استئناف المؤقت بحساب الطابع الزمني الدقيق
  void startTimer() {
    if (state.isRunning) return;

    final targetEndTime = DateTime.now().add(Duration(seconds: state.remainingSeconds));

    emit(state.copyWith(
      isRunning: true,
      targetEndTime: targetEndTime,
    ));

    _playAmbientSoundIfEnabled();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      syncRemainingTime();
    });
  }

  /// مزامنة الوقت المتبقي اعتماداً على الطابع الزمني لضمان الدقة في الخلفية
  void syncRemainingTime() {
    if (!state.isRunning || state.targetEndTime == null) return;

    final now = DateTime.now();
    final differenceInSeconds = state.targetEndTime!.difference(now).inSeconds;

    if (differenceInSeconds > 0) {
      emit(state.copyWith(remainingSeconds: differenceInSeconds));
    } else {
      _onSessionCompleted();
    }
  }

  /// إيقاف مؤقت للمؤقت
  void pauseTimer() {
    _timer?.cancel();
    _stopAmbientSound();
    emit(state.copyWith(
      isRunning: false,
      clearTargetEndTime: true,
    ));
  }

  /// إعادة ضبط الوقت للجلسة الحالية
  void resetTimer() {
    _timer?.cancel();
    _stopAmbientSound();
    emit(state.copyWith(
      isRunning: false,
      remainingSeconds: state.totalSeconds,
      clearTargetEndTime: true,
    ));
  }

  /// تغيير نمط المؤقت (تركيز، استراحة قصيرة، استراحة طويلة)
  void switchMode(PomodoroMode mode) {
    _timer?.cancel();
    _stopAmbientSound();
    int minutes;
    switch (mode) {
      case PomodoroMode.focus:
        minutes = state.focusDurationMinutes;
        break;
      case PomodoroMode.shortBreak:
        minutes = state.shortBreakMinutes;
        break;
      case PomodoroMode.longBreak:
        minutes = state.longBreakMinutes;
        break;
    }
    final seconds = minutes * 60;
    emit(state.copyWith(
      mode: mode,
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: false,
      clearTargetEndTime: true,
    ));
  }

  /// ربط المؤقت بمهمة معينة
  void bindTask(String? taskId) {
    if (taskId == null) {
      emit(state.copyWith(clearSelectedTask: true));
    } else {
      emit(state.copyWith(selectedTaskId: taskId));
    }
  }

  /// تعيين الصوت المحيطي المهدئ
  Future<void> setAmbientSound(AmbientSoundType sound) async {
    emit(state.copyWith(ambientSound: sound));
    if (state.isRunning) {
      await _playAmbientSoundIfEnabled();
    }
  }

  /// تعيين مستوى الصوت
  Future<void> setAmbientVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    emit(state.copyWith(ambientVolume: clamped));
    await _ambientAudioService.setVolume(clamped);
  }

  Future<void> _playAmbientSoundIfEnabled() async {
    if (state.ambientSound == AmbientSoundType.none) {
      await _stopAmbientSound();
      return;
    }

    try {
      await _ambientAudioService.playAmbient(
        state.ambientSound.name,
        volume: state.ambientVolume,
      );
    } catch (_) {}
  }

  Future<void> _stopAmbientSound() async {
    try {
      await _ambientAudioService.stopAmbient();
    } catch (_) {}
  }

  /// جلب سجل الجلسات المكتملة
  List<Map<String, dynamic>> getSessionHistory() {
    if (_box == null) return [];
    final raw = _box.get(keySessionHistory);
    if (raw is List) {
      return raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  /// معالجة اكتمال جلسة بومودورو وتثبيت الإنجاز محلياً في Hive
  void _onSessionCompleted() {
    _timer?.cancel();
    _stopAmbientSound();

    final isFocus = state.mode == PomodoroMode.focus;
    final newSessions = isFocus ? state.completedSessions + 1 : state.completedSessions;
    final xpEarned = isFocus ? 50 : 15;
    final newXp = state.xpPoints + xpEarned;

    // تسجيل الجلسة في سجل التاريخ
    if (isFocus) {
      final history = getSessionHistory();
      history.add({
        'timestamp': DateTime.now().toIso8601String(),
        'durationMinutes': state.focusDurationMinutes,
        'taskId': state.selectedTaskId,
        'xpEarned': xpEarned,
      });
      _box?.put(keySessionHistory, history);
    }

    // تحديث سلسلة الأيام (Streaks) إذا كان يوماً جديداً
    int updatedStreak = state.streakDays;
    final now = DateTime.now();
    final lastActiveStr = _box?.get(keyLastActiveDate) as String?;
    if (lastActiveStr != null) {
      final lastDate = DateTime.tryParse(lastActiveStr);
      if (lastDate != null) {
        final diffDays = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diffDays == 1) {
          updatedStreak++;
        }
      }
    }

    // حفظ البيانات في Hive
    _box?.put(keyXpPoints, newXp);
    _box?.put(keyCompletedSessions, newSessions);
    _box?.put(keyStreakDays, updatedStreak);
    _box?.put(keyLastActiveDate, now.toIso8601String());

    // إرسال تنبيه فوري باكتمال الجلسة
    _notificationService.scheduleTaskReminder(
      id: 999999,
      title: isFocus ? 'أحسنت! اكتملت جلسة التركيز 🎉' : 'انتهت الاستراحة! حان وقت الإنجاز 🚀',
      body: isFocus
          ? 'حصلت على +50 XP! خذ استراحة قصيرة لتجديد طاقتك.'
          : 'لنعد للعمل ونحقق أهداف اليوم بكامل طاقتنا.',
      scheduledDate: DateTime.now().add(const Duration(seconds: 1)),
    );

    // التبديل التلقائي للاستراحة بعد التركيز
    final nextMode = isFocus
        ? (newSessions % 4 == 0 ? PomodoroMode.longBreak : PomodoroMode.shortBreak)
        : PomodoroMode.focus;

    int nextMinutes;
    switch (nextMode) {
      case PomodoroMode.focus:
        nextMinutes = state.focusDurationMinutes;
        break;
      case PomodoroMode.shortBreak:
        nextMinutes = state.shortBreakMinutes;
        break;
      case PomodoroMode.longBreak:
        nextMinutes = state.longBreakMinutes;
        break;
    }
    final nextSeconds = nextMinutes * 60;

    emit(state.copyWith(
      isRunning: false,
      clearTargetEndTime: true,
      completedSessions: newSessions,
      xpPoints: newXp,
      streakDays: updatedStreak,
      mode: nextMode,
      totalSeconds: nextSeconds,
      remainingSeconds: nextSeconds,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _stopAmbientSound();
    return super.close();
  }
}
