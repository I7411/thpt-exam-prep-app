import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thpt_exam_prep_app/providers/admin_provider.dart';

class AdminDocumentManagementScreen extends StatefulWidget {
  const AdminDocumentManagementScreen({super.key});

  @override
  State<AdminDocumentManagementScreen> createState() => _AdminDocumentManagementScreenState();
}

class _AdminDocumentManagementScreenState extends State<AdminDocumentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<AdminProvider>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài liệu'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryCard(provider: provider),
                  const SizedBox(height: 16),
                  if (provider.documentSummaries.isEmpty)
                    const _EmptyState(message: 'Chưa có tài liệu nào')
                  else
                    ...provider.documentSummaries.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DocumentCard(item: item),
                        )),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo UI: thêm tài liệu'))),
        icon: const Icon(Icons.add),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AdminProvider provider;

  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStat(label: 'Tổng tài liệu', value: provider.documents.length.toString(), color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat(label: 'Môn', value: provider.subjects.length.toString(), color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _MiniStat(label: 'Cập nhật', value: provider.documentSummaries.where((item) => item.status == 'Updated').length.toString(), color: Colors.orange)),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final AdminDocumentSummary item;

  const _DocumentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.description, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.document.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(item.document.description, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: item.subjectName, color: Colors.blue),
              _Tag(label: item.status, color: item.status == 'Updated' ? Colors.green : Colors.orange),
              _Tag(label: 'Cập nhật: ${item.document.updatedAt?.toLocal().toString().split('.').first ?? '-'}', color: Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.edit), label: const Text('Sửa')),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.delete), label: const Text('Xóa')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.16))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade200)),
      child: Text(message, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}