import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> ejecutarMigracionRemoveEstadoPago() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('solicitudes').get();

  var actualizados = 0;
  for (final doc in snapshot.docs) {
    if (!doc.data().containsKey('estadoPago')) continue;
    await doc.reference.update({'estadoPago': FieldValue.delete()});
    actualizados++;
  }

  // ignore: avoid_print
  print('Migración completada: $actualizados documentos actualizados.');
}
