import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart' show AppColors;
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/auth/complete_profile_page.dart';
import 'package:phone_store/main/auth/login_page.dart';
import 'package:phone_store/main/pages/home/mainPage/home_page.dart';
import 'package:phone_store/models/user.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primary,
              size: 60,
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: Collections.user.doc(user.uid).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                ),
              );
            }

            if (!snap.hasData || !snap.data!.exists) {
              return CompleteProfilePage(
                userId: user.uid,
                userEmail: user.email ?? '',
              );
            }

            final data = snap.data!.data() as Map<String, dynamic>?;

            if (data?[UserApp.isCompletedField] != true) {
              return CompleteProfilePage(
                userId: user.uid,
                userEmail: user.email ?? '',
              );
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
