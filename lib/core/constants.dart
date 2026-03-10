/// API and app constants.
class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://5.78.43.182:5050';
  static const int pageSize = 50;
  static const int maxPageSize = 50;

  /// Query characters for paging (a-z, 0-9).
  static const List<String> queryChars = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];
}
