class MbProfile {
  final String id;
  final String role;
  final List<String> scopes;

  MbProfile({
    required this.id,
    required this.role,
    required this.scopes,
  });

  // For /v1/me response
  factory MbProfile.fromMeResponse(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>? ?? {});
    return MbProfile(
      id: data['id']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      scopes: (data['scopes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  // For OIDC userinfo response
  factory MbProfile.fromUserInfo(Map<String, dynamic> json) {
    return MbProfile(
      id: json['sub']?.toString() ?? '',
      role: 'user',
      scopes: (json['scope'] is String)
          ? (json['scope'] as String).split(' ')
          : <String>[],
    );
  }
}