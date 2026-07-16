import 'package:flutter/material.dart';
import 'app_models.dart';
import '../../design/app_colors.dart';

class MockData {
  static const demoEmail = 'demo@planyourtrip.com';
  static const demoPassword = 'demo123456';

  static const categories = <Category>[
    Category(
        id: 'accommodation',
        slug: 'accommodation',
        type: 'ACCOMMODATION',
        name: 'Hotels',
        icon: Icons.hotel_rounded,
        color: AppColors.violet,
        description: 'Cozy stays and luxury resorts',
        sortOrder: 0),
    Category(
        id: 'food',
        slug: 'food',
        type: 'FOOD',
        name: 'Food',
        icon: Icons.restaurant_rounded,
        color: AppColors.coral,
        description: 'Local and international cuisine',
        sortOrder: 1),
    Category(
        id: 'cafe',
        slug: 'cafe',
        type: 'CAFE',
        name: 'Cafes',
        icon: Icons.coffee_rounded,
        color: AppColors.warning,
        description: 'Coffee, tea and chill vibes',
        sortOrder: 2),
    Category(
        id: 'attraction',
        slug: 'attraction',
        type: 'ATTRACTION',
        name: 'Attractions',
        icon: Icons.attractions_rounded,
        color: AppColors.ocean,
        description: 'Must-see sights and landmarks',
        sortOrder: 3),
    Category(
        id: 'photo-spot',
        slug: 'photo-spot',
        type: 'PHOTO_SPOT',
        name: 'Photo Spots',
        icon: Icons.camera_alt_rounded,
        color: AppColors.aqua,
        description: 'Instagram-worthy locations',
        sortOrder: 4),
    Category(
        id: 'shopping',
        slug: 'shopping',
        type: 'SHOPPING',
        name: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        color: AppColors.coral,
        description: 'Markets, malls and local crafts',
        sortOrder: 5),
    Category(
        id: 'entertainment',
        slug: 'entertainment',
        type: 'ENTERTAINMENT',
        name: 'Entertainment',
        icon: Icons.nightlife_rounded,
        color: AppColors.violet,
        description: 'Bars, clubs and evening entertainment',
        sortOrder: 6),
    Category(
        id: 'transportation',
        slug: 'transportation',
        type: 'TRANSPORTATION',
        name: 'Transportation',
        icon: Icons.directions_bus_rounded,
        color: AppColors.turquoise600,
        description: 'Local transport providers and stations',
        sortOrder: 7),
    Category(
        id: 'tour',
        slug: 'tour',
        type: 'TOUR',
        name: 'Tours',
        icon: Icons.tour_rounded,
        color: AppColors.ocean,
        description: 'Guided local trip ideas',
        sortOrder: 8),
    Category(
        id: 'wellness',
        slug: 'wellness',
        type: 'WELLNESS',
        name: 'Wellness',
        icon: Icons.spa_rounded,
        color: AppColors.mint,
        description: 'Spa, wellness and slower travel',
        sortOrder: 9),
  ];

