enum FuturePlanCategory { education, marriage, investment }

enum AssetType { gold, diamond, land, property, stocks, mutualFund, money, other }

extension FuturePlanCategoryX on FuturePlanCategory {
  String get label => switch (this) {
        FuturePlanCategory.education => 'Education',
        FuturePlanCategory.marriage => 'Marriage',
        FuturePlanCategory.investment => 'Investment',
      };

  String get emoji => switch (this) {
        FuturePlanCategory.education => '🎓',
        FuturePlanCategory.marriage => '💍',
        FuturePlanCategory.investment => '📈',
      };
}

extension AssetTypeX on AssetType {
  String get label => switch (this) {
        AssetType.gold => 'Gold',
        AssetType.diamond => 'Diamond',
        AssetType.land => 'Land',
        AssetType.property => 'Property',
        AssetType.stocks => 'Stocks',
        AssetType.mutualFund => 'Mutual Fund',
        AssetType.money => 'Money / FD',
        AssetType.other => 'Other',
      };

  String get emoji => switch (this) {
        AssetType.gold => '🪙',
        AssetType.diamond => '💎',
        AssetType.land => '🏞️',
        AssetType.property => '🏠',
        AssetType.stocks => '📊',
        AssetType.mutualFund => '💹',
        AssetType.money => '💵',
        AssetType.other => '📦',
      };
}

class FuturePlan {
  final String id;
  final FuturePlanCategory category;
  final AssetType assetType;
  final String title;
  final String? description;
  final double? targetAmount;
  final double? currentAmount;
  final String currency;
  final DateTime? targetDate;
  final DateTime createdAt;

  const FuturePlan({
    required this.id,
    required this.category,
    required this.assetType,
    required this.title,
    this.description,
    this.targetAmount,
    this.currentAmount,
    this.currency = 'INR',
    this.targetDate,
    required this.createdAt,
  });

  double get progressPercent {
    if (targetAmount == null || targetAmount == 0) return 0;
    final current = currentAmount ?? 0;
    return (current / targetAmount!).clamp(0.0, 1.0);
  }

  FuturePlan copyWith({
    FuturePlanCategory? category,
    AssetType? assetType,
    String? title,
    String? description,
    bool clearDescription = false,
    double? targetAmount,
    bool clearTargetAmount = false,
    double? currentAmount,
    bool clearCurrentAmount = false,
    String? currency,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) =>
      FuturePlan(
        id: id,
        category: category ?? this.category,
        assetType: assetType ?? this.assetType,
        title: title ?? this.title,
        description: clearDescription ? null : (description ?? this.description),
        targetAmount: clearTargetAmount ? null : (targetAmount ?? this.targetAmount),
        currentAmount: clearCurrentAmount ? null : (currentAmount ?? this.currentAmount),
        currency: currency ?? this.currency,
        targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'assetType': assetType.name,
        'title': title,
        if (description != null) 'description': description,
        if (targetAmount != null) 'targetAmount': targetAmount,
        if (currentAmount != null) 'currentAmount': currentAmount,
        'currency': currency,
        if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FuturePlan.fromJson(Map<String, dynamic> j) => FuturePlan(
        id: j['id'] as String,
        category: FuturePlanCategory.values.firstWhere(
          (c) => c.name == (j['category'] as String? ?? 'investment'),
          orElse: () => FuturePlanCategory.investment,
        ),
        assetType: AssetType.values.firstWhere(
          (a) => a.name == (j['assetType'] as String? ?? 'other'),
          orElse: () => AssetType.other,
        ),
        title: j['title'] as String,
        description: j['description'] as String?,
        targetAmount: (j['targetAmount'] as num?)?.toDouble(),
        currentAmount: (j['currentAmount'] as num?)?.toDouble(),
        currency: j['currency'] as String? ?? 'INR',
        targetDate: j['targetDate'] != null
            ? DateTime.tryParse(j['targetDate'] as String)
            : null,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
