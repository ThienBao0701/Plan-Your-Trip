import 'package:flutter/material.dart';
import 'app_models.dart';
import '../../design/app_colors.dart';

class MockData {
  static const demoEmail = 'demo@planyourtrip.com';
  static const demoPassword = 'demo123456';

  static const categories = <Category>[
    Category(
        id: 'Hotels',
        name: 'Hotels',
        icon: Icons.hotel_rounded,
        color: AppColors.violet,
        description: 'Cozy stays and luxury resorts',
        sortOrder: 0),
    Category(
        id: 'Restaurants',
        name: 'Restaurants',
        icon: Icons.restaurant_rounded,
        color: AppColors.coral,
        description: 'Local and international cuisine',
        sortOrder: 1),
    Category(
        id: 'Cafe',
        name: 'Cafes',
        icon: Icons.coffee_rounded,
        color: AppColors.warning,
        description: 'Coffee, tea and chill vibes',
        sortOrder: 2),
    Category(
        id: 'Attractions',
        name: 'Attractions',
        icon: Icons.attractions_rounded,
        color: AppColors.ocean,
        description: 'Must-see sights and landmarks',
        sortOrder: 3),
    Category(
        id: 'Photo Spots',
        name: 'Photo Spots',
        icon: Icons.camera_alt_rounded,
        color: AppColors.aqua,
        description: 'Instagram-worthy locations',
        sortOrder: 4),
    Category(
        id: 'Nature',
        name: 'Nature',
        icon: Icons.nature_people_rounded,
        color: AppColors.mint,
        description: 'Parks, forests and natural beauty',
        sortOrder: 5),
    Category(
        id: 'Shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        color: AppColors.coral,
        description: 'Markets, malls and local crafts',
        sortOrder: 6),
    Category(
        id: 'Nightlife',
        name: 'Nightlife',
        icon: Icons.nightlife_rounded,
        color: AppColors.violet,
        description: 'Bars, clubs and evening entertainment',
        sortOrder: 7),
    Category(
        id: 'Food',
        name: 'Food',
        icon: Icons.fastfood_rounded,
        color: AppColors.warning,
        description: 'Street food and local delicacies',
        sortOrder: 8),
    Category(
        id: 'Culture',
        name: 'Culture',
        icon: Icons.museum_rounded,
        color: AppColors.mint,
        description: 'Museums, temples and heritage',
        sortOrder: 9),
  ];

  static final places = <Place>[
    const Place(
        id: 1,
        name: 'Mây Lang Thang Villa',
        category: 'Hotels',
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
        category: 'Hotel',
        amount: 2200000,
        date: DateTime(2026, 8, 12),
        notes: 'Paid via bank transfer'),
    Expense(
        id: 2,
        tripId: 1,
        title: 'Cafe and breakfast',
        category: 'Food',
        amount: 420000,
        date: DateTime(2026, 8, 12)),
    Expense(
        id: 3,
        tripId: 2,
        title: 'Resort booking',
        category: 'Hotel',
        amount: 2600000,
        date: DateTime(2026, 9, 5),
        notes: 'Non-refundable rate'),
  ];

  static const expenseCategories = [
    'Hotel',
    'Food',
    'Transport',
    'Activity',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  static IconData expenseCategoryIcon(String category) {
    switch (category) {
      case 'Hotel':
        return Icons.hotel_rounded;
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.directions_car_rounded;
      case 'Activity':
        return Icons.local_activity_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
