// lib/admin/screens/admin_poojas_screen.dart
// CRUD management for Poojas — accessible only to admin.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../controllers/admin_controller.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

class AdminPoojasScreen extends ConsumerStatefulWidget {
  const AdminPoojasScreen({super.key});

  @override
  ConsumerState<AdminPoojasScreen> createState() =>
      _AdminPoojasScreenState();
}

class _AdminPoojasScreenState extends ConsumerState<AdminPoojasScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final poojas = state.poojas
        .where((p) =>
            _search.isEmpty ||
            p.title.toLowerCase().contains(_search.toLowerCase()) ||
            p.category.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final loading = state.isSectionLoading(AdminSection.poojas);

    ref.listen<AdminState>(adminProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
        ref.read(adminProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Poojas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPoojaDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Pooja'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search poojas…',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Summary chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _PillChip(
                    label:
                        '${state.poojas.where((p) => p.isActive).length} Active',
                    color: AppColors.success),
                const SizedBox(width: 8),
                _PillChip(
                    label:
                        '${state.poojas.where((p) => !p.isActive).length} Inactive',
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _PillChip(
                    label:
                        '${state.poojas.where((p) => p.isOnlineAvailable).length} Online-ready',
                    color: AppColors.info),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: poojas.isEmpty
                ? const Center(
                    child: Text('No poojas found',
                        style:
                            TextStyle(color: AppColors.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemCount: poojas.length,
                    itemBuilder: (_, i) => _PoojaCard(
                      pooja: poojas[i],
                      onEdit: () =>
                          _showPoojaDialog(context, ref, poojas[i]),
                      onDelete: () =>
                          _confirmDelete(context, ref, poojas[i]),
                      onToggle: (v) => ref
                          .read(adminProvider.notifier)
                          .togglePooja(poojas[i].id, isActive: v),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AdminPooja pooja) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pooja?'),
        content: Text(
            '"${pooja.title}" will be permanently removed from listings.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ctx.pop();
              ref
                  .read(adminProvider.notifier)
                  .deletePooja(pooja.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPoojaDialog(
      BuildContext context, WidgetRef ref, AdminPooja? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PoojaFormSheet(
        existing: existing,
        onSave: (p) {
          if (existing == null) {
            ref.read(adminProvider.notifier).createPooja(p);
          } else {
            ref.read(adminProvider.notifier).updatePooja(p);
          }
        },
      ),
    );
  }
}

// ── Pooja card ────────────────────────────────────────────────────────────────

class _PoojaCard extends StatelessWidget {
  const _PoojaCard({
    required this.pooja,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final AdminPooja pooja;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pooja.isActive
              ? AppColors.divider
              : AppColors.warning.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pooja.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Switch(
                value: pooja.isActive,
                onChanged: onToggle,
                activeThumbColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pooja.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pooja.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                icon: Icons.currency_rupee,
                label: '₹${pooja.basePrice.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule,
                label: pooja.durationLabel,
              ),
              if (pooja.isOnlineAvailable) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.wifi,
                  label: 'Online',
                  color: AppColors.info,
                ),
              ],
              const Spacer(),
              _ActionIcon(
                icon: Icons.edit_outlined,
                color: AppColors.secondary,
                onTap: onEdit,
              ),
              const SizedBox(width: 6),
              _ActionIcon(
                icon: Icons.delete_outline,
                color: AppColors.error,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pooja form sheet ──────────────────────────────────────────────────────────

class _PoojaFormSheet extends StatefulWidget {
  const _PoojaFormSheet({this.existing, required this.onSave});
  final AdminPooja? existing;
  final ValueChanged<AdminPooja> onSave;

  @override
  State<_PoojaFormSheet> createState() => _PoojaFormSheetState();
}

class _PoojaFormSheetState extends State<_PoojaFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late bool _isActive;
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _title = TextEditingController(text: p?.title ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p != null ? p.basePrice.toStringAsFixed(0) : '');
    _duration = TextEditingController(
        text: p != null ? '${p.durationMinutes}' : '');
    _isActive = p?.isActive ?? true;
    _isOnline = p?.isOnlineAvailable ?? false;
  }

  @override
  void dispose() {
    for (final c in [_title, _category, _description, _price, _duration]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  isEdit ? 'Edit Pooja' : 'New Pooja',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FormField(controller: _title, label: 'Title'),
            const SizedBox(height: 12),
            _FormField(controller: _category, label: 'Category'),
            const SizedBox(height: 12),
            _FormField(
                controller: _description,
                label: 'Description',
                maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    controller: _price,
                    label: 'Base Price (₹)',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormField(
                    controller: _duration,
                    label: 'Duration (min)',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ToggleRow(
                    label: 'Active listing',
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ),
                Expanded(
                  child: _ToggleRow(
                    label: 'Online available',
                    value: _isOnline,
                    onChanged: (v) => setState(() => _isOnline = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    Text(isEdit ? 'Save Changes' : 'Create Pooja'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_title.text.isEmpty || _category.text.isEmpty) return;
    final price = double.tryParse(_price.text) ?? 0;
    final duration = int.tryParse(_duration.text) ?? 60;
    final pooja = AdminPooja(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _title.text.trim(),
      category: _category.text.trim(),
      description: _description.text.trim(),
      basePrice: price,
      durationMinutes: duration,
      isActive: _isActive,
      isOnlineAvailable: _isOnline,
      tags: widget.existing?.tags ?? [],
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    widget.onSave(pooja);
    Navigator.pop(context);
  }
}

// ── Shared mini widgets ───────────────────────────────────────────────────────

class _PillChip extends StatelessWidget {
  const _PillChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon,
      required this.label,
      this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
      {required this.label,
      required this.value,
      required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.success,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Flexible(
          child: Text(label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
