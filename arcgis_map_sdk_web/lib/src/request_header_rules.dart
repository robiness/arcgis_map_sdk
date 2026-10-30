/// Answers the headers for one request.
typedef RequestHeadersCallback = Future<Map<String, String>> Function();

/// The [headers] for every request whose URL starts with [urlPrefix], set
/// last through the map [mapId].
class RequestHeaderRule {
  const RequestHeaderRule({
    required this.urlPrefix,
    required this.mapId,
    required this.headers,
  });

  final String urlPrefix;
  final int mapId;
  final RequestHeadersCallback headers;
}

/// The request headers of the page, one rule per URL prefix.
///
/// The page shares them between its maps: the map that set a prefix last
/// owns it, so a recreated map keeps its headers whichever map is disposed
/// first.
class RequestHeaderRules {
  final _rules = <String, RequestHeaderRule>{};

  /// ArcGIS runs only the first interceptor whose prefix matches a request,
  /// so the longest prefix comes first and the most specific rule wins.
  List<RequestHeaderRule> get rules => List.unmodifiable(
        _rules.values.toList()
          ..sort((a, b) => b.urlPrefix.length.compareTo(a.urlPrefix.length)),
      );

  /// Sets [headers] for [urlPrefix], replacing the rule any map set for it.
  ///
  /// Throws an [ArgumentError] unless [urlPrefix] is an absolute http or
  /// https URL with a host: an empty prefix would send the headers with
  /// every request ArcGIS makes.
  void set({
    required String urlPrefix,
    required int mapId,
    required RequestHeadersCallback headers,
  }) {
    final uri = Uri.tryParse(urlPrefix);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      throw ArgumentError.value(
        urlPrefix,
        'urlPrefix',
        'must be an absolute http or https URL',
      );
    }
    _rules[urlPrefix] =
        RequestHeaderRule(urlPrefix: urlPrefix, mapId: mapId, headers: headers);
  }

  /// Removes the rule for [urlPrefix], whichever map set it.
  void clear(String urlPrefix) => _rules.remove(urlPrefix);

  /// Removes the rules [mapId] set last.
  void clearMap(int mapId) =>
      _rules.removeWhere((_, rule) => rule.mapId == mapId);
}