  static final places = <Place>[
    const Place(
        id: 1,
        name: 'Mây Lang Thang Villa',
        category: 'Hotels',
        categorySlug: 'accommodation',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        imageUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900&q=80',
        rating: 4.8,
        reviewCount: 312,
        priceLevel: '\$\$\$',
        estimatedDurationMinutes: 1440,
        openingHours: 'Check-in 14:00 / Check-out 12:00',
        description:
            'A quiet hillside stay with misty valley views and warm glass interiors. Perfect for couples and photographers.',
        tags: ['romantic', 'hill-view', 'boutique'],
        isFeatured: true),
    const Place(
        id: 2,
        name: 'Kombi Land',
        category: 'Photo Spots',
        categorySlug: 'photo-spot',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900&q=80',
        rating: 4.6,
        reviewCount: 524,
        priceLevel: '\$',
        estimatedDurationMinutes: 120,
        openingHours: '07:00 - 18:00',
        description:
            'Colorful desert-inspired photo garden with vintage cars and cactus corners. Great for social media content.',
        tags: ['instagram', 'vintage', 'garden'],
        isFeatured: true,
        isNearby: true),
    const Place(
        id: 3,
        name: 'Túi Mơ To Cafe',
        category: 'Cafe',
        categorySlug: 'cafe',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        imageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=900&q=80',
        rating: 4.7,
        reviewCount: 891,
        priceLevel: '\$\$',
        estimatedDurationMinutes: 90,
        openingHours: '07:00 - 22:00',
        description:
            'A cozy cafe for sunset, mountain air, and slow travel mornings. Famous for their avocado smoothies.',
        tags: ['coffee', 'sunset-view', 'cozy'],
        isFeatured: true,
        isNearby: true),
    const Place(
        id: 4,
        name: 'Bánh Khọt Gốc Vú Sữa',
        category: 'Food',
        categorySlug: 'food',
        locationName: 'Vung Tau',
        city: 'Vung Tau',
        province: 'Ba Ria - Vung Tau',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&q=80',
        rating: 4.5,
        reviewCount: 1247,
        priceLevel: '\$',
        estimatedDurationMinutes: 60,
        openingHours: '06:00 - 14:00',
        description:
            'Crispy local seafood pancakes for a classic Vung Tau food stop. One of the best street foods in the city.',
        tags: ['street-food', 'seafood', 'local'],
        isFeatured: true),
    const Place(
        id: 5,
        name: 'Hồ Mây Park',
        category: 'Attractions',
        categorySlug: 'attraction',
        locationName: 'Vung Tau',
        city: 'Vung Tau',
        province: 'Ba Ria - Vung Tau',
        imageUrl:
            'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=900&q=80',
        rating: 4.4,
        reviewCount: 756,
        priceLevel: '\$\$',
        estimatedDurationMinutes: 180,
        openingHours: '08:00 - 17:00',
        description:
            'Cable car, hill views, gardens, and family activities above the sea. Perfect for families and thrill seekers.',
        tags: ['cable-car', 'family', 'viewpoint'],
        isFeatured: true,
        isNearby: true),
    const Place(
        id: 6,
        name: 'Marina Bay Resort',
        category: 'Hotels',
        categorySlug: 'accommodation',
        locationName: 'Vung Tau',
        city: 'Vung Tau',
        province: 'Ba Ria - Vung Tau',
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900&q=80',
        rating: 4.7,
        reviewCount: 203,
        priceLevel: '\$\$\$',
        estimatedDurationMinutes: 1440,
        openingHours: 'Check-in 14:00 / Check-out 12:00',
        description:
            'Premium seaside resort with pool deck and elegant coastal rooms. Stunning ocean sunsets included.',
        tags: ['beachfront', 'pool', 'luxury'],
        isFeatured: true),
    const Place(
        id: 7,
        name: 'Night Market Da Lat',
        category: 'Shopping',
        categorySlug: 'shopping',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        imageUrl:
            'https://images.unsplash.com/photo-1464983953574-0892a716854b?w=900&q=80',
        rating: 4.3,
        reviewCount: 2100,
        priceLevel: '\$',
        estimatedDurationMinutes: 120,
        openingHours: '17:00 - 23:00',
        description:
            'Bustling night market with local produce, handicrafts, street food stalls and flower vendors.',
        tags: ['market', 'souvenir', 'nightlife'],
        isNearby: true),
    const Place(
        id: 8,
        name: 'Linh Phuoc Pagoda',
        category: 'Culture',
        categorySlug: 'attraction',
        locationName: 'Da Lat',
        city: 'Da Lat',
        province: 'Lam Dong',
        imageUrl:
            'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=900&q=80',
        rating: 4.5,
        reviewCount: 638,
        priceLevel: '\$',
        estimatedDurationMinutes: 60,
        openingHours: '07:00 - 17:00',
        description:
            'Stunning ceramic mosaic temple with intricate dragon sculptures and peaceful gardens.',
        tags: ['temple', 'culture', 'architecture'],
        isNearby: true),
    const Place(
        id: 9,
        name: 'Bếp Quảng',
        category: 'Food',
        categorySlug: 'food',
        subcategorySlug: 'local-food',
        locationName: 'Da Nang',
        city: 'Da Nang',
        province: 'Da Nang',
        address: 'Hai Chau, Da Nang',
        imageUrl:
            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=900&q=80',
        rating: 4.8,
        reviewCount: 1600,
        priceLevel: '\$',
        estimatedDurationMinutes: 75,
        openingHours: '09:00 - 21:00',
        description:
            'A local food stop for Mi Quang and central Vietnam flavors.',
        tags: ['mi-quang', 'local-food', 'danang'],
        isFeatured: true,
        verified: true),
    const Place(
        id: 10,
        name: 'Bà Nà Hills',
        category: 'Attractions',
        categorySlug: 'attraction',
        subcategorySlug: 'theme-park',
        locationName: 'Hoa Vang',
        city: 'Da Nang',
        province: 'Da Nang',
        address: 'Hoa Vang, Da Nang',
        imageUrl:
            'https://images.unsplash.com/photo-1548013146-72479768bada?w=900&q=80',
        rating: 4.8,
        reviewCount: 12400,
        priceLevel: '\$\$\$',
        estimatedDurationMinutes: 360,
        openingHours: '08:00 - 17:00',
        description:
            'Mountain attraction with cable car views and landmark photo spots. Ticketing and schedules are not connected in this app.',
        tags: ['family', 'mountain', 'landmark'],
        isFeatured: true,
        verified: true),
    const Place(
        id: 11,
        name: 'Helio Center',
        category: 'Entertainment',
        categorySlug: 'entertainment',
        subcategorySlug: 'night-market',
        locationName: 'Hai Chau',
        city: 'Da Nang',
        province: 'Da Nang',
        imageUrl:
            'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=900&q=80',
        rating: 4.5,
        reviewCount: 2100,
        priceLevel: '\$\$',
        estimatedDurationMinutes: 180,
        openingHours: '17:00 - 23:00',
        description:
            'Evening entertainment area with local food stalls and public activities.',
        tags: ['evening', 'family', 'nightlife'],
        isFeatured: true),
    const Place(
        id: 12,
        name: 'Da Nang Airport Shuttle Counter',
        category: 'Transportation',
        categorySlug: 'transportation',
        subcategorySlug: 'shuttle',
        locationName: 'Da Nang Airport',
        city: 'Da Nang',
        province: 'Da Nang',
        imageUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=900&q=80',
        rating: 0,
        reviewCount: 0,
        priceLevel: '',
        estimatedDurationMinutes: 0,
        openingHours: 'Service availability varies',
        description:
            'Local transport provider listing. Live fares, schedules, route geometry, and ticket booking are not connected yet.',
        tags: ['airport', 'shuttle', 'transport'],
        isFeatured: false),
  ];

