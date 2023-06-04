import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';

abstract class RateLimiter {
  /// Returns true if the [requestIdentifiers] should be allowed given the
  /// [limit] imposed.
  /// The [key] will be used to separate different rate counts.
  /// If [increaseCount] is true, the count for [key] associated with
  /// all [requestIdentifiers] will be increased.
  Future<bool> isAllowed(
    List<String> requestIdentifiers,
    String key,
    RateLimit limit, {
    required int increaseCount,
  });

  /// Returns true if the [requestIdentifiers] should be allowed given the
  /// [limits] imposed.
  /// The [key] will be used to separate different rate counts.
  /// If [increaseCount] is true, the count for [key] associated with
  /// all [requestIdentifiers] will be increased.
  Future<Map<String, List<RateLimitResult>>> isAllowedResults(
    List<String> requestIdentifiers,
    String key,
    List<RateLimit> limits, {
    required int increaseCount,
  });

  ///
  Future<void> increaseCount(
    List<String> requestIdentifiers,
    String key, {
    int amount = 1,
  }) {
    return isAllowed(
      requestIdentifiers,
      key,
      const RateLimit(1, Duration(minutes: 1)),
      increaseCount: amount,
    );
  }
}

/// A rate limit with a [limit] of requests in a [duration].
class RateLimit implements Comparable<RateLimit>, SerializableToJson {
  /// The number of requests allowed in the [duration].
  final int limit;

  /// The duration in which the [limit] is valid.
  final Duration duration;

  /// Creates a new [RateLimit] with the given [limit] and [duration].
  const RateLimit(this.limit, this.duration);

  factory RateLimit.fromJson(Map<String, Object?> json) {
    return RateLimit(
      json['limit']! as int,
      Duration(microseconds: json['duration']! as int),
    );
  }

  /// The number of microseconds allowed per request.
  int get microsecondsPerRequest => duration.inMicroseconds ~/ limit;

  @override
  bool operator ==(Object other) =>
      other is RateLimit && other.limit == limit && other.duration == duration;

  @override
  int get hashCode => Object.hash(limit, duration);

  @override
  int compareTo(RateLimit other) {
    final c = microsecondsPerRequest.compareTo(other.microsecondsPerRequest);
    return c == 0 ? other.limit.compareTo(limit) : c;
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'limit': limit,
      'duration': duration.inMicroseconds,
    };
  }

  @override
  String toString() {
    return 'RateLimit{limit: $limit, duration: $duration}';
  }
}

class RateLimitResult implements Comparable<RateLimitResult> {
  /// X-RateLimit-Remaining
  /// The number of calls remaining in the interval before reaching the limit.
  final int remaining;

  /// X-RateLimit-Reset
  /// The number of seconds remaining until the beginning of the next interval.
  final Duration reset;

  /// The limit that was used to calculate the [remaining] and [reset] values.
  final RateLimit limit;

  /// Whether the [remaining] is greater than 0
  /// and the request should be allowed.
  bool get isAllowed => remaining > 0;

  ///
  RateLimitResult({
    required this.remaining,
    required this.reset,
    required this.limit,
  });

  Map<String, String> toHeaders({bool standard = true}) {
    final prefix = standard ? '' : 'X-';
    final policy =
        '${limit.limit};w=${limit.duration.inSeconds};comment="sliding window"';
    return {
      '${prefix}RateLimit-Policy': policy,
      '${prefix}RateLimit-Limit': limit.limit.toString(),
      '${prefix}RateLimit-Remaining': remaining.toString(),
      '${prefix}RateLimit-Reset': reset.inSeconds.toString(),
      if (!isAllowed) 'Retry-After': reset.inSeconds.toString(),
    };
  }

  @override
  int compareTo(RateLimitResult other) {
    final c = remaining.compareTo(other.remaining);
    final resetC = reset.compareTo(other.reset);
    return c == 0
        ? resetC == 0
            ? limit.compareTo(other.limit)
            : resetC
        : c;
  }
}

// TODO:
// https://stackoverflow.com/questions/16022624/examples-of-http-api-rate-limiting-http-response-headers

