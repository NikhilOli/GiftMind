class UserInput {
  final int age;
  final String gender;
  final String relationship;
  final String occasion;
  final int budgetNpr;

  final List<String> interests; // e.g., ["Books", "Fashion"]
  final String giftStyle; // "Practical" | "Surprise"

  const UserInput({
    required this.age,
    required this.gender,
    required this.relationship,
    required this.occasion,
    required this.budgetNpr,
    required this.interests,
    required this.giftStyle,
  });

  UserInput copyWith({
    List<String>? interests,
    String? giftStyle,
  }) {
    return UserInput(
      age: age,
      gender: gender,
      relationship: relationship,
      occasion: occasion,
      budgetNpr: budgetNpr,
      interests: interests ?? this.interests,
      giftStyle: giftStyle ?? this.giftStyle,
    );
  }
}
