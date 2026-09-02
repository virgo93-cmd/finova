import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _googleWebClientId =
    '1029399359713-tkf0k0v6st0hlhqtt7chkimu2celaaim.apps.googleusercontent.com';
const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

class AuthService {
  AuthService._();

  static final instance = AuthService._();
  final GoogleSignIn _google = GoogleSignIn.instance;
  Future<void>? _initialization;

  SupabaseClient get supabase => Supabase.instance.client;
  User? get user => supabase.auth.currentUser;
  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  Future<void> initializeGoogle() => _initialization ??= _google.initialize(
    serverClientId: _googleWebClientId,
  );

  Future<User> signInWithGoogle() async {
    await initializeGoogle();
    final account = await _google.authenticate(
      scopeHint: const [driveAppDataScope],
    );
    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google tidak memberikan ID token.');
    }

    var authorization = await account.authorizationClient
        .authorizationForScopes(const [driveAppDataScope]);
    authorization ??= await account.authorizationClient.authorizeScopes(const [
      driveAppDataScope,
    ]);

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
    final signedInUser = response.user;
    if (signedInUser == null) {
      throw const AuthException('Supabase tidak membuat sesi pengguna.');
    }
    return signedInUser;
  }

  Future<Map<String, String>> driveAuthorizationHeaders() async {
    await initializeGoogle();
    final headers = await _google.authorizationClient.authorizationHeaders(
      const [driveAppDataScope],
      promptIfNecessary: true,
    );
    if (headers == null) {
      throw StateError('Izin Google Drive belum diberikan.');
    }
    return headers;
  }

  Future<void> signOut() async {
    await initializeGoogle();
    await supabase.auth.signOut();
    await _google.signOut();
  }
}
