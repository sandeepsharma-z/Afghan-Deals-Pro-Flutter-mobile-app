class RentalCarModel {
  final String id;
  final String name;
  final String subtitle;
  final String currency;
  final List<String> images;
  final String location;

  // category_data fields
  final String carModel;
  final String year;
  final int seats;
  final int doors;
  final int luggage;
  final double dailyRent;
  final double monthlyRent;
  final String kmDay;
  final String kmMonth;
  final String extraKmCharge;
  final bool hasDayRental;
  final bool hasInsurance;
  final String interiorColor;
  final String trim;
  final String horsepower;

  const RentalCarModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.currency,
    required this.images,
    required this.location,
    required this.carModel,
    required this.year,
    required this.seats,
    required this.doors,
    required this.luggage,
    required this.dailyRent,
    required this.monthlyRent,
    required this.kmDay,
    required this.kmMonth,
    required this.extraKmCharge,
    required this.hasDayRental,
    required this.hasInsurance,
    required this.interiorColor,
    required this.trim,
    required this.horsepower,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';
  String get photoCount => images.length.toString();

  String get priceDaily {
    final val = dailyRent.toInt();
    return '$currency ${_fmt(val)}';
  }

  String get priceMonthly {
    final val = monthlyRent.toInt();
    return '$currency ${_fmt(val)}';
  }

  String _fmt(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  factory RentalCarModel.fromMap(Map<String, dynamic> map) {
    final cd = (map['category_data'] as Map<String, dynamic>?) ?? {};
    final imgs = (map['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return RentalCarModel(
      id: map['id']?.toString() ?? '',
      name: map['title']?.toString() ?? '',
      subtitle: map['description']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'AED',
      images: imgs,
      location: map['city']?.toString() ?? '',
      carModel: cd['model']?.toString() ?? '',
      year: cd['year']?.toString() ?? '',
      seats: (cd['seats'] as num?)?.toInt() ?? 0,
      doors: (cd['doors'] as num?)?.toInt() ?? 0,
      luggage: (cd['luggage'] as num?)?.toInt() ?? 0,
      dailyRent: (cd['daily_rent'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0,
      monthlyRent: (cd['monthly_rent'] as num?)?.toDouble() ?? 0,
      kmDay: cd['km_day']?.toString() ?? '',
      kmMonth: cd['km_month']?.toString() ?? '',
      extraKmCharge:
          cd['extra_km_charge']?.toString() ?? 'AED 5 for each additional km',
      hasDayRental: cd['has_day_rental'] as bool? ?? false,
      hasInsurance: cd['has_insurance'] as bool? ?? false,
      interiorColor: cd['interior_color']?.toString() ?? '',
      trim: cd['trim']?.toString() ?? '',
      horsepower: cd['horsepower']?.toString() ?? '',
    );
  }
}
