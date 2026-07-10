// lib/screens/help_center_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple Help Center page that shows contact persons.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  // Daftar kontak (contoh statis). Anda dapat menggantinya dengan data dinamis nanti.
  static const List<_Contact> _contacts = [
    _Contact(
      name: 'Alaudin Maliqulsaleh',
      role: 'Manajer Operasional',
      phone: '+6285254282622',
      email: 'alaudin@danwise.id',
      whatsappUrl: 'https://wa.me/6285254282622?text=Halo%20Admin',
    ),
    _Contact(
      name: 'Abhel Bilqis Salsabila',
      role: 'Manajer Operasional',
      phone: '+6285748583849',
      email: 'Bilqis@danwise.id',
      whatsappUrl: 'https://wa.me/6285748583849?text=Halo%20Admin',
    ),
    _Contact(
      name: 'Muhammad Fikri',
      role: 'Manajer Operasional',
      phone: '+628131013467',
      email: 'Fikri@danwise.id',
      whatsappUrl: 'https://wa.me/628131013467?text=Halo%20Admin',
    ),
  ];

  // Membuka tautan menggunakan url_launcher.
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Tidak dapat membuka $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pusat Bantuan',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
              child: Icon(Icons.person,
                  color: const Color(0xFFDC2626), size: 28),
            ),
            title: Text(contact.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(contact.role),
            trailing: PopupMenuButton<_ContactAction>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (action) async {
                switch (action) {
                  case _ContactAction.call:
                      await _launch('tel:${contact.phone}');
                      break;
                  case _ContactAction.email:
                    await _launch('mailto:${contact.email}');
                    break;
                  case _ContactAction.whatsapp:
                    // Use custom URL if provided, otherwise fallback to phone number
                    final url = contact.whatsappUrl ??
                        'https://wa.me/' +
                            contact.phone.replaceAll('+', '').replaceAll(' ', '');
                    await _launch(url);
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _ContactAction.call,
                  child: ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Hubungi via Telepon'),
                  ),
                ),
                const PopupMenuItem(
                  value: _ContactAction.email,
                  child: ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Hubungi via Email'),
                  ),
                ),
                            const PopupMenuItem(
                value: _ContactAction.whatsapp,
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Hubungi via WhatsApp'),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helper classes / enums (private)
enum _ContactAction { call, email, whatsapp }

class _Contact {
  final String name;
  final String role;
  final String phone;
  final String email;
  final String? whatsappUrl; // optional custom WhatsApp link

  const _Contact({
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    this.whatsappUrl,
  });
}