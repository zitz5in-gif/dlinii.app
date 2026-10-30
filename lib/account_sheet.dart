import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dlinii_brand.dart';
import 'dlinii_motion.dart';

class DliniiAccountSheet extends StatefulWidget {
  const DliniiAccountSheet({super.key, required this.english});
  final bool english;
  @override
  State<DliniiAccountSheet> createState() => _DliniiAccountSheetState();
}

class _DliniiAccountSheetState extends State<DliniiAccountSheet> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _register = false, _busy = false, _hidden = true;
  String? _message;
  String t(String ar, String en) => widget.english ? en : ar;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool reset = false}) async {
    if (_busy) return;
    if (reset ? !_email.text.contains('@') : !_form.currentState!.validate()) {
      if (reset)
        setState(
          () => _message = t('أدخل بريدك أولاً', 'Enter your email first'),
        );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (reset) {
        await auth.sendPasswordResetEmail(email: _email.text.trim());
        if (mounted)
          setState(
            () => _message = t(
              'إذا كان البريد مسجلاً ستصلك رسالة استعادة.',
              'If registered, a recovery email will arrive.',
            ),
          );
      } else {
        if (_register) {
          await auth.createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
        } else {
          await auth.signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
        }
        if (mounted) Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted)
        setState(
          () => _message = switch (e.code) {
            'email-already-in-use' => t(
              'البريد مسجّل؛ استخدم تسجيل الدخول.',
              'Email already registered. Sign in instead.',
            ),
            'weak-password' => t(
              'اختر كلمة مرور أقوى.',
              'Choose a stronger password.',
            ),
            'network-request-failed' => t(
              'تحقق من اتصال الإنترنت.',
              'Check your connection.',
            ),
            'operation-not-allowed' => t(
              'تسجيل الدخول بالبريد غير مفعّل على الخادم بعد.',
              'Email sign-in is not enabled on the server yet.',
            ),
            'too-many-requests' => t(
              'محاولات كثيرة؛ حاول لاحقاً.',
              'Too many attempts. Try later.',
            ),
            _ => t(
              'تعذر تسجيل الدخول. تحقق من البريد وكلمة المرور.',
              'Sign-in failed. Check your email and password.',
            ),
          },
        );
    } catch (_) {
      if (mounted)
        setState(
          () => _message = t('تعذر الاتصال بالخدمة.', 'Service unavailable.'),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DliniiBrandHeader(compact: true),
            const SizedBox(height: 20),
            Text(
              t(
                _register ? 'حسابك على دلّيني' : 'أهلاً بعودتك',
                _register ? 'Your Dlinii account' : 'Welcome back',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              t(
                'انشر مكانك للجميع واحتفظ بحق تعديله وحذفه بحسابك.',
                'Publish your place for everyone; only your account can edit or delete it.',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: t('البريد الإلكتروني', 'Email'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v != null &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                  ? null
                  : t('أدخل بريداً صحيحاً', 'Enter a valid email'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: t('كلمة المرور', 'Password'),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: t('إظهار أو إخفاء', 'Show or hide'),
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => v != null && v.length >= 6
                  ? null
                  : t('ستة أحرف على الأقل', 'At least six characters'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_message!, semanticsLabel: _message),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : () => _submit(),
              child: _busy
                  ? const DliniiLoader(size: 24)
                  : Text(
                      t(
                        _register ? 'إنشاء حساب' : 'تسجيل الدخول',
                        _register ? 'Create account' : 'Sign in',
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              icon: const Icon(Icons.person_outline_rounded, size: 20),
              label: Text(t('المتابعة كزائر', 'Continue as guest')),
            ),
            const SizedBox(height: 6),
            Text(
              t(
                'تصفح الخريطة والتنقل دون حساب. النشر والتصويت يحتاجان تسجيل الدخول.',
                'Explore and navigate without an account. Publishing and voting require sign-in.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _register = !_register;
                      _message = null;
                    }),
              child: Text(
                t(
                  _register
                      ? 'لديك حساب؟ سجّل الدخول'
                      : 'جديد هنا؟ أنشئ حساباً',
                  _register
                      ? 'Already registered? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => _submit(reset: true),
              child: Text(t('نسيت كلمة المرور', 'Forgot password')),
            ),
          ],
        ),
      ),
    ),
  );
}
