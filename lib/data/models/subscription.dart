/// Subscription state reflecting the `subscriptions` table in Supabase.
class Subscription {
  final String userId;
  final bool isPro;
  final String? entitlement;
  final String? productId;
  final String? store;
  final DateTime? expiresAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.userId,
    this.isPro = false,
    this.entitlement,
    this.productId,
    this.store,
    this.expiresAt,
    this.updatedAt,
  });

  /// Check whether subscription is currently active
  bool get isActive {
    if (!isPro) return false;
    if (expiresAt == null) return true; // lifetime / perpetual
    return expiresAt!.isAfter(DateTime.now());
  }

  Subscription copyWith({
    String? userId,
    bool? isPro,
    String? entitlement,
    String? productId,
    String? store,
    DateTime? expiresAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      userId: userId ?? this.userId,
      isPro: isPro ?? this.isPro,
      entitlement: entitlement ?? this.entitlement,
      productId: productId ?? this.productId,
      store: store ?? this.store,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      userId: json['user_id'] as String,
      isPro: json['is_pro'] as bool? ?? false,
      entitlement: json['entitlement'] as String?,
      productId: json['product_id'] as String?,
      store: json['store'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_pro': isPro,
      'entitlement': entitlement,
      'product_id': productId,
      'store': store,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
