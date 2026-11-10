import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/category_model.dart';
import '../domain/location_model.dart';
import '../domain/symptom_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  /// Fetch Master Locations (Cities and Areas)
  Future<MasterLocationsModel> getLocations() async {
    try {
      final response = await _apiClient.get('/doctors/locations/master');
      return MasterLocationsModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return const MasterLocationsModel(
        cities: [
          CityLocation(name: 'Nagpur', areas: ['Raj Nagar', 'Dharampeth', 'Ramdaspeth', 'Sadar', 'Civil Lines', 'Sitabuldi', 'Pratap Nagar']),
          CityLocation(name: 'Pune', areas: ['Kothrud', 'Baner', 'Viman Nagar', 'Wakad', 'Aundh']),
          CityLocation(name: 'Mumbai', areas: ['Andheri West', 'Bandra', 'Powai', 'Juhu']),
        ],
        areas: ['Raj Nagar', 'Dharampeth', 'Ramdaspeth', 'Sadar', 'Civil Lines', 'Sitabuldi', 'Pratap Nagar'],
        panIndia: true,
      );
    }
  }

  /// Fetch Clinical Specialties / Categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      final list = response.data['categories'] as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Design-accurate fallback from website screenshots and live Supabase assets
    return const [
      CategoryModel(
        id: 'cat_ortho',
        title: 'Orthopedic Doctor',
        slug: 'orthopedic',
        description: 'Specialized therapy for bones, joints, ligaments, tendons, and post-surgical rehabilitation.',
        doctorCount: 1,
        conditions: ['Back Pain', 'Neck Pain'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264306507-xt27qr.webp',
      ),
      CategoryModel(
        id: 'cat_sports',
        title: 'Sports Injury Doctor',
        slug: 'sports-injury',
        description: 'High-performance sports medicine, kinesio taping, dry needling, and explosive return-to-play conditioning.',
        doctorCount: 0,
        conditions: ['ACL Tear', 'Rotator Cuff Injury'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264324560-6ch54c.webp',
      ),
      CategoryModel(
        id: 'cat_neuro',
        title: 'Neurological Doctor',
        slug: 'neurological',
        description: 'Expert care for nerve disorders, stroke rehabilitation, Parkinson\'s, and spinal cord injuries.',
        doctorCount: 0,
        conditions: ['Stroke', 'Parkinson\'s Disease'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264343332-9exy9s.webp',
      ),
      CategoryModel(
        id: 'cat_pedia',
        title: 'Pediatric Doctor',
        slug: 'pediatrics',
        description: 'Gentle, play-based physical therapy for developmental delays, cerebral palsy, and juvenile posture correction.',
        doctorCount: 0,
        conditions: ['Cerebral Palsy in Children', 'Developmental Delay'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264360361-u7avqs.webp',
      ),
      CategoryModel(
        id: 'cat_cardio',
        title: 'Cardio Doctor',
        slug: 'cardio-pulmonary',
        description: 'Lung capacity building, post-COVID respiratory recovery, and cardiac endurance conditioning.',
        doctorCount: 0,
        conditions: ['COPD', 'Post-COVID Recovery'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264373903-q9kfn8.webp',
      ),
      CategoryModel(
        id: 'cat_geriatric',
        title: 'Geriatric Doctor',
        slug: 'geriatric',
        description: 'Specialized elderly mobility enhancement, fall prevention, and gentle arthritis relief at home.',
        doctorCount: 0,
        conditions: ['Osteoporosis', 'Balance Disorders'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264390190-vhlaet.webp',
      ),
      CategoryModel(
        id: 'cat_womens',
        title: 'Women\'s Health',
        slug: 'womens-health',
        description: 'Pre and post-natal pelvic floor strengthening, diastasis recti, and pregnancy postural decompression.',
        doctorCount: 0,
        conditions: ['Pelvic Girdle Pain', 'Back Pain in Pregnancy'],
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/categories/1793264406592-hch3ip.webp',
      ),
    ];
  }

  /// Fetch Medical Symptoms / Conditions Catalogue
  Future<List<SymptomModel>> getSymptoms() async {
    try {
      final response = await _apiClient.get('/symptoms');
      final list = response.data['symptoms'] as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        return list.map((s) => SymptomModel.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Design-accurate 8 conditions from website screenshots and live Supabase assets
    return const [
      SymptomModel(
        id: 'back-pain',
        title: 'Back Pain',
        slug: 'back-pain',
        recoveryEstimate: '4-8 weeks',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Pain along the spine caused by muscle strain, poor posture, disc issues, or prolonged sitting/standing.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263744836-jiwd6q.webp',
      ),
      SymptomModel(
        id: 'neck-pain-cervical-spondylosis',
        title: 'Neck Pain',
        slug: 'neck-pain-cervical-spondylosis',
        recoveryEstimate: '4-6 weeks',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Wear-and-tear or strain affecting the cervical (neck) spine, common with age or desk-bound work.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263028410-eefe6s.webp',
      ),
      SymptomModel(
        id: 'sciatica',
        title: 'Sciatica',
        slug: 'sciatica',
        recoveryEstimate: '4-8 weeks',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Irritation or compression of the sciatic nerve, usually from a disc issue or piriformis tightness.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263044438-pbny0i.webp',
      ),
      SymptomModel(
        id: 'frozen-shoulder',
        title: 'Frozen Shoulder',
        slug: 'frozen-shoulder',
        recoveryEstimate: '8-16 weeks',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Progressive stiffening and thickening of the shoulder joint capsule, restricting movement.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263063110-hrc6ub.webp',
      ),
      SymptomModel(
        id: 'osteoarthritis',
        title: 'Knee Osteoarthritis',
        slug: 'osteoarthritis',
        recoveryEstimate: 'Ongoing management',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Degeneration of joint cartilage leading to bone-on-bone friction, common with aging.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263078949-rjttlc.webp',
      ),
      SymptomModel(
        id: 'spondylosis',
        title: 'Spondylosis',
        slug: 'spondylosis',
        recoveryEstimate: '4-6 weeks',
        department: 'Musculoskeletal / Orthopedic',
        description: 'Age-related wear-and-tear of the spine\'s discs and joints, causing stiffness and, at times, nerve-related pain.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263093560-q26j7a.webp',
      ),
      SymptomModel(
        id: 'stroke-rehabilitation',
        title: 'Stroke',
        slug: 'stroke-rehabilitation',
        recoveryEstimate: '3-12 months',
        department: 'Neurological Conditions',
        description: 'Recovery therapy after a stroke affecting brain blood supply, causing motor/sensory deficits.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263159699-1by8n1.webp',
      ),
      SymptomModel(
        id: 'traumatic-brain-injury',
        title: 'Traumatic Brain Injury',
        slug: 'traumatic-brain-injury',
        recoveryEstimate: '3-12 months',
        department: 'Neurological Conditions',
        description: 'Recovery therapy after a head injury that has affected movement, balance, or coordination.',
        image: 'https://usrgvhubmbnyvxocjpga.supabase.co/storage/v1/object/public/media/symptoms/1793263185206-59trlb.webp',
      ),
    ];
  }
}
