import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String userType; // 'player' or 'scout'
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isActive;

  // Player specific fields
  final String? sport;
  final String? gender;
  final int? age;
  final double? height; // in cm
  final double? weight; // in kg
  final String? location;
  final String? region;
  final String? bio;
  final List<String> achievements;
  final Map<String, dynamic>? performanceMetrics;

  // Player flags/scores
  final bool hasUploadedVideo; // whether player has at least one video
  final double? topAiScore; // latest or top AI score for dashboard/leaderboard

  // Scout specific fields
  final String? organization;
  final String? designation;
  final String? experience; // years of experience
  final List<String> specializations;
  final String? verificationDocumentUrl;
  final String? verificationStatus; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.isActive = true,

    // Player fields
    this.sport,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.location,
    this.region,
    this.bio,
    this.achievements = const [],
    this.performanceMetrics,

    // Player flags/scores
    this.hasUploadedVideo = false,
    this.topAiScore,

    // Scout fields
    this.organization,
    this.designation,
    this.experience,
    this.specializations = const [],
    this.verificationDocumentUrl,
    this.verificationStatus = 'pending',
    this.rejectionReason,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: data['userType'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,

      // Player fields
      sport: data['sport'],
      gender: data['gender'],
      age: data['age'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      location: data['location'],
      region: data['region'],
      bio: data['bio'],
      achievements: List<String>.from(data['achievements'] ?? []),
      performanceMetrics: data['performanceMetrics'],
      hasUploadedVideo: data['hasUploadedVideo'] ?? false,
      topAiScore: (data['topAiScore'] is num) ? (data['topAiScore'] as num).toDouble() : null,

      // Scout fields
      organization: data['organization'],
      designation: data['designation'],
      experience: data['experience'],
      specializations: List<String>.from(data['specializations'] ?? []),
      verificationDocumentUrl: data['verificationDocumentUrl'],
      verificationStatus: data['verificationStatus'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
    );
  }
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      userType: data['userType'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      sport: data['sport'],
      gender: data['gender'],
      age: data['age'],
      height: (data['height'] is num) ? (data['height'] as num).toDouble() : null,
      weight: (data['weight'] is num) ? (data['weight'] as num).toDouble() : null,
      location: data['location'],
      region: data['region'],
      bio: data['bio'],
      achievements: List<String>.from(data['achievements'] ?? []),
      performanceMetrics: data['performanceMetrics'],
      hasUploadedVideo: data['hasUploadedVideo'] ?? false,
      topAiScore: (data['topAiScore'] is num) ? (data['topAiScore'] as num).toDouble() : null,
      organization: data['organization'],
      designation: data['designation'],
      experience: data['experience'],
      specializations: List<String>.from(data['specializations'] ?? []),
      verificationDocumentUrl: data['verificationDocumentUrl'],
      verificationStatus: data['verificationStatus'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isVerified': isVerified,
      'isActive': isActive,
      'sport': sport,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'location': location,
      'region': region,
      'bio': bio,
      'achievements': achievements,
      'performanceMetrics': performanceMetrics,
      'hasUploadedVideo': hasUploadedVideo,
      'topAiScore': topAiScore,
      'organization': organization,
      'designation': designation,
      'experience': experience,
      'specializations': specializations,
      'verificationDocumentUrl': verificationDocumentUrl,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
    };
  }


  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'isActive': isActive,

      // Player fields
      'sport': sport,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'location': location,
      'region': region,
      'bio': bio,
      'achievements': achievements,
      'performanceMetrics': performanceMetrics,
      'hasUploadedVideo': hasUploadedVideo,
      'topAiScore': topAiScore,

      // Scout fields
      'organization': organization,
      'designation': designation,
      'experience': experience,
      'specializations': specializations,
      'verificationDocumentUrl': verificationDocumentUrl,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
    String? sport,
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? location,
    String? region,
    String? bio,
    List<String>? achievements,
    Map<String, dynamic>? performanceMetrics,
    String? organization,
    String? designation,
    String? experience,
    List<String>? specializations,
    String? verificationDocumentUrl,
    String? verificationStatus,
    String? rejectionReason,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      sport: sport ?? this.sport,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      location: location ?? this.location,
      region: region ?? this.region,
      bio: bio ?? this.bio,
      achievements: achievements ?? this.achievements,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      organization: organization ?? this.organization,
      designation: designation ?? this.designation,
      experience: experience ?? this.experience,
      specializations: specializations ?? this.specializations,
      verificationDocumentUrl: verificationDocumentUrl ?? this.verificationDocumentUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  bool get isPlayer => userType == 'player';
  bool get isScout => userType == 'scout';
  bool get isAdmin => userType == 'admin';

  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  String get ageGroup {
    if (age == null) return 'Unknown';
    if (age! < 12) return 'Under 12';
    if (age! < 15) return '12-14';
    if (age! < 18) return '15-17';
    if (age! < 21) return '18-20';
    if (age! < 26) return '21-25';
    return '26+';
  }
}
