class UserInput {
  final int age; // recipient age (your existing field)
  final String gender;
  final String relationship;
  final String occasion;
  final int budgetNpr;

  // Recipient preference signals (strong personalization)
  final List<String> interests; // e.g., ["Books", "Technology"]
  final String giftStyle; // "Practical" | "Surprise"

  // NEW: recipient persona attributes
  final String recipientAgeGroup; // "Teen" | "Young Adult" | "Adult" | "Senior"
  final String recipientPersonality; // "Minimalist" | "Trendy" | "Sentimental"
  final List<String> dislikedCategories; // e.g., ["Beauty", "Food"]

  const UserInput({
    required this.age,
    required this.gender,
    required this.relationship,
    required this.occasion,
    required this.budgetNpr,
    required this.interests,
    required this.giftStyle,

    required this.recipientAgeGroup,
    required this.recipientPersonality,
    required this.dislikedCategories,
  });

  UserInput copyWith({
    List<String>? interests,
    String? giftStyle,
    String? recipientAgeGroup,
    String? recipientPersonality,
    List<String>? dislikedCategories,
  }) {
    return UserInput(
      age: age,
      gender: gender,
      relationship: relationship,
      occasion: occasion,
      budgetNpr: budgetNpr,
      interests: interests ?? this.interests,
      giftStyle: giftStyle ?? this.giftStyle,
      recipientAgeGroup: recipientAgeGroup ?? this.recipientAgeGroup,
      recipientPersonality: recipientPersonality ?? this.recipientPersonality,
      dislikedCategories: dislikedCategories ?? this.dislikedCategories,
    );
  }
}