import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Basic settings
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _username = 'User';

  // New settings
  String _selectedLanguage = 'Bahasa Indonesia';
  String _defaultSortOrder = 'Tanggal Dibuat';
  String _selectedTheme = 'Default';
  bool _useBiometric = false;
  int _defaultReminderTime = 30; // in minutes
  String _defaultView = 'List';
  bool _enableAutoBackup = false;
  int _autoDeleteCompletedTasks = 0; // 0 = never, 7 = week, 30 = month

  // Options lists
  final List<String> _languages = ['English', 'Bahasa Indonesia', 'Jawa'];
  final List<String> _sortOptions = [
    'Tanggal Dibuat',
    'Prioritas',
    'Abjad',
    'Tenggat Waktu'
  ];
  final List<String> _themeOptions = [
    'Default',
    'Biru',
    'Merah',
    'Hijau',
    'Ungu'
  ];
  final List<String> _viewOptions = ['List', 'Grid', 'Kalender'];
  final List<int> _deleteOptions = [0, 7, 30, 90];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load basic settings
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _username = prefs.getString('username') ?? 'User';

      // Load new settings
      _selectedLanguage = prefs.getString('language') ?? 'Bahasa Indonesia';
      _defaultSortOrder = prefs.getString('default_sort') ?? 'Tanggal Dibuat';
      _selectedTheme = prefs.getString('theme') ?? 'Default';
      _useBiometric = prefs.getBool('use_biometric') ?? false;
      _defaultReminderTime = prefs.getInt('default_reminder_time') ?? 30;
      _defaultView = prefs.getString('default_view') ?? 'List';
      _enableAutoBackup = prefs.getBool('auto_backup') ?? false;
      _autoDeleteCompletedTasks = prefs.getInt('auto_delete') ?? 0;
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Save basic settings
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setString('username', _username);

    // Save new settings
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('default_sort', _defaultSortOrder);
    await prefs.setString('theme', _selectedTheme);
    await prefs.setBool('use_biometric', _useBiometric);
    await prefs.setInt('default_reminder_time', _defaultReminderTime);
    await prefs.setString('default_view', _defaultView);
    await prefs.setBool('auto_backup', _enableAutoBackup);
    await prefs.setInt('auto_delete', _autoDeleteCompletedTasks);
  }

  String _getAutoDeleteText(int days) {
    if (days == 0) return 'Jangan pernah hapus';
    if (days == 7) return 'Setelah 1 minggu';
    if (days == 30) return 'Setelah 1 bulan';
    if (days == 90) return 'Setelah 3 bulan';
    return 'Custom';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Card
          _buildProfileCard(),

          // General Settings
          _buildSectionTitle('Umum'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Bahasa'),
              subtitle: Text(_selectedLanguage),
              onTap: () => _showLanguageDialog(),
            ),
            Divider(),
            SwitchListTile(
              secondary: Icon(Icons.dark_mode),
              title: Text('Mode Gelap'),
              subtitle: Text('Ubah tema aplikasi menjadi gelap'),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                  _saveSettings();
                });
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.color_lens),
              title: Text('Tema'),
              subtitle: Text(_selectedTheme),
              onTap: () => _showThemeDialog(),
            ),
          ]),

          // Task Preferences
          _buildSectionTitle('Preferensi Tugas'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.sort),
              title: Text('Pengurutan Default'),
              subtitle: Text(_defaultSortOrder),
              onTap: () => _showSortOrderDialog(),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.grid_view),
              title: Text('Tampilan Default'),
              subtitle: Text(_defaultView),
              onTap: () => _showViewDialog(),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.auto_delete),
              title: Text('Hapus Otomatis Tugas Selesai'),
              subtitle: Text(_getAutoDeleteText(_autoDeleteCompletedTasks)),
              onTap: () => _showAutoDeleteDialog(),
            ),
          ]),

          // Notifications
          _buildSectionTitle('Notifikasi'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.notifications),
              title: Text('Notifikasi'),
              subtitle: Text('Aktifkan notifikasi push'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Waktu Pengingat Default'),
              subtitle: Text('$_defaultReminderTime menit sebelumnya'),
              onTap: () => _showReminderTimeDialog(),
            ),
          ]),

          // Privacy & Security
          _buildSectionTitle('Privasi & Keamanan'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.fingerprint),
              title: Text('Kunci Biometrik'),
              subtitle: Text('Gunakan sidik jari/wajah untuk membuka aplikasi'),
              value: _useBiometric,
              onChanged: (value) {
                setState(() {
                  _useBiometric = value;
                  _saveSettings();
                });
              },
            ),
          ]),

          // Backup & Restore
          _buildSectionTitle('Backup & Restore'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.backup),
              title: Text('Backup Otomatis'),
              subtitle: Text('Backup data ke cloud secara otomatis'),
              value: _enableAutoBackup,
              onChanged: (value) {
                setState(() {
                  _enableAutoBackup = value;
                  _saveSettings();
                });
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.save_alt),
              title: Text('Backup Sekarang'),
              onTap: () {
                // Implement backup functionality
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Backup dimulai...')));
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restore dari Backup'),
              onTap: () {
                // Implement restore functionality
                _showRestoreDialog();
              },
            ),
          ]),

          // About & Help
          _buildSectionTitle('Tentang & Bantuan'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Tentang Aplikasi'),
              onTap: () {
                // Show about dialog
                _showAboutDialog();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Bantuan'),
              onTap: () {
                // Navigate to help screen
              },
            ),
          ]),

          SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () {
                _showLogoutDialog();
              },
              child: Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF81D4FA),
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                _username,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profil'),
                onPressed: () {
                  _showEditProfileDialog();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Column(
        children: children,
      ),
    );
  }

  // Dialog methods
  void _showEditProfileDialog() {
    final usernameController = TextEditingController(text: _username);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF81D4FA),
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pengguna',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Simpan'),
              onPressed: () {
                setState(() {
                  _username = usernameController.text;
                  _saveSettings();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Bahasa'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(_languages[index]),
                  value: _languages[index],
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSortOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pengurutan Default'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sortOptions.length,
              itemBuilder: (context, index) {
                return RadioListTile<String>(
                  title: Text(_sortOptions[index]),
                  value: _sortOptions[index],
                  groupValue: _defaultSortOrder,
                  onChanged: (value) {
                    setState(() {
                      _defaultSortOrder = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Tema'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _themeOptions.length,
              itemBuilder: (context, index) {
                Color themeColor;
                switch (_themeOptions[index]) {
                  case 'Biru':
                    themeColor = Colors.blue;
                    break;
                  case 'Merah':
                    themeColor = Colors.red;
                    break;
                  case 'Hijau':
                    themeColor = Colors.green;
                    break;
                  case 'Ungu':
                    themeColor = Colors.purple;
                    break;
                  default:
                    themeColor = Colors.blue[300]!;
                }

                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(_themeOptions[index]),
                    ],
                  ),
                  value: _themeOptions[index],
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showViewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tampilan Default'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _viewOptions.length,
              itemBuilder: (context, index) {
                IconData viewIcon;
                switch (_viewOptions[index]) {
                  case 'Grid':
                    viewIcon = Icons.grid_view;
                    break;
                  case 'Kalender':
                    viewIcon = Icons.calendar_today;
                    break;
                  default:
                    viewIcon = Icons.view_list;
                }

                return RadioListTile<String>(
                  title: Row(
                    children: [
                      Icon(viewIcon),
                      SizedBox(width: 16),
                      Text(_viewOptions[index]),
                    ],
                  ),
                  value: _viewOptions[index],
                  groupValue: _defaultView,
                  onChanged: (value) {
                    setState(() {
                      _defaultView = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReminderTimeDialog() {
    final options = [
      5,
      10,
      15,
      30,
      60,
      120,
      1440
    ]; // in minutes (last one is 1 day)
    final optionLabels = [
      '5 menit sebelumnya',
      '10 menit sebelumnya',
      '15 menit sebelumnya',
      '30 menit sebelumnya',
      '1 jam sebelumnya',
      '2 jam sebelumnya',
      '1 hari sebelumnya',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Waktu Pengingat Default'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                return RadioListTile<int>(
                  title: Text(optionLabels[index]),
                  value: options[index],
                  groupValue: _defaultReminderTime,
                  onChanged: (value) {
                    setState(() {
                      _defaultReminderTime = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAutoDeleteDialog() {
    final optionLabels = [
      'Jangan pernah hapus',
      'Setelah 1 minggu',
      'Setelah 1 bulan',
      'Setelah 3 bulan',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Otomatis Tugas Selesai'),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _deleteOptions.length,
              itemBuilder: (context, index) {
                return RadioListTile<int>(
                  title: Text(optionLabels[index]),
                  value: _deleteOptions[index],
                  groupValue: _autoDeleteCompletedTasks,
                  onChanged: (value) {
                    setState(() {
                      _autoDeleteCompletedTasks = value!;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Restore dari Backup'),
          content: Text(
              'Anda yakin ingin me-restore data? Data saat ini akan diganti dengan data backup terakhir.'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Restore'),
              onPressed: () {
                // Implement restore functionality
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore dimulai...')));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tentang Aplikasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.blue[300],
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'SkyList App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Versi 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text('© 2025 by Andini Rahmadina'),
              SizedBox(height: 8),
              Text('Dibuat dengan Flutter'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Keluar'),
          content: Text('Anda yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Keluar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Implement logout functionality
                Navigator.of(context).pop();
                // Kembali ke welcome page
                Navigator.of(context).pushReplacementNamed('/welcome');
              },
            ),
          ],
        );
      },
    );
  }
}
