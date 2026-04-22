import 'package:flutter/material.dart';
import 'package:telur_mobile/widgets/topbar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Profil',
        onProfileTap: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ProfileHeaderCard(),
          SizedBox(height: 14),
          _InfoCard(),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFE9F1E3),
              child: Icon(Icons.person, size: 46, color: Color(0xFF3F6B2A)),
            ),
            SizedBox(height: 12),
            Text(
              'Alex Saputra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F4A2B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Anggota Telur Mobile',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7565),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: const [
            _ProfileInfoTile(
              icon: Icons.badge_outlined,
              label: 'Nama',
              value: 'Alex Saputra',
            ),
            Divider(height: 18, color: Color(0xFFE9ECE7)),
            _ProfileInfoTile(
              icon: Icons.phone_outlined,
              label: 'Nomor Handphone',
              value: '0812-3456-7890',
            ),
            Divider(height: 18, color: Color(0xFFE9ECE7)),
            _ProfileInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'alexsaputra@gmail.com',
            ),
            Divider(height: 18, color: Color(0xFFE9ECE7)),
            _ProfileInfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal Bergabung',
              value: '10 April 2026',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1E3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF3F6B2A)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7565),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F4A2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
