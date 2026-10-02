import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user.dart';

// Enhancement 1: ValueNotifier so widgets can rebuild when auth state
// changes via this shared UserService instance
ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== Existing DummyJSON-based login (from Lab 4) =====
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// **Save User Data to SharedPreferences**
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }

    // Enhancement 2: mark which login type was used, so profile_screen
    // can render the correct fields for DummyJSON vs Firebase users
    await prefs.setString('loginType', 'dummyjson');
    // DummyJSON users have no Firebase Auth uid, so chat (Firebase-based)
    // isn't available to them — leave uid blank
    await prefs.setString('uid', '');
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? '',
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'loginType': prefs.getString('loginType') ?? '',
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return (token != null && token.isNotEmpty) || firebaseUser != null;
  }

  /// **Logout and Clear User Data**
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // also sign out of Firebase in case the session was a Firebase one
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // ===== Enhancement 1 (Lab 5): Firebase Auth functions =====
  final fb_auth.FirebaseAuth firebaseAuth = fb_auth.FirebaseAuth.instance;

  fb_auth.User? get currentFirebaseUser => firebaseAuth.currentUser;

  Stream<fb_auth.User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Lab 6: writes/updates this user's profile doc in Firestore's "Users"
  // collection, so they show up in everyone else's chat list
  Future<void> _upsertFirestoreUser({
    required String uid,
    required String email,
    String firstName = '',
    String lastName = '',
    String username = '',
  }) async {
    await _firestore.collection('Users').doc(uid).set({
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
    }, SetOptions(merge: true));
  }

  Future<fb_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid ?? '';
    final displayName = credential.user?.displayName ?? '';

    // Enhancement 2 & 3 (Lab 5): save minimal user data locally so
    // profile_screen can render it, marking loginType as 'firebase'
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('email', credential.user?.email ?? email);
    await prefs.setString('firstName', displayName);
    await prefs.setString('loginType', 'firebase');
    await prefs.setString('token', await credential.user?.getIdToken() ?? '');

    // Lab 6: keep this user's Firestore doc up to date on every sign-in
    if (uid.isNotEmpty) {
      await _upsertFirestoreUser(
        uid: uid,
        email: credential.user?.email ?? email,
        firstName: displayName,
      );
    }

    return credential;
  }

  Future<fb_auth.UserCredential> createAccount({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String username = '',
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      await credential.user?.updateDisplayName('$firstName $lastName'.trim());
    }

    // Lab 6: create this user's Firestore doc immediately on sign-up,
    // so they appear in the chat list right away
    if (uid.isNotEmpty) {
      await _upsertFirestoreUser(
        uid: uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
      );
    }

    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> updateUsername({required String username}) async {
    await firebaseAuth.currentUser!.updateDisplayName(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', username);

    // Lab 6: keep the Firestore doc's firstName in sync too, since
    // that's what the chat list displays
    final uid = firebaseAuth.currentUser?.uid;
    if (uid != null) {
      await _upsertFirestoreUser(
        uid: uid,
        email: firebaseAuth.currentUser?.email ?? '',
        firstName: username,
      );
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final uid = firebaseAuth.currentUser?.uid;
    await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
    await firebaseAuth.currentUser!.delete();
    if (uid != null) {
      await _firestore.collection('Users').doc(uid).delete();
    }
    await firebaseAuth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
    await firebaseAuth.currentUser!.updatePassword(newPassword);
  }
}
