/// Records browser history entries for back/forward navigation.
final class HistoryEntry {
  const HistoryEntry({
    required this.location,
    this.extra,
    this.disposition = HistoryDisposition.push,
  });

  final String location;
  final Object? extra;
  final HistoryDisposition disposition;
}

enum HistoryDisposition { push, replace }

/// Manages navigation history for web back/forward support.
final class NavigationHistory {
  NavigationHistory();

  final List<HistoryEntry> _entries = [];
  int _index = -1;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  int get index => _index;
  bool get canGoBack => _index > 0;
  bool get canGoForward => _index < _entries.length - 1;

  HistoryEntry? get current =>
      _index >= 0 && _index < _entries.length ? _entries[_index] : null;

  void push(String location, {Object? extra}) {
    if (_index < _entries.length - 1) {
      _entries.removeRange(_index + 1, _entries.length);
    }
    _entries.add(HistoryEntry(location: location, extra: extra));
    _index = _entries.length - 1;
  }

  void replace(String location, {Object? extra}) {
    if (_index >= 0) {
      _entries[_index] = HistoryEntry(
        location: location,
        extra: extra,
        disposition: HistoryDisposition.replace,
      );
    } else {
      push(location, extra: extra);
    }
  }

  HistoryEntry? goBack() {
    if (!canGoBack) return null;
    _index--;
    return current;
  }

  HistoryEntry? goForward() {
    if (!canGoForward) return null;
    _index++;
    return current;
  }
}