  static final trips = <Trip>[
    Trip(
        id: 1,
        title: 'Da Lat 3 days 2 nights',
        destination: 'Da Lat',
        imageUrl: places[0].imageUrl,
        startDate: DateTime(2026, 8, 12),
        endDate: DateTime(2026, 8, 14),
        travelers: 2,
        budget: 6500000,
        notes: 'Book villa early. Bring a jacket — Da Lat nights are cold.'),
    Trip(
        id: 2,
        title: 'Vung Tau 2 days 1 night',
        destination: 'Vung Tau',
        imageUrl: places[5].imageUrl,
        startDate: DateTime(2026, 9, 5),
        endDate: DateTime(2026, 9, 6),
        travelers: 4,
        budget: 5200000,
        notes: 'Great beach trip with friends. Check tide schedules.'),
  ];

  static final timeline = <TimelineItem>[
    TimelineItem(
        id: 1,
        tripId: 1,
        dayNumber: 1,
        startTime: '07:30',
        endTime: '09:00',
        title: 'Breakfast and coffee',
        notes: 'Arrive early, light breakfast before check-in.',
        place: places[2],
        placeId: 3,
        category: 'Food',
        estimatedCost: 120000,
        sortOrder: 0),
    TimelineItem(
        id: 2,
        tripId: 1,
        dayNumber: 1,
        startTime: '10:00',
        endTime: '12:00',
        title: 'Check-in villa',
        notes: 'Leave luggage and take balcony photos.',
        place: places[0],
        placeId: 1,
        category: 'Hotel',
        estimatedCost: 2200000,
        sortOrder: 1),
    TimelineItem(
        id: 3,
        tripId: 1,
        dayNumber: 2,
        startTime: '08:00',
        endTime: '11:00',
        title: 'Photo walk at Kombi Land',
        notes: 'Bring camera and jacket.',
        place: places[1],
        placeId: 2,
        category: 'Activity',
        estimatedCost: 50000,
        sortOrder: 0),
    const TimelineItem(
        id: 4,
        tripId: 1,
        dayNumber: 3,
        startTime: '09:00',
        endTime: '10:30',
        title: 'Souvenir shopping',
        notes: 'Buy strawberry jam and avocado snacks.',
        category: 'Shopping',
        estimatedCost: 300000,
        sortOrder: 0),
    TimelineItem(
        id: 5,
        tripId: 2,
        dayNumber: 1,
        startTime: '11:00',
        endTime: '12:30',
        title: 'Local lunch',
        notes: 'Try bánh khọt and seafood.',
        place: places[3],
        placeId: 4,
        category: 'Food',
        estimatedCost: 180000,
        sortOrder: 0),
    TimelineItem(
        id: 6,
        tripId: 2,
        dayNumber: 2,
        startTime: '08:30',
        endTime: '11:30',
        title: 'Cable car and park',
        notes: 'Book tickets before arriving.',
        place: places[4],
        placeId: 5,
        category: 'Activity',
        estimatedCost: 150000,
        sortOrder: 0),
  ];

