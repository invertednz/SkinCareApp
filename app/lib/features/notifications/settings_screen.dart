import 'package:flutter/material.dart';
import '../../services/notifications_service.dart';
import '../../services/analytics_service.dart';
import 'data/notifications_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationsRepository _repository = NotificationsRepository();
  final NotificationsService _notificationsService = NotificationsService();
  
  List<NotificationSetting> _settings = [];
  NotificationPermissionResult _permissionStatus = NotificationPermissionResult.notDetermined;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissionStatus();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      
      // Check if user has settings, create defaults if not
      final hasSettings = await _repository.hasNotificationSettings();
      if (!hasSettings) {
        await _repository.createDefaultSettings();
      }
      
      final settings = await _repository.getNotificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkPermissionStatus() async {
    final status = await _notificationsService.getPermissionStatus();
    setState(() => _permissionStatus = status);
  }

  Future<void> _requestPermission() async {
    final result = await _notificationsService.requestPermission();
    setState(() => _permissionStatus = result);
    
    if (result == NotificationPermissionResult.granted ||
        result == NotificationPermissionResult.provisional) {
      // With push disabled, schedule local notifications when allowed
      await _notificationsService.updateNotificationSchedules();
    }
  }

  Future<void> _updateSetting(NotificationSetting setting) async {
    try {
      setState(() => _isSaving = true);
      await _repository.updateNotificationSetting(setting);
      
      // Update local state
      final index = _settings.indexWhere((s) => s.id == setting.id);
      if (index != -1) {
        setState(() {
          _settings[index] = setting;
        });
      }

      // Rebuild schedules to reflect the new settings
      await _notificationsService.updateNotificationSchedules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime(NotificationSetting setting) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: setting.time.hour, minute: setting.time.minute),
    );
    
    if (picked != null) {
      final updatedSetting = setting.copyWith(
        time: AppTimeOfDay(hour: picked.hour, minute: picked.minute),
        updatedAt: DateTime.now(),
      );
      await _updateSetting(updatedSetting);
    }
  }

  Future<void> _selectQuietHours(NotificationSetting setting) async {
    await showDialog(
      context: context,
      builder: (context) => _QuietHoursDialog(
        setting: setting,
        onUpdate: _updateSetting,
      ),
    );
  }

  Widget _buildPermissionSection() {
    switch (_permissionStatus) {
      case NotificationPermissionResult.granted:
        return const Card(
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Color(0xFF6A11CB)),
            title: Text('Notifications Enabled'),
            subtitle: Text('You will receive notifications'),
          ),
        );
      
      case NotificationPermissionResult.denied:
        return Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_off, color: Colors.orange),
            title: const Text('Notifications Disabled'),
            subtitle: const Text('Tap to enable notifications'),
            trailing: ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Enable'),
            ),
          ),
        );
      
      case NotificationPermissionResult.permanentlyDenied:
        return Card(
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Notifications Blocked'),
            subtitle: const Text('Enable in device settings to receive notifications'),
            trailing: ElevatedButton(
              onPressed: () => _notificationsService.openAppSettings(),
              child: const Text('Settings'),
            ),
          ),
        );
      
      default:
        return Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get reminders for your skincare routine'),
            trailing: ElevatedButton(
              onPressed: _requestPermission,
              child: const Text('Enable'),
            ),
          ),
        );
    }
  }

  Widget _buildSettingTile(NotificationSetting setting) {
    final isEnabled = setting.enabled && 
        (_permissionStatus == NotificationPermissionResult.granted ||
         _permissionStatus == NotificationPermissionResult.provisional);
    
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(setting.displayName),
            subtitle: Text(setting.description),
            value: setting.enabled,
            onChanged: _permissionStatus == NotificationPermissionResult.permanentlyDenied
                ? null
                : (value) async {
                    final updatedSetting = setting.copyWith(
                      enabled: value,
                      updatedAt: DateTime.now(),
                    );
                    await _updateSetting(updatedSetting);
                  },
          ),
          if (isEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Time'),
              subtitle: Text(setting.time.format12Hour),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(setting),
            ),
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('Quiet Hours'),
              subtitle: Text('${setting.quietFrom.format12Hour} - ${setting.quietTo.format12Hour}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectQuietHours(setting),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPermissionSection(),
                  const SizedBox(height: 16),
                  if (_settings.isNotEmpty) ...[
                    const Text(
                      'Notification Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._settings.map(_buildSettingTile),
                  ],
                  if (_isSaving)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }
}

class _QuietHoursDialog extends StatefulWidget {
  final NotificationSetting setting;
  final Function(NotificationSetting) onUpdate;

  const _QuietHoursDialog({
    required this.setting,
    required this.onUpdate,
  });

  @override
  State<_QuietHoursDialog> createState() => _QuietHoursDialogState();
}

class _QuietHoursDialogState extends State<_QuietHoursDialog> {
  late AppTimeOfDay _quietFrom;
  late AppTimeOfDay _quietTo;

  @override
  void initState() {
    super.initState();
    _quietFrom = widget.setting.quietFrom;
    _quietTo = widget.setting.quietTo;
  }

  Future<void> _selectFromTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _quietFrom.hour, minute: _quietFrom.minute),
    );
    
    if (picked != null) {
      setState(() {
        _quietFrom = AppTimeOfDay(hour: picked.hour, minute: picked.minute);
      });
    }
  }

  Future<void> _selectToTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _quietTo.hour, minute: _quietTo.minute),
    );
    
    if (picked != null) {
      setState(() {
        _quietTo = AppTimeOfDay(hour: picked.hour, minute: picked.minute);
      });
    }
  }

  void _save() {
    final updatedSetting = widget.setting.copyWith(
      quietFrom: _quietFrom,
      quietTo: _quietTo,
      updatedAt: DateTime.now(),
    );
    widget.onUpdate(updatedSetting);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiet Hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No notifications will be sent during these hours:'),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('From'),
            subtitle: Text(_quietFrom.format12Hour),
            trailing: const Icon(Icons.schedule),
            onTap: _selectFromTime,
          ),
          ListTile(
            title: const Text('To'),
            subtitle: Text(_quietTo.format12Hour),
            trailing: const Icon(Icons.schedule),
            onTap: _selectToTime,
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: Quiet hours can span across midnight (e.g., 10 PM to 7 AM)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
