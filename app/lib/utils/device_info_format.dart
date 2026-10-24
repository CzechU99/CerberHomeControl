String formatUptime(Duration uptime) {
  final days = uptime.inDays;
  final hours = uptime.inHours % 24;
  final minutes = uptime.inMinutes % 60;

  if (days > 0) return '$days d $hours h';
  if (hours > 0) return '$hours h $minutes min';
  return '$minutes min';
}

String formatLastSeen(DateTime lastSeen, {required DateTime now}) {
  final elapsed = now.difference(lastSeen);

  if (elapsed.inMinutes < 1) return 'przed chwilą';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} min temu';
  if (elapsed.inDays < 1) return '${elapsed.inHours} h temu';

  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final local = lastSeen.toLocal();
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

String signalQuality(int rssi) {
  if (rssi >= -60) return 'dobry';
  if (rssi >= -75) return 'średni';
  return 'słaby';
}