  static final expenses = <Expense>[
    Expense(
        id: 1,
        tripId: 1,
        title: 'Villa deposit',
        category: 'ACCOMMODATION',
        amount: 2200000,
        currency: 'VND',
        date: DateTime(2026, 8, 12),
        tripDayId: 1,
        notes: 'Paid via bank transfer'),
    Expense(
        id: 2,
        tripId: 1,
        title: 'Cafe and breakfast',
        category: 'FOOD',
        amount: 420000,
        currency: 'VND',
        date: DateTime(2026, 8, 12)),
    Expense(
        id: 3,
        tripId: 2,
        title: 'Resort booking',
        category: 'ACCOMMODATION',
        amount: 2600000,
        currency: 'VND',
        date: DateTime(2026, 9, 5),
        tripDayId: 1,
        notes: 'Non-refundable rate'),
  ];

  static const expenseCategories = [
    'ACCOMMODATION',
    'FOOD',
    'TRANSPORT',
    'ATTRACTION',
    'SHOPPING',
    'HEALTH',
    'VISA',
    'INSURANCE',
    'OTHER',
  ];

  static IconData expenseCategoryIcon(String category) {
    switch (category) {
      case 'ACCOMMODATION':
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'FOOD':
      case 'Food':
        return Icons.restaurant_rounded;
      case 'TRANSPORT':
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'ATTRACTION':
      case 'Activity':
        return Icons.local_activity_rounded;
      case 'SHOPPING':
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'HEALTH':
        return Icons.local_hospital_rounded;
      case 'VISA':
        return Icons.badge_rounded;
      case 'INSURANCE':
        return Icons.verified_user_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
