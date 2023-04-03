import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:oauth_example/persistence.dart';
import 'package:oauth_example/rate_limit.dart';
import 'package:test/test.dart';

import 'credentials_test.dart';

/// Runs a callback using FakeAsync.run while continually pumping the
/// microtask queue. This avoids a deadlock when tests `await` a Future
/// which queues a microtask that will not be processed unless the queue
/// is flushed.
Future<T> runFakeAsync<T>(
  Future<T> Function(FakeAsync time) f, {
  DateTime? initialTime,
}) async {
  return FakeAsync(initialTime: initialTime).run((FakeAsync time) async {
    bool pump = true;
    final Future<T> future = f(time).whenComplete(() => pump = false);
    while (pump) {
      time.flushMicrotasks();
      time.flushTimers();
    }
    return future.onError((error, stackTrace) => exit(1));
  });
}

void main() {
  group('PersistenceRateLimiter', () {
    test('single', () {
      final persistence = InMemoryPersistance();
      const rate = RateLimit(5, Duration(minutes: 1));

      final initialTime = DateTime(2023, 4, 1);

      runFakeAsync<void>(initialTime: initialTime, (time) async {
        final secsInterval = Counts.defaultSecondsPerMinuteFraction;
        const id = 'id';
        final keyCurrent = 'rl${initialTime.year}0${initialTime.month}$id';
        final keyPrevious = 'rl${initialTime.year}0${initialTime.month - 1}$id';
        final rateLimiter = PersistenceRateLimiter(persistence);
        Object? cachedValues() {
          return jsonEncDec(
            rateLimiter.inMemoryCache.map(
              (key, value) => MapEntry(
                key,
                {
                  'lastUpdate': value.lastUpdate.toIso8601String(),
                  'keyCurrent': value.key.currentMonthKey,
                  'keyPrevious': value.key.previousMonthKey,
                  'previousSaved': value.previousSaved,
                  'saved': value.saved,
                  'current': value.current,
                },
              ),
            ),
          );
        }

        for (final _ in Iterable<void>.generate(rate.limit - 1)) {
          expect(
            await rateLimiter.isAllowed([id], '', rate, increaseCount: true),
            true,
          );
          time.elapse(const Duration(seconds: 1));
          expect(persistence.mapState, isEmpty);
        }

        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: false),
          true,
        );
        final item1 = {
          'c': rate.limit - 1,
          'month': initialTime.toIso8601String(),
          'inner': [
            ['d', initialTime.day, rate.limit - 1],
            ['h', initialTime.hour, rate.limit - 1],
            ['mi', initialTime.minute, rate.limit - 1],
            [
              's$secsInterval',
              initialTime.second ~/ secsInterval,
              rate.limit - 1
            ],
          ]
        };
        expect(
          cachedValues(),
          {
            keyCurrent: {
              'lastUpdate': clock.ago(seconds: 1).toIso8601String(),
              'previousSaved': null,
              'keyCurrent': keyCurrent,
              'keyPrevious': keyPrevious,
              'saved': CountsMonth.empty(initialTime).toJson(),
              'current': item1
            }
          },
        );
        // timer executed
        expect(persistence.mapState, isEmpty);
        time.elapse(const Duration(seconds: 1));
        expect(persistence.mapState, isNotEmpty);
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: true),
          true,
        );

        final item2 = {
          'c': rate.limit,
          'month': clock.ago(seconds: rate.limit).toIso8601String(),
          'inner': [
            ['d', initialTime.day, rate.limit],
            ['h', initialTime.hour, rate.limit],
            ['mi', initialTime.minute, rate.limit],
            ['s$secsInterval', initialTime.second ~/ secsInterval, rate.limit],
          ]
        };

        expect(
          cachedValues(),
          {
            keyCurrent: {
              'lastUpdate': clock.now().toIso8601String(),
              'previousSaved': null,
              'keyCurrent': keyCurrent,
              'keyPrevious': keyPrevious,
              'saved': item1,
              'current': item2
            }
          },
        );
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: false),
          false,
        );
        time.elapse(const Duration(seconds: 1));
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: false),
          false,
        );
        time.elapse(const Duration(seconds: 9));
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: true),
          false,
        );
        final item3 = {
          'c': rate.limit + 1,
          'month': initialTime.toIso8601String(),
          'inner': [
            ['d', initialTime.day, rate.limit + 1],
            ['h', initialTime.hour, rate.limit + 1],
            ['mi', initialTime.minute, rate.limit + 1],
            ['s$secsInterval', initialTime.second ~/ secsInterval, rate.limit],
            ['s$secsInterval', 1, 1],
          ]
        };
        expect(
          cachedValues(),
          {
            keyCurrent: {
              'lastUpdate': clock.now().toIso8601String(),
              'previousSaved': null,
              'keyCurrent': keyCurrent,
              'keyPrevious': keyPrevious,
              'saved': item2,
              'current': item3
            }
          },
        );

        time.elapse(Duration(seconds: secsInterval * 3));
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: false),
          false,
        );
        time.elapse(Duration(seconds: secsInterval));
        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: true),
          true,
        );
        final item4 = {
          'c': rate.limit + 2,
          'month': initialTime.toIso8601String(),
          'inner': [
            ['d', initialTime.day, rate.limit + 2],
            ['h', initialTime.hour, rate.limit + 2],
            ['mi', initialTime.minute, rate.limit + 1],
            ['s$secsInterval', initialTime.second ~/ secsInterval, rate.limit],
            ['s$secsInterval', 1, 1],
            ['mi', initialTime.minute + 1, 1],
            ['s$secsInterval', 1, 1],
          ]
        };
        expect(
          cachedValues(),
          {
            keyCurrent: {
              'lastUpdate': clock.now().toIso8601String(),
              'previousSaved': null,
              'keyCurrent': keyCurrent,
              'keyPrevious': keyPrevious,
              'saved': item3,
              'current': item4
            }
          },
        );

        time.elapse(const Duration(days: 30));
        // removed cache
        expect(cachedValues(), <String, dynamic>{});

        expect(
          await rateLimiter.isAllowed([id], '', rate, increaseCount: true),
          true,
        );
        final now = clock.now();
        final item5 = {
          'c': 1,
          'month': now.toIso8601String(),
          'inner': [
            ['d', now.day, 1],
            ['h', now.hour, 1],
            ['mi', now.minute, 1],
            ['s$secsInterval', now.second ~/ secsInterval, 1],
          ]
        };
        expect(
          cachedValues(),
          {
            'rl${initialTime.year}0${initialTime.month + 1}$id': {
              'lastUpdate': clock.now().toIso8601String(),
              'previousSaved': item4,
              'keyCurrent': 'rl${initialTime.year}0${initialTime.month + 1}$id',
              'keyPrevious': keyCurrent,
              'saved': CountsMonth.empty(now).toJson(),
              'current': item5
            }
          },
        );

        expect(
          await rateLimiter.isAllowed(
            [id],
            '',
            RateLimit(1 + rate.limit + 2, time.elapsed),
            increaseCount: false,
          ),
          false,
        );

        expect(rateLimiter.isDisposed, false);
        await rateLimiter.dispose();
        expect(rateLimiter.isDisposed, true);
      });
    });

    group('Counts', () {
      test('Month jump', () {
        const rate = RateLimit(5, Duration(minutes: 1));
        final initialTime = DateTime(2023, 4, 1);
        final secsInterval = Counts.defaultSecondsPerMinuteFraction;

        final count = CountsMonth.fromJson({
          'c': rate.limit + 2,
          'month': initialTime.toIso8601String(),
          'inner': [
            ['d', initialTime.day, rate.limit + 2],
            ['h', initialTime.hour, rate.limit + 2],
            ['mi', initialTime.minute, rate.limit + 1],
            ['s$secsInterval', initialTime.second ~/ secsInterval, rate.limit],
            ['s$secsInterval', 1, 1],
            ['mi', initialTime.minute + 1, 1],
            ['s$secsInterval', 0, 1],
          ]
        });
        // expect(
        //   count.inner.first.inner.first.contained(
        //     DateTime.parse('2023-04-01 00:00:00.000'),
        //     DateTime.parse('2023-04-01 00:01:00.000'),
        //   ),
        //   CountsContained.full,
        // );
        expect(
          {
            '0': count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 0, 0)),
            '14':
                count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 0, 14)),
            '15':
                count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 0, 15)),
            '59':
                count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 0, 59)),
            '100':
                count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 1, 0)),
            '101':
                count.countInRange(initialTime, DateTime(2023, 4, 1, 0, 1, 1)),
            '202': count.countInRange(
              DateTime(2023, 3, 31, 23, 59, 15),
              DateTime(2023, 4, 1, 0, 0, 15),
            ),
            '203': count.countInRange(
              DateTime(2023, 3, 31, 23, 59, 45),
              DateTime(2023, 4, 1, 0, 0, 15),
            ),
            '204': count.countInRange(
              DateTime(2023, 3, 31, 23, 59, 16),
              DateTime(2023, 4, 1, 0, 0, 16),
            ),
            '205': count.countInRange(
              DateTime(2023, 3, 31, 23, 59, 16),
              DateTime(2023, 4, 1, 0, 0, 14),
            ),
            '201': count.countInRange(
              DateTime(2023, 4, 1, 0, 0, 30),
              DateTime(2023, 4, 1, 0, 1, 30),
            ),
          },
          {
            '0': 5,
            '14': 5,
            '15': 6,
            '59': 6,
            '100': 7,
            '101': 7,
            '202': 6,
            '203': 6,
            '204': 6,
            '205': 5,
            '201': 1
          },
        );
      });
    });

    group('Serde', () {
      test('Compression', () {
        const c = 500000;

        final r = Random(42);

        final days = CountsSerializedItem(
          counts: [],
          ids: [],
        );
        final hours = CountsSerializedItem(
          counts: [],
          ids: [],
        );
        final minutes = CountsSerializedItem(
          counts: [],
          ids: [],
        );
        final seconds = CountsSerializedItem(
          counts: [],
          ids: [],
        );
        int currentC = 0;
        int prevDay = 0;
        while (currentC < c) {
          prevDay = (r.nextBool() ? r.nextInt(1) : r.nextInt(7)) + prevDay + 1;
          if (prevDay > 31) break;
          int currentD = 0;
          int prevHour = -1;
          while (true) {
            prevHour =
                (r.nextBool() ? r.nextInt(5) : r.nextInt(10)) + prevHour + 1;
            if (prevHour > 23) break;
            int currentH = 0;
            int prevMinute = -1;
            while (true) {
              prevMinute = (r.nextBool() ? r.nextInt(8) : r.nextInt(20)) +
                  prevMinute +
                  1;
              if (prevMinute > 59) break;
              int currentMi = 0;
              int prevSecond = -1;
              while (true) {
                prevSecond = (r.nextBool() ? r.nextInt(1) : r.nextInt(4)) +
                    prevSecond +
                    1;
                if (prevSecond > 3) break;
                final currentS =
                    (r.nextBool() ? r.nextInt(10) : r.nextInt(500)) + 1;
                seconds.counts.add(currentS);
                seconds.ids.add(prevSecond);
                currentMi += currentS;
              }
              if (currentMi == 0) continue;
              minutes.counts.add(currentMi);
              minutes.ids.add(prevMinute);
              currentH += currentMi;
            }
            hours.counts.add(currentH);
            hours.ids.add(prevHour);
            currentD += currentH;
          }
          days.counts.add(currentD);
          days.ids.add(prevDay);
          currentC += currentD;
        }
        final counts = CountsMonthSerialized2(
          c: currentC,
          month: DateTime.now(),
          days: days,
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        );

        /// Brotli, Lz4, Zstd usage example
        // final bytes = utf8.encode('Hello Dart');
        // for (final codec in [brotli, lz4, zstd]) {
        //   final encoded = codec.encode(bytes);
        //   print(encoded.length);
        //   final value = counts.toJson(
        //     compressIntegers: (v) => codec.encode(
        //       Uint8List.sublistView(Int64List.fromList(v)),
        //     ),
        //   );
        //   print(jsonEncode(value).length);
        //   final decoded = codec.decode(encoded);
        //   print(utf8.decode(decoded));
        // }

        final encoders = {
          'ZLib ': ZLibEncoder().encode,
          'GZip ': GZipEncoder().encode,
          'BZip2': BZip2Encoder().encode,
        };

        final mappedCounts = counts.toCounts();
        print(utf8.encode(jsonEncode(counts)).length);
        print(utf8.encode(jsonEncode(mappedCounts)).length);

        for (final e in encoders.entries) {
          final encode = e.value;
          final value = counts.toJson(
            compressIntegers: (v) => encode(
              Uint8List.sublistView(Int64List.fromList(v)),
            )!,
          );
          print(
              '${e.key}   comp ${encode(utf8.encode(jsonEncode(value)))!.length}');
          print('${e.key} compIn ${utf8.encode(jsonEncode(value)).length}');
          print(
              '${e.key} noComp ${encode(utf8.encode(jsonEncode(counts)))!.length}');
          print(
              '${e.key} mapped ${encode(utf8.encode(jsonEncode(mappedCounts)))!.length}');
        }

// 4072
// 9418
// ZLib    comp 2236
// ZLib  compIn 2975
// ZLib  noComp 1615
// ZLib  mapped 2157
// GZip    comp 2281
// GZip  compIn 3103
// GZip  noComp 1627
// GZip  mapped 2169
// BZip2   comp 2098
// BZip2 compIn 2671
// BZip2 noComp 1466
// BZip2 mapped 1651

// 12741
// 30160
// ZLib    comp 6115
// ZLib  compIn 8168
// ZLib  noComp 4729
// ZLib  mapped 6493
// GZip    comp 6157
// GZip  compIn 8296
// GZip  noComp 4741
// GZip  mapped 6505
// BZip2   comp 4734
// BZip2 compIn 6240
// BZip2 noComp 4163
// BZip2 mapped 4607
      });
    });

    group('Cache', () {
      test('cache duration less than twice persistDuration', () {
        expect(
          () => PersistenceRateLimiter(
            InMemoryPersistance(),
            cacheDuration: const Duration(seconds: 9),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Exceptions', () {
      test('cache duration less than twice persistDuration', () {
        expect(
          () => PersistenceRateLimiter(
            InMemoryPersistance(),
            cacheDuration: const Duration(seconds: 9),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('less than 1 min limit unsupported', () {
        final persistence = InMemoryPersistance();
        final rateLimiter = PersistenceRateLimiter(persistence);

        expect(
          () => rateLimiter.isAllowed(
            ['id'],
            'key',
            const RateLimit(2, Duration(seconds: 10)),
            increaseCount: true,
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('isAllowed when disposed', () async {
        final persistence = InMemoryPersistance();
        final rateLimiter = PersistenceRateLimiter(persistence);
        await rateLimiter.dispose();

        expect(
          () => rateLimiter.isAllowed(
            ['id'],
            'key',
            const RateLimit(2, Duration(seconds: 10)),
            increaseCount: true,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
