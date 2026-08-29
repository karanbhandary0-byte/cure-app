class DiseaseSpecialtyMapper {
  static const Map<String, List<String>> diseaseToSpecialties = {
    "fever": ["General Physician", "Internal Medicine"],
    "cough": ["General Physician", "ENT", "Pulmonology"],
    "cold": ["General Physician", "ENT"],
    "flu": ["General Physician"],
    "headache": ["General Physician", "Neurology"],
    "hypertension": ["General Physician", "Cardiology"],
    "high bp": ["Cardiology", "General Physician"],
    "blood pressure": ["Cardiology", "General Physician"],
    "heart pain": ["Cardiology"],
    "chest pain": ["Cardiology", "General Physician"],
    "palpitations": ["Cardiology"],
    "cardiac": ["Cardiology"],
    "skin rash": ["Dermatology"],
    "acne": ["Dermatology"],
    "itching": ["Dermatology"],
    "eczema": ["Dermatology"],
    "hair loss": ["Dermatology"],
    "skin allergy": ["Dermatology"],
    "diabetes": ["Endocrinology", "General Physician"],
    "sugar": ["Endocrinology", "General Physician"],
    "thyroid": ["Endocrinology"],
    "child fever": ["Pediatrics"],
    "baby cough": ["Pediatrics"],
    "vaccination": ["Pediatrics"],
    "pediatric": ["Pediatrics"],
    "eye pain": ["Ophthalmology"],
    "vision problem": ["Ophthalmology"],
    "cataract": ["Ophthalmology"],
    "red eye": ["Ophthalmology"],
    "bone pain": ["Orthopedics"],
    "joint pain": ["Orthopedics"],
    "back pain": ["Orthopedics"],
    "knee pain": ["Orthopedics"],
    "fracture": ["Orthopedics"],
    "toothache": ["Dentistry"],
    "dental cavity": ["Dentistry"],
    "bleeding gums": ["Dentistry"],
    "stomach pain": ["Gastroenterology", "General Physician"],
    "acidity": ["Gastroenterology", "General Physician"],
    "indigestion": ["Gastroenterology"],
    "depression": ["Psychiatry", "Psychology"],
    "anxiety": ["Psychiatry", "Psychology"],
    "insomnia": ["Psychiatry"],
    "stress": ["Psychiatry"],
  };

  /// Maps a disease, symptom, or condition query to matching doctor specialties
  static List<String> getSpecialtiesForQuery(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final Set<String> matched = {};

    diseaseToSpecialties.forEach((keyword, specialties) {
      if (clean.contains(keyword) || keyword.contains(clean)) {
        matched.addAll(specialties);
      }
    });

    return matched.toList();
  }
}
