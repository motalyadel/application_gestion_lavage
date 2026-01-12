// import 'package:app_gest_lavage/data/models/reservation_model.dart';
// import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/core/utils/app_massenger.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
// import 'package:app_gest_lavage/presentation/providers/car_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
// import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 25, 118, 210);
  static const Color primaryDark = Color.fromARGB(255, 13, 71, 161);
  static const Color primaryLight = Color.fromARGB(255, 187, 222, 251);
  static const Color secondary = Color.fromARGB(255, 67, 160, 71);
  static const Color accent = Color.fromARGB(255, 251, 140, 0);
  static const Color error = Color.fromARGB(255, 229, 57, 53);
  static const Color background = Color.fromARGB(255, 245, 245, 245);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);
  static const Color textPrimary = Color.fromARGB(255, 67, 37, 37);
  static const Color textSecondary = Color.fromARGB(255, 117, 117, 117);
}

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  // String? _selectedClientId;
  bool _isLoadingInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadReservationsIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReservationsIfNeeded();
  }

  void _loadReservationsIfNeeded() {
    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);
    if (!_isLoadingInitialized &&
        (reservationController.reservations.isEmpty ||
            reservationController.error != null)) {
      reservationController.loadReservations(isAdmin: true);
      _isLoadingInitialized = true;
    }
  }

  // Future<void> _showAddReservationDialog(BuildContext context) async {
  //   final reservationController =
  //       Provider.of<ReservationManagementController>(context, listen: false);
  //   final serviceController =
  //       Provider.of<ServiceManagementController>(context, listen: false);

  //   String? selectedClientId;
  //   String? selectedServiceId;
  //   String? selectedCarId;
  //   DateTime selectedDateTime = DateTime.now();
  //   List<dynamic> cars = [];

  //   // Charger les clients et services une seule fois
  //   final clients = await Supabase.instance.client
  //       .from('auth.users')
  //       .select('id, email')
  //       .eq('role', 'client');

  //   final services = serviceController.services;

  //   final result = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setStateDialog) => AlertDialog(
  //         title: const Text('Ajouter une Réservation'),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               // CLIENT
  //               DropdownButtonFormField<String>(
  //                 hint: const Text('Client'),
  //                 value: selectedClientId,
  //                 items: clients.map<DropdownMenuItem<String>>((c) {
  //                   return DropdownMenuItem(
  //                     value: c['id'],
  //                     child: Text(c['email']),
  //                   );
  //                 }).toList(),
  //                 onChanged: (value) async {
  //                   setStateDialog(() {
  //                     selectedClientId = value;
  //                     selectedCarId = null;
  //                     cars = [];
  //                   });

  //                   if (value != null) {
  //                     final data = await Supabase.instance.client
  //                         .from('cars')
  //                         .select('id, immatriculation')
  //                         .eq('user_id', value);

  //                     setStateDialog(() {
  //                       cars = data;
  //                     });
  //                   }
  //                 },
  //               ),
  //               const SizedBox(height: 12),

  //               // SERVICE
  //               DropdownButtonFormField<String>(
  //                 hint: const Text('Service'),
  //                 value: selectedServiceId,
  //                 items: services.map<DropdownMenuItem<String>>((s) {
  //                   return DropdownMenuItem(
  //                     value: s.id,
  //                     child: Text(s.name),
  //                   );
  //                 }).toList(),
  //                 onChanged: (value) =>
  //                     setStateDialog(() => selectedServiceId = value),
  //               ),
  //               const SizedBox(height: 12),

  //               // VOITURE
  //               DropdownButtonFormField<String>(
  //                 hint: const Text('Voiture'),
  //                 value: selectedCarId,
  //                 items: cars.map<DropdownMenuItem<String>>((c) {
  //                   return DropdownMenuItem(
  //                     value: c['id'],
  //                     child: Text(c['immatriculation']),
  //                   );
  //                 }).toList(),
  //                 onChanged: selectedClientId != null
  //                     ? (value) => setStateDialog(() => selectedCarId = value)
  //                     : null,
  //               ),
  //               const SizedBox(height: 12),

  //               // DATE
  //               InkWell(
  //                 onTap: () async {
  //                   final picked = await showDatePicker(
  //                     context: context,
  //                     initialDate: selectedDateTime,
  //                     firstDate: DateTime.now(),
  //                     lastDate: DateTime(2026),
  //                   );
  //                   if (picked != null) {
  //                     setStateDialog(() => selectedDateTime = picked);
  //                   }
  //                 },
  //                 child: InputDecorator(
  //                   decoration: const InputDecoration(
  //                     labelText: 'Date',
  //                     border: OutlineInputBorder(),
  //                   ),
  //                   child: Text(
  //                     selectedDateTime.toLocal().toString().split(' ')[0],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text('Annuler'),
  //           ),
  //           TextButton(
  //             onPressed: selectedClientId != null &&
  //                     selectedServiceId != null &&
  //                     selectedCarId != null
  //                 ? () => Navigator.pop(context, true)
  //                 : null,
  //             child: const Text('Ajouter'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );

  //   if (result == true) {
  //     final success = await reservationController.addReservation(
  //       context: context,
  //       clientId: selectedClientId!,
  //       serviceId: selectedServiceId!,
  //       carId: selectedCarId!,
  //       dateTime: selectedDateTime,
  //     );

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(success
  //               ? 'Réservation ajoutée'
  //               : reservationController.error ?? 'Échec'),
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isAdmin = authController.currentRole == 'admin';
    // final car = Provider.of<CarManagementController>(context);
    final reservationController =
        Provider.of<ReservationManagementController>(context);

    if (authController.user == null || authController.currentRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des Réservations'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _isLoadingInitialized = false;
              reservationController.loadReservations(isAdmin: true);
            },
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: reservationController.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : reservationController.error != null &&
                  reservationController.reservations.isEmpty
              ? Center(child: Text(reservationController.error!))
              : reservationController.reservations.isEmpty
                  ? const Center(child: Text('Aucune réservation trouvée'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: reservationController.reservations.length,
                      itemBuilder: (context, index) {
                        final reservation =
                            reservationController.reservations[index];
                        print("reservation cars ${reservation.car}");
                        print(reservation.car?.immatriculation);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                            title: Text(
                              reservation.service?.name ?? 'Service inconnu',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: reservation.status == 'waiting'
                                ? ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Début Lavage'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final success =
                                          await reservationController
                                              .startLavage(
                                        // context: context,
                                        reservationId: reservation.id, isAdmin: isAdmin,
                                      );

                                      if (success) {
                                        AppMessenger.showSuccess(
                                            '🚿 Lavage démarré avec succès');
                                        reservationController
                                            .loadReservations(isAdmin: true);
                                      } else {
                                        AppMessenger.showError(
                                          reservationController.error ??
                                              '❌ Aucune réservation en attente',
                                        );
                                      }

                                      // if (success) {
                                      //   reservationController
                                      //       .loadReservations(context);
                                      // }
                                    },
                                  )
                                : null,
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),

                                // 🚗 Immatriculation
                                Text(
                                  reservation.car?.immatriculation != null
                                      ? 'Véhicule : ${reservation.car!.immatriculation}'
                                      : 'Véhicule : inconnu',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // Position
                                Text(
                                  reservation.position != null
                                      ? 'Position  : ${reservation.position}'
                                      : 'Position non définie',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),

                                const SizedBox(height: 4),

                                // Expected time
                                Text(
                                  reservation.expectedTime != null
                                      ? 'Heure estimée : '
                                          '${reservation.expectedTime!.hour.toString().padLeft(2, '0')}:'
                                          '${reservation.expectedTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Heure estimée : en attente',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),

                                const SizedBox(height: 4),

                                // Status
                                Text(
                                  'Statut : ${reservation.status}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: reservation.status == 'waiting'
                                        ? Colors.orange
                                        : reservation.status == 'in_progress'
                                            ? Colors.blue
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     print('Bouton + cliqué !');
      //     // Ajouter un délai pour éviter le build en cours
      //     WidgetsBinding.instance.addPostFrameCallback((_) {
      //       _showAddReservationDialog(context);
      //     });
      //   },
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(Icons.add),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.pushNamed(context, '/create-reservation');
          if (result == true) {
            reservationController.loadReservations(isAdmin: true);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
