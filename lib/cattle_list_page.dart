import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app_scaffold.dart';
import 'cattle_detail_page.dart';
import 'cattle_registration_page.dart';
import 'models/app_models.dart';
import 'session_controller.dart';

class CattleListPage extends StatefulWidget {
  const CattleListPage({super.key});

  @override
  State<CattleListPage> createState() => _CattleListPageState();
}

class _CattleListPageState extends State<CattleListPage> {
  final _searchController = TextEditingController();
  late Future<CattlePageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<CattlePageData> _load() {
    return context.read<SessionController>().api.listCattle(
          search: _searchController.text.trim(),
          size: 100,
        );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cattle Registry',
      current: AppSection.cattle,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: unzaGreen,
        foregroundColor: Colors.white,
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CattleRegistrationPage()),
          );
          if (changed == true) _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Register'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by cattle ID, breed, or owner',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              onSubmitted: (_) => _refresh(),
            ),
            const SizedBox(height: 16),
            FutureBuilder<CattlePageData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _MessageCard(
                    icon: Icons.error_outline,
                    title: 'Could not load cattle',
                    message: snapshot.error.toString(),
                  );
                }
                final cattle = snapshot.data?.content ?? const <CattleRecord>[];
                if (cattle.isEmpty) {
                  return const _MessageCard(
                    icon: Icons.pets_outlined,
                    title: 'No cattle records found',
                    message: 'Try a different search or register a new animal.',
                  );
                }
                return Column(
                  children: cattle
                      .map(
                        (item) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: unzaGold.withOpacity(0.18),
                              child: const Icon(Icons.pets_outlined, color: unzaBlack),
                            ),
                            title: Text(
                              item.cattleId,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${item.breed} • ${item.owner}\n'
                                '${item.farmName ?? item.farmLocation ?? 'No farm'} • '
                                'Registered ${DateFormat('dd MMM yyyy').format(item.registeredAt)}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final changed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CattleDetailPage(cattleId: item.id),
                                ),
                              );
                              if (changed == true) _refresh();
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Colors.black45),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
