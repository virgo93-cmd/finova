import 'dart:io';

import 'package:finova/core/services/ad_service.dart';
import 'package:finova/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const premiumCheckoutBaseUrl =
    'https://harend93.lemonsqueezy.com/checkout/buy/30316872-efa7-41fe-867d-2ffae87694c7';

class AccountState {
  const AccountState({
    this.user,
    this.displayName,
    this.avatarUrl,
    this.premiumExpiresAt,
    this.localAvatarPath,
  });
  final User? user;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? premiumExpiresAt;
  final String? localAvatarPath;

  factory AccountState.fromUser(User user) => AccountState(
    user: user,
    displayName:
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        user.email,
    avatarUrl:
        user.userMetadata?['avatar_url'] as String? ??
        user.userMetadata?['picture'] as String?,
  );

  bool get isSignedIn => user != null;
  bool get isPremium =>
      premiumExpiresAt != null && premiumExpiresAt!.isAfter(DateTime.now());
}

final accountProvider = AsyncNotifierProvider<AccountController, AccountState>(
  AccountController.new,
);

class AccountController extends AsyncNotifier<AccountState> {
  @override
  Future<AccountState> build() async {
    final user = AuthService.instance.user;
    if (user == null) {
      AdService.setPremium(false);
      return const AccountState();
    }
    final prefs = await SharedPreferences.getInstance();
    final localAvatarPath = prefs.getString('profile_avatar_path');
    Map<String, dynamic>? row;
    try {
      row = await AuthService.instance.supabase
          .from('finova_profiles')
          .select('display_name,avatar_url,is_premium,premium_expires_at')
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      // Authentication is still valid when optional profile enrichment is
      // temporarily unavailable. Never hide a successful login because of it.
      AdService.setPremium(false);
      return AccountState.fromUser(user);
    }
    final expiry = DateTime.tryParse(
      row?['premium_expires_at'] as String? ?? '',
    );
    final premium =
        row?['is_premium'] == true &&
        expiry != null &&
        expiry.isAfter(DateTime.now());
    AdService.setPremium(premium);
    return AccountState(
      user: user,
      displayName:
          row?['display_name'] as String? ??
          user.userMetadata?['full_name'] as String?,
      avatarUrl:
          row?['avatar_url'] as String? ??
          user.userMetadata?['avatar_url'] as String?,
      premiumExpiresAt: premium ? expiry : null,
      localAvatarPath: localAvatarPath,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> updateDisplayName(String name) async {
    final user = AuthService.instance.user;
    if (user == null) throw StateError('Silakan masuk terlebih dahulu.');
    await AuthService.instance.supabase
        .from('finova_profiles')
        .update({'display_name': name.trim()})
        .eq('id', user.id);
    ref.invalidateSelf();
  }

  Future<void> updateAvatarFromGallery() async {
    final user = AuthService.instance.user;
    if (user == null) throw StateError('Silakan masuk terlebih dahulu.');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 86,
    );
    if (picked == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final target = File(
      '${directory.path}${Platform.pathSeparator}finova_profile.jpg',
    );
    await File(picked.path).copy(target.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_avatar_path', target.path);
    ref.invalidateSelf();
  }
}

Future<void> openPremiumCheckout(String userId, String userEmail) async {
  final uri = Uri.parse(
    '$premiumCheckoutBaseUrl?checkout[custom][user_id]='
    '${Uri.encodeQueryComponent(userId)}&checkout[email]='
    '${Uri.encodeQueryComponent(userEmail)}',
  );
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened) throw StateError('Halaman pembayaran tidak dapat dibuka.');
}
