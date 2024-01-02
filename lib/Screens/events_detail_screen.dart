// event_details_page.dart
import 'package:flutter/material.dart';
import 'package:login_screen/Models/events_model.dart';
import 'package:login_screen/QRScanner/qr_scanner.dart';

import '../Constants/api_constants.dart';
import '../Models/participant_model.dart';
import '../Services/api_service.dart';
import '../date_utils.dart';

class EventDetailsPage extends StatefulWidget {
  final EtkinlikModel event;
  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  List<ParticipantModel> participants = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Etkinlik Detayı',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrScanner(
                    onQrCodeScanned: (scannedResult) {
                      _refreshParticipants(widget.event.id);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshParticipants(widget.event.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Etkinlik Adı:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tarih ve Saat:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateUtilsFunctions.addHoursAndFormat(widget.event.time.toString()),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Katılımcılar:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                FutureBuilder<List<ParticipantModel>>(
                  future: ApiService.getParticipantsForEvent(widget.event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      print(ApiConstants.baseUrl +
                          ApiConstants.getTicketsOfEventEndpoint(widget.event.id));
                      print('Error Description: ${snapshot.error}');
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return const Text(
                        'Katılımcı bulunamadı.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      );
                    } else {
                      participants = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final participant in participants)
                            ParticipantCard(participant: participant),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshParticipants(int eventId) async {
    try {
      List<ParticipantModel> updatedParticipants =
      await ApiService.getParticipantsForEvent(eventId);
      setState(() {
        participants = updatedParticipants;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh participants: $error'),
        ),
      );
    }
  }
}

class ParticipantCard extends StatelessWidget {
  final ParticipantModel participant;

  const ParticipantCard({Key? key, required this.participant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color indicatorColor = _calculateIndicatorColor();

    return Card(
      margin: const EdgeInsets.all(7),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${participant.name} ${participant.surname}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  participant.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            _buildIndicator(indicatorColor),
          ],
        ),
      ),
    );
  }

  Color _calculateIndicatorColor() {
    if (!participant.isConfirmed) {
      return Colors.black
          .withOpacity(0.3); // Yellow when participant hasn't shown QR yet
    } else {
      return Colors.green; // Red when participant is denied
    }
  }

  Widget _buildIndicator(Color color) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
