import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqeducaplay/services/daily_mission_service.dart';

void main() {
  final date = DateTime(2026, 8, 17);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('concede a recompensa uma única vez por dia e usuário', () async {
    final service = DailyMissionService();

    final first = await service.claimIfCompleted(
      username: 'aluno',
      completed: true,
      now: date,
    );
    final second = await service.claimIfCompleted(
      username: 'aluno',
      completed: true,
      now: date,
    );

    expect(first.claimed, isTrue);
    expect(first.stars, DailyMissionService.rewardStars);
    expect(second.claimed, isTrue);
    expect(second.stars, DailyMissionService.rewardStars);
  });

  test('nao concede recompensa antes de concluir a missao', () async {
    final result = await DailyMissionService().claimIfCompleted(
      username: 'aluno',
      completed: false,
      now: date,
    );

    expect(result.claimed, isFalse);
    expect(result.stars, 0);
  });

  test('permite nova recompensa em outro dia', () async {
    final service = DailyMissionService();

    await service.claimIfCompleted(username: 'aluno', completed: true, now: date);
    final nextDay = await service.claimIfCompleted(
      username: 'aluno',
      completed: true,
      now: date.add(const Duration(days: 1)),
    );

    expect(nextDay.stars, DailyMissionService.rewardStars);
  });
}
