import '../models/analytics_item.dart';
import '../models/clothing_item.dart';
import '../models/outfit_recommendation.dart';

class MockData {
  // Starter closet items matching Screen 7 & Home outfits
  static final List<ClothingItem> initialClothes = [
    const ClothingItem(
      id: 1,
      name: 'Parachute jacket',
      category: 'Outwear',
      color: 'Beige',
      tags: 'rainy, coat, smart, casual',
      imageKey: 'parachute_jacket',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 2,
      name: 'Relax jacket',
      category: 'Outwear',
      color: 'Brown',
      tags: 'cold, casual, hooded, winter',
      imageKey: 'relax_jacket',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 3,
      name: 'Villa',
      category: 'Outwear',
      color: 'Blue / Yellow',
      tags: 'rainy, waterproof, sporty, bright',
      imageKey: 'villa_jacket',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 4,
      name: 'pink jean',
      category: 'Pants',
      color: 'Pink',
      tags: 'casual, bright, street, free',
      imageKey: 'pink_jean',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 5,
      name: 'blue jean',
      category: 'Pants',
      color: 'Light Blue',
      tags: 'casual, everyday, denim',
      imageKey: 'blue_jean',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 6,
      name: 'brown jean',
      category: 'Pants',
      color: 'Brown',
      tags: 'workplace, smart, earth-tone',
      imageKey: 'brown_jean',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 7,
      name: 'Gryphon Sweatshirt',
      category: 'Shirts',
      color: 'Crimson Red',
      tags: 'casual, cold, rainy, campus',
      imageKey: 'gryphon_sweatshirt',
      isFavorite: true,
    ),
    const ClothingItem(
      id: 8,
      name: 'Blue shirt',
      category: 'Shirts',
      color: 'Light Blue',
      tags: 'workplace, smart, evening',
      imageKey: 'blue_shirt',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 9,
      name: 'yellow uspa shirt',
      category: 'Shirts',
      color: 'Yellow',
      tags: 'energy, sunny, casual',
      imageKey: 'yellow_shirt',
      isFavorite: false,
    ),
    const ClothingItem(
      id: 10,
      name: 'Blue Nike Shoes',
      category: 'Shoes',
      color: 'Blue',
      tags: 'sporty, everyday, walking',
      imageKey: 'blue_nike_shoes',
      isFavorite: true,
    ),
    const ClothingItem(
      id: 11,
      name: 'air jordan shoes',
      category: 'Shoes',
      color: 'Red / White',
      tags: 'street, casual, weekend',
      imageKey: 'air_jordan_shoes',
      isFavorite: false,
    ),
  ];

  static const OutfitRecommendation defaultRecommendation =
      OutfitRecommendation(
    todaysOutfit: 'Gryphon Sweatshirt + black jeans',
    weather: 'Rainy 6°C',
    stylesRemaining: 14,
    monthlyStylesTried: 28,
    tip: DailyTip(
      category: 'Energy',
      date: 'Sat, 11 Jan',
      message: 'wearing yellow this week will make you feel more energised!',
    ),
    schedule: [
      ScheduleEvent(
        time: '10:00 AM',
        outfit: 'Gryphon Sweatshirt + black jeans',
        accent: 'coral',
        topKey: 'gryphon_sweatshirt',
        bottomKey: 'black_jeans',
      ),
      ScheduleEvent(
        time: '7:00 PM',
        outfit: 'Blue shirt + fabric trousers',
        accent: 'blue',
        topKey: 'blue_shirt',
        bottomKey: 'fabric_trousers',
      ),
    ],
  );

  // Matches the 10-item WardFIT360 Analytics legend and bar heights
  static const WardrobeAnalytics defaultAnalytics = WardrobeAnalytics(
    months: ['JAN', 'FEB', 'MAR'],
    maxY: 35,
    monthlyStylesTried: 28,
    series: [
      AnalyticsSeriesItem(
        label: 'Blue Jean',
        colorHex: '#00BCD4',
        jan: 31,
        feb: 25,
        mar: 8,
      ),
      AnalyticsSeriesItem(
        label: 'Blue Sweat',
        colorHex: '#29B6F6',
        jan: 30,
        feb: 24,
        mar: 9,
      ),
      AnalyticsSeriesItem(
        label: 'Blue Nike Shoes',
        colorHex: '#5C85E6',
        jan: 31,
        feb: 25,
        mar: 7,
      ),
      AnalyticsSeriesItem(
        label: 'navy blue t shirt',
        colorHex: '#7986CB',
        jan: 30,
        feb: 24,
        mar: 8,
      ),
      AnalyticsSeriesItem(
        label: 'Purple sweater',
        colorHex: '#9C59D1',
        jan: 31,
        feb: 25,
        mar: 9,
      ),
      AnalyticsSeriesItem(
        label: 'red dress',
        colorHex: '#C2085A',
        jan: 31,
        feb: 25,
        mar: 8,
      ),
      AnalyticsSeriesItem(
        label: 'red lacoste shirt',
        colorHex: '#E05246',
        jan: 30,
        feb: 24,
        mar: 9,
      ),
      AnalyticsSeriesItem(
        label: 'orange addidas shirt',
        colorHex: '#F29141',
        jan: 31,
        feb: 25,
        mar: 7,
      ),
      AnalyticsSeriesItem(
        label: 'air jordan shoes',
        colorHex: '#F7B859',
        jan: 30,
        feb: 24,
        mar: 8,
      ),
      AnalyticsSeriesItem(
        label: 'yellow uspa shirt',
        colorHex: '#E4E868',
        jan: 31,
        feb: 25,
        mar: 9,
      ),
    ],
  );

  static OutfitRecommendation buildOfflineRecommendation({
    required String weather,
    required String plan,
    required String stylePref,
    required int clothCount,
  }) {
    final planLower = plan.toLowerCase();
    String todays = 'Gryphon Sweatshirt + black jeans';
    String morning = 'Gryphon Sweatshirt + black jeans';
    String evening = 'Blue shirt + fabric trousers';

    if (planLower.contains('work')) {
      todays = 'Blue shirt + fabric trousers';
      morning = 'Blue shirt + fabric trousers';
      evening = 'Parachute jacket + brown jean';
    } else if (planLower.contains('new') || stylePref == 'change') {
      todays = 'Villa + pink jean';
      morning = 'yellow uspa shirt + blue jean';
      evening = 'Villa + pink jean';
    } else if (planLower.contains('free')) {
      todays = 'Relax jacket + blue jean';
      morning = 'Relax jacket + blue jean';
      evening = 'Gryphon Sweatshirt + black jeans';
    } else if (weather.toLowerCase().contains('sunny')) {
      todays = 'yellow uspa shirt + blue jean';
      morning = 'yellow uspa shirt + blue jean';
    }

    return OutfitRecommendation(
      todaysOutfit: todays,
      weather: weather,
      stylesRemaining: clothCount > 14 ? clothCount : 14,
      monthlyStylesTried: 28,
      tip: defaultRecommendation.tip,
      schedule: [
        ScheduleEvent(
          time: '10:00 AM',
          outfit: morning,
          accent: 'coral',
          topKey: morning.contains('Gryphon')
              ? 'gryphon_sweatshirt'
              : 'blue_shirt',
          bottomKey:
              morning.contains('black') ? 'black_jeans' : 'fabric_trousers',
        ),
        ScheduleEvent(
          time: '7:00 PM',
          outfit: evening,
          accent: 'blue',
          topKey: 'blue_shirt',
          bottomKey: 'fabric_trousers',
        ),
      ],
    );
  }
}
