import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Public listing data only. Email/password and personal shortcuts never enter it.
class PublicPlaces {
  static bool get ready => Firebase.apps.isNotEmpty;
  static bool get publishingEnabled =>
      ready && const bool.fromEnvironment('PUBLIC_PLACES_ENABLED', defaultValue: true);
  static String? get uid =>
      ready ? FirebaseAuth.instance.currentUser?.uid : null;
  static bool owns(Map<String, dynamic> place) =>
      uid != null && place['ownerUid'] == uid;
  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('public_places');
  static const fields = [
    'name',
    'category',
    'lat',
    'lng',
    'address',
    'phone',
    'website',
    'about',
    'hours',
    'hoursMode',
    'aliases',
  ];

  static Future<String> save(
    Map<String, dynamic> data, {
    String? publicId,
  }) async {
    if (!publishingEnabled)
      throw StateError('Public publishing is not enabled yet.');
    final owner = uid;
    if (owner == null) throw StateError('Sign in before publishing.');
    final lat = data['lat'], lng = data['lng'];
    if (lat is! num ||
        lng is! num ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180 ||
        (data['name']?.toString().trim() ?? '').isEmpty) {
      throw ArgumentError('Invalid place');
    }
    final value = <String, dynamic>{
      for (final key in fields)
        if (data[key] != null) key: data[key],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = publicId == null ? collection.doc() : collection.doc(publicId);
    if (publicId == null) {
      await ref.set({
        ...value,
        'ownerUid': owner,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // The server rule also enforces ownership and immutable ownerUid/createdAt.
      await ref.update(value);
    }
    return ref.id;
  }

  static Future<void> delete(Map<String, dynamic> place) async {
    if (!owns(place))
      throw StateError('Only the creator can delete this place.');
    await collection.doc(place['publicId'] as String).delete();
  }
}
