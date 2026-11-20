import '../domain/symptom_model.dart';

class ConditionCategoryData {
  final String title;
  final String specialtySlug;
  final List<ConditionData> conditions;

  const ConditionCategoryData({
    required this.title,
    required this.specialtySlug,
    required this.conditions,
  });
}

class ConditionData {
  final String title;
  final String slug;
  final String category;
  final String categorySlug;

  const ConditionData({
    required this.title,
    required this.slug,
    required this.category,
    required this.categorySlug,
  });
}

class ConditionsCatalogue {
  ConditionsCatalogue._();

  static const List<ConditionCategoryData> allCategories = [
    ConditionCategoryData(
      title: 'Musculoskeletal / Orthopedic',
      specialtySlug: 'orthopedic',
      conditions: [
        ConditionData(title: 'Back Pain', slug: 'back-pain', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
        ConditionData(title: 'Neck Pain', slug: 'neck-pain-cervical-spondylosis', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
        ConditionData(title: 'Sciatica', slug: 'sciatica', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
        ConditionData(title: 'Frozen Shoulder', slug: 'frozen-shoulder', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
        ConditionData(title: 'Knee Osteoarthritis', slug: 'osteoarthritis', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
        ConditionData(title: 'Spondylosis', slug: 'spondylosis', category: 'Musculoskeletal / Orthopedic', categorySlug: 'orthopedic'),
      ],
    ),
    ConditionCategoryData(
      title: 'Sports Injuries',
      specialtySlug: 'sports-injury',
      conditions: [
        ConditionData(title: 'ACL Tear', slug: 'ligament-sprains', category: 'Sports Injuries', categorySlug: 'sports-injury'),
        ConditionData(title: 'Rotator Cuff Injury', slug: 'rotator-cuff-strain', category: 'Sports Injuries', categorySlug: 'sports-injury'),
        ConditionData(title: 'Tennis Elbow', slug: 'tennis-elbow', category: 'Sports Injuries', categorySlug: 'sports-injury'),
        ConditionData(title: 'Ankle Sprain', slug: 'ankle-sprain', category: 'Sports Injuries', categorySlug: 'sports-injury'),
        ConditionData(title: 'Stress Fracture', slug: 'stress-fractures', category: 'Sports Injuries', categorySlug: 'sports-injury'),
        ConditionData(title: 'Hamstring Strain', slug: 'muscle-pulls-strains', category: 'Sports Injuries', categorySlug: 'sports-injury'),
      ],
    ),
    ConditionCategoryData(
      title: 'Neurological Conditions',
      specialtySlug: 'neurological',
      conditions: [
        ConditionData(title: 'Stroke', slug: 'stroke-rehabilitation', category: 'Neurological Conditions', categorySlug: 'neurological'),
        ConditionData(title: 'Parkinson\'s Disease', slug: 'parkinsons-disease', category: 'Neurological Conditions', categorySlug: 'neurological'),
        ConditionData(title: 'Multiple Sclerosis (MS)', slug: 'multiple-sclerosis', category: 'Neurological Conditions', categorySlug: 'neurological'),
        ConditionData(title: 'Spinal Cord Injury', slug: 'spinal-cord-injury', category: 'Neurological Conditions', categorySlug: 'neurological'),
        ConditionData(title: 'Cerebral Palsy', slug: 'cerebral-palsy', category: 'Neurological Conditions', categorySlug: 'neurological'),
        ConditionData(title: 'Traumatic Brain Injury', slug: 'traumatic-brain-injury', category: 'Neurological Conditions', categorySlug: 'neurological'),
      ],
    ),
    ConditionCategoryData(
      title: 'Pediatric Conditions',
      specialtySlug: 'pediatrics',
      conditions: [
        ConditionData(title: 'Cerebral Palsy in Children', slug: 'cerebral-palsy-children', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
        ConditionData(title: 'Developmental Delay', slug: 'developmental-delay', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
        ConditionData(title: 'Muscular Dystrophy', slug: 'muscular-dystrophy', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
        ConditionData(title: 'Infant Torticollis', slug: 'torticollis', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
        ConditionData(title: 'Scoliosis in Children', slug: 'scoliosis-postural-deformities', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
        ConditionData(title: 'Coordination Difficulties in Children', slug: 'coordination-difficulties-children', category: 'Pediatric Conditions', categorySlug: 'pediatrics'),
      ],
    ),
    ConditionCategoryData(
      title: 'Cardio-Respiratory',
      specialtySlug: 'cardio-pulmonary',
      conditions: [
        ConditionData(title: 'COPD', slug: 'copd', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
        ConditionData(title: 'Post-COVID Recovery', slug: 'post-covid-pulmonary-rehabilitation', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
        ConditionData(title: 'Asthma', slug: 'asthma-breathing-exercises', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
        ConditionData(title: 'Post-CABG Rehabilitation', slug: 'cardiac-rehabilitation', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
        ConditionData(title: 'Bronchiectasis', slug: 'bronchiectasis', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
        ConditionData(title: 'ICU Recovery', slug: 'icu-recovery', category: 'Cardio-Respiratory', categorySlug: 'cardio-pulmonary'),
      ],
    ),
    ConditionCategoryData(
      title: 'Geriatric Care',
      specialtySlug: 'geriatric',
      conditions: [
        ConditionData(title: 'Osteoporosis', slug: 'osteoporosis-related-fragility', category: 'Geriatric Care', categorySlug: 'geriatric'),
        ConditionData(title: 'Balance Disorders', slug: 'balance-coordination-disorders', category: 'Geriatric Care', categorySlug: 'geriatric'),
        ConditionData(title: 'Fall Prevention', slug: 'fall-risk-balance-training', category: 'Geriatric Care', categorySlug: 'geriatric'),
        ConditionData(title: 'Hip Fracture Rehabilitation', slug: 'hip-fracture-rehabilitation', category: 'Geriatric Care', categorySlug: 'geriatric'),
        ConditionData(title: 'Age-Related Deconditioning', slug: 'age-related-mobility-decline', category: 'Geriatric Care', categorySlug: 'geriatric'),
        ConditionData(title: 'Knee and Hip Arthritis', slug: 'knee-hip-arthritis', category: 'Geriatric Care', categorySlug: 'geriatric'),
      ],
    ),
    ConditionCategoryData(
      title: 'Women\'s Health',
      specialtySlug: 'womens-health',
      conditions: [
        ConditionData(title: 'Pelvic Girdle Pain', slug: 'pelvic-girdle-pain', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Back Pain in Pregnancy', slug: 'prenatal-postnatal-back-pain', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Diastasis Recti', slug: 'postpartum-recovery-diastasis-recti', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Postnatal Core Weakness', slug: 'postnatal-core-weakness', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Symphysis Pubis Dysfunction', slug: 'symphysis-pubis-dysfunction', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Swelling in Pregnancy', slug: 'swelling-in-pregnancy', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Urinary Incontinence', slug: 'urinary-incontinence', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Pelvic Organ Prolapse', slug: 'pelvic-floor-dysfunction', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Chronic Pelvic Pain', slug: 'pelvic-pain', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Painful Intercourse (Dyspareunia)', slug: 'dyspareunia-painful-intercourse', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Vaginismus', slug: 'vaginismus', category: 'Women\'s Health', categorySlug: 'womens-health'),
        ConditionData(title: 'Faecal Incontinence', slug: 'faecal-incontinence', category: 'Women\'s Health', categorySlug: 'womens-health'),
      ],
    ),
  ];

  static final Map<String, ConditionData> bySlug = {
    for (final cat in allCategories)
      for (final cond in cat.conditions)
        cond.slug: cond,
  };

  static List<ConditionData> get allConditions => [
    for (final cat in allCategories) ...cat.conditions,
  ];

  /// Find or synthesize a SymptomModel from canonical catalogue data.
  /// Guarantees that condition detail screens never fail or show null errors.
  static SymptomModel findOrCreateSymptom(String slug, {List<SymptomModel>? liveSymptoms}) {
    if (liveSymptoms != null) {
      final found = liveSymptoms.where((s) => s.slug == slug).firstOrNull;
      if (found != null) return found;
    }
    final meta = bySlug[slug];
    final title = meta?.title ?? slug.replaceAll('-', ' ');
    final category = meta?.category ?? 'Musculoskeletal / Orthopedic';
    return SymptomModel(
      id: slug,
      title: title,
      slug: slug,
      description: 'Specialized clinical physiotherapy assessment, targeted rehabilitation, and evidence-based treatment plan for $title.',
      department: category,
      symptomsList: [title, 'Localized stiffness or discomfort', 'Reduced range of motion', 'Activity limitation'],
      recoveryEstimate: '2-6 weeks depending on severity',
      treatment: 'Personalized manual therapy, mobility drills, therapeutic exercises, and progressive strengthening tailored by our certified physiotherapists.',
    );
  }
}
