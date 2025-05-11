import 'package:flutter/material.dart';
import 'category_tasks_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoriesPage extends StatefulWidget {
  @override
  _CategoriesPageState createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<String> categories = ['Umum', 'Pekerjaan', 'Pribadi'];
  Map<String, List<Map<String, dynamic>>> categoryTasks = {
    'Umum': [],
    'Pekerjaan': [],
    'Pribadi': [],
  };

  // Untuk pencarian kategori
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

  // Color palette for category cards
  final List<Color> categoryColors = [
    Colors.blue.shade100,
    Colors.green.shade100,
    Colors.orange.shade100,
    Colors.purple.shade100,
    Colors.red.shade100,
  ];

  // Icons for categories
  final List<IconData> categoryIcons = [
    Icons.category,
    Icons.work,
    Icons.person,
    Icons.school,
    Icons.home,
  ];

  // Map untuk menyimpan pengaturan warna dan ikon yang dipilih pengguna
  Map<String, Map<String, dynamic>> categorySettings = {};

  // Map untuk kategori favorit/pin
  Map<String, bool> favoritedCategories = {};

  @override
  void initState() {
    super.initState();
    // Inisialisasi pengaturan default untuk kategori awal
    for (String category in categories) {
      categorySettings[category] = {
        'colorIndex': categories.indexOf(category) % categoryColors.length,
        'iconIndex': categories.indexOf(category) % categoryIcons.length,
      };
      favoritedCategories[category] = false;
    }
    // Load data dari SharedPreferences
    _loadData();
  }

  // Menyimpan data ke SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan categories
    await prefs.setStringList('categories', categories);

    // Simpan categoryTasks (perlu dikonversi ke JSON String)
    final tasksJson = json.encode(categoryTasks);
    await prefs.setString('categoryTasks', tasksJson);

    // Simpan categorySettings
    final settingsMap = {};
    categorySettings.forEach((key, value) {
      settingsMap[key] = {
        'colorIndex': value['colorIndex'],
        'iconIndex': value['iconIndex'],
      };
    });
    await prefs.setString('categorySettings', json.encode(settingsMap));

    // Simpan favoritedCategories
    final favoritesMap = {};
    favoritedCategories.forEach((key, value) {
      favoritesMap[key] = value;
    });
    await prefs.setString('favoritedCategories', json.encode(favoritesMap));
  }

  // Memuat data dari SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load categories
    final savedCategories = prefs.getStringList('categories');
    if (savedCategories != null) {
      setState(() {
        categories = savedCategories;
      });
    }

    // Load categoryTasks
    final tasksJson = prefs.getString('categoryTasks');
    if (tasksJson != null) {
      final Map<String, dynamic> decoded = json.decode(tasksJson);
      final Map<String, List<Map<String, dynamic>>> loadedTasks = {};

      decoded.forEach((key, value) {
        final List<Map<String, dynamic>> tasksList = [];
        for (var task in value) {
          tasksList.add(Map<String, dynamic>.from(task));
        }
        loadedTasks[key] = tasksList;
      });

      setState(() {
        categoryTasks = loadedTasks;
      });
    }

    // Load categorySettings
    final settingsJson = prefs.getString('categorySettings');
    if (settingsJson != null) {
      final Map<String, dynamic> decoded = json.decode(settingsJson);
      final Map<String, Map<String, dynamic>> loadedSettings = {};

      decoded.forEach((key, value) {
        loadedSettings[key] = Map<String, dynamic>.from(value);
      });

      setState(() {
        categorySettings = loadedSettings;
      });
    }

    // Load favoritedCategories
    final favoritesJson = prefs.getString('favoritedCategories');
    if (favoritesJson != null) {
      final Map<String, dynamic> decoded = json.decode(favoritesJson);
      final Map<String, bool> loadedFavorites = {};

      decoded.forEach((key, value) {
        loadedFavorites[key] = value;
      });

      setState(() {
        favoritedCategories = loadedFavorites;
      });
    }
  }

  void _addCategory(String name) {
    if (name.trim().isEmpty || categories.contains(name)) return;

    setState(() {
      categories.add(name.trim());
      categoryTasks[name.trim()] = [];

      // Tambahkan pengaturan default untuk kategori baru
      categorySettings[name.trim()] = {
        'colorIndex': categories.length % categoryColors.length,
        'iconIndex': categories.length % categoryIcons.length,
      };
      favoritedCategories[name.trim()] = false;

      // Simpan perubahan
      _saveData();
    });
  }

  void _editCategory(int index, String newName) {
    String oldName = categories[index];
    if (newName.trim().isEmpty || categories.contains(newName)) return;

    setState(() {
      // Simpan pengaturan lama
      final oldSettings = categorySettings[oldName];
      final wasFavorited = favoritedCategories[oldName];

      categories[index] = newName;
      categoryTasks[newName] = categoryTasks[oldName]!;
      categoryTasks.remove(oldName);

      // Pindahkan pengaturan ke nama baru
      categorySettings[newName] = oldSettings!;
      categorySettings.remove(oldName);

      // Pindahkan status favorit
      favoritedCategories[newName] = wasFavorited!;
      favoritedCategories.remove(oldName);

      // Simpan perubahan
      _saveData();
    });
  }

  void _deleteCategory(int index) {
    String name = categories[index];
    setState(() {
      categories.removeAt(index);
      categoryTasks.remove(name);
      categorySettings.remove(name);
      favoritedCategories.remove(name);

      // Simpan perubahan
      _saveData();
    });
  }

  void _openTasks(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryTasksPage(
          categoryName: categoryName,
          tasks: categoryTasks[categoryName]!,
          onTasksChanged: (newTasks) {
            setState(() {
              categoryTasks[categoryName] = newTasks;
              // Simpan perubahan
              _saveData();
            });
          },
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchQuery = '';
        searchController.clear();
      } else {
        // Autofocus saat search bar ditampilkan
        FocusScope.of(context).requestFocus(FocusNode());
        // Delay sedikit untuk memastikan search bar sudah muncul
        Future.delayed(const Duration(milliseconds: 100), () {
          FocusScope.of(context).requestFocus(FocusNode());
        });
      }
    });
  }

  // Fitur untuk mengurutkan kategori
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this for fixing overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Urutkan Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Berdasarkan Nama (A-Z)'),
              onTap: () {
                setState(() {
                  categories.sort();
                  // Simpan perubahan
                  _saveData();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('Berdasarkan Jumlah Tugas'),
              onTap: () {
                setState(() {
                  categories.sort((a, b) {
                    return (categoryTasks[b]?.length ?? 0)
                        .compareTo(categoryTasks[a]?.length ?? 0);
                  });
                  // Simpan perubahan
                  _saveData();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favorit di Awal'),
              onTap: () {
                setState(() {
                  categories.sort((a, b) {
                    if (favoritedCategories[a] == favoritedCategories[b]) {
                      return a.compareTo(
                          b); // Jika status favorit sama, urutkan berdasarkan nama
                    }
                    return favoritedCategories[b]! ? 1 : -1; // Favorit di awal
                  });
                  // Simpan perubahan
                  _saveData();
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite(String category) {
    setState(() {
      favoritedCategories[category] = !(favoritedCategories[category] ?? false);
      // Simpan perubahan
      _saveData();
    });
  }

  void _showAddCategoryDialog() {
    String newName = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kategori',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => newName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (newName.trim().isNotEmpty) {
                _addCategory(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditOptions(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this for fixing overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              10.0, // Adjusted to prevent overflow
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(index);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.color_lens, color: Colors.purple),
              title: const Text('Ubah Tampilan'),
              onTap: () {
                Navigator.pop(context);
                _showAppearanceDialog(categories[index]);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                favoritedCategories[categories[index]] ?? false
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              title: Text(
                favoritedCategories[categories[index]] ?? false
                    ? 'Hapus dari Favorit'
                    : 'Tambahkan ke Favorit',
              ),
              onTap: () {
                _toggleFavorite(categories[index]);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceDialog(String category) {
    // Default values
    int selectedColorIndex = categorySettings[category]?['colorIndex'] ?? 0;
    int selectedIconIndex = categorySettings[category]?['iconIndex'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Tampilan untuk $category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Warna:'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryColors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: categoryColors[index],
                              shape: BoxShape.circle,
                              border: selectedColorIndex == index
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Pilih Ikon:'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryIcons.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIconIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIconIndex == index
                                  ? Colors.grey.shade200
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categoryIcons[index],
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
                onPressed: () {
                  setState(() {
                    categorySettings[category] = {
                      'colorIndex': selectedColorIndex,
                      'iconIndex': selectedIconIndex,
                    };
                    // Simpan perubahan
                    _saveData();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus kategori ${categories[index]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              _deleteCategory(index);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(int index) {
    String updated = categories[index];
    TextEditingController controller = TextEditingController(text: updated);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _editCategory(index, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tekan kategori untuk melihat tugas'),
            SizedBox(height: 5),
            Text('• Tekan lama untuk mengedit atau hapus'),
            SizedBox(height: 5),
            Text('• Gunakan pencarian untuk menemukan kategori'),
            SizedBox(height: 5),
            Text('• Urutkan kategori dengan tombol sort'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // Mendapatkan persentase tugas yang selesai untuk kategori tertentu
  double _getCompletionPercentage(String category) {
    final tasks = categoryTasks[category] ?? [];
    if (tasks.isEmpty) return 0.0;

    int completedCount =
        tasks.where((task) => task['isCompleted'] == true).length;
    return completedCount / tasks.length;
  }

  // Filter kategori berdasarkan kata kunci pencarian
  List<String> _getFilteredCategories() {
    if (searchQuery.isEmpty) {
      return categories;
    }

    return categories
        .where((category) =>
            category.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _getFilteredCategories();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar with horizontally aligned elements
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Search field yang sejajar dengan icon
                  Expanded(
                    child: isSearching
                        ? TextField(
                            controller: searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Cari kategori...',
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.blue.shade600),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.blue.shade600),
                                onPressed: _toggleSearch,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade200),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                          )
                        : Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _toggleSearch,
                                color: Colors.blue.shade600,
                              ),
                            ],
                          ),
                  ),
                  // Icon sort dan info tetap di sebelah kanan
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: _showSortOptions,
                    color: Colors.blue.shade600,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: _showInfoDialog,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
            ),

            // Divider line
            Divider(color: Colors.grey.shade300, height: 1),

            // Main content
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSearching
                                ? Icons.search_off
                                : Icons.category_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isSearching
                                ? 'Tidak ada kategori yang cocok'
                                : 'Belum ada kategori',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          if (isSearching)
                            TextButton(
                              onPressed: _toggleSearch,
                              child: const Text('Reset Pencarian'),
                            ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          // Increase the childAspectRatio to allow more height
                          childAspectRatio: 0.95,
                        ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final categoryName = filteredCategories[index];
                          final colorIndex = categorySettings[categoryName]
                                  ?['colorIndex'] ??
                              (index % categoryColors.length);
                          final iconIndex = categorySettings[categoryName]
                                  ?['iconIndex'] ??
                              (index % categoryIcons.length);
                          final isFavorite =
                              favoritedCategories[categoryName] ?? false;
                          final completionPercentage =
                              _getCompletionPercentage(categoryName);

                          return InkWell(
                            onTap: () => _openTasks(categoryName),
                            onLongPress: () => _showEditOptions(
                                categories.indexOf(categoryName)),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: categoryColors[colorIndex],
                              child: Stack(
                                children: [
                                  if (isFavorite)
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 22,
                                      ),
                                    ),
                                  // Made padding more compact
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 12.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Icon(
                                          categoryIcons[iconIndex],
                                          size: 32, // Reduced size
                                          color: Colors.blue.shade800,
                                        ),
                                        const SizedBox(
                                            height: 6), // Reduced spacing
                                        Text(
                                          categoryName,
                                          style: TextStyle(
                                            fontSize: 16, // Reduced font size
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                            height: 2), // Reduced spacing
                                        Text(
                                          '${categoryTasks[categoryName]?.length ?? 0} Tugas',
                                          style: TextStyle(
                                            fontSize: 12, // Reduced font size
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 6), // Reduced spacing
                                        // Progress indicator with more compact layout
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              height: 6, // Reduced height
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                child: LinearProgressIndicator(
                                                  value: completionPercentage,
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.blue.shade800,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: 2), // Reduced spacing
                                        Text(
                                          '${(completionPercentage * 100).toInt()}% Selesai',
                                          style: TextStyle(
                                            fontSize: 10, // Reduced font size
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}
