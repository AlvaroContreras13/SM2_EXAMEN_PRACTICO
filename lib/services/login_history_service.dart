import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'historial_alvaro';

  //registrar un nuevo inicio de sesión
  Future<void> registrarInicioSesion(String userId, String email) async {
    try {
      String ipAddress = await _obtenerDireccionIP();
      
      await _firestore.collection(collectionName).add({
        'userId': userId,
        'email': email,
        'fechaHora': FieldValue.serverTimestamp(),
        'ipAddress': ipAddress,
      });
      
      print('Inicio de sesión registrado correctamente');
    } catch (e) {
      print('Error al registrar inicio de sesión: $e');
    }
  }

  //obtener la dirección IP del usuario
  Future<String> _obtenerDireccionIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] ?? 'IP desconocida';
      }
      return 'IP desconocida';
    } catch (e) {
      print('Error al obtener IP: $e');
      return 'IP desconocida';
    }
  }

  //obtener el historial de inicios de sesión de un usuario
  Stream<QuerySnapshot> obtenerHistorialUsuario(String userId) {
    return _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('fechaHora', descending: true)
        .snapshots();
  }

  //obtener historial con límite
  Future<List<Map<String, dynamic>>> obtenerHistorialLimitado(
      String userId, int limite) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('fechaHora', descending: true)
          .limit(limite)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error al obtener historial limitado: $e');
      return [];
    }
  }

  //eliminar registros antiguos 
  Future<void> limpiarHistorialAntiguo(String userId, int diasAntiguedad) async {
    try {
      DateTime fechaLimite = DateTime.now().subtract(Duration(days: diasAntiguedad));
      
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('fechaHora', isLessThan: fechaLimite)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('Historial antiguo limpiado');
    } catch (e) {
      print('Error al limpiar historial: $e');
    }
  }
}