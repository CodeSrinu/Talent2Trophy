import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Talent2Trophy';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  
  // Sports Types (restricted per project scope)
  static const List<String> sportsTypes = [
    'Football',
    'Kabaddi',
  ];

  // User Types
  static const String userTypePlayer = 'player';
  static const String userTypeScout = 'scout';
  static const String userTypeAdmin = 'admin';
  
  // Gender Options
  static const List<String> genderOptions = ['Male', 'Female', 'Other'];
  
  // Age Groups
  static const List<String> ageGroups = [
    'Under 12',
    '12-14',
    '15-17',
    '18-20',
    '21-25',
    '26+'
  ];
  
  // Regions (Indian States)
  static const List<String> regions = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Chandigarh',
    'Dadra and Nagar Haveli',
    'Daman and Diu',
    'Lakshadweep',
    'Puducherry',
    'Andaman and Nicobar Islands'
  ];
  
  // Video Quality Settings
  static const int defaultVideoQuality = 720;
  static const int maxVideoDuration = 60; // seconds
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String userTypeKey = 'user_type';
  static const String offlineDataKey = 'offline_data';
  
  // API Endpoints (for future use)
  static const String baseUrl = 'https://api.talent2trophy.com';
  static const String authEndpoint = '/auth';
  static const String profileEndpoint = '/profile';
  static const String videoEndpoint = '/video';
  static const String leaderboardEndpoint = '/leaderboard';
  
  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String generalError = 'Something went wrong. Please try again.';
  static const String validationError = 'Please check your input and try again.';
  
  // Success Messages
  static const String profileUpdated = 'Profile updated successfully!';
  static const String videoUploaded = 'Video uploaded successfully!';
  static const String registrationSuccess = 'Registration successful!';
  static const String loginSuccess = 'Login successful!';
}
