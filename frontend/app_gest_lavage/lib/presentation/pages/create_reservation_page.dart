import 'package:app_gest_lavage/presentation/pages/client/add_client_page.dart';
import 'package:app_gest_lavage/presentation/providers/auth_controller.dart';
import 'package:app_gest_lavage/presentation/providers/create_reservation_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/washops_header.dart';

/// Écran "Add Reservation" — calqué sur la maquette WashOps Pro.
/// Wrappé avec son propre ChangeNotifierProvider pour rester autonome,
/// indépendamment de la façon dont le reste de l'app fournit ses providers.
class CreateReservationPage extends StatelessWidget {
  const CreateReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateReservationProvider>(
      create: (_) => CreateReservationProvider(),
      child: const _CreateReservationView(),
    );
  }
}

class _CreateReservationView extends StatefulWidget {
  const _CreateReservationView();

  @override
  State<_CreateReservationView> createState() => _CreateReservationViewState();
}

class _CreateReservationViewState extends State<_CreateReservationView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final auth = Provider.of<AuthController>(context, listen: false);
      final provider =
          Provider.of<CreateReservationProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.init(
          isAdmin: auth.currentRole == 'admin',
          userId: auth.currentUser?.id,
        );
      });
    }
  }

  Future<void> _pickDateTime(CreateReservationProvider provider) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: provider.selectedDateTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(provider.selectedDateTime ?? now),
    );
    if (time == null) return;

    provider.onDateTimeSelected(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  IconData _iconForService(String name) {
    final n = name.toLowerCase();
    if (n.contains('premium')) return Icons.water_drop;
    if (n.contains('detail') || n.contains('full')) return Icons.auto_awesome;
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreateReservationProvider>(context);
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      backgroundColor: WashTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            WashOpsHeader(
              onAvatarTap: () => Navigator.pushNamed(context, '/profile'),
              onNotificationTap: () {},
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: WashTheme.navy),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const WashSectionTitle(
                          title: 'Add Reservation',
                          subtitle: 'Schedule a new wash service.',
                        ),
                        const SizedBox(height: 20),
                        if (provider.businessHoursMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: WashTheme.chipOrangeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: WashTheme.chipOrangeText, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.businessHoursMessage!,
                                    style: const TextStyle(
                                        color: WashTheme.chipOrangeText,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: WashTheme.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClientSection(provider, auth),
                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 18),
                              _buildCarSection(provider),
                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 18),
                              _buildServiceSection(provider),
                              const SizedBox(height: 18),
                              const Divider(height: 1),
                              const SizedBox(height: 18),
                              // _buildDateTimeSection(provider),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (provider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              provider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: WashTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: provider.canSubmit &&
                                        provider.isWithinBusinessHours
                                    ? () async {
                                        final success =
                                            await provider.submit(context);
                                        if (success && mounted) {
                                          Navigator.pop(context, true);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Réservation créée avec succès'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else if (mounted &&
                                            provider.error != null) {
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
                                icon: provider.isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.event_available,
                                        size: 18),
                                label: const Text('Create Reservation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WashTheme.navy,
                                  disabledBackgroundColor:
                                      WashTheme.navy.withOpacity(0.4),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CLIENT
  // ---------------------------------------------------------------------

  Widget _buildClientSection(
      CreateReservationProvider provider, AuthController auth) {
    if (!provider.isAdmin) {
      // Le client réserve pour lui-même : champ informatif, non modifiable.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('CLIENT'),
          const SizedBox(height: 8),
          _buildReadOnlyField(auth.currentUser?.name ?? 'Vous'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('CHOISIR LE CLIENT'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: provider.selectedClientId,
              hint: const Text('Select a client...',
                  style: TextStyle(color: WashTheme.textSecondary)),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: WashTheme.textSecondary),
              items: provider.clients
                  .map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['name']?.toString() ?? 'Client'),
                      ))
                  .toList(),
              onChanged: provider.onClientSelected,
            ),
          ),
        ),
        // const SizedBox(height: 8),
        // Align(
        //   alignment: Alignment.centerRight,
        //   child: TextButton.icon(
        //     onPressed: () async {
        //       final result = await Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (_) => const AddClientPage()),
        //       );
        //       if (result == true) {
        //         await provider.reloadClients();
        //       }
        //     },
        //     icon: const Icon(Icons.person_add_alt,
        //         size: 18, color: WashTheme.navy),
        //     label: const Text('Ajouter Client',
        //         style: TextStyle(
        //             color: WashTheme.navy, fontWeight: FontWeight.w600)),
        //   ),
        // ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // VOITURE
  // ---------------------------------------------------------------------

  Widget _buildCarSection(CreateReservationProvider provider) {
    final hasClient = provider.selectedClientId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('CHOISIR LA VOITURE'),
        const SizedBox(height: 8),
        _buildDropdownContainer(
          enabled: hasClient,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: provider.selectedCarId,
              hint: Text(
                hasClient ? 'Select a car...' : 'Select client first...',
                style: const TextStyle(color: WashTheme.textSecondary),
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: WashTheme.textSecondary),
              items: provider.availableCars
                  .map((car) => DropdownMenuItem<String>(
                        value: car.id,
                        enabled: !provider.isCarBusy(car.id),
                        child: Text(
                          '${car.marque ?? ''} ${car.modele ?? ''} — ${car.immatriculation}'
                              .trim(),
                          style: TextStyle(
                            color: provider.isCarBusy(car.id)
                                ? WashTheme.textSecondary
                                : Colors.black87,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: hasClient ? provider.onCarSelected : null,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // SERVICE
  // ---------------------------------------------------------------------

  Widget _buildServiceSection(CreateReservationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('CHOISIR LE SERVICE'),
        const SizedBox(height: 10),
        ...provider.services.map((service) {
          final selected = provider.selectedServiceId == service.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => provider.onServiceSelected(service.id),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? WashTheme.navy : WashTheme.border,
                    width: selected ? 2 : 1,
                  ),
                  color: selected
                      ? WashTheme.navy.withOpacity(0.04)
                      : Colors.white,
                ),
                child: Column(
                  children: [
                    Icon(_iconForService(service.name),
                        color: WashTheme.navy, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: WashTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service.duration} mins',
                      style: const TextStyle(
                          fontSize: 13, color: WashTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // // ---------------------------------------------------------------------
  // // DATE & HEURE
  // // ---------------------------------------------------------------------

  // Widget _buildDateTimeSection(CreateReservationProvider provider) {
  //   final formatted = provider.selectedDateTime != null
  //       ? DateFormat('MM/dd/yyyy, hh:mm a').format(provider.selectedDateTime!)
  //       : 'mm/dd/yyyy, --:-- --';

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildLabel('DATE & HEURE'),
  //       const SizedBox(height: 8),
  //       InkWell(
  //         onTap: () => _pickDateTime(provider),
  //         borderRadius: BorderRadius.circular(12),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: WashTheme.border),
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   formatted,
  //                   style: TextStyle(
  //                     color: provider.selectedDateTime != null
  //                         ? Colors.black87
  //                         : WashTheme.textSecondary,
  //                   ),
  //                 ),
  //               ),
  //               const Icon(Icons.calendar_today_outlined,
  //                   size: 18, color: WashTheme.textSecondary),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ---------------------------------------------------------------------
  // HELPERS UI
  // ---------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: WashTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: WashTheme.chipGrayBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black87)),
    );
  }

  Widget _buildDropdownContainer({required Widget child, bool enabled = true}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : WashTheme.chipGrayBg,
        border: Border.all(color: WashTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