// IBM
// If the burst limit is exceeded, no X-RateLimit-* headers but a 429 error code is returned.
// If the burst limit is not exceeded, the action proceeds to check the rate limit.
// When the rate limit is not exceeded, the request is processed. When the rate limit is exceeded but the hard limit setting is not enabled, the request is still processed but with a warning. In this case, the response carries the following headers.

class CachedValue {
  final CountsMonth? previousSaved;
  final CountsMonth saved;
  final CachedKey key;
  CountsMonth current;
  DateTime lastUpdate;

  ///
  CachedValue({
    required this.key,
    required this.previousSaved,
    required this.saved,
    required this.current,
    required this.lastUpdate,
  });
}

class CachedKey {
  final String currentMonthKey;
  final String previousMonthKey;
  final String requestIdentifier;

  ///
  CachedKey(
    this.currentMonthKey,
    this.previousMonthKey,
    this.requestIdentifier,
  );
}

/// Eventually-consistent sliding window rate limiting.
///
/// Tracks sliding counters in memory and relies on transactions
/// in [persistence] to periodically sync the local count data with
/// the shared persistence.
class PersistenceRateLimiter extends RateLimiter {
  /// The [Persistence] used to store the [CountsMonth]s.
  /// // TODO: use a custom persistence for Rate Limits
  final Persistence persistence;

  /// The duration for which a [CountsMonth] is synced to the [persistence]
  final Duration persistDuration;

  /// The duration for which a [CachedValue] is kept in memory if it
  /// has not been updated.
  final Duration cacheDuration;

  /// The values currently in memory.
  final Map<String, CachedValue> inMemoryCache = {};
  Set<String> _updatedKeysToKeep = {};
  Map<String, CachedValue> _toPersist = {};
  late Timer _persistTimer;
  late Timer _removeCacheTimer;

  /// Whether this [PersistenceRateLimiter] has been [dispose]d.
  bool isDisposed = false;

  ///
  PersistenceRateLimiter(
    this.persistence, {
    this.persistDuration = const Duration(seconds: 5),
    this.cacheDuration = const Duration(minutes: 4),
    // TODO: max number of keys in memory cache
    // TODO: persistence key granularity month or day
  }) {
    if (cacheDuration < persistDuration * 2) {
      throw ArgumentError.value(
        cacheDuration,
        'cacheDuration',
        'Cache durations of less than twice the persistDuration'
            ' are not supported. cacheDuration: $cacheDuration,'
            ' persistDuration: $persistDuration.',
      );
    }
    _persistTimer = Timer(persistDuration, _executePersistTimer);
    _removeCacheTimer = Timer(cacheDuration, _removeFromCache);
  }

  Future<void> _executePersistTimer() async {
    final toPersistValues = _toPersist.values.toList();
    _updatedKeysToKeep.addAll(_toPersist.keys);
    _toPersist = {};
    await _setStates(toPersistValues);
    if (!isDisposed) {
      _persistTimer = Timer(persistDuration, _executePersistTimer);
    }
  }

  void _removeFromCache() {
    _removeCacheTimer.cancel();
    _updatedKeysToKeep.addAll(_toPersist.keys);
    inMemoryCache.removeWhere((k, v) => !_updatedKeysToKeep.contains(k));
    _updatedKeysToKeep = {};
    if (!isDisposed) {
      _removeCacheTimer = Timer(cacheDuration, _removeFromCache);
    }
  }

  /// Disposes and stops syncing to the database.
  Future<void> dispose() async {
    if (isDisposed) return;
    isDisposed = true;
    _removeCacheTimer.cancel();
    _persistTimer.cancel();
    await _executePersistTimer();
  }

