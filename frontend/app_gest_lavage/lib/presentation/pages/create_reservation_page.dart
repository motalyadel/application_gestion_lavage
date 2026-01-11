import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/create_reservation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color primary = Color.fromARGB(255, 25, 118, 210);
  static const Color error = Color.fromARGB(255, 229, 57, 53);
}

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({super.key});

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isAdmin = auth.currentRole == 'admin';

    return ChangeNotifierProvider(
      create: (_) => CreateReservationProvider(),
      child: Consumer<CreateReservationProvider>(
        builder: (context, provider, _) {
          // 🔥 INIT UNE SEULE FOIS
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.init(
                isAdmin: isAdmin,
                userId: auth.currentUser?.id,
              );
            });
          }

          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.error != null) {
            return Scaffold(
              body: Center(child: Text(provider.error!)),
            );
          }
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              title: const Text('Nouvelle réservation'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  /// 🔹 CONTENU SCROLLABLE
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Consumer<CreateReservationProvider>(
                            builder: (context, provider, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  /// 👤 CLIENT
                                  if (isAdmin) ...[
                                    DropdownButtonFormField<String>(
                                      value: provider.selectedClientId,
                                      decoration: const InputDecoration(
                                        labelText: 'Client',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      items: provider.clients.map((client) {
                                        return DropdownMenuItem<String>(
                                          value: client['id'],
                                          child: Text(client['name']),
                                        );
                                      }).toList(),
                                      onChanged: provider.onClientSelected,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  /// 🚗 VOITURE
                                  DropdownButtonFormField<String>(
                                    value: provider.selectedCarId,
                                    decoration: const InputDecoration(
                                      labelText: 'Voiture',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.directions_car),
                                    ),
                                    items: provider.availableCars.map((car) {
                                      return DropdownMenuItem(
                                        value: car.id,
                                        enabled: !provider.isCarBusy(car.id),
                                        child: Text(
                                          '${car.modele}(${car.immatriculation})'
                                          '${provider.isCarBusy(car.id) ? ' (En cours)' : ''}',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: provider.onCarSelected,
                                  ),

                                  const SizedBox(height: 16),

                                  /// 🧼 SERVICE
                                  DropdownButtonFormField<String>(
                                    value: provider.selectedServiceId,
                                    decoration: const InputDecoration(
                                      labelText: 'Service',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.local_car_wash),
                                    ),
                                    items: provider.services.map((s) {
                                      return DropdownMenuItem(
                                        value: s.id,
                                        child:
                                            Text('${s.name} - ${s.price} MRU'),
                                      );
                                    }).toList(),
                                    onChanged: provider.onServiceSelected,
                                  ),

                                  const SizedBox(height: 32),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// 🔻 BOUTON FIXE
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Consumer<CreateReservationProvider>(
                      builder: (context, provider, _) {
                        return Column(
                            // width: double.infinity,
                            // height: 50,
                            children: [
                              Text(
                                'Réservation pour : ${auth.currentUser?.name ?? 'Vous'}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Créer la réservation'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: provider.canSubmit
                                    ? () async {
                                        final success =
                                            await provider.submit(context);

                                        if (!context.mounted) return;

                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  '✅ Réservation ajoutée avec succès'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          Navigator.pop(context); // optionnel
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                provider.error ??
                                                    '❌ Échec de l’ajout de la réservation',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                              ),
                            ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
