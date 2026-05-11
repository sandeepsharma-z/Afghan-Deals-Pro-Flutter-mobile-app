import 'app_localizations.dart';

String localizedCategoryName(AppLocalizations l10n, String slug, {String? fallbackName}) {
  switch (slug.trim().toLowerCase()) {
    case 'cars':
      return l10n.t('category_cars');
    case 'properties':
      return l10n.t('category_properties');
    case 'mobiles':
      return l10n.t('category_mobiles');
    case 'spare-parts':
    case 'spare_parts':
      return l10n.t('category_spare_parts');
    case 'electronics':
      return l10n.t('category_electronics');
    case 'furniture':
      return l10n.t('category_furniture');
    case 'classifieds':
      return l10n.t('category_classifieds');
    case 'jobs':
      return l10n.t('category_jobs');
    default:
      return fallbackName?.trim().isNotEmpty == true
          ? fallbackName!.trim()
          : l10n.t('category');
  }
}

String localizedCarSubcategoryName(AppLocalizations l10n, String slug, {String? fallbackName}) {
  switch (slug.trim().toLowerCase()) {
    case 'used-cars':
    case 'used':
      return l10n.t('used_cars');
    case 'new-cars':
    case 'new':
      return l10n.t('new_cars');
    case 'export-cars':
    case 'export':
      return l10n.t('export_cars');
    case 'rental-cars':
    case 'rental':
      return l10n.t('rental_cars');
    default:
      return fallbackName?.trim().isNotEmpty == true
          ? fallbackName!.trim()
          : l10n.t('category');
  }
}

String localizedCarSortLabel(AppLocalizations l10n, String value) {
  switch (value.trim()) {
    case 'Popular':
      return l10n.t('popular');
    case 'Verified':
      return l10n.t('verified_sort');
    case 'Latest':
      return l10n.t('latest');
    case 'Most Popular':
      return l10n.t('most_popular');
    case 'Newest to Oldest':
      return l10n.t('newest_to_oldest');
    case 'Oldest to Newest':
      return l10n.t('oldest_to_newest');
    case 'Price Highest to Lowest':
      return l10n.t('price_highest_to_lowest');
    case 'Price Lowest to Highest':
    case 'Price: Low to High':
      return l10n.t('price_lowest_to_highest');
    case 'Price: High to Low':
      return l10n.t('price_highest_to_lowest');
    default:
      return value;
  }
}

String localizedCountryName(AppLocalizations l10n, String country) {
  switch (country.trim()) {
    case 'Afghanistan':
      return l10n.t('afghanistan');
    case 'Pakistan':
      return l10n.t('pakistan');
    case 'Iran':
      return l10n.t('iran');
    case 'India':
      return l10n.t('india');
    case 'Turkey':
      return l10n.t('turkey');
    case 'Germany':
      return l10n.t('germany');
    case 'Oman':
      return l10n.t('oman');
    case 'UAE':
      return l10n.t('uae_short');
    case 'Qatar':
      return l10n.t('qatar');
    case 'KSA':
      return l10n.t('ksa');
    case 'Syria':
      return l10n.t('syria');
    default:
      return country;
  }
}
