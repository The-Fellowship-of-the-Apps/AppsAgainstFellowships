import 'package:appsagainsthumanity/data/features/cards/cache/cards_cache.dart';
import 'package:appsagainsthumanity/data/features/cards/cache/in_memory_cards_cache.dart';
import 'package:appsagainsthumanity/data/features/cards/cards_repository.dart';
import 'package:appsagainsthumanity/data/features/cards/model/card_set.dart';
import 'package:appsagainsthumanity/data/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCardsRepository extends CardsRepository {
  final Firestore _db;
  final CardsCache _cache;

  FirestoreCardsRepository({Firestore firestore, CardsCache cache})
      : _db = firestore ?? Firestore.instance,
        _cache = cache ?? InMemoryCardsCache();

  @override
  Future<List<CardSet>> getAvailableCardSets() {
    return currentUserOrThrow((firebaseUser) async {
      // Check and return cache if valid
      final cachedSets = await _cache.getCardSets();
      if (cachedSets.isNotEmpty) {
        return cachedSets;
      } else {
        var cardSetsCollection = _db.collection(FirebaseConstants.COLLECTION_CARD_SETS);
        var snapshots = await cardSetsCollection.getDocuments();
        print("${snapshots.documents.length} Card sets found");
        final cardSets = snapshots.documents.map((e) {
          var cardSet = CardSet.fromJson(e.data);
          cardSet.id = e.documentID;
          return cardSet;
        }).toList();
        await _cache.setCardSets(cardSets);
        return cardSets;
      }
    });
  }
}
