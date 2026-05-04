import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../features/listings/data/models/jobs_listing_model.dart';
import '../../../../admin/presentation/providers/admin_dynamic_provider.dart';

const _unset = Object();

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

const _defaultJobsSubcategories = [
  JobsSubcategory(
      name: 'Sales & Marketing', slug: 'sales-and-marketing', sortOrder: 1),
  JobsSubcategory(name: 'Teacher', slug: 'teacher', sortOrder: 2),
  JobsSubcategory(name: 'Accountant', slug: 'accountant', sortOrder: 3),
  JobsSubcategory(name: 'Designer', slug: 'designer', sortOrder: 4),
  JobsSubcategory(
      name: 'Office Assistant', slug: 'office-assistant', sortOrder: 5),
  JobsSubcategory(name: 'Driver', slug: 'driver', sortOrder: 6),
  JobsSubcategory(
      name: 'IT Engineer & Developer',
      slug: 'it-engineer-developer',
      sortOrder: 7),
];

const _jobsSubcategoryAliases = {
  'sales-marketing': 'sales-and-marketing',
  'it-engineer': 'it-engineer-developer',
};

const _jobsAllowedSlugs = {
  'sales-and-marketing',
  'sales-marketing',
  'teacher',
  'accountant',
  'designer',
  'office-assistant',
  'driver',
  'it-engineer-developer',
  'it-engineer',
};

String normalizeJobSubcategorySlug(String slug) {
  final normalized = slug
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return _jobsSubcategoryAliases[normalized] ?? normalized;
}

String _normalizeSearchText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _slugFromText(String value) {
  final text = value.toLowerCase();
  if (text.contains('accountant') ||
      text.contains('accounting') ||
      text.contains('finance')) {
    return 'accountant';
  }
  if (text.contains('marketing') || text.contains('sales')) {
    return 'sales-and-marketing';
  }
  if (text.contains('teacher') ||
      text.contains('tutor') ||
      text.contains('academy') ||
      text.contains('school')) {
    return 'teacher';
  }
  if (text.contains('designer') ||
      text.contains('graphic') ||
      text.contains('creative')) {
    return 'designer';
  }
  if (text.contains('driver') ||
      text.contains('transport') ||
      text.contains('delivery')) {
    return 'driver';
  }
  if (text.contains('assistant') ||
      text.contains('support') ||
      text.contains('customer') ||
      text.contains('office')) {
    return 'office-assistant';
  }
  if (text.contains('developer') ||
      text.contains('engineer') ||
      text.contains('flutter') ||
      text.contains('software') ||
      text.contains('data analyst') ||
      text.contains('tech')) {
    return 'it-engineer-developer';
  }
  return '';
}

String jobCategorySlugForItem(JobsListingModel item) {
  final direct = normalizeJobSubcategorySlug(item.subcategory);
  if (_jobsAllowedSlugs.contains(direct) &&
      direct != 'sales-marketing' &&
      direct != 'it-engineer') {
    return direct;
  }
  return _slugFromText([
    item.title,
    item.description,
    item.company,
    item.industry,
    item.sellerName,
  ].join(' '));
}

bool jobMatchesSubcategory(JobsListingModel item, String subcategory) {
  if (subcategory.isEmpty) return true;
  return jobCategorySlugForItem(item) ==
      normalizeJobSubcategorySlug(subcategory);
}

String jobIndustryForItem(JobsListingModel item) {
  final explicit = item.industry.trim();
  if (explicit.isNotEmpty) return explicit;
  final category = jobCategorySlugForItem(item);
  switch (category) {
    case 'accountant':
      return 'Finance & Accounting';
    case 'sales-and-marketing':
      return 'Sales & Marketing';
    case 'it-engineer-developer':
      return 'Technology';
    case 'teacher':
      return 'Education';
    case 'designer':
      return 'Design & Creative';
    case 'driver':
      return 'Transportation';
    case 'office-assistant':
      return 'Administration & Support';
  }
  return '';
}

