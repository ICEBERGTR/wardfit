import 'package:flutter/material.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/wardfit_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editFieldDialog(
    BuildContext context, {
    required String label,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      onSave(result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = WardrobeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.textDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar with Back button and help icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    state.setTab(0);
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8FF65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('WardFit Help'),
                      content: const Text(
                        'Manage your profile details, notification preferences, and app theme from this page.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.settingsTileDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.question_mark_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // User avatar and online status row
          Row(
            children: [
              const UserAvatarBadge(size: 54),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.username,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // About Me section
          Text(
            'About Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryText.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),

          _ProfileSettingTile(
            icon: Icons.person_rounded,
            title: state.username,
            subtitle: 'Username',
            showArrow: true,
            onTap: () => _editFieldDialog(
              context,
              label: 'Username',
              initialValue: state.username,
              onSave: (v) => state.updateProfileField(newUsername: v),
            ),
          ),
          const Divider(height: 1, color: Colors.black38),

          _ProfileSettingTile(
            icon: Icons.email_rounded,
            title: state.email,
            subtitle: 'E-mail Address',
            showArrow: true,
            onTap: () => _editFieldDialog(
              context,
              label: 'E-mail Address',
              initialValue: state.email,
              onSave: (v) => state.updateProfileField(newEmail: v),
            ),
          ),
          const Divider(height: 1, color: Colors.black38),

          _ProfileSettingTile(
            icon: Icons.phone_rounded,
            title: state.phone,
            subtitle: 'Phone Number',
            showArrow: true,
            onTap: () => _editFieldDialog(
              context,
              label: 'Phone Number',
              initialValue: state.phone,
              onSave: (v) => state.updateProfileField(newPhone: v),
            ),
          ),
          const Divider(height: 1, color: Colors.black38),

          _ProfileSettingTile(
            icon: Icons.location_on_rounded,
            title: state.address,
            subtitle: 'Address',
            showArrow: true,
            onTap: () => _editFieldDialog(
              context,
              label: 'Address',
              initialValue: state.address,
              onSave: (v) => state.updateProfileField(newAddress: v),
            ),
          ),
          const SizedBox(height: 26),

          // Settings section
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 10),

          _ProfileSettingTile(
            icon: Icons.language_rounded,
            title: state.language,
            subtitle: 'Language',
            showArrow: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language is currently set to English.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.black38),

          _ProfileSettingTile(
            icon: Icons.volume_off_rounded,
            title: 'Silent Mode',
            subtitle: 'Notifications & Message',
            toggleValue: state.silentMode,
            onToggleChanged: state.toggleSilentMode,
          ),
          const Divider(height: 1, color: Colors.black38),

          _ProfileSettingTile(
            icon: Icons.nightlight_round,
            title: 'Dark Mode',
            subtitle: 'Theme',
            toggleValue: state.darkMode,
            onToggleChanged: state.toggleDarkMode,
          ),
          const Divider(height: 1, color: Colors.black38),

          const _ProfileSettingTile(
            icon: Icons.smartphone_rounded,
            title: 'Camera, Location, & Microphone',
            subtitle: 'Device Permissions',
          ),
          const Divider(height: 1, color: Colors.black38),

          const _ProfileSettingTile(
            icon: Icons.storage_rounded,
            title: 'Highest Quality',
            subtitle: 'Mobile Data Settings',
          ),
          const SizedBox(height: 30),

          // Footer: Sign Out and Privacy & Policy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  state.setTab(0);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: primaryText, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Privacy & Policy'),
                      content: const Text(
                        'WardFit stores your wardrobe photos and style tags locally on your server to generate daily outfit suggestions.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Privacy & Policy',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: primaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showArrow;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;
  final VoidCallback? onTap;

  const _ProfileSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showArrow = false,
    this.toggleValue,
    this.onToggleChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.settingsTileDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.settingsTileDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            if (toggleValue != null)
              Switch(
                value: toggleValue!,
                onChanged: onToggleChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primaryGreen,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.settingsTileDark,
              ),
          ],
        ),
      ),
    );
  }
}
