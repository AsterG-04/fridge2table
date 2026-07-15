class Ingredient {
  final int? id;
  final String name;
  final double quantity;
  final String unit;
  final String? expiryDate;
  final String? category;
  final String? location;
  final DateTime? updatedAt;

  Ingredient({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.category,
    this.location,
    this.updatedAt,
  });


  // Convert Flutter object → JSON
  // (sending data to FastAPI)
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "quantity": quantity,
      "unit": unit,
      "expiry_date": expiryDate,
      "category": category,
      "location": location,
    };
  }


  // Convert JSON → Flutter object
  // (receiving data from FastAPI or Supabase)
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json["id"],
      name: json["name"],
      quantity: (json["quantity"]).toDouble(),
      unit: json["unit"],
      expiryDate: json["expiry_date"],
      category: json["category"],
      location: json["location"],
      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.tryParse(json["updated_at"].toString()),
    );
  }

  // Convert Flutter object → JSON for Supabase, which (unlike the local
  // FastAPI create/update endpoints) needs an explicit id + updated_at
  // since sync upserts by id and compares timestamps.
  Map<String, dynamic> toSupabaseJson() {
    return {
      "id": id,
      "name": name,
      "quantity": quantity,
      "unit": unit,
      "expiry_date": expiryDate,
      "category": category,
      "location": location,
      "updated_at": (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
  }
}