import '../json.dart';
import 'catalog_candidate.dart';
import 'resolution_kind.dart';

class CatalogResolution {
  const CatalogResolution({required this.kind, required this.candidates});

  factory CatalogResolution.fromJson(Json json) {
    final kind = ResolutionKind.values.byName(json['kind']! as String);
    return CatalogResolution(
      kind: kind,
      candidates: switch (kind) {
        ResolutionKind.exact => [
          CatalogCandidate.fromJson(json['candidate']! as Json),
        ],
        ResolutionKind.ambiguous => decodeList(
          json['candidates'],
          CatalogCandidate.fromJson,
        ),
        ResolutionKind.unknown => const [],
      },
    );
  }

  final ResolutionKind kind;
  final List<CatalogCandidate> candidates;
}