  @override
  Future<Map<String, List<RateLimitResult>>> isAllowedResults(
    List<String> requestIdentifiers,
    String key,
    List<RateLimit> limits, {
    required int increaseCount,
  }) async {
    if (isDisposed) {
      throw StateError('This $PersistenceRateLimiter has been disposed.');
    }
    limits.forEach(_validateLimit);

    final now = clock.now();
    final keys = _getKeys(requestIdentifiers, key, now);
    final states = await _getStates(keys, now);
    // final Map<String, List<RateLimitResult>> isAllowedResult = states
    //     .expand(
    //   (s) => limits.map(
    //     (limit) => MapEntry(
    //       s.key.requestIdentifier,
    //       s.current.isAllowedResult(s.previousSaved, limit, now),
    //     ),
    //   ),
    // )
    //    .fold({}, (map, e) => map..putIfAbsent(e.key, () => []).add(e.value));

    final Map<String, List<RateLimitResult>> isAllowedResult =
        Map.fromIterables(
      requestIdentifiers,
      states.map(
        (s) => limits
            .map(
              (limit) => s.current.isAllowedResult(s.previousSaved, limit, now),
            )
            .toList(),
      ),
    );

    if (increaseCount > 0) {
      for (final c in states) {
        c.lastUpdate = now;
        c.current.increaseCount(now, amount: increaseCount);
      }
      _toPersist
          .addEntries(states.map((e) => MapEntry(e.key.currentMonthKey, e)));
    }

    return isAllowedResult;
  }

  List<CachedKey> _getKeys(
    List<String> requestIdentifiers,
    String key,
    DateTime now,
  ) {
    final currentMonth = '${now.year}${now.month < 10 ? '0' : ''}${now.month}';
    final previousMonth = now.month == 1
        ? '${now.year - 1}12'
        : '${now.year}${(now.month - 1) < 10 ? '0' : ''}${now.month - 1}';
    return requestIdentifiers
        .map(
          (e) => CachedKey(
            'rl$currentMonth.$e.$key',
            'rl$previousMonth.$e.$key',
            e,
          ),
        )
        .toList();
  }

  void _validateLimit(RateLimit limit) {
    if (limit.duration < const Duration(minutes: 1)) {
      throw UnsupportedError(
        'Limit duration of less than one minute are not'
        ' supported. Limit: $limit.',
      );
    }
  }

  @override
  Future<bool> isAllowed(
    List<String> requestIdentifiers,
    String key,
    RateLimit limit, {
    required int increaseCount,
  }) async {
    if (isDisposed) {
      throw StateError('This $PersistenceRateLimiter has been disposed.');
    }
    _validateLimit(limit);

    final now = clock.now();
    final keys = _getKeys(requestIdentifiers, key, now);

    // TODO: improve performance
    final states = await _getStates(keys, now);
    final isAllowedResult =
        states.every((s) => s.current.isAllowed(s.previousSaved, limit, now));
    if (increaseCount > 0) {
      for (final c in states) {
        c.lastUpdate = now;
        c.current.increaseCount(now, amount: increaseCount);
      }
      _toPersist
          .addEntries(states.map((e) => MapEntry(e.key.currentMonthKey, e)));
    }

    return isAllowedResult;
  }

  Future<List<CachedValue>> _getStates(List<CachedKey> keys, DateTime now) {
    // return Future.wait(keys.map(persistence.getState));
    return Future.wait(
      keys.map((k) async {
        final inCache = inMemoryCache[k.currentMonthKey];
        if (inCache != null) return inCache;
        final value = await persistence.getState(k.currentMonthKey);
        final previous = await persistence.getState(k.previousMonthKey);
        final previousSaved =
            previous == null ? null : CountsMonth.fromJson(previous.meta!);
        final saved = value == null
            ? CountsMonth.empty(now)
            : CountsMonth.fromJson(value.meta!);
        final newCounts = saved.clone();
        final item = CachedValue(
          key: k,
          previousSaved: previousSaved,
          saved: saved,
          current: newCounts,
          lastUpdate: now,
        );
        inMemoryCache[k.currentMonthKey] = item;
        return item;
      }),
    );
  }

  Future<void> _setStates(List<CachedValue> newStates) {
    // return Future.wait(newStates.map((s) => persistence.setState(s.state, s)));
    return Future.wait(
      newStates.map(
        (s) async {
          final key = s.key.currentMonthKey;
          // TODO: transaction and performance
          final previous = await persistence.getState(key);
          final prev =
              previous == null ? null : CountsMonth.fromJson(previous.meta!);
          final value = s.saved;
          value.applyChange([
            if (prev != null) prev,
            s.current,
          ]);
          s.current = value.clone();
          return persistence.setState(
            key,
            AuthStateModel(
              state: key,
              providerId: '',
              createdAt: clock.now(),
              responseType: null,
              meta: value.toJson(),
            ),
          );
        },
      ),
    );
  }
}

