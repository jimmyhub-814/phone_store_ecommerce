import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/auth/profile_setup.dart'; 
import 'package:phone_store/main/auth/login.dart';
import 'package:phone_store/main/pages/mainPage/home.dart';
import 'package:phone_store/models/user.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? currentUser;
  bool isGoogle = false;
  bool isPhone = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) return const LoginPage();

        final isGoogle =
            user.providerData.any((p) => p.providerId == 'google.com');
        return StreamBuilder<DocumentSnapshot>(
          stream: Collections.user.doc(user.uid).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: AppColors.surface,
                body: Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: AppColors.primary,
                    size: 60,
                  ),
                ),
              );
            }

            if (snap.hasError) {
              return const LoginPage();
            }
            final doc = snap.data;

            if (doc == null || !doc.exists) {
              return ProfileSetup(
                userId: user.uid,
                userAccount: isGoogle ? user.email : user.phoneNumber ?? '',
              );
            }

            final data = snap.data!.data() as Map<String, dynamic>?;

            if (data?[UserApp.isCompletedField] != true) {
              return ProfileSetup(
                userId: user.uid,
                userAccount: isGoogle ? user.email : user.phoneNumber ?? '',
              );
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
