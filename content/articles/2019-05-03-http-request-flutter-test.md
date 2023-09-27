# Making HTTP Requests in Flutter Tests

By default all HTTP request made in a test invoked with `flutter test` [result in an empty response with status code 400](https://github.com/flutter/flutter/blob/63aa5b3647dbd912a02f7545fc0101003cb3adc4/packages/flutter_test/lib/src/binding.dart#L1570).

Generally that seems like a good default behavior to avoid external dependencies and hence reduce flakyness in tests. But what if you really want to make HTTP requests in your tests?

<div class="note">HTTP requests are disabled for a good reason. Before enabling them, think about whether you have an even better reason to revert that behavior.</div>

Since making outgoing requests in tests is discouraged, the usual advice is to use a mock client (for example [`MockClient`](https://pub.dartlang.org/documentation/http/latest/testing/MockClient-class.html) from the `http` package).

But how does one then efficiently and correctly create mock responses and assertions for incoming requests? For that we've written a request/response recording HTTP client.

Tests get run once with recording enabled, which writes the requests and responses as JSON files to disk. On subsequent runs the recording can then be disabled and all requests will be served form those files.

So that's why we needed to enable HTTP requests during tests in this specific case. How does one go about enabling them?

Turns out there is a discussion about this exact behavior on [Flutter's GitHub Issues](https://github.com/flutter/flutter/issues/19588#issuecomment-406771070) which I was lucky to find after some searching. The simplified version of that solution, shown here as part of a test, is this:

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
// [...] other testing imports

Future<void> main() async {
  HttpOverrides.global = _MyHttpOverrides(); // Setting a customer override that'll use an unmocked HTTP client

  testWidgets(
    'Test with HTTP enabled',
    (tester) async {
      await tester.runAsync(() async { // Use `runAsync` to make real asynchronous calls
        expect(
          (await http.Client().get('https://www.google.com/')).statusCode,
          200,
        );
      });
    },
  );
}

class _MyHttpOverrides extends HttpOverrides {}
```