enum CountsContained {
  /// The count is contained in this object and all
  /// of the inner counts are contained
  full,

  /// Some of the counts may be contained in this object, but not
  /// necessarily all of the inner counts are contained
  partial,

  /// The count is not contained in this object
  none,
}

abstract class Counts {
  /// Default number of seconds per fraction in [CountsMinuteFraction]
  static const int defaultSecondsPerMinuteFraction = 15;

  /// The count
  int get c;
  set c(int newC);

  /// The inner counts
  List<Counts> get inner;

  /// The local identifier for this count
  int get id;

  /// The empty default that can be added to [inner]
  /// Returns null when this cannot have inner counts
  Counts? innerDefault(int id);

  /// Returns a different object with the same information
  Counts clone();

  @override
  String toString() {
    return '$runtimeType{c: $c,id: $id,inner: $inner}';
  }

  /// Adds a count
  void increaseCount(DateTime date, {int amount = 1}) {
    _findAndAdd(date, amount: amount);
    c += amount;
  }

  Counts? _findAndAdd(DateTime date, {required int amount}) {
    final innerBase = innerDefault(1);
    if (innerBase == null) return null;
    final innerId = innerBase.idFromDate(date);

    final found = inner.reversed.firstWhereOrNull((e) => e.id == innerId);
    final Counts item;
    if (found != null) {
      item = found;
    } else {
      item = innerDefault(innerId)!;
      // TODO: insert in order. binary search.
      inner.add(item);
    }
    item.increaseCount(date, amount: amount);
    return item;
  }

  /// How is this contained in the given range
  /// If [start] is null, it is considered to be the beginning of time
  /// If [end] is null, it is considered to be the end of time
  CountsContained contained(DateTime? start, DateTime? end) {
    final id = this.id;
    final startId = start == null ? -1 : idFromDate(start);
    final endId = end == null ? 1e12 : idFromDate(end);
    return startId < id && id < endId
        ? CountsContained.full
        : startId == id || id == endId
            ? CountsContained.partial
            : CountsContained.none;
  }

  /// The local id for the given date
  int idFromDate(DateTime date);

  /// Applies the deltas between the [other] counts and this.
  /// Counts in [other]s should be higher than this.
  int applyChange(List<Counts> other) {
    int delta = 0;
    for (final o in other) {
      assert(o.id == id, 'applyChange should only be called with the same id');
      assert(c <= o.c, 'applyChange should only be called with higher counts');
      delta += o.c - c;
    }
    if (delta == 0) return 0;
    c += delta;
    final maxInnerLength = other.map((o) => o.inner.length).fold(0, max);
    if (maxInnerLength == 0) return delta;

    final indexes = List.filled(other.length, 0);
    int innerDelta = 0;
    int innerIndex = 0;
    // TODO: reversed is probably faster
    while (true) {
      var i = 0;
      final vals = other.map((e) {
        final index = indexes[i++];
        return index < e.inner.length ? e.inner[index] : null;
      }).toList();

      final minValue = vals.whereType<Counts>().map((e) => e.id).reduce(min);
      i = -1;
      final toUpdate = vals
          .map((e) {
            i++;
            if (e?.id == minValue) {
              indexes[i] += 1;
              return e;
            }
            return null;
          })
          .whereType<Counts>()
          .toList();
      if (inner.length <= innerIndex) {
        inner.add(innerDefault(minValue)!);
      }

      innerDelta += inner[innerIndex++].applyChange(toUpdate);
      if (innerDelta == delta) {
        break;
      }
    }

    return delta;
  }

  /// The count in the range
  int countInRange(
    DateTime start,
    DateTime end, {
    int? maxCount,
    bool checkedStart = false,
    bool checkedEnd = false,
  }) {
    // TODO: should we interpolate?
    final contained = this.contained(
      checkedStart ? null : start,
      checkedEnd ? null : end,
    );

    switch (contained) {
      case CountsContained.full:
        return c;
      case CountsContained.partial:
        if (inner.isEmpty) return c;
        final newCheckedStart = checkedStart || id > idFromDate(start);
        final newCheckedEnd = checkedEnd || id < idFromDate(end);
        int pc = 0;
        final startSearch = binarySearch(
          inner,
          inner.first.idFromDate(start),
          (v) => v.id,
        ).indexOrNext;
        for (int i = startSearch; i < inner.length; i++) {
          final innerItem = inner[i];
          // We may stop if inner.contained() is none after a not none
          final itemC = innerItem.countInRange(
            start,
            end,
            maxCount: maxCount == null ? null : maxCount - pc,
            checkedStart: newCheckedStart,
            checkedEnd: newCheckedEnd,
          );
          // if (itemC == 0) break;
          pc += itemC;
          if (maxCount != null && pc >= maxCount) {
            return maxCount;
          }
        }
        return pc;
      case CountsContained.none:
        return 0;
    }
  }

