import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';

class DailyMissionReward {
  final int stars;
  final bool claimed;

  const DailyMissionReward({required this.stars, required this.claimed});
}

class DailyMissionService {
  static const int rewardStars = 10;

  String _key(String username, DateTime date) {
    final day = date.toIso8601String().substring(0, 10);
    return 'daily_mission_claimed_${username}_$day';
  }

  Future<DailyMissionReward> claimIfCompleted({
    required String username,
    required bool completed,
    int? userId,
    DateTime? now,
  }) async {
    if (!completed) {
      return const DailyMissionReward(stars: 0, claimed: false);
    }

    final date = now ?? DateTime.now();
    if (userId != null) {
      await AppDatabase.instance.claimDailyMissionReward(
        userId: userId,
        date: date,
        stars: rewardStars,
      );
      return const DailyMissionReward(stars: rewardStars, claimed: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _key(username, date);
    if (prefs.getBool(key) ?? false) {
      return const DailyMissionReward(stars: rewardStars, claimed: true);
    }

    await prefs.setBool(key, true);
    return const DailyMissionReward(stars: rewardStars, claimed: true);
  }

  Future<int> getTotalRewardStars({required int userId}) {
    return AppDatabase.instance.getDailyMissionStars(userId);
  }
}
