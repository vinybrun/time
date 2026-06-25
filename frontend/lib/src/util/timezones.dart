/// A curated list of common IANA time zones for the settings dropdown.
/// The backend stores whatever string is selected, so any value works; this
/// just keeps the picker short and friendly.
const List<String> commonTimezones = [
  'UTC',
  'America/Sao_Paulo',
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'America/Mexico_City',
  'America/Bogota',
  'America/Buenos_Aires',
  'America/Toronto',
  'Europe/London',
  'Europe/Lisbon',
  'Europe/Madrid',
  'Europe/Paris',
  'Europe/Berlin',
  'Europe/Rome',
  'Europe/Amsterdam',
  'Europe/Moscow',
  'Africa/Lagos',
  'Africa/Johannesburg',
  'Asia/Dubai',
  'Asia/Kolkata',
  'Asia/Bangkok',
  'Asia/Shanghai',
  'Asia/Tokyo',
  'Asia/Singapore',
  'Australia/Sydney',
  'Pacific/Auckland',
];

/// Ensures [current] is present in the list (so the dropdown never breaks).
List<String> timezoneOptions(String current) {
  if (commonTimezones.contains(current)) return commonTimezones;
  return [current, ...commonTimezones];
}
