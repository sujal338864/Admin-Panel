// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      notifications = await ApiService.getNotifications();
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
      notifications = [];
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteNotification(int id) async {
    final ok = await ApiService.deleteNotification(id);
    if (ok) {
      fetchNotifications();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ Deleted')));
    }
  }

  void openDialog([Map<String, dynamic>? data]) async {
    await showDialog(
      context: context,
      builder: (_) => AddEditNotificationDialog(notification: data),
    );
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📢 Notifications"),
        actions: [
          IconButton(onPressed: fetchNotifications, icon: const Icon(Icons.refresh)),
          ElevatedButton.icon(
            onPressed: () => openDialog(),
            icon: const Icon(Icons.add),
            label: const Text("Add"),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(child: Text("No notifications"))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Title")),
                        DataColumn(label: Text("Message")),
                        DataColumn(label: Text("Image")),
                        DataColumn(label: Text("Created")),
                        DataColumn(label: Text("Edit")),
                        DataColumn(label: Text("Delete")),
                      ],
                      rows: notifications.map((n) {
                        return DataRow(cells: [
                          DataCell(Text(n['title'] ?? '')),
                          DataCell(SizedBox(
                            width: 200,
                            child: Text(
                              n['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                          DataCell(
                            n['image_url'] != null && n['image_url'] != ''
                                ? Image.network(n['image_url'], width: 50)
                                : const Icon(Icons.image_not_supported),
                          ),
                          DataCell(Text(
                              n['created_at'].toString().split('T')[0])),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => openDialog(n),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  deleteNotification(n['notification_id']),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
      ),
    );
  }
}

/* ===========================
   ADD / EDIT DIALOG
   =========================== */

class AddEditNotificationDialog extends StatefulWidget {
  final Map<String, dynamic>? notification;
  const AddEditNotificationDialog({super.key, this.notification});

  @override
  State<AddEditNotificationDialog> createState() =>
      _AddEditNotificationDialogState();
}

class _AddEditNotificationDialogState
    extends State<AddEditNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final msgCtrl = TextEditingController();
  String? imageUrl;
  bool saving = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    titleCtrl.text = widget.notification?['title'] ?? '';
    msgCtrl.text = widget.notification?['description'] ?? '';
    imageUrl = widget.notification?['image_url'];
  }

  Future<void> uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    final bytes = result.files.single.bytes!;
    final name =
        "notif_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}";

    await supabase.storage
        .from('notifications')
        .uploadBinary(name, bytes, fileOptions: const FileOptions(upsert: true));

    imageUrl =
        supabase.storage.from('notifications').getPublicUrl(name);
    setState(() {});
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    bool ok;
    if (widget.notification == null) {
      ok = await ApiService.addNotification(
        titleCtrl.text,
        msgCtrl.text,
        imageUrl,
      );
    } else {
ok = await ApiService.updateNotification(
  widget.notification!['notification_id'],
  titleCtrl.text,
  msgCtrl.text,
  imageUrl ?? '',   // ✅ FIX
);

    }

    setState(() => saving = false);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.notification == null
          ? "Add Notification"
          : "Edit Notification"),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Title"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: msgCtrl,
            decoration: const InputDecoration(labelText: "Message"),
            maxLines: 3,
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton.icon(
              onPressed: uploadImage,
              icon: const Icon(Icons.image),
              label: const Text("Upload"),
            ),
            const SizedBox(width: 10),
            if (imageUrl != null)
              Image.network(imageUrl!, width: 50, height: 50),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: saving ? null : save,
          child: saving
              ? const CircularProgressIndicator()
              : const Text("Save"),
        )
      ],
    );
  }
}
