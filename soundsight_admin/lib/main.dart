import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'admin_theme.dart';
import 'firebase_options.dart';
import 'library_screen.dart';
import 'read_only_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: AdminFirebaseOptions.web);
  runApp(const SoundSightAdminApp());
}

class SoundSightAdminApp extends StatefulWidget {
  const SoundSightAdminApp({super.key});

  @override
  State<SoundSightAdminApp> createState() => _SoundSightAdminAppState();
}

class _SoundSightAdminAppState extends State<SoundSightAdminApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSight Admin',
      debugShowCheckedModeBanner: false,
      theme: adminTheme(Brightness.light),
      darkTheme: adminTheme(Brightness.dark),
      themeMode: _themeMode,
      home: AdminAuthGate(
        isDark: _themeMode == ThemeMode.dark,
        onThemeChanged: (dark) => setState(() {
          _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  String? _checkedUid;
  Future<bool>? _accessCheck;
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  Future<bool> _checkAccess(User user) async {
    final admin = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    return admin.data()?['enabled'] == true;
  }

  void _retry(User user) {
    setState(() => _accessCheck = _checkAccess(user));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          _checkedUid = null;
          _accessCheck = null;
          return const AdminLoginScreen();
        }
        if (_checkedUid != user.uid || _accessCheck == null) {
          _checkedUid = user.uid;
          _accessCheck = _checkAccess(user);
        }
        return FutureBuilder<bool>(
          future: _accessCheck,
          builder: (context, access) {
            if (access.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (access.hasError) {
              return Scaffold(
                body: AdminMessage(
                  icon: Icons.cloud_off_outlined,
                  message: 'Could not check admin access. Check your connection and retry.',
                  onRetry: () => _retry(user),
                ),
              );
            }
            if (access.data != true) {
              return Scaffold(
                body: Center(
                  child: AdminPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 40),
                        const SizedBox(height: 16),
                        const Text('Admin access required',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text(
                          'This account needs an enabled admin document in Firebase.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => _retry(user),
                          child: const Text('Check again'),
                        ),
                        TextButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AdminDashboard(
              user: user,
              isDark: widget.isDark,
              onThemeChanged: widget.onThemeChanged,
            );
          },
        );
      },
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
          'invalid-credential' || 'wrong-password' || 'user-not-found' =>
            'Incorrect email or password.',
          'too-many-requests' => 'Too many attempts. Try again later.',
          _ => error.message ?? 'Sign in failed. Please try again.',
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AdminPanel(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(colors.logo, height: 72, fit: BoxFit.contain),
                    const SizedBox(height: 20),
                    const Text('SoundSight Admin',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Sign in to manage SoundSight content',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.muted)),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => (value == null || !value.contains('@'))
                          ? 'Enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Password is required.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _signIn,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_busy ? 'Signing in…' : 'Sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AdminSection { users, compositions, library }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.user,
    required this.isDark,
    required this.onThemeChanged,
  });

  final User user;
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AdminSection _section = AdminSection.users;

  void _select(AdminSection section) {
    setState(() => _section = section);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 820;
    final title = switch (_section) {
      AdminSection.users => 'Users',
      AdminSection.compositions => 'Published compositions',
      AdminSection.library => 'Music library',
    };
    return Scaffold(
      key: _scaffoldKey,
      appBar: narrow ? AppBar(title: Text(title)) : null,
      drawer: narrow ? Drawer(child: SafeArea(child: _navigation(colors))) : null,
      body: Row(
        children: [
          if (!narrow) SizedBox(width: 260, child: _navigation(colors)),
          Expanded(
            child: switch (_section) {
              AdminSection.users => const UsersScreen(),
              AdminSection.compositions => const CompositionsScreen(),
              AdminSection.library => const LibraryScreen(),
            },
          ),
        ],
      ),
    );
  }

  Widget _navigation(AdminPalette colors) {
    return Container(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(colors.logo, height: 54, alignment: Alignment.centerLeft),
                const SizedBox(height: 12),
                const Text('SoundSight Admin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.user.email ?? 'Admin',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _navTile(AdminSection.users, Icons.people_outline, 'Users'),
          _navTile(AdminSection.compositions, Icons.music_note_outlined,
              'Published compositions'),
          _navTile(AdminSection.library, Icons.library_music_outlined,
              'Music library'),
          const Spacer(),
          SwitchListTile(
            title: const Text('Dark mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: widget.isDark,
            onChanged: widget.onThemeChanged,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _navTile(AdminSection section, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: _section == section,
        leading: Icon(icon),
        title: Text(title),
        onTap: () => _select(section),
      ),
    );
  }
}
