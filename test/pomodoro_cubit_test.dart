import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/pomodoro/presentation/cubit/pomodoro_cubit.dart';
import 'package:task_manager/features/pomodoro/presentation/cubit/pomodoro_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroCubit Tests', () {
    late PomodoroCubit cubit;

    setUp(() {
      cubit = PomodoroCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('الحالة الافتراضية تكون جلسة تركيز والمؤقت متوقف', () {
      expect(cubit.state.mode, equals(PomodoroMode.focus));
      expect(cubit.state.isRunning, isFalse);
      expect(cubit.state.focusDurationMinutes, equals(25));
      expect(cubit.state.remainingSeconds, equals(25 * 60));
    });

    test('تغيير نمط المؤقت إلى استراحة قصيرة يحسب الثواني بدقة', () {
      cubit.switchMode(PomodoroMode.shortBreak);

      expect(cubit.state.mode, equals(PomodoroMode.shortBreak));
      expect(cubit.state.remainingSeconds, equals(5 * 60));
      expect(cubit.state.isRunning, isFalse);
    });

    test('تحديث أوقات الجلسات المخصصة ينعكس على الحالة', () {
      cubit.updateDurations(
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 20,
      );

      expect(cubit.state.focusDurationMinutes, equals(50));
      expect(cubit.state.shortBreakMinutes, equals(10));
      expect(cubit.state.longBreakMinutes, equals(20));
      expect(cubit.state.totalSeconds, equals(50 * 60));
    });

    test('ربط جلسة بومودورو بمهمة معينة', () {
      cubit.bindTask('task-123');
      expect(cubit.state.selectedTaskId, equals('task-123'));

      cubit.bindTask(null);
      expect(cubit.state.selectedTaskId, isNull);
    });
  });
}
