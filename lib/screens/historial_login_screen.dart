import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/login_history_service.dart';

class HistorialLoginScreen extends StatefulWidget {
  const HistorialLoginScreen({Key? key}) : super(key: key);

  @override
  State<HistorialLoginScreen> createState() => _HistorialLoginScreenState();
}

class _HistorialLoginScreenState extends State<HistorialLoginScreen> {
  final LoginHistoryService _historyService = LoginHistoryService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Inicios de Sesión'),
        ),
        body: const Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Inicios de Sesión'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyService.obtenerHistorialUsuario(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay registros de inicios de sesión',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final historial = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final registro = historial[index].data() as Map<String, dynamic>;
              final Timestamp? timestamp = registro['fechaHora'] as Timestamp?;
              final DateTime? fechaHora = timestamp?.toDate();
              final String email = registro['email'] ?? 'Usuario desconocido';
              final String ipAddress = registro['ipAddress'] ?? 'IP desconocida';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.login,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            fechaHora != null
                                ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                    .format(fechaHora)
                                : 'Fecha desconocida',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'IP: $ipAddress',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: _construirEtiquetaTiempo(fechaHora),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _construirEtiquetaTiempo(DateTime? fechaHora) {
    if (fechaHora == null) return const SizedBox.shrink();

    final diferencia = DateTime.now().difference(fechaHora);
    String texto;
    Color color;

    if (diferencia.inMinutes < 60) {
      texto = 'Reciente';
      color = Colors.green;
    } else if (diferencia.inHours < 24) {
      texto = 'Hoy';
      color = Colors.orange;
    } else if (diferencia.inDays < 7) {
      texto = '${diferencia.inDays}d';
      color = Colors.blue;
    } else {
      texto = '${(diferencia.inDays / 7).floor()}sem';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}