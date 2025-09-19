import 'package:cloud_firestore/cloud_firestore.dart';

class StaffSeeder {
  /// Adds an `image` field to every staff document with a placeholder URL.
  static Future<void> addImageFieldToStaff() async {
    final staffCollection = FirebaseFirestore.instance.collection("staff");
    final snapshot = await staffCollection.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // ✅ Only add image if it's missing
      if (!data.containsKey("image")) {
        await staffCollection.doc(doc.id).update({
          "image": "https://picsum.photos/seed/${doc.id}/400/300"
        });
        print("Added image for staff: ${doc.id}");
      } else {
        print("Skipped (already has image): ${doc.id}");
      }
    }

    print("✅ Seeding complete! All staff documents now have an image field.");
  }
}
