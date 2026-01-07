import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/reservation_management_controller.dart';
import 'package:app_gest_lavage/presentation/providers/service_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({super.key});

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  String? _selectedClientId;
  String? _selectedServiceId;
  String? _selectedCarId;
  // DateTime _selectedDate = DateTime.now();
  // TimeOfDay _selectedTime = TimeOfDay.now();
  Service? _selectedService;

  List<Map<String, dynamic>> _clients = [];
  List<Service> _services = [];
  List<Car> _cars = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authController =
          Provider.of<AuthController>(context, listen: false);
      final serviceController =
          Provider.of<ServiceManagementController>(context, listen: false);

      // Charger les services
      await serviceController.loadServices(context);
      _services = serviceController.services;

      if (authController.currentRole == 'admin') {
        // Admin : charger tous les clients
        final clientsResponse = await Supabase.instance.client
            .from('users')
            .select('id, name')
            .eq('status', 'Active');

        _clients = clientsResponse;
      } else {
        // Client : pré-remplir avec son ID
        _selectedClientId = authController.currentUser?.id;
      }

      // Charger les voitures du client (ou vide pour admin au départ)
      await _loadCarsForClient(_selectedClientId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur de chargement : $e';
      });
    }
  }

  Future<void> _loadCarsForClient(String? clientId) async {
    if (clientId == null) {
      setState(() => _cars = []);
      return;
    }

    try {
      final carsResponse = await Supabase.instance.client
          .from('cars')
          .select('*')
          .eq('user_id', clientId);

      setState(() {
        _cars = carsResponse.map((map) => Car.fromMap(map)).toList();
      });
    } catch (e) {
      print('Erreur chargement voitures: $e');
      setState(() => _cars = []);
    }
  }

  // Future<void> _pickDateTime() async {
  //   final date = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDate,
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime(2027),
  //   );

  //   if (date != null) {
  //     final time = await showTimePicker(
  //       context: context,
  //       initialTime: _selectedTime,
  //     );

  //     if (time != null) {
  //       setState(() {
  //         _selectedDate = date;
  //         _selectedTime = time;
  //       });
  //     }
  //   }
  // }

  Future<void> _submitReservation() async {
    if (_selectedClientId == null ||
        _selectedServiceId == null ||
        _selectedCarId == null ||
        _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final reservationController =
        Provider.of<ReservationManagementController>(context, listen: false);
    final auth = Provider.of<AuthController>(context, listen: false);

    // final dateTime = DateTime(
    //   _selectedDate.year,
    //   _selectedDate.month,
    //   _selectedDate.day,
    //   _selectedTime.hour,
    //   _selectedTime.minute,
    // );

    final success = await reservationController.addReservation(
      context: context,
      clientId: _selectedClientId!,
      clientName: auth.currentUser?.name ?? 'Admin',
      clientPhone: auth.currentUser?.contact ?? '42516535',
      serviceId: _selectedServiceId!,
      serviceName: _selectedService!.name,
      serviceDuration: _selectedService!.duration,
      carId: _selectedCarId!,
      // dateTime: dateTime,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retour avec succès
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reservationController.error ?? 'Échec de la réservation',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isAdmin = authController.currentRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réservation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error)))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Client (seulement pour admin)
                        if (isAdmin) ...[
                          const Text('Client',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Client',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Sélectionner un client'),
                            value: _selectedClientId,
                            items: _clients.map<DropdownMenuItem<String>>(
                                (Map<String, dynamic> client) {
                              final String id = client['id'] as String;
                              final String name = client['name'] as String? ??
                                  client['email'] as String? ??
                                  'Client sans nom';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedClientId = newValue;
                                _selectedCarId =
                                    null; // Réinitialiser la voiture
                                _cars = [];
                              });
                              if (newValue != null) {
                                _loadCarsForClient(newValue);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ] else ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Réservation pour : ${authController.currentUser?.name ?? 'Vous'}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Service
                        const Text('Service',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedServiceId,
                          hint: const Text('Choisir un service'),
                          items: _services.map((service) {
                            return DropdownMenuItem(
                              value: service.id,
                              child: Text(
                                  '${service.name} - ${service.price} UM (${service.duration} min)'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() {
                            _selectedServiceId = value;
                            _selectedService =
                                _services.firstWhere((s) => s.id == value);
                          }),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Voiture
                        const Text('Véhicule',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCarId,
                          hint: Text(
                            _cars.isEmpty
                                ? (isAdmin
                                    ? 'Sélectionnez d\'abord un client'
                                    : 'Aucune voiture enregistrée')
                                : 'Choisir une voiture',
                          ),
                          items: _cars.map<DropdownMenuItem<String>>((Car car) {
                            final display =
                                '${car.marque ?? ''} ${car.modele ?? ''}'
                                    .trim();
                            final text = display.isEmpty
                                ? car.immatriculation
                                : '$display (${car.immatriculation})';

                            return DropdownMenuItem<String>(
                              value: car.id,
                              child: Text(text),
                            );
                          }).toList(),

                          // 🔥 CLÉ DE LA SOLUTION
                          onChanged: _cars.isEmpty
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    _selectedCarId = newValue;
                                  });
                                },

                          decoration: const InputDecoration(
                            labelText: 'Véhicule',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        // const SizedBox(height: 20),

                        // // Date et heure
                        // const Text('Date et heure',
                        //     style: TextStyle(
                        //         fontSize: 16, fontWeight: FontWeight.bold)),
                        // const SizedBox(height: 8),
                        // InkWell(
                        //   onTap: _pickDateTime,
                        //   child: InputDecorator(
                        //     decoration: const InputDecoration(
                        //       border: OutlineInputBorder(),
                        //       labelText: 'Sélectionner date et heure',
                        //     ),
                        //     child: Text(
                        //       '${_selectedDate.toLocal().toString().split(' ')[0]} à ${_selectedTime.format(context)}',
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 40),

                        // Bouton valider
                        ElevatedButton(
                          onPressed: _selectedClientId != null &&
                                  _selectedServiceId != null &&
                                  _selectedCarId != null
                              ? _submitReservation
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Créer la réservation',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