  /// Whether this count is allowed for [limit]
  bool isAllowed(Counts? previous, RateLimit limit, DateTime end) {
    final start = end.subtract(limit.duration);
    final previousCount =
        previous?.countInRange(start, end, maxCount: limit.limit) ?? 0;
    if (previousCount >= limit.limit) return false;

    final pc = countInRange(start, end, maxCount: limit.limit - previousCount);
    return previousCount + pc < limit.limit;
  }
}

class CountsMonthSerialized {
  final int c;
  final DateTime month;
  final List<int> counts;
  final List<int> ids;
  final List<int> kinds;

  ///
  CountsMonthSerialized({
    required this.month,
    required this.c,
    required this.counts,
    required this.ids,
    required this.kinds,
  });
}

class CountsSerializedItem {
  final List<int> counts;
  final List<int> ids;

  ///
  CountsSerializedItem({
    required this.counts,
    required this.ids,
  });

  Map<String, Object?> toJson({
    List<int> Function(List<int>)? compressIntegers,
  }) {
    return {
      'counts': compressIntegers == null
          ? counts
          : base64Encode(compressIntegers(counts)),
      'ids':
          compressIntegers == null ? ids : base64Encode(compressIntegers(ids)),
    };
  }

  factory CountsSerializedItem.fromJson(
    Map<String, Object?> json, {
    List<int> Function(List<int>)? decompressIntegers,
  }) {
    final counts = json['counts'] is String
        ? base64Decode(json['counts']! as String)
        : (json['counts']! as List).cast<int>();
    final ids = json['ids'] is String
        ? base64Decode(json['ids']! as String)
        : (json['ids']! as List).cast<int>();

    return CountsSerializedItem(
      counts: decompressIntegers == null ? counts : decompressIntegers(counts),
      ids: decompressIntegers == null ? ids : decompressIntegers(ids),
    );
  }
}

class CountsMonthSerialized2 {
  final int c;
  final DateTime month;
  final CountsSerializedItem days;
  final CountsSerializedItem hours;
  final CountsSerializedItem minutes;
  final CountsSerializedItem seconds;

  ///
  CountsMonthSerialized2({
    required this.month,
    required this.c,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  factory CountsMonthSerialized2.fromCountsMonth(CountsMonth counts) {
    final hours = counts.inner.expand((e) => e.inner);
    final minutes = hours.expand((e) => e.inner);
    final seconds = minutes.expand((e) => e.inner);

    return CountsMonthSerialized2(
      c: counts.c,
      month: counts.month,
      days: CountsSerializedItem(
        counts: counts.inner.map((e) => e.c).toList(),
        ids: counts.inner.map((e) => e.id).toList(),
      ),
      hours: CountsSerializedItem(
        counts: hours.map((e) => e.c).toList(),
        ids: hours.map((e) => e.id).toList(),
      ),
      minutes: CountsSerializedItem(
        counts: minutes.map((e) => e.c).toList(),
        ids: minutes.map((e) => e.id).toList(),
      ),
      seconds: CountsSerializedItem(
        counts: seconds.map((e) => e.c).toList(),
        ids: seconds.map((e) => e.id).toList(),
      ),
    );
  }

  factory CountsMonthSerialized2.fromJson(
    Map<String, Object?> json, {
    List<int> Function(List<int>)? decompressIntegers,
  }) {
    return CountsMonthSerialized2(
      c: json['c']! as int,
      month: DateTime.parse(json['month']! as String),
      days: CountsSerializedItem.fromJson(
        json['days']! as Map<String, Object?>,
        decompressIntegers: decompressIntegers,
      ),
      hours: CountsSerializedItem.fromJson(
        json['hours']! as Map<String, Object?>,
        decompressIntegers: decompressIntegers,
      ),
      minutes: CountsSerializedItem.fromJson(
        json['minutes']! as Map<String, Object?>,
        decompressIntegers: decompressIntegers,
      ),
      seconds: CountsSerializedItem.fromJson(
        json['seconds']! as Map<String, Object?>,
        decompressIntegers: decompressIntegers,
      ),
    );
  }

  Map<String, Object?> toJson({
    List<int> Function(List<int>)? compressIntegers,
  }) {
    return {
      'c': c,
      'month': month.toIso8601String(),
      'days': days.toJson(compressIntegers: compressIntegers),
      'hours': hours.toJson(compressIntegers: compressIntegers),
      'minutes': minutes.toJson(compressIntegers: compressIntegers),
      'seconds': seconds.toJson(compressIntegers: compressIntegers),
    };
  }

  /// Converts this to a [CountsMonth]
  CountsMonth toCounts() {
    final inner = <CountsDay>[];
    int daysIndex = 0;
    int hoursIndex = 0;
    int minutesIndex = 0;
    int secondsIndex = 0;

    while (days.ids.length > daysIndex) {
      final day = CountsDay(days.counts[daysIndex], days.ids[daysIndex], []);
      inner.add(day);
      int dayC = 0;
      while (hours.ids.length > hoursIndex && day.c != dayC) {
        final hour =
            CountsHour(hours.counts[hoursIndex], hours.ids[hoursIndex], []);
        day.inner.add(hour);
        dayC += hour.c;

        int hourC = 0;
        while (minutes.ids.length > minutesIndex && hour.c != hourC) {
          final minute = CountsMinute(
            minutes.counts[minutesIndex],
            minutes.ids[minutesIndex],
            [],
          );
          hour.inner.add(minute);
          hourC += minute.c;

          int minuteC = 0;
          while (seconds.ids.length > secondsIndex && minute.c != minuteC) {
            final second = CountsMinuteFraction(
              seconds.counts[secondsIndex],
              seconds.ids[secondsIndex],
              Counts.defaultSecondsPerMinuteFraction,
            );
            minute.inner.add(second);
            minuteC += second.c;

            secondsIndex++;
          }
          assert(minute.c == minuteC, '${minute.c} != $minuteC');
          minutesIndex++;
        }
        assert(hour.c == hourC, '${hour.c} != $hourC');
        hoursIndex++;
      }
      assert(day.c == dayC, '${day.c} != $dayC');
      daysIndex++;
    }

    return CountsMonth(c, month, inner);
  }
}

class CountsMonth extends Counts implements SerializableToJson {
  @override
  int c;
  final DateTime month;
  @override
  final List<CountsDay> inner;

  CountsMonth(this.c, this.month, this.inner);

  factory CountsMonth.empty(DateTime date) {
    return CountsMonth(0, date, []);
  }

  @override
  int get id => idFromDate(month);
  @override
  int idFromDate(DateTime date) => date.year * 100 + date.month;
  @override
  CountsDay innerDefault(int id) => CountsDay(0, id, []);
  @override
  CountsMonth clone() {
    return CountsMonth(c, month, inner.map((e) => e.clone()).toList());
  }

  RateLimitResult isAllowedResult(
    CountsMonth? previous,
    RateLimit limit,
    DateTime end,
  ) {
    final start = end.subtract(limit.duration);
    final previousCount =
        previous?.countInRange(start, end, maxCount: limit.limit) ?? 0;
    final pc = previousCount >= limit.limit
        ? 0
        : countInRange(start, end, maxCount: limit.limit - previousCount);
    final remaining = limit.limit - (previousCount + pc);
    var reset = const Duration(seconds: Counts.defaultSecondsPerMinuteFraction);

    if (remaining <= 0) {
      final endReset = getReset(limit.limit);
      // TODO: count backwards and return the date
      final resetDate = endReset ?? previous!.getReset(limit.limit - c)!;
      reset = limit.duration - end.difference(resetDate);
    }

    return RateLimitResult(
      remaining: remaining,
      limit: limit,
      reset: reset,
    );
  }

  /// Returns the date where the amount of counts sum to [count]
  /// The aggregation is done from the last to first dates so that the
  /// date returned is the first date that would reset the sliding window
  /// if no more petitions are performed. See [isAllowedResult].
  DateTime? getReset(int count) {
    if (count > c) {
      return null;
    } else if (count == c) {
      return month;
    }
    int inc = count;
    for (final day in inner.reversed) {
      if (day.c < inc) {
        inc -= day.c;
        continue;
      }
      for (final hour in day.inner.reversed) {
        if (hour.c < inc) {
          inc -= hour.c;
          continue;
        }
        for (final minute in hour.inner.reversed) {
          if (minute.c < inc) {
            inc -= minute.c;
            continue;
          }
          for (final fraction in minute.inner.reversed) {
            if (fraction.c < inc) {
              inc -= fraction.c;
              continue;
            }
            return DateTime(
              month.year,
              month.month,
              day.day,
              hour.hour,
              minute.minute,
              fraction.minuteFraction * fraction.secondsPerFraction,
            );
          }
        }
      }
    }
    throw Exception('Could not find reset $count in $this');
  }

  // @override
  // CountsContained contained(DateTime start, DateTime end) {
  //   final isBefore = start.isBefore(month);
  //   final isAfter = end.isAfter(month);
  //   return isAfter && isBefore
  //       ? CountsContained.full
  //       : (isAfter || start.isAtSameMomentAs(month)) &&
  //               (isBefore || end.isAtSameMomentAs(month))
  //           ? CountsContained.partial
  //           : CountsContained.none;
  // }

  factory CountsMonth.fromJson(Map<String, Object?> json) {
    final months = json['inner']! as List<Object?>;

    final monthsList = <CountsMonth>[];
    var daysList = <CountsDay>[];
    var hoursList = <CountsHour>[];
    var minutesList = <CountsMinute>[];
    var minutesFractionList = <CountsMinuteFraction>[];

    for (final e in months) {
      final list = e! as List<Object?>;
      final kind = list[0]! as String;
      final id = list[1]!;
      final c = list[2]! as int;

      if (kind.startsWith('s')) {
        final v = CountsMinuteFraction(
          c,
          id as int,
          int.parse(kind.substring(1)),
        );
        if (v.secondsPerFraction != Counts.defaultSecondsPerMinuteFraction) {
          throw Exception(
            'Invalid secondsPerFraction: ${v.secondsPerFraction}.'
            ' Configured: ${Counts.defaultSecondsPerMinuteFraction}',
          );
        }
        minutesFractionList.add(v);
        continue;
      }
      switch (kind) {
        case 'mo':
          final v = CountsMonth(c, DateTime.parse(id as String), []);
          monthsList.add(v);
          daysList = v.inner;
          break;
        case 'd':
          final v = CountsDay(c, id as int, []);
          daysList.add(v);
          hoursList = v.inner;
          break;
        case 'h':
          final v = CountsHour(c, id as int, []);
          hoursList.add(v);
          minutesList = v.inner;
          break;
        case 'mi':
          final v = CountsMinute(c, id as int, []);
          minutesList.add(v);
          minutesFractionList = v.inner;
          break;
        default:
          throw Exception('Unknown kind $kind');
      }
    }

    return CountsMonth(
      json['c']! as int,
      DateTime.parse(json['month']! as String),
      daysList,
    );
  }

  CountsMonthSerialized serialized() {
    final List<int> counts = [];
    final List<int> ids = [];
    final List<int> kinds = [];

    void add(Counts c) {
      kinds.add(_countKindInt(c));
      ids.add(c.id);
      counts.add(c.c);
      c.inner.forEach(add);
    }

    inner.forEach(add);

    return CountsMonthSerialized(
      c: c,
      month: month,
      counts: counts,
      ids: ids,
      kinds: kinds,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'c': c,
      'month': month.toIso8601String(),
      'inner': inner
          .expand(
            (CountsDay e) => [
              ['d', e.day, e.c]
            ].followedBy(
              e.inner.expand(
                (CountsHour e) => [
                  ['h', e.hour, e.c]
                ].followedBy(
                  e.inner.expand(
                    (CountsMinute e) => [
                      ['mi', e.minute, e.c]
                    ].followedBy(
                      e.inner.map(
                        (CountsMinuteFraction e) => [
                          's${e.secondsPerFraction}',
                          e.minuteFraction,
                          e.c,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    };
  }
}

String _countKind(Counts count) {
  if (count is CountsMonth) return 'mo';
  if (count is CountsDay) return 'd';
  if (count is CountsHour) return 'h';
  if (count is CountsMinute) return 'mi';
  if (count is CountsMinuteFraction) {
    return 's${count.secondsPerFraction}';
  }

  throw Exception('Unknown kind ${count.runtimeType}');
}

int _countKindInt(Counts count) {
  if (count is CountsMonth) return 0;
  if (count is CountsDay) return 1;
  if (count is CountsHour) return 2;
  if (count is CountsMinute) return 3;
  if (count is CountsMinuteFraction) return 4;

  throw Exception('Unknown kind ${count.runtimeType}');
}

class CountsDay extends Counts {
  @override
  int c;
  final int day;
  @override
  final List<CountsHour> inner;

  CountsDay(this.c, this.day, this.inner);

  @override
  int get id => day;
  @override
  int idFromDate(DateTime date) => date.day;
  @override
  CountsHour innerDefault(int id) => CountsHour(0, id, []);
  @override
  CountsDay clone() {
    return CountsDay(c, day, inner.map((e) => e.clone()).toList());
  }
}

class CountsHour extends Counts {
  @override
  int c;
  final int hour;
  @override
  final List<CountsMinute> inner;

  CountsHour(this.c, this.hour, this.inner);

  @override
  int get id => hour;
  @override
  int idFromDate(DateTime date) => date.hour;
  @override
  CountsMinute innerDefault(int id) => CountsMinute(0, id, []);
  @override
  CountsHour clone() {
    return CountsHour(c, hour, inner.map((e) => e.clone()).toList());
  }
}

class CountsMinute extends Counts {
  @override
  int c;
  final int minute;
  @override
  final List<CountsMinuteFraction> inner;

  CountsMinute(this.c, this.minute, this.inner);

  @override
  CountsMinuteFraction innerDefault(int id) =>
      CountsMinuteFraction(0, id, Counts.defaultSecondsPerMinuteFraction);

  @override
  int get id => minute;
  @override
  int idFromDate(DateTime date) => date.minute;
  @override
  CountsMinute clone() {
    return CountsMinute(c, minute, inner.map((e) => e.clone()).toList());
  }
}

class CountsMinuteFraction extends Counts {
  @override
  int c;
  final int minuteFraction;
  final int secondsPerFraction;

  /// [secondsPerFraction] must be a divisor of 60
  CountsMinuteFraction(
    this.c,
    this.minuteFraction,
    this.secondsPerFraction,
  ) : assert(
          60 % secondsPerFraction == 0,
          'secondsPerFraction ($secondsPerFraction) must be a divisor of 60.',
        );

  @override
  Null innerDefault(int id) => null;

  @override
  int get id => minuteFraction;
  @override
  int idFromDate(DateTime date) => date.second ~/ secondsPerFraction;
  @override
  List<Counts> get inner => const [];
  @override
  CountsMinuteFraction clone() {
    return CountsMinuteFraction(c, minuteFraction, secondsPerFraction);
  }
}

class BinarySearchResult<T> {
  final int indexOrNext;
  final bool found;
  final T? value;

  /// [indexOrNext] is the index of the found value, or the index of the next
  /// value if the value was not found.
  BinarySearchResult(
    this.indexOrNext,
    this.found,
    this.value,
  );
}

/// Performs a binary search on [items] using [valueFn]
/// to get the value to compare to [value].
BinarySearchResult<T> binarySearch<T>(
  List<T> items,
  int value,
  int Function(T) valueFn,
) {
  var min = 0;
  var max = items.length - 1;
  var found = false;
  var index = 0;
  while (min <= max) {
    index = ((min + max) / 2).floor();
    final item = items[index];
    final v = valueFn(item);
    if (v == value) {
      found = true;
      break;
    }
    if (v < value) {
      max = index - 1;
    } else {
      min = index + 1;
    }
  }
  if (!found && index > 0 && valueFn(items[index - 1]) > value) {
    index--;
  }
  return BinarySearchResult(index, found, found ? items[index] : null);
}
