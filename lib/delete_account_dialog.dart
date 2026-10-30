import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dlinii_motion.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.english});
  final bool english;
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final password = TextEditingController();
  bool busy = false;
  String? error;
  String t(String ar, String en) => widget.english ? en : ar;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> remove() async {
    if (busy || password.text.isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null)
        throw StateError('No email account');
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: password.text,
        ),
      );
      // Delete owned public places before deleting the identity. If a batch
      // fails, keep the account so the owner can retry the remaining cleanup.
      final db = FirebaseFirestore.instance;
      while (true) {
        final places = await db
            .collection('public_places')
            .where('ownerUid', isEqualTo: user.uid)
            .limit(100)
            .get();
        if (places.docs.isEmpty) break;
        final batch = db.batch();
        for (final place in places.docs) {
          batch.delete(place.reference);
        }
        await batch.commit();
      }
      await user.delete();
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (mounted)
        setState(
          () => error = t(
            e.code == 'network-request-failed'
                ? 'تحقق من الإنترنت وحاول مجدداً.'
                : 'تعذر حذف الحساب. تحقق من كلمة المرور وحاول مجدداً.',
            'Could not delete account. Check your password and connection, then retry.',
          ),
        );
    } catch (_) {
      if (mounted)
        setState(
          () => error = t(
            'لم يكتمل الحذف. حسابك باقٍ؛ قد حُذفت بعض أماكنك. أعد المحاولة لإكمال الباقي.',
            'Deletion did not finish. Your account remains; some places may have been removed. Retry to finish.',
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(t('حذف الحساب نهائياً', 'Delete account permanently')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t(
                'سيُحذف حسابك والأماكن العامة التي نشرتها. لا يمكن التراجع. تبقى البلاغات والتصويتات السابقة دون بريدك، وسجلك المحلي على هذا الجهاز. أدخل كلمة المرور للتأكيد.',
                'Your account and published places will be deleted permanently. Previous reports and votes remain without your email, as does local history on this device. Enter your password to confirm.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              enabled: !busy,
              decoration: InputDecoration(
                labelText: t('كلمة المرور', 'Password'),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: Text(t('إلغاء', 'Cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: busy || password.text.isEmpty ? null : remove,
          child: busy
              ? const DliniiLoader(size: 22)
              : Text(t('حذف نهائي', 'Delete permanently')),
        ),
      ],
    ),
  );
}
