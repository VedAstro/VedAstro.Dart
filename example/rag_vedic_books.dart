import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Semantic search across classical Vedic texts, so an answer can be grounded in a
/// source rather than in a model's memory.
///
///     dart run example/rag_vedic_books.dart
Future<void> main() async {
  final client = demoClient();
  final pace = demoShouldPace(client);

  demoHeading('Which texts are indexed');
  final sources = await client.calculate().getAvailableSourceTexts();
  for (final source in Response.list(sources, [])) {
    // Each entry is a name and the number of chunks indexed for it.
    // ignore: avoid_print
    print('   - $source');
  }

  await demoPace(enabled: pace);

  const question = 'effects of Saturn in the seventh house';
  demoHeading('Searching: "$question"');

  final passages = await client.calculate().searchSourceText(question, topK: 3);
  for (final passage in Response.list(passages, [])) {
    demoField('Source', Response.string(passage, 'sourceName'));
    demoField('Page', Response.intValue(passage, 'pageNumber'));
    demoField('Score', Response.doubleValue(passage, 'score'));
    // ignore: avoid_print
    print('   ${demoTruncate(Response.string(passage, 'text'), 220)}\n');
  }

  client.close();
}