String jobSellerTypeForItem(JobsListingModel item) {
  if (item.sellerType.trim().isNotEmpty) return item.sellerType.trim();
  return item.company.trim().isNotEmpty ? 'Company' : 'Individual';
}

bool _matchesAnyNormalized(String value, List<String> selected) {
  final normalized = _normalizeSearchText(value);
  return selected.any((item) => _normalizeSearchText(item) == normalized);
}

bool _matchesRegion(JobsListingModel item, String region) {
  final needle = _normalizeSearchText(region);
  if (needle.isEmpty) return true;
  final haystack = _normalizeSearchText([
    item.city,
    item.country,
    item.location,
  ].join(' '));
  return haystack.contains(needle);
}

JobsSubcategory _normalizeJobsSubcategory(JobsSubcategory item) {
  final slug = normalizeJobSubcategorySlug(item.slug);
  if (slug == item.slug) return item;
  return JobsSubcategory(
    name: item.name,
    slug: slug,
    iconUrl: item.iconUrl,
    sortOrder: item.sortOrder,
  );
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

  final bySlug = {
    for (final item in _defaultJobsSubcategories) item.slug: item,
    for (final item in rows)
      if (_jobsAllowedSlugs.contains(item.slug))
        _normalizeJobsSubcategory(item).slug: _normalizeJobsSubcategory(item),
  };
  return bySlug.values.toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.compareTo(b.name);
    });
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
    Object? minSalary = _unset,
    Object? maxSalary = _unset,
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
        minSalary: identical(minSalary, _unset)
            ? this.minSalary
            : minSalary as double?,
        maxSalary: identical(maxSalary, _unset)
            ? this.maxSalary
            : maxSalary as double?,
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
  final response = await Supabase.instance.client
      .from('listings')
      .select()
      .eq('category', 'jobs')
      .eq('is_active', true)
      .order('created_at', ascending: false);
  final items = (response as List<dynamic>)
      .map((e) => JobsListingModel.fromMap(e as Map<String, dynamic>))
      .toList();
  if (subcategory.isEmpty) return items;
  return items
      .where((item) => jobMatchesSubcategory(item, subcategory))
      .toList();
}

final jobsListingsProvider =
    FutureProvider.autoDispose<List<JobsListingModel>>((ref) async {
  return _fetchJobs();
});

final jobsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<JobsListingModel>, String>((ref, subcategory) async {
  return _fetchJobs(subcategory: subcategory);
});

