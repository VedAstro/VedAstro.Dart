import 'package:test/test.dart';
import 'package:vedastro/vedastro.dart';

import 'fake_transport.dart';

void main() {
  group('Time', () {
    test('accepts the API format and remembers it verbatim', () {
      final moment = sampleBirth();
      expect(moment.stdTime, '14:30 25/10/1992 +05:30');
      expect(moment.location.name, 'Mumbai');
    });

    test('reads the day before the month, as VedAstro does', () {
      // 25/10/1992 is 25 October, not 10 May. Getting this backwards is the single
      // most common way to get a plausible but wrong chart.
      final moment = Time.of(
        '08:05 03/11/2001 +08:00',
        GeoLocation.of('Singapore', 103.8198, 1.3521),
      );
      final parts = moment.toJson();
      expect(parts['StdTime'], '08:05 03/11/2001 +08:00');
    });

    test('rejects a date that does not exist', () {
      expect(
        () => Time.of(
          '10:00 31/02/2020 +00:00',
          GeoLocation.of('Nowhere', 0, 0),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a badly shaped string', () {
      for (final bad in [
        '14:30 1992-10-25 +05:30', // ISO order
        '14:30 25/10/1992', // no offset
        '2:30 25/10/1992 +05:30', // unpadded hour
        'nonsense',
        '',
      ]) {
        expect(
          () => Time.of(bad, GeoLocation.of('Mumbai', 72.8777, 19.0760)),
          throwsArgumentError,
          reason: 'should reject "$bad"',
        );
      }
    });

    test('rejects an impossible clock time', () {
      expect(
        () => Time.of('25:00 25/10/1992 +05:30',
            GeoLocation.of('Mumbai', 72.8777, 19.0760)),
        throwsArgumentError,
      );
      expect(
        () => Time.of('10:75 25/10/1992 +05:30',
            GeoLocation.of('Mumbai', 72.8777, 19.0760)),
        throwsArgumentError,
      );
    });

    test('builds from fields with a half-hour offset', () {
      final moment = Time.ofFields(
        year: 1992,
        month: 10,
        day: 25,
        hour: 14,
        minute: 30,
        location: GeoLocation.of('Mumbai', 72.8777, 19.0760),
        offset: 5.5,
      );
      expect(moment.stdTime, '14:30 25/10/1992 +05:30');
    });

    test('formats a negative offset with the right sign', () {
      final moment = Time.ofFields(
        year: 1992,
        month: 10,
        day: 25,
        hour: 9,
        minute: 0,
        location: GeoLocation.of('New York', -74.006, 40.7128),
        offset: -5,
      );
      expect(moment.stdTime, '09:00 25/10/1992 -05:00');
    });

    test('builds from a DateTime', () {
      final moment = Time.fromDateTime(
        DateTime.utc(1992, 10, 25, 9, 0),
        GeoLocation.of('Mumbai', 72.8777, 19.0760),
        utcOffset: 5.5,
      );
      expect(moment.stdTime, '14:30 25/10/1992 +05:30');
    });

    test('serialises to the wire shape the API expects', () {
      final json = sampleBirth().toJson();
      expect(json['StdTime'], '14:30 25/10/1992 +05:30');
      expect(json['Location'], {
        'Name': 'Mumbai',
        'Longitude': 72.8777,
        'Latitude': 19.0760,
      });
    });
  });

  group('GeoLocation', () {
    test('accepts the whole legal range', () {
      expect(() => GeoLocation.of('Null Island', 0, 0), returnsNormally);
      expect(() => GeoLocation.of('Dateline', 180, 90), returnsNormally);
      expect(() => GeoLocation.of('Dateline', -180, -90), returnsNormally);
    });

    test('rejects an out-of-range latitude and longitude', () {
      expect(() => GeoLocation.of('Bad', 200, 10), throwsArgumentError);
      expect(() => GeoLocation.of('Bad', 100, 95), throwsArgumentError);
      expect(() => GeoLocation.of('Bad', -181, 0), throwsArgumentError);
      expect(() => GeoLocation.of('Bad', 0, -91), throwsArgumentError);
    });

    test('keeps a coordinate pair that is valid in either order', () {
      // Mumbai as (lon, lat) and as (lat, lon) are both inside the legal ranges, so
      // the two cannot be told apart - the ranges overlap. Recorded here so the
      // silent-failure mode is known: check your own coordinates.
      final correct = GeoLocation.of('Mumbai', 72.8777, 19.0760);
      expect(correct.longitude, 72.8777);
      expect(correct.latitude, 19.0760);
    });
  });

  group('Response', () {
    final payload = <String, Object?>{
      'Name': 'Libra',
      'DegreesIn': {
        'DegreeMinuteSecond': "8° 26' 31",
        'TotalDegrees': '8.441944444444445',
      },
      'IsRetrograde': false,
      'Count': 7,
      'Items': [
        {'Name': 'first'},
        {'Name': 'second'},
      ],
    };

    test('reads a top-level key', () {
      expect(Response.string(payload, 'Name'), 'Libra');
    });

    test('reads a nested key through a path list', () {
      expect(Response.string(payload, ['DegreesIn', 'DegreeMinuteSecond']),
          "8° 26' 31");
    });

    test('reads a numeric string as a double, which is what the API sends', () {
      expect(Response.doubleValue(payload, ['DegreesIn', 'TotalDegrees']),
          closeTo(8.4419, 0.0001));
    });

    test('reads an int and a bool', () {
      expect(Response.intValue(payload, 'Count'), 7);
      expect(Response.boolValue(payload, 'IsRetrograde'), false);
    });

    test('indexes into a list', () {
      expect(Response.string(payload, ['Items', 1, 'Name']), 'second');
    });

    test('returns defaults instead of throwing on a wrong shape', () {
      // This is the property that keeps a service up when the API changes shape.
      expect(Response.string(payload, 'Missing'), '');
      expect(Response.string(payload, ['Name', 'TooDeep']), '');
      expect(Response.doubleValue(payload, 'Name'), isNull);
      expect(Response.intValue(payload, 'Missing'), isNull);
      expect(Response.boolValue(payload, 'Missing'), isNull);
      expect(Response.list(payload, 'Missing'), isEmpty);
      expect(Response.map(payload, 'Missing'), isEmpty);
      expect(Response.count(payload, 'Missing'), 0);
      expect(Response.get(payload, 'Missing'), isNull);
      expect(Response.has(payload, 'Missing'), isFalse);
      expect(Response.get(payload, ['Items', 99, 'Name']), isNull);
    });

    test('accepts a bare payload that is not a map', () {
      expect(Response.string('Aquarius', 'Name'), '');
      expect(Response.list([1, 2, 3], []), hasLength(3));
    });
  });

  group('Request encoding', () {
    test('posts to the endpoint with the key and the arguments', () async {
      final transport = FakeTransport()
        ..respondWith('PlanetRasiD1Sign', {'Name': 'Libra'});
      final client = clientWith(transport);

      await client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth());

      expect(transport.lastUrl.toString(),
          'https://example.test/api/Calculate/PlanetRasiD1Sign');
      expect(transport.lastBody['APIKey'], 'test-key');
      expect(transport.lastBody['planetName'], 'Sun');
      expect(
        (transport.lastBody['time']! as Map)['StdTime'],
        '14:30 25/10/1992 +05:30',
      );
      expect(transport.lastHeaders['Content-Type'], 'application/json');
    });

    test('trims a trailing slash so URLs never double up', () async {
      final transport = FakeTransport()
        ..respondWith('HouseSignName', 'Aquarius');
      final client = VedAstroClient(
        apiKey: 'k',
        baseUrl: 'https://example.test/api/Calculate/',
        silent: true,
        buildTransport: (_) => transport,
      );

      await client.calculate().houseSignName(HouseName.house1, sampleBirth());
      expect(transport.lastUrl.toString(),
          'https://example.test/api/Calculate/HouseSignName');
    });

    test(
        'omits an optional argument left null, so the server applies its default',
        () async {
      final transport = FakeTransport()
        ..respondWith('SearchSourceText', <Object?>[]);
      final client = clientWith(transport);

      await client.calculate().searchSourceText('saturn in 7th');
      expect(transport.lastBody.containsKey('useRawBindus'), isFalse);
      expect(transport.lastBody['query'], 'saturn in 7th');
    });

    test(
        'sends an optional argument when it is set, including a false or a zero',
        () async {
      final transport = FakeTransport()
        ..respondWith('AshtakavargaTransitPrediction', <Object?>[]);
      final client = clientWith(transport);

      await client.calculate().ashtakavargaTransitPrediction(
            PlanetName.sun,
            1,
            2,
            sampleBirth(),
            useRawBindus: false,
          );

      expect(transport.lastBody['useRawBindus'], isFalse);
    });

    test('sends the client default ayanamsa as its wire name', () async {
      final transport = FakeTransport()
        ..respondWith('PlanetRasiD1Sign', 'Libra');
      final client = clientWith(transport, ayanamsa: Ayanamsa.lahiri);

      await client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth());
      expect(transport.lastBody['Ayanamsa'], 'LAHIRI');
    });

    test('lets a call override the client ayanamsa', () async {
      final transport = FakeTransport()
        ..respondWith('PlanetRasiD1Sign', 'Libra');
      final client = clientWith(transport, ayanamsa: Ayanamsa.lahiri);

      await client.call(
        'PlanetRasiD1Sign',
        parameters: {'planetName': PlanetName.sun, 'birthTime': sampleBirth()},
        ayanamsa: Ayanamsa.raman,
      );
      expect(transport.lastBody['Ayanamsa'], 'RAMAN');
    });

    test('rejects a blank endpoint and a non-positive timeout', () {
      final transport = FakeTransport();
      final client = clientWith(transport);
      expect(() => client.call('  '), throwsArgumentError);
      expect(
        () => VedAstroClient(
            timeout: Duration.zero,
            silent: true,
            buildTransport: (_) => transport),
        throwsArgumentError,
      );
    });
  });

  group('Payload unwrapping', () {
    test('unwraps a single-property payload, as the family does', () async {
      final transport = FakeTransport()
        ..respondWith('HouseSignName', 'Aquarius');
      final client = clientWith(transport);

      final result = await client
          .calculate()
          .houseSignName(HouseName.house1, sampleBirth());
      expect(result, 'Aquarius');
    });

    test('keeps a multi-property payload as a map', () async {
      final transport = FakeTransport()
        ..respondWith('LunarDay', {
          'Name': 'Amavasya',
          'Paksha': 'Krishna',
          'Date': '30/30',
        });
      final client = clientWith(transport);

      final result = await client.calculate().lunarDay(sampleBirth());
      expect(result, isA<Map<String, Object?>>());
      expect(Response.string(result, 'Name'), 'Amavasya');
      expect(Response.string(result, 'Paksha'), 'Krishna');
    });

    test('returns a list payload unwrapped to the list', () async {
      final transport = FakeTransport()
        ..respondWith('AllPlanetRasiSigns', [
          {'Planet': 'Sun', 'Sign': 'Libra'},
          {'Planet': 'Moon', 'Sign': 'Scorpio'},
        ]);
      final client = clientWith(transport);

      final result = await client.calculate().allPlanetRasiSigns(sampleBirth());
      expect(result, isA<List<Object?>>());
      expect(Response.count(result, []), 2);
    });

    test('treats an SVG response as markup rather than an envelope', () async {
      final transport = FakeTransport()
        ..statusCode = 200
        ..contentType = 'image/svg+xml'
        ..body = '<svg viewBox="0 0 10 10"><rect/></svg>';
      final client = clientWith(transport);

      final result = await client.calculate().southIndianChart(sampleBirth());
      expect(result, startsWith('<svg'));
    });

    test('detects SVG even when the content type lies', () async {
      final transport = FakeTransport()
        ..contentType = 'text/plain'
        ..body = '  <svg xmlns="http://www.w3.org/2000/svg"></svg>';
      final client = clientWith(transport);

      final result = await client.calculate().southIndianChart(sampleBirth());
      expect(result, contains('<svg'));
    });
  });

  group('Errors', () {
    test(
        'raises ApiException for the API failure envelope, carrying the endpoint',
        () async {
      final transport = FakeTransport()
        ..respondFailure('Free tier rate limit exceeded (5 calls/minute).');
      final client = clientWith(transport);

      await expectLater(
        client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.endpoint, 'endpoint', 'PlanetRasiD1Sign')
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.isHttpFailure, 'isHttpFailure', isFalse)
              .having((e) => e.message, 'message', contains('rate limit')),
        ),
      );
    });

    test('raises ApiException for a non-2xx status, carrying it', () async {
      final transport = FakeTransport()
        ..statusCode = 503
        ..body = 'upstream exploded';
      final client = clientWith(transport);

      await expectLater(
        client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.isHttpFailure, 'isHttpFailure', isTrue),
        ),
      );
    });

    test('raises ApiException for malformed JSON', () async {
      final transport = FakeTransport()..body = '{not json at all';
      final client = clientWith(transport);

      await expectLater(
        client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth()),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('invalid JSON'))),
      );
    });

    test('raises ApiException when the envelope has no Payload', () async {
      final transport = FakeTransport()..body = '{"Status":"Pass"}';
      final client = clientWith(transport);

      await expectLater(
        client.calculate().planetRasiD1Sign(PlanetName.sun, sampleBirth()),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', contains('missing its Payload'))),
      );
    });

    test('never echoes the API key in a message', () async {
      final transport = FakeTransport()
        ..respondFailure('rejected key test-key for your account');
      final client = clientWith(transport);

      try {
        await client
            .calculate()
            .planetRasiD1Sign(PlanetName.sun, sampleBirth());
        fail('should have thrown');
      } on ApiException catch (failure) {
        expect(failure.message, isNot(contains('test-key')));
        expect(failure.message, contains('[redacted]'));
      }
    });
  });

  group('Client', () {
    test('reports whether a key is configured', () {
      expect(clientWith(FakeTransport()).hasApiKey, isTrue);
      expect(
        VedAstroClient(silent: true, buildTransport: (_) => FakeTransport())
            .hasApiKey,
        isFalse,
      );
    });

    test('reads configuration from a supplied environment', () {
      final client = VedAstroClient.fromEnvironment(
        {
          'VEDASTRO_API_KEY': 'env-key',
          'VEDASTRO_BASE_URL': 'https://alt.test/api'
        },
        silent: true,
      );
      expect(client.apiKey, 'env-key');
      expect(client.baseUrl, 'https://alt.test/api');
    });

    test('falls back to the public service when the environment is empty', () {
      final client = VedAstroClient.fromEnvironment({}, silent: true);
      expect(client.apiKey, '');
      expect(client.baseUrl, VedAstroClient.defaultBaseUrl);
    });

    test('rejects a blank base URL', () {
      expect(
        () => VedAstroClient(
            baseUrl: '  ',
            silent: true,
            buildTransport: (_) => FakeTransport()),
        throwsArgumentError,
      );
    });

    test('closes the transport', () {
      final transport = FakeTransport();
      clientWith(transport).close();
      expect(transport.closed, isTrue);
    });

    test('applies no request timeout by default', () {
      // A calculation can take minutes; the library must not guess a deadline.
      final defaultClient = VedAstroClient(silent: true);
      expect(defaultClient.timeout, isNull);
      defaultClient.close();

      // An explicit deadline is honoured.
      final limited =
          VedAstroClient(timeout: const Duration(seconds: 42), silent: true);
      expect(limited.timeout, const Duration(seconds: 42));
      limited.close();
    });

    test('reports everything the API sent through callWithResponse', () async {
      final transport = FakeTransport()
        ..respondWith('HouseSignName', 'Aquarius');
      final client = clientWith(transport);

      final response = await client.callWithResponse(
        'HouseSignName',
        parameters: {'houseName': HouseName.house1, 'birthTime': sampleBirth()},
      );
      expect(response.endpoint, 'HouseSignName');
      expect(response.statusCode, 200);
      expect(response.payload, 'Aquarius');
      expect(response.contentType, contains('json'));
    });
  });

  group('Generated surface', () {
    test('exposes every calculator with a unique name', () {
      const expected = 685;
      final names = Calculators.methodNames;
      expect(names, hasLength(expected));
      expect(names.toSet(), hasLength(expected),
          reason: 'method names must be unique');
    });

    test('includes the newest endpoint alongside the classics', () {
      final names = Calculators.methodNames;
      for (final name in [
        'planetRasiD1Sign',
        'houseSignName',
        'lunarDay',
        'southIndianChart',
        'searchSourceText',
        'astrocartography',
      ]) {
        expect(names, contains(name));
      }
    });

    test('carries the API wire names on the enums', () {
      expect(PlanetName.sun.wireName, 'Sun');
      expect(PlanetName.all.wireName, 'All');
      expect(HouseName.house1.wireName, 'House1');
      expect(Ayanamsa.lahiri.wireName, 'LAHIRI');
      expect(Ayanamsa.faganBradley.wireName, 'FAGAN_BRADLEY');
      expect(Ayanamsa.values, hasLength(47));
    });
  });
}
