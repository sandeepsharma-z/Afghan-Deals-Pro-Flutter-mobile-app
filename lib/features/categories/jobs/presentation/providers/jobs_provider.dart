import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/jobs_listing_model.dart';

// ── Subcategory model ──────────────────────────────────────────────────────
class JobsSubcategory {
  final String name;
  final String slug;
  final String? iconUrl;
  final int sortOrder;

  const JobsSubcategory({
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.sortOrder,
  });

  factory JobsSubcategory.fromMap(Map<String, dynamic> map) {
    return JobsSubcategory(
      name: map['name']?.toString().trim() ?? '',
      slug: map['slug']?.toString().trim() ?? '',
      iconUrl: map['icon_url']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

final jobsSubcategoriesProvider =
    FutureProvider.autoDispose<List<JobsSubcategory>>((ref) async {
  final response = await Supabase.instance.client
      .from('subcategories')
      .select('name, slug, icon_url, sort_order')
      .eq('category_slug', 'jobs')
      .eq('is_active', true)
      .order('sort_order', ascending: true)
      .order('name', ascending: true);

  final rows = (response as List<dynamic>)
      .map((e) => JobsSubcategory.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => s.name.isNotEmpty && s.slug.isNotEmpty)
      .toList();

  if (rows.isNotEmpty) return rows;

  return const [
    JobsSubcategory(name: 'Sales & Marketing',      slug: 'sales-marketing',      sortOrder: 1),
    JobsSubcategory(name: 'Teacher',                 slug: 'teacher',              sortOrder: 2),
    JobsSubcategory(name: 'Accountant',              slug: 'accountant',           sortOrder: 3),
    JobsSubcategory(name: 'Designer',                slug: 'designer',             sortOrder: 4),
    JobsSubcategory(name: 'Office Assistant',        slug: 'office-assistant',     sortOrder: 5),
    JobsSubcategory(name: 'Driver',                  slug: 'driver',               sortOrder: 6),
    JobsSubcategory(name: 'IT Engineer & Developer', slug: 'it-engineer-developer', sortOrder: 7),
  ];
});

// ── Filter model ───────────────────────────────────────────────────────────
class JobsFilter {
  final List<String> jobCategories;
  final List<String> jobTypes;
  final List<String> experiences;
  final List<String> industries;
  final List<String> educations;
  final List<String> sellerTypes;
  final double? minSalary;
  final double? maxSalary;
  final String region;
  final String sortBy;

  const JobsFilter({
    this.jobCategories = const [],
    this.jobTypes = const [],
    this.experiences = const [],
    this.industries = const [],
    this.educations = const [],
    this.sellerTypes = const [],
    this.minSalary,
    this.maxSalary,
    this.region = '',
    this.sortBy = 'newest',
  });

  JobsFilter copyWith({
    List<String>? jobCategories,
    List<String>? jobTypes,
    List<String>? experiences,
    List<String>? industries,
    List<String>? educations,
    List<String>? sellerTypes,
    double? minSalary,
    double? maxSalary,
    String? region,
    String? sortBy,
  }) =>
      JobsFilter(
        jobCategories: jobCategories ?? this.jobCategories,
        jobTypes: jobTypes ?? this.jobTypes,
        experiences: experiences ?? this.experiences,
        industries: industries ?? this.industries,
        educations: educations ?? this.educations,
        sellerTypes: sellerTypes ?? this.sellerTypes,
        minSalary: minSalary ?? this.minSalary,
        maxSalary: maxSalary ?? this.maxSalary,
        region: region ?? this.region,
        sortBy: sortBy ?? this.sortBy,
      );

  bool get isEmpty =>
      jobCategories.isEmpty &&
      jobTypes.isEmpty &&
      experiences.isEmpty &&
      industries.isEmpty &&
      educations.isEmpty &&
      sellerTypes.isEmpty &&
      minSalary == null &&
      maxSalary == null &&
      region.isEmpty;
}

final jobsFilterProvider =
    StateProvider.autoDispose<JobsFilter>((ref) => const JobsFilter());

// ── Listings providers ─────────────────────────────────────────────────────
Future<List<JobsListingModel>> _fetchJobs({String subcategory = ''}) async {
  var query = Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'jobs')
      .eq('is_active', true);
  if (subcategory.isNotEmpty) {
    query = query.eq('subcategory', subcategory);
  }
  final response = await query.order('created_at', ascending: false);
  return (response as List<dynamic>)
      .map((e) => JobsListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
}

final jobsListingsProvider =
    FutureProvider.autoDispose<List<JobsListingModel>>((ref) async {
  return _fetchJobs();
});

final jobsBySubcategoryProvider =
    FutureProvider.autoDispose.family<List<JobsListingModel>, String>(
        (ref, subcategory) async {
  return _fetchJobs(subcategory: subcategory);
});

final jobsFilteredProvider =
    FutureProvider.autoDispose.family<List<JobsListingModel>, String>(
        (ref, subcategory) async {
  final filter = ref.watch(jobsFilterProvider);
  final all = await ref.watch(jobsBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.jobCategories.isNotEmpty &&
        !filter.jobCategories.any((c) => c.toLowerCase() == item.subcategory.toLowerCase())) {
      return false;
    }
    if (filter.jobTypes.isNotEmpty &&
        !filter.jobTypes.any((t) => t.toLowerCase() == item.jobType.toLowerCase())) {
      return false;
    }
    if (filter.experiences.isNotEmpty &&
        !filter.experiences.any((e) => e.toLowerCase() == item.experience.toLowerCase())) {
      return false;
    }
    if (filter.industries.isNotEmpty &&
        !filter.industries.any((i) => i.toLowerCase() == item.industry.toLowerCase())) {
      return false;
    }
    if (filter.educations.isNotEmpty &&
        !filter.educations.any((e) => e.toLowerCase() == item.education.toLowerCase())) {
      return false;
    }
    if (filter.sellerTypes.isNotEmpty &&
        !filter.sellerTypes.any((s) => s.toLowerCase() == item.sellerType.toLowerCase())) {
      return false;
    }
    final salary = double.tryParse(item.price) ?? 0;
    if (filter.minSalary != null && salary < filter.minSalary!) { return false; }
    if (filter.maxSalary != null && salary > filter.maxSalary!) { return false; }
    if (filter.region.isNotEmpty &&
        !item.city.toLowerCase().contains(filter.region.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  switch (filter.sortBy) {
    case 'salary_high':
      result.sort((a, b) =>
          (double.tryParse(b.price) ?? 0).compareTo(double.tryParse(a.price) ?? 0));
    case 'salary_low':
      result.sort((a, b) =>
          (double.tryParse(a.price) ?? 0).compareTo(double.tryParse(b.price) ?? 0));
    case 'oldest':
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});

// ── Dynamic filter option providers ───────────────────────────────────────
Future<List<String>> _distinctJobsField(String field) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select('category_data')
      .eq('category', 'jobs')
      .eq('is_active', true);
  return (response as List<dynamic>)
      .map((e) {
        final cd = (e as Map<String, dynamic>)['category_data'] as Map<String, dynamic>? ?? {};
        return cd[field]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

final jobsTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctJobsField('job_type');
  if (dynamic.isNotEmpty) return dynamic;
  return const ['Full-time', 'Part-time', 'Contract', 'Freelance', 'Internship', 'Remote'];
});

final jobsExperiencesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctJobsField('experience');
  if (dynamic.isNotEmpty) return dynamic;
  return const [
    'No Experience', 'Less than 1 year', '1-2 years',
    '2-5 years', '5-10 years', '10+ years',
  ];
});

final jobsIndustriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctJobsField('industry');
  if (dynamic.isNotEmpty) return dynamic;
  return const [
    'Technology', 'Education', 'Healthcare', 'Finance & Accounting',
    'Sales & Marketing', 'Construction', 'Transportation', 'Hospitality',
    'Government', 'Manufacturing', 'Retail', 'Other',
  ];
});

final jobsEducationsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctJobsField('education');
  if (dynamic.isNotEmpty) return dynamic;
  return const [
    'High School', 'Diploma', "Bachelor's Degree",
    "Master's Degree", 'PhD', 'Any',
  ];
});

final jobsSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final dynamic = await _distinctJobsField('seller_type');
  if (dynamic.isNotEmpty) return dynamic;
  return const ['All', 'Individual', 'Company'];
});