final jobsFilteredProvider = FutureProvider.autoDispose
    .family<List<JobsListingModel>, String>((ref, subcategory) async {
  final filter = ref.watch(jobsFilterProvider);
  final all = await ref.watch(jobsBySubcategoryProvider(subcategory).future);

  var result = all.where((item) {
    if (filter.jobCategories.isNotEmpty &&
        !filter.jobCategories.any((c) {
          final slug = normalizeJobSubcategorySlug(c);
          return slug == jobCategorySlugForItem(item) ||
              c.toLowerCase() == item.subcategoryLabel.toLowerCase();
        })) {
      return false;
    }
    if (filter.jobTypes.isNotEmpty &&
        !_matchesAnyNormalized(item.jobType, filter.jobTypes)) {
      return false;
    }
    if (filter.experiences.isNotEmpty &&
        !_matchesAnyNormalized(item.experience, filter.experiences)) {
      return false;
    }
    if (filter.industries.isNotEmpty &&
        !_matchesAnyNormalized(jobIndustryForItem(item), filter.industries)) {
      return false;
    }
    if (filter.educations.isNotEmpty &&
        !_matchesAnyNormalized(item.education, filter.educations)) {
      return false;
    }
    if (filter.sellerTypes.isNotEmpty &&
        !filter.sellerTypes.any((s) => s.toLowerCase() == 'all') &&
        !_matchesAnyNormalized(
            jobSellerTypeForItem(item), filter.sellerTypes)) {
      return false;
    }
    final salary = double.tryParse(item.price) ?? 0;
    if (filter.minSalary != null && salary < filter.minSalary!) {
      return false;
    }
    if (filter.maxSalary != null && salary > filter.maxSalary!) {
      return false;
    }
    if (!_matchesRegion(item, filter.region)) {
      return false;
    }
    return true;
  }).toList();

  switch (filter.sortBy) {
    case 'salary_high':
      result.sort((a, b) => (double.tryParse(b.price) ?? 0)
          .compareTo(double.tryParse(a.price) ?? 0));
    case 'salary_low':
      result.sort((a, b) => (double.tryParse(a.price) ?? 0)
          .compareTo(double.tryParse(b.price) ?? 0));
    case 'oldest':
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    default:
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return result;
});

// ── Dynamic filter option providers ───────────────────────────────────────
Future<List<String>> _distinctJobsField(String field,
    {String subcategory = ''}) async {
  final response = await Supabase.instance.client
      .from('listings')
      .select(
          'title,description,subcategory,seller_name,city,country,price,currency,category_data')
      .eq('category', 'jobs')
      .eq('is_active', true);
  return (response as List<dynamic>)
      .map((e) => JobsListingModel.fromMap(e as Map<String, dynamic>))
      .where((item) => jobMatchesSubcategory(item, subcategory))
      .map((e) {
        final cd = {
          'job_type': e.jobType,
          'experience': e.experience,
          'industry': jobIndustryForItem(e),
          'education': e.education,
          'seller_type': jobSellerTypeForItem(e),
        };
        return cd[field]?.toString().trim() ?? '';
      })
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}

final jobsCategoriesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final categories = await ref.watch(jobsSubcategoriesProvider.future);
  if (subcategory.isEmpty) return categories.map((s) => s.name).toList();
  final normalized = normalizeJobSubcategorySlug(subcategory);
  final current = categories
      .where((s) => normalizeJobSubcategorySlug(s.slug) == normalized)
      .map((s) => s.name)
      .toList();
  return current.isNotEmpty ? current : categories.map((s) => s.name).toList();
});

final jobsTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctJobsField('job_type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  final admin = await fetchAdminFilterOptions('jobs', 'job_type');
  if (admin.isNotEmpty) return admin;
  return const [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
    'Remote'
  ];
});

final jobsTypesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(jobsTypesBySubcategoryProvider('').future);
});

final jobsExperiencesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctJobsField('experience', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  final admin = await fetchAdminFilterOptions('jobs', 'experience');
  if (admin.isNotEmpty) return admin;
  return const [
    'No Experience',
    'Less than 1 year',
    '1-2 years',
    '2-5 years',
    '5-10 years',
    '10+ years',
  ];
});

final jobsExperiencesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(jobsExperiencesBySubcategoryProvider('').future);
});

final jobsIndustriesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctJobsField('industry', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  final admin = await fetchAdminFilterOptions('jobs', 'industry');
  if (admin.isNotEmpty) return admin;
  return const [
    'Technology',
    'Education',
    'Finance & Accounting',
    'Sales & Marketing',
    'Design & Creative',
    'Administration & Support',
    'Transportation',
  ];
});

final jobsIndustriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(jobsIndustriesBySubcategoryProvider('').future);
});

final jobsEducationsBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctJobsField('education', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  final admin = await fetchAdminFilterOptions('jobs', 'education');
  if (admin.isNotEmpty) return admin;
  return const [];
});

final jobsEducationsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(jobsEducationsBySubcategoryProvider('').future);
});

final jobsSellerTypesBySubcategoryProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, subcategory) async {
  final fromListings =
      await _distinctJobsField('seller_type', subcategory: subcategory);
  if (fromListings.isNotEmpty) return fromListings;
  final admin = await fetchAdminFilterOptions('jobs', 'seller_type');
  if (admin.isNotEmpty) return admin;
  return const ['All', 'Individual', 'Company'];
});

final jobsSellerTypesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(jobsSellerTypesBySubcategoryProvider('').future);
});
