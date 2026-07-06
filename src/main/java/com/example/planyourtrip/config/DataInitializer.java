package com.example.planyourtrip.config;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;

import java.math.RoundingMode;
import java.time.format.DateTimeFormatter;

import java.math.BigDecimal;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.List;
import java.util.function.Consumer;

import static com.example.planyourtrip.model.UnitType.*;

@Component
@Profile("!prod")
public class DataInitializer implements ApplicationRunner {

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final AdministrativeUnitRepository locations;
    private final CategoryRepository categories;
    private final AmenityRepository amenities;
    private final PlaceRepository placeRepo;
    private final PlaceTagRepository placeTagRepo;
    private final PlaceAmenityRepository placeAmenityRepo;
    private final PlaceOpeningHourRepository placeOpeningHourRepo;
    private final MediaAssetRepository mediaAssetRepo;
    private final PlaceMetadataRepository placeMetadataRepo;
    private final HotelDetailRepository hotelDetailRepo;
    private final HotelRoomRepository hotelRoomRepo;
    private final RoomAmenityRepository roomAmenityRepo;
    private final HotelFacilityRepository hotelFacilityRepo;
    private final HotelServiceRepository hotelServiceRepo;
    private final RoomInventoryRepository roomInventoryRepo;
    private final RatePlanRepository ratePlanRepo;
    private final PromotionRepository promotionRepo;
    private final BookingRepository bookingRepo;
    private final PaymentRepository paymentRepo;
    private final NotificationRepository notificationRepo;

    public DataInitializer(UserRepository users, PasswordEncoder encoder,
                           AdministrativeUnitRepository locations,
                           CategoryRepository categories,
                           AmenityRepository amenities,
                           PlaceRepository placeRepo,
                           PlaceTagRepository placeTagRepo,
                           PlaceAmenityRepository placeAmenityRepo,
                           PlaceOpeningHourRepository placeOpeningHourRepo,
                           MediaAssetRepository mediaAssetRepo,
                           PlaceMetadataRepository placeMetadataRepo,
                           HotelDetailRepository hotelDetailRepo,
                           HotelRoomRepository hotelRoomRepo,
                           RoomAmenityRepository roomAmenityRepo,
                           HotelFacilityRepository hotelFacilityRepo,
                           HotelServiceRepository hotelServiceRepo,
                           RoomInventoryRepository roomInventoryRepo,
                           RatePlanRepository ratePlanRepo,
                           PromotionRepository promotionRepo,
                           BookingRepository bookingRepo,
                           PaymentRepository paymentRepo,
                           NotificationRepository notificationRepo) {
        this.users      = users;
        this.encoder    = encoder;
        this.locations  = locations;
        this.categories = categories;
        this.amenities  = amenities;
        this.placeRepo            = placeRepo;
        this.placeTagRepo         = placeTagRepo;
        this.placeAmenityRepo     = placeAmenityRepo;
        this.placeOpeningHourRepo = placeOpeningHourRepo;
        this.mediaAssetRepo       = mediaAssetRepo;
        this.placeMetadataRepo    = placeMetadataRepo;
        this.hotelDetailRepo      = hotelDetailRepo;
        this.hotelRoomRepo        = hotelRoomRepo;
        this.roomAmenityRepo      = roomAmenityRepo;
        this.hotelFacilityRepo    = hotelFacilityRepo;
        this.hotelServiceRepo     = hotelServiceRepo;
        this.roomInventoryRepo    = roomInventoryRepo;
        this.ratePlanRepo         = ratePlanRepo;
        this.promotionRepo        = promotionRepo;
        this.bookingRepo          = bookingRepo;
        this.paymentRepo          = paymentRepo;
        this.notificationRepo     = notificationRepo;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedUsers();
        seedLocations();
        seedCategories();
        seedAmenities();
        seedPlaces();
        seedMedia();
        seedPlaceMetadata();
        seedHotelDetails();
        seedHotelRooms();
        seedHotelExperience();
        seedRoomInventory();
        seedRatePlans();
        seedPromotions();
        seedBookings();
        seedPayments();
        seedNotifications();
    }

    // ─────────────────────────────────────────────────────────────
    // USERS
    // ─────────────────────────────────────────────────────────────

    private void seedUsers() {
        user("Demo User",    "demo@planyourtrip.com",    "demo123456",    "USER");
        user("Partner User", "partner@planyourtrip.com", "partner123456", "PARTNER");
        user("Admin User",   "admin@planyourtrip.com",   "admin123456",   "ADMIN");
    }

    private void user(String fullName, String email, String password, String role) {
        if (users.existsByEmail(email)) return;
        User u = new User();
        u.setFullName(fullName); u.setEmail(email);
        u.setPasswordHash(encoder.encode(password)); u.setRole(role);
        users.save(u);
    }

    // ─────────────────────────────────────────────────────────────
    // LOCATIONS — 34 provincial-level units (post-2025 merger)
    //             + 10 tourism child areas
    // ─────────────────────────────────────────────────────────────

    private void seedLocations() {
        AdministrativeUnit vn = loc(null, "VN", "Vietnam", COUNTRY, 0, null, 14.06, 108.28, 0);

        // ── 5 Centrally-governed cities ──────────────────────────
        AdministrativeUnit hn  = loc(vn, "HN",  "Hà Nội",          CITY, 2, "Ha Noi",  21.0285, 105.8542,  1);
        AdministrativeUnit hcm = loc(vn, "HCM", "TP Hồ Chí Minh",  CITY, 2, "Sai Gon", 10.8231, 106.6297,  2);
        AdministrativeUnit hp  = loc(vn, "HP",  "Hải Phòng",        CITY, 2, null,      20.8449, 106.6881,  3);
        AdministrativeUnit dng = loc(vn, "DNG", "Đà Nẵng",          CITY, 2, null,      16.0544, 108.2022,  4);
        AdministrativeUnit ct  = loc(vn, "CT",  "Cần Thơ",          CITY, 2, null,      10.0452, 105.7469,  5);

        // ── 29 Provinces (North → South) ─────────────────────────
        loc(vn, "HGG", "Hà Giang",         PROVINCE, 2, null, 22.8026, 104.9784,  6);
        loc(vn, "CB",  "Cao Bằng",          PROVINCE, 2, null, 22.6653, 106.2638,  7);
        loc(vn, "LS",  "Lạng Sơn",          PROVINCE, 2, null, 21.8537, 106.7615,  8);
        AdministrativeUnit qni = loc(vn, "QNI", "Quảng Ninh",  PROVINCE, 2, null, 21.0064, 107.2925,  9);
        AdministrativeUnit lci = loc(vn, "LCI", "Lào Cai",     PROVINCE, 2, null, 22.4834, 103.9756, 10);
        loc(vn, "DBI", "Điện Biên",         PROVINCE, 2, null, 21.8066, 103.1129, 11);
        loc(vn, "SLA", "Sơn La",            PROVINCE, 2, null, 21.3274, 103.9146, 12);
        loc(vn, "TNN", "Thái Nguyên",       PROVINCE, 2, null, 21.5944, 105.8412, 13);
        loc(vn, "BNN", "Bắc Ninh",          PROVINCE, 2, null, 21.1861, 106.0763, 14);
        loc(vn, "HDG", "Hải Dương",         PROVINCE, 2, null, 20.9373, 106.3146, 15);
        loc(vn, "NBH", "Ninh Bình",         PROVINCE, 2, null, 20.2506, 105.9745, 16);
        loc(vn, "THO", "Thanh Hóa",         PROVINCE, 2, null, 19.8071, 105.7852, 17);
        loc(vn, "NAN", "Nghệ An",           PROVINCE, 2, null, 19.2342, 104.9200, 18);
        loc(vn, "QBH", "Quảng Bình",        PROVINCE, 2, null, 17.4830, 106.3994, 19);
        AdministrativeUnit tth = loc(vn, "TTH", "Thừa Thiên Huế", PROVINCE, 2, null, 16.4637, 107.5909, 20);
        AdministrativeUnit qnm = loc(vn, "QNM", "Quảng Nam",   PROVINCE, 2, null, 15.5394, 108.0191, 21);
        loc(vn, "BDH", "Bình Định",         PROVINCE, 2, null, 13.7765, 109.2237, 22);
        AdministrativeUnit kho = loc(vn, "KHO", "Khánh Hòa",   PROVINCE, 2, "Khanh Hoa", 12.2388, 109.1967, 23);
        loc(vn, "DLK", "Đắk Lắk",          PROVINCE, 2, null, 12.7100, 108.2378, 24);
        loc(vn, "GLA", "Gia Lai",           PROVINCE, 2, null, 13.9831, 108.0000, 25);
        AdministrativeUnit ldg = loc(vn, "LDG", "Lâm Đồng",    PROVINCE, 2, null, 11.5753, 108.1429, 26);
        AdministrativeUnit btn = loc(vn, "BTN", "Bình Thuận",   PROVINCE, 2, null, 11.0904, 108.0721, 27);
        loc(vn, "DNI", "Đồng Nai",          PROVINCE, 2, null, 11.0686, 107.1676, 28);
        AdministrativeUnit bvt = loc(vn, "BVT", "Bà Rịa - Vũng Tàu", PROVINCE, 2, "Ba Ria - Vung Tau", 10.5417, 107.2429, 29);
        loc(vn, "LAN", "Long An",           PROVINCE, 2, null, 10.5381, 106.4126, 30);
        loc(vn, "DTP", "Đồng Tháp",         PROVINCE, 2, null, 10.4933, 105.6882, 31);
        AdministrativeUnit kgg = loc(vn, "KGG", "Kiên Giang",   PROVINCE, 2, null, 10.0125, 105.0809, 32);
        loc(vn, "STG", "Sóc Trăng",         PROVINCE, 2, null,  9.6025, 105.9740, 33);
        loc(vn, "CMU", "Cà Mau",            PROVINCE, 2, null,  9.1769, 105.1524, 34);

        // ── 10 Tourism child areas ───────────────────────────────
        loc(bvt, "VT",  "Vũng Tàu",          AREA, 3, "Ba Ria - Vung Tau", 10.4113, 107.1362,  1);
        loc(ldg, "DL",  "Đà Lạt",            AREA, 3, "Da Lat",            11.9465, 108.4419,  2);
        loc(kho, "NT",  "Nha Trang",          AREA, 3, "Khanh Hoa",         12.2388, 109.1967,  3);
        loc(dng, "DNC", "Đà Nẵng Trung Tâm", AREA, 3, null,                16.0544, 108.2022,  4);
        loc(qni, "HL",  "Hạ Long",           AREA, 3, null,                20.9517, 107.0785,  5);
        loc(kgg, "PQ",  "Phú Quốc",          AREA, 3, null,                10.2899, 103.9840,  6);
        loc(lci, "SP",  "Sa Pa",             AREA, 3, null,                22.3364, 103.8438,  7);
        loc(qnm, "HOI", "Hội An",            AREA, 3, null,                15.8800, 108.3380,  8);
        loc(tth, "HUE", "Huế",               AREA, 3, null,                16.4637, 107.5909,  9);
        loc(btn, "MN",  "Mũi Né",            AREA, 3, null,                10.9329, 108.2838, 10);
    }

    private AdministrativeUnit loc(AdministrativeUnit parent, String code, String name,
                                    UnitType type, int level, String oldName,
                                    double lat, double lng, int sort) {
        return (code != null ? locations.findByCode(code) : locations.findBySlug(SlugUtils.toSlug(name)))
            .orElseGet(() -> {
                AdministrativeUnit u = new AdministrativeUnit();
                u.setParent(parent);
                u.setCode(code);
                u.setName(name);
                u.setSlug(SlugUtils.toSlug(name));
                u.setNameNormalized(SlugUtils.normalize(name));
                u.setType(type);
                u.setLevel(level);
                u.setOldName(oldName);
                u.setFullPath(parent != null ? parent.getFullPath() + " > " + name : name);
                u.setLatitude(lat);
                u.setLongitude(lng);
                u.setSortOrder(sort);
                u.setActive(true);
                return locations.save(u);
            });
    }

    // ─────────────────────────────────────────────────────────────
    // CATEGORIES — 10 root + 67 subcategories
    // ─────────────────────────────────────────────────────────────

    private void seedCategories() {
        Category acc   = cat(null, "Accommodation", "ACCOMMODATION", "hotel",         "#2196F3", 1);
        cat(acc,  "Hotel",            "ACCOMMODATION", "hotel",              "#2196F3", 1);
        cat(acc,  "Resort",           "ACCOMMODATION", "beach_access",       "#2196F3", 2);
        cat(acc,  "Homestay",         "ACCOMMODATION", "home",               "#2196F3", 3);
        cat(acc,  "Villa",            "ACCOMMODATION", "villa",              "#2196F3", 4);
        cat(acc,  "Hostel",           "ACCOMMODATION", "bunk_bed",           "#2196F3", 5);
        cat(acc,  "Apartment",        "ACCOMMODATION", "apartment",          "#2196F3", 6);
        cat(acc,  "Camping",          "ACCOMMODATION", "outdoor_grill",      "#2196F3", 7);
        cat(acc,  "Glamping",         "ACCOMMODATION", "cabin",              "#2196F3", 8);

        Category food  = cat(null, "Food",           "FOOD",          "restaurant",          "#FF5722", 2);
        cat(food, "Restaurant",       "FOOD",          "restaurant",          "#FF5722", 1);
        cat(food, "Seafood",          "FOOD",          "set_meal",            "#FF5722", 2);
        cat(food, "BBQ",              "FOOD",          "outdoor_grill",       "#FF5722", 3);
        cat(food, "Buffet",           "FOOD",          "dinner_dining",       "#FF5722", 4);
        cat(food, "Vegetarian",       "FOOD",          "eco",                 "#FF5722", 5);
        cat(food, "Street Food",      "FOOD",          "fastfood",            "#FF5722", 6);
        cat(food, "Local Specialty",  "FOOD",          "emoji_food_beverage", "#FF5722", 7);
        cat(food, "Fine Dining",      "FOOD",          "wine_bar",            "#FF5722", 8);
        cat(food, "Breakfast",        "FOOD",          "free_breakfast",      "#FF5722", 9);

        Category cafe  = cat(null, "Cafe",            "CAFE",          "local_cafe",          "#795548", 3);
        cat(cafe, "Coffee",           "CAFE",          "local_cafe",          "#795548", 1);
        cat(cafe, "Milk Tea",         "CAFE",          "emoji_food_beverage", "#795548", 2);
        cat(cafe, "Bakery",           "CAFE",          "bakery_dining",       "#795548", 3);
        cat(cafe, "Workspace Cafe",   "CAFE",          "laptop",              "#795548", 4);
        cat(cafe, "Rooftop Cafe",     "CAFE",          "roofing",             "#795548", 5);
        cat(cafe, "Garden Cafe",      "CAFE",          "park",                "#795548", 6);
        cat(cafe, "Dessert",          "CAFE",          "icecream",            "#795548", 7);

        Category attr  = cat(null, "Attraction",      "ATTRACTION",    "landscape",           "#4CAF50", 4);
        cat(attr, "Beach",            "ATTRACTION",    "beach_access",        "#4CAF50", 1);
        cat(attr, "Mountain",         "ATTRACTION",    "landscape",           "#4CAF50", 2);
        cat(attr, "Museum",           "ATTRACTION",    "museum",              "#4CAF50", 3);
        cat(attr, "Temple",           "ATTRACTION",    "temple_buddhist",     "#4CAF50", 4);
        cat(attr, "Pagoda",           "ATTRACTION",    "temple_buddhist",     "#4CAF50", 5);
        cat(attr, "Historical Site",  "ATTRACTION",    "account_balance",     "#4CAF50", 6);
        cat(attr, "Theme Park",       "ATTRACTION",    "attractions",         "#4CAF50", 7);
        cat(attr, "Waterfall",        "ATTRACTION",    "water",               "#4CAF50", 8);
        cat(attr, "Lake",             "ATTRACTION",    "water",               "#4CAF50", 9);
        cat(attr, "Island",           "ATTRACTION",    "island",              "#4CAF50", 10);
        cat(attr, "Market",           "ATTRACTION",    "storefront",          "#4CAF50", 11);

        Category photo = cat(null, "Photo Spot",       "PHOTO_SPOT",    "photo_camera",        "#9C27B0", 5);
        cat(photo, "Sunset",          "PHOTO_SPOT",    "wb_sunny",            "#9C27B0", 1);
        cat(photo, "Viewpoint",       "PHOTO_SPOT",    "panorama",            "#9C27B0", 2);
        cat(photo, "Bridge",          "PHOTO_SPOT",    "settings_input_antenna", "#9C27B0", 3);
        cat(photo, "Street",          "PHOTO_SPOT",    "add_road",            "#9C27B0", 4);
        cat(photo, "Flower Garden",   "PHOTO_SPOT",    "local_florist",       "#9C27B0", 5);
        cat(photo, "Landmark",        "PHOTO_SPOT",    "place",               "#9C27B0", 6);
        cat(photo, "Night View",      "PHOTO_SPOT",    "nightlife",           "#9C27B0", 7);

        Category shop  = cat(null, "Shopping",         "SHOPPING",      "shopping_bag",        "#FF9800", 6);
        cat(shop, "Mall",             "SHOPPING",      "local_mall",          "#FF9800", 1);
        cat(shop, "Local Market",     "SHOPPING",      "storefront",          "#FF9800", 2);
        cat(shop, "Souvenir Shop",    "SHOPPING",      "card_giftcard",       "#FF9800", 3);
        cat(shop, "Night Market",     "SHOPPING",      "nights_stay",         "#FF9800", 4);

        Category ent   = cat(null, "Entertainment",    "ENTERTAINMENT", "celebration",         "#E91E63", 7);
        cat(ent,  "Bar",              "ENTERTAINMENT", "sports_bar",          "#E91E63", 1);
        cat(ent,  "Club",             "ENTERTAINMENT", "nightlife",           "#E91E63", 2);
        cat(ent,  "Cinema",           "ENTERTAINMENT", "movie",               "#E91E63", 3);
        cat(ent,  "Karaoke",          "ENTERTAINMENT", "mic",                 "#E91E63", 4);
        cat(ent,  "Live Music",       "ENTERTAINMENT", "music_note",          "#E91E63", 5);
        cat(ent,  "Family Entertainment", "ENTERTAINMENT", "family_restroom", "#E91E63", 6);

        Category trans = cat(null, "Transportation",   "TRANSPORTATION", "directions_car",     "#607D8B", 8);
        cat(trans, "Motorbike Rental","TRANSPORTATION", "two_wheeler",        "#607D8B", 1);
        cat(trans, "Car Rental",      "TRANSPORTATION", "directions_car",     "#607D8B", 2);
        cat(trans, "Airport Transfer","TRANSPORTATION", "local_airport",      "#607D8B", 3);
        cat(trans, "Bus",             "TRANSPORTATION", "directions_bus",     "#607D8B", 4);
        cat(trans, "Train",           "TRANSPORTATION", "directions_railway", "#607D8B", 5);

        Category tour  = cat(null, "Tour",             "TOUR",          "tour",                "#00BCD4", 9);
        cat(tour, "City Tour",        "TOUR",          "location_city",       "#00BCD4", 1);
        cat(tour, "Island Tour",      "TOUR",          "island",              "#00BCD4", 2);
        cat(tour, "Food Tour",        "TOUR",          "restaurant",          "#00BCD4", 3);
        cat(tour, "Adventure Tour",   "TOUR",          "hiking",              "#00BCD4", 4);
        cat(tour, "Cultural Tour",    "TOUR",          "account_balance",     "#00BCD4", 5);

        Category well  = cat(null, "Wellness",         "WELLNESS",      "spa",                 "#8BC34A", 10);
        cat(well, "Spa",              "WELLNESS",      "spa",                 "#8BC34A", 1);
        cat(well, "Massage",          "WELLNESS",      "self_improvement",    "#8BC34A", 2);
        cat(well, "Hot Spring",       "WELLNESS",      "hot_tub",             "#8BC34A", 3);
        cat(well, "Yoga",             "WELLNESS",      "self_improvement",    "#8BC34A", 4);
        cat(well, "Gym",              "WELLNESS",      "fitness_center",      "#8BC34A", 5);
    }

    private Category cat(Category parent, String name, String type, String icon, String color, int sort) {
        String slug = SlugUtils.toSlug(name);
        return categories.findBySlug(slug).orElseGet(() -> {
            Category c = new Category();
            c.setParent(parent);
            c.setName(name);
            c.setSlug(slug);
            c.setType(type);
            c.setIcon(icon);
            c.setColor(color);
            c.setSortOrder(sort);
            c.setActive(true);
            return categories.save(c);
        });
    }

    // ─────────────────────────────────────────────────────────────
    // AMENITIES — 64 across 6 groups
    // ─────────────────────────────────────────────────────────────

    private void seedAmenities() {
        // GENERAL (12)
        a("Free WiFi",              "GENERAL",     "wifi",               "Free wireless internet access",                           1);
        a("Parking",                "GENERAL",     "local_parking",      "Free or paid parking on site",                            2);
        a("Air Conditioning",       "GENERAL",     "ac_unit",            "Air-conditioned rooms or areas",                          3);
        a("Pet Friendly",           "GENERAL",     "pets",               "Pets are welcome",                                        4);
        a("Kid Friendly",           "GENERAL",     "child_care",         "Suitable for families with children",                     5);
        a("Wheelchair Accessible",  "GENERAL",     "accessible",         "Facilities accessible for wheelchair users",               6);
        a("Outdoor Seating",        "GENERAL",     "deck",               "Seating available outdoors",                              7);
        a("Smoking Area",           "GENERAL",     "smoking_rooms",      "Designated smoking zone",                                 8);
        a("Non-smoking Area",       "GENERAL",     "smoke_free",         "Smoke-free premises",                                     9);
        a("Credit Card Accepted",   "GENERAL",     "credit_card",        "Major credit cards accepted",                             10);
        a("Cash Payment",           "GENERAL",     "payments",           "Cash payment accepted",                                   11);
        a("QR Payment",             "GENERAL",     "qr_code",            "QR code payment supported",                               12);

        // HOTEL (14)
        a("Swimming Pool",          "HOTEL",       "pool",               "Outdoor or indoor swimming pool",                          1);
        a("Sea View",               "HOTEL",       "water",              "Room or facility with sea view",                           2);
        a("Breakfast",              "HOTEL",       "free_breakfast",     "Breakfast included in rate",                               3);
        a("Airport Shuttle",        "HOTEL",       "airport_shuttle",    "Shuttle service to/from airport",                          4);
        a("Family Room",            "HOTEL",       "family_restroom",    "Rooms suitable for families",                              5);
        a("Spa",                    "HOTEL",       "spa",                "On-site spa services",                                     6);
        a("Gym",                    "HOTEL",       "fitness_center",     "Fitness center on premises",                               7);
        a("Laundry",                "HOTEL",       "local_laundry_service", "Laundry service available",                             8);
        a("Elevator",               "HOTEL",       "elevator",           "Elevator / lift access",                                   9);
        a("24-hour Front Desk",     "HOTEL",       "support_agent",      "Reception open 24 hours",                                 10);
        a("Room Service",           "HOTEL",       "room_service",       "In-room dining service",                                  11);
        a("Free Cancellation",      "HOTEL",       "event_available",    "No fee for cancellation",                                 12);
        a("Pay at Property",        "HOTEL",       "price_check",        "Payment made on arrival",                                 13);
        a("No Prepayment Required", "HOTEL",       "money_off",          "No advance payment needed",                               14);

        // ROOM (13)
        a("Private Bathroom",       "ROOM",        "bathroom",           "En-suite private bathroom",                                1);
        a("Bathtub",                "ROOM",        "bathtub",            "Bathtub in bathroom",                                      2);
        a("Balcony",                "ROOM",        "balcony",            "Private outdoor balcony",                                  3);
        a("City View",              "ROOM",        "location_city",      "Room with city view",                                      4);
        a("Ocean View",             "ROOM",        "waves",              "Room with ocean or sea view",                              5);
        a("TV",                     "ROOM",        "tv",                 "Television in room",                                       6);
        a("Mini Bar",               "ROOM",        "liquor",             "Mini bar with beverages",                                  7);
        a("Hair Dryer",             "ROOM",        "dry_cleaning",       "Hair dryer provided",                                      8);
        a("Desk",                   "ROOM",        "desk",               "Work desk in room",                                        9);
        a("Wardrobe",               "ROOM",        "door_back",          "Wardrobe or closet space",                                10);
        a("Safe Box",               "ROOM",        "lock",               "In-room safe for valuables",                              11);
        a("Kettle",                 "ROOM",        "coffee_maker",       "Electric kettle for hot drinks",                          12);
        a("Refrigerator",           "ROOM",        "kitchen",            "Mini fridge in room",                                     13);

        // RESTAURANT (9)
        a("Seafood",                "RESTAURANT",  "set_meal",           "Specializes in fresh seafood",                             1);
        a("Vegetarian Options",     "RESTAURANT",  "eco",                "Vegetarian dishes available",                              2);
        a("Buffet",                 "RESTAURANT",  "dinner_dining",      "All-you-can-eat buffet",                                   3);
        a("Private Room",           "RESTAURANT",  "meeting_room",       "Private dining room for groups",                           4);
        a("Reservation Available",  "RESTAURANT",  "event_seat",         "Table reservations accepted",                              5);
        a("Delivery",               "RESTAURANT",  "delivery_dining",    "Food delivery service",                                    6);
        a("Takeaway",               "RESTAURANT",  "takeout_dining",     "Takeaway / takeout available",                             7);
        a("Live Music",             "RESTAURANT",  "music_note",         "Live music during dining hours",                           8);
        a("Sea View Dining",        "RESTAURANT",  "water",              "Dining area with sea or ocean view",                       9);

        // CAFE (8)
        a("Workspace Friendly",     "CAFE",        "laptop",             "Good for remote work",                                     1);
        a("Power Outlets",          "CAFE",        "electrical_services","Power sockets at seats",                                   2);
        a("Quiet Space",            "CAFE",        "volume_mute",        "Quiet, low-noise environment",                             3);
        a("Rooftop",                "CAFE",        "roofing",            "Rooftop seating area",                                     4);
        a("Garden View",            "CAFE",        "park",               "Seating with garden view",                                 5);
        a("Specialty Coffee",       "CAFE",        "local_cafe",         "Specialty or single-origin coffee",                        6);
        a("Dessert",                "CAFE",        "icecream",           "Desserts and sweets on menu",                              7);
        a("Board Games",            "CAFE",        "games",              "Board games available for guests",                         8);

        // ATTRACTION (8)
        a("Ticket Required",        "ATTRACTION",  "confirmation_number","Entrance ticket required",                                  1);
        a("Free Entry",             "ATTRACTION",  "free_cancellation",  "No entrance fee",                                          2);
        a("Guided Tour",            "ATTRACTION",  "tour",               "Guided tour service available",                            3);
        a("Parking Nearby",         "ATTRACTION",  "local_parking",      "Parking area near the attraction",                         4);
        a("Best for Sunset",        "ATTRACTION",  "wb_sunny",           "Ideal spot to watch the sunset",                           5);
        a("Best for Family",        "ATTRACTION",  "family_restroom",    "Family-friendly attraction",                               6);
        a("Hiking Required",        "ATTRACTION",  "hiking",             "Requires hiking to reach",                                 7);
        a("Photography Allowed",    "ATTRACTION",  "photo_camera",       "Photography permitted on site",                            8);
    }

    private void a(String name, String group, String icon, String desc, int sort) {
        String slug = SlugUtils.toSlug(name);
        if (amenities.existsBySlug(slug)) return;
        Amenity a = new Amenity();
        a.setName(name);
        a.setSlug(slug);
        a.setGroupName(group);
        a.setIcon(icon);
        a.setDescription(desc);
        a.setSortOrder(sort);
        a.setActive(true);
        amenities.save(a);
    }

    // ─────────────────────────────────────────────────────────────
    // PLACES — 4 sample published places
    // ─────────────────────────────────────────────────────────────

    private void seedPlaces() {
        User admin = users.findByEmail("admin@planyourtrip.com").orElse(null);
        if (admin == null) return;

        // Hotel in Vũng Tàu
        place(admin,
            "Grand Palace Hotel Vũng Tàu",
            "accommodation", "hotel", "VT",
            "48 Quang Trung, Bãi Trước, TP. Vũng Tàu", null,
            10.3457, 107.0843,
            "Khách sạn sang trọng 4 sao bên bờ biển Vũng Tàu.",
            "Khách sạn tọa lạc ngay trung tâm TP. Vũng Tàu, cách bãi biển Bãi Trước chỉ 200m. " +
            "Với kiến trúc hiện đại, phòng nghỉ rộng rãi và dịch vụ chuyên nghiệp, " +
            "đây là lựa chọn lý tưởng cho kỳ nghỉ biển.",
            3, true, true,
            List.of("luxury", "sea-view", "beach-hotel", "vung-tau"),
            List.of("free-wifi", "swimming-pool", "breakfast", "air-conditioning", "parking"),
            allDays(LocalTime.of(0, 0), LocalTime.of(23, 59))
        );

        // Cafe in Đà Lạt
        place(admin,
            "The Dreamer Café Đà Lạt",
            "cafe", "garden-cafe", "DL",
            "15 Hoàng Diệu, Phường 5, Đà Lạt, Lâm Đồng", null,
            11.9385, 108.4350,
            "Quán cà phê vườn xinh đẹp giữa lòng thành phố ngàn hoa.",
            "The Dreamer là không gian cà phê vườn lãng mạn, được bao phủ bởi hoa và cây xanh. " +
            "Nơi đây phục vụ các loại cà phê đặc sản Đà Lạt và các loại thức uống sáng tạo " +
            "trong không gian thơ mộng đặc trưng của thành phố cao nguyên.",
            1, false, true,
            List.of("cozy", "garden", "dalat", "coffee"),
            List.of("free-wifi", "outdoor-seating", "workspace-friendly"),
            List.of(
                new int[]{1, 8, 0, 22, 0}, new int[]{2, 8, 0, 22, 0}, new int[]{3, 8, 0, 22, 0},
                new int[]{4, 8, 0, 22, 0}, new int[]{5, 8, 0, 22, 0},
                new int[]{6, 7, 30, 22, 30}, new int[]{7, 7, 30, 22, 30}
            )
        );

        // Attraction in Đà Nẵng
        place(admin,
            "Bà Nà Hills & Cầu Vàng",
            "attraction", "theme-park", "DNC",
            "Thôn An Sơn, Xã Hoà Ninh, Huyện Hoà Vang, Đà Nẵng", null,
            15.9956, 107.9884,
            "Khu du lịch nổi tiếng với Cầu Vàng biểu tượng và cảnh quan núi rừng hùng vĩ.",
            "Bà Nà Hills là khu du lịch sinh thái nằm trên đỉnh núi Bà Nà ở độ cao 1.487m. " +
            "Nơi đây nổi tiếng với Cầu Vàng – biểu tượng du lịch của Đà Nẵng – " +
            "cùng với thị trấn Pháp cổ tích, các trò chơi giải trí và khí hậu mát mẻ quanh năm.",
            2, true, true,
            List.of("iconic", "danang", "theme-park", "golden-bridge"),
            List.of("ticket-required", "parking-nearby", "photography-allowed"),
            List.of(
                new int[]{1, 7, 30, 21, 30}, new int[]{2, 7, 30, 21, 30}, new int[]{3, 7, 30, 21, 30},
                new int[]{4, 7, 30, 21, 30}, new int[]{5, 7, 30, 21, 30},
                new int[]{6, 7, 0, 22, 0}, new int[]{7, 7, 0, 22, 0}
            )
        );

        // Photo spot in Hạ Long
        place(admin,
            "Hang Sửng Sốt - Vịnh Hạ Long",
            "photo-spot", "viewpoint", "HL",
            "Đảo Bồ Hòn, Vịnh Hạ Long, Quảng Ninh", null,
            20.8984, 107.0800,
            "Hang động kỳ vĩ và điểm chụp ảnh ngoạn mục nhất Vịnh Hạ Long.",
            "Hang Sửng Sốt (Surprise Cave) là một trong những hang động lớn nhất và đẹp nhất " +
            "tại Vịnh Hạ Long. Tên gọi 'Sửng Sốt' phản ánh cảm xúc kinh ngạc của du khách " +
            "khi lần đầu bước vào hang với những nhũ đá hùng vĩ và ánh sáng tự nhiên.",
            1, true, true,
            List.of("halong", "viewpoint", "bay", "scenic"),
            List.of("free-entry", "photography-allowed", "best-for-sunset"),
            List.of(
                new int[]{1, 8, 0, 17, 0}, new int[]{2, 8, 0, 17, 0}, new int[]{3, 8, 0, 17, 0},
                new int[]{4, 8, 0, 17, 0}, new int[]{5, 8, 0, 17, 0},
                new int[]{6, 7, 30, 17, 30}, new int[]{7, 7, 30, 17, 30}
            )
        );
    }

    private void place(User admin, String name, String catSlug, String subcatSlug,
                       String locCode, String address, String googleMapUrl,
                       double lat, double lng, String shortDesc, String desc,
                       int priceLevel, boolean featured, boolean verified,
                       List<String> tagList, List<String> amenitySlugs,
                       List<int[]> openHours) {
        String slug = SlugUtils.toSlug(name);
        if (placeRepo.existsBySlug(slug)) return;

        Category cat = categories.findBySlug(catSlug).orElse(null);
        if (cat == null) return;
        Category subcat = subcatSlug != null ? categories.findBySlug(subcatSlug).orElse(null) : null;
        AdministrativeUnit loc = locations.findByCode(locCode).orElse(null);
        if (loc == null) return;

        Place p = new Place();
        p.setName(name);
        p.setNameNormalized(SlugUtils.normalize(name));
        p.setSlug(slug);
        p.setCategory(cat);
        p.setSubcategory(subcat);
        p.setAdministrativeUnit(loc);
        p.setAddress(address);
        p.setGoogleMapUrl(googleMapUrl);
        p.setLatitude(lat);
        p.setLongitude(lng);
        p.setShortDescription(shortDesc);
        p.setDescription(desc);
        p.setPriceLevel(priceLevel);
        p.setFeatured(featured);
        p.setVerified(verified);
        p.setStatus(PlaceStatus.PUBLISHED);
        p.setCreatedBy(admin);
        placeRepo.save(p);

        for (String t : tagList) {
            PlaceTag tag = new PlaceTag();
            tag.setPlace(p);
            tag.setTag(t);
            tag.setTagNormalized(SlugUtils.normalize(t));
            placeTagRepo.save(tag);
        }

        for (String aSlug : amenitySlugs) {
            amenities.findBySlug(aSlug).ifPresent(am -> {
                PlaceAmenity pa = new PlaceAmenity();
                pa.setPlace(p);
                pa.setAmenity(am);
                placeAmenityRepo.save(pa);
            });
        }

        for (int[] oh : openHours) {
            PlaceOpeningHour h = new PlaceOpeningHour();
            h.setPlace(p);
            h.setDayOfWeek(oh[0]);
            h.setOpenTime(LocalTime.of(oh[1], oh[2]));
            h.setCloseTime(LocalTime.of(oh[3], oh[4]));
            h.setClosed(false);
            placeOpeningHourRepo.save(h);
        }
    }

    private List<int[]> allDays(LocalTime open, LocalTime close) {
        int oh = open.getHour(), om = open.getMinute();
        int ch = close.getHour(), cm = close.getMinute();
        return List.of(
            new int[]{1, oh, om, ch, cm}, new int[]{2, oh, om, ch, cm},
            new int[]{3, oh, om, ch, cm}, new int[]{4, oh, om, ch, cm},
            new int[]{5, oh, om, ch, cm}, new int[]{6, oh, om, ch, cm},
            new int[]{7, oh, om, ch, cm}
        );
    }

    // ─────────────────────────────────────────────────────────────
    // MEDIA — seed MediaAsset entries for seed places
    // ─────────────────────────────────────────────────────────────

    private void seedMedia() {
        // Hotel: 1 cover + 2 gallery
        mediaFor("grand-palace-hotel-vung-tau",
            new MediaData("https://cdn.planyourtrip.vn/places/grand-palace-hotel/exterior.jpg",
                "Hotel exterior", true, 1),
            new MediaData("https://cdn.planyourtrip.vn/places/grand-palace-hotel/pool.jpg",
                "Swimming pool", false, 2),
            new MediaData("https://cdn.planyourtrip.vn/places/grand-palace-hotel/room.jpg",
                "Superior sea-view room", false, 3)
        );

        // Cafe: 2 images with no cover — preserves fallback behavior (first by sortOrder used as cover)
        mediaFor("the-dreamer-cafe-da-lat",
            new MediaData("https://cdn.planyourtrip.vn/places/the-dreamer-cafe/garden.jpg",
                "Garden seating area", false, 1),
            new MediaData("https://cdn.planyourtrip.vn/places/the-dreamer-cafe/coffee.jpg",
                "Specialty coffee", false, 2)
        );

        // Attraction: 1 cover + 2 gallery
        mediaFor("ba-na-hills-cau-vang",
            new MediaData("https://cdn.planyourtrip.vn/places/ba-na-hills/golden-bridge.jpg",
                "The iconic Golden Bridge", true, 1),
            new MediaData("https://cdn.planyourtrip.vn/places/ba-na-hills/french-village.jpg",
                "French Village", false, 2),
            new MediaData("https://cdn.planyourtrip.vn/places/ba-na-hills/cable-car.jpg",
                "Cable car ride", false, 3)
        );

        // Ha Long: intentionally no media — tests null coverImageUrl
    }

    // ─────────────────────────────────────────────────────────────
    // PLACE METADATA — recommendation signals for demo places
    // ─────────────────────────────────────────────────────────────

    private void seedPlaceMetadata() {
        metadataFor("grand-palace-hotel-vung-tau", m -> {
            m.getTravelStyles().addAll(List.of(
                TravelStyle.COUPLE, TravelStyle.FAMILY, TravelStyle.BUSINESS, TravelStyle.LUXURY));
            m.getBestVisitTimes().addAll(List.of(
                BestVisitTime.AFTERNOON, BestVisitTime.SUNSET, BestVisitTime.EVENING));
            m.getBestSeasons().addAll(List.of(
                BestSeason.SPRING, BestSeason.SUMMER, BestSeason.ALL_YEAR));
            m.getWeatherTypes().addAll(List.of(WeatherType.SUNNY, WeatherType.ANY));
            m.setEstimatedVisitMinutes(120);
            m.setEstimatedBudgetLevel(BudgetLevel.HIGH);
            m.setDifficultyLevel(DifficultyLevel.EASY);
            m.setAccessibilityLevel(AccessibilityLevel.HIGH);
            m.setCrowdLevel(CrowdLevel.MEDIUM);
            m.setRomantic(true);
            m.setFamilyFriendly(true);
            m.setKidFriendly(true);
            m.setPetFriendly(false);
            m.setWheelchairFriendly(true);
            m.setPhotographySpot(true);
            m.setSunsetSpot(true);
            m.setSunriseSpot(false);
            m.setIndoor(true);
            m.setOutdoor(true);
            m.setRainyDaySuitable(true);
        });

        metadataFor("the-dreamer-cafe-da-lat", m -> {
            m.getTravelStyles().addAll(List.of(
                TravelStyle.SOLO, TravelStyle.COUPLE, TravelStyle.FRIENDS));
            m.getBestVisitTimes().addAll(List.of(
                BestVisitTime.MORNING, BestVisitTime.AFTERNOON));
            m.getBestSeasons().addAll(List.of(BestSeason.SPRING, BestSeason.AUTUMN));
            m.getWeatherTypes().addAll(List.of(WeatherType.COOL, WeatherType.CLOUDY));
            m.setEstimatedVisitMinutes(60);
            m.setEstimatedBudgetLevel(BudgetLevel.LOW);
            m.setDifficultyLevel(DifficultyLevel.EASY);
            m.setAccessibilityLevel(AccessibilityLevel.HIGH);
            m.setCrowdLevel(CrowdLevel.MEDIUM);
            m.setRomantic(true);
            m.setFamilyFriendly(false);
            m.setKidFriendly(false);
            m.setPetFriendly(false);
            m.setWheelchairFriendly(false);
            m.setPhotographySpot(true);
            m.setSunsetSpot(false);
            m.setSunriseSpot(false);
            m.setIndoor(true);
            m.setOutdoor(true);
            m.setRainyDaySuitable(true);
        });

        metadataFor("ba-na-hills-cau-vang", m -> {
            m.getTravelStyles().addAll(List.of(
                TravelStyle.FAMILY, TravelStyle.FRIENDS, TravelStyle.COUPLE, TravelStyle.BACKPACKER));
            m.getBestVisitTimes().addAll(List.of(
                BestVisitTime.MORNING, BestVisitTime.AFTERNOON, BestVisitTime.SUNSET));
            m.getBestSeasons().addAll(List.of(
                BestSeason.SPRING, BestSeason.SUMMER, BestSeason.AUTUMN, BestSeason.WINTER));
            m.getWeatherTypes().addAll(List.of(WeatherType.SUNNY, WeatherType.CLOUDY));
            m.setEstimatedVisitMinutes(360);
            m.setEstimatedBudgetLevel(BudgetLevel.MEDIUM);
            m.setDifficultyLevel(DifficultyLevel.EASY);
            m.setAccessibilityLevel(AccessibilityLevel.HIGH);
            m.setCrowdLevel(CrowdLevel.HIGH);
            m.setRomantic(true);
            m.setFamilyFriendly(true);
            m.setKidFriendly(true);
            m.setPetFriendly(false);
            m.setWheelchairFriendly(false);
            m.setPhotographySpot(true);
            m.setSunsetSpot(true);
            m.setSunriseSpot(false);
            m.setIndoor(false);
            m.setOutdoor(true);
            m.setRainyDaySuitable(false);
        });

        metadataFor("hang-sung-sot---vinh-ha-long", m -> {
            m.getTravelStyles().addAll(List.of(
                TravelStyle.COUPLE, TravelStyle.FAMILY, TravelStyle.FRIENDS,
                TravelStyle.BACKPACKER, TravelStyle.SOLO));
            m.getBestVisitTimes().addAll(List.of(
                BestVisitTime.MORNING, BestVisitTime.AFTERNOON));
            m.getBestSeasons().addAll(List.of(BestSeason.SPRING, BestSeason.AUTUMN));
            m.getWeatherTypes().addAll(List.of(WeatherType.SUNNY));
            m.setEstimatedVisitMinutes(180);
            m.setEstimatedBudgetLevel(BudgetLevel.MEDIUM);
            m.setDifficultyLevel(DifficultyLevel.MODERATE);
            m.setAccessibilityLevel(AccessibilityLevel.MEDIUM);
            m.setCrowdLevel(CrowdLevel.MEDIUM);
            m.setRomantic(true);
            m.setFamilyFriendly(true);
            m.setKidFriendly(false);
            m.setPetFriendly(false);
            m.setWheelchairFriendly(false);
            m.setPhotographySpot(true);
            m.setSunsetSpot(false);
            m.setSunriseSpot(true);
            m.setIndoor(false);
            m.setOutdoor(true);
            m.setRainyDaySuitable(false);
        });
    }

    private void metadataFor(String placeSlug, Consumer<PlaceMetadata> configure) {
        Place place = placeRepo.findBySlug(placeSlug).orElse(null);
        if (place == null) return;
        if (placeMetadataRepo.existsByPlaceId(place.getId())) return;
        PlaceMetadata m = new PlaceMetadata();
        m.setPlace(place);
        configure.accept(m);
        placeMetadataRepo.save(m);
    }

    private void mediaFor(String placeSlug, MediaData... items) {
        Place place = placeRepo.findBySlug(placeSlug).orElse(null);
        if (place == null) return;
        if (mediaAssetRepo.existsByOwnerTypeAndOwnerId(MediaOwnerType.PLACE, place.getId())) return;
        for (MediaData d : items) {
            MediaAsset asset = new MediaAsset();
            asset.setOwnerType(MediaOwnerType.PLACE);
            asset.setOwnerId(place.getId());
            asset.setUrl(d.url());
            asset.setMediaType(MediaType.IMAGE);
            asset.setAltText(d.altText());
            asset.setCover(d.cover());
            asset.setSortOrder(d.sortOrder());
            mediaAssetRepo.save(asset);
        }
    }

    private record MediaData(String url, String altText, boolean cover, int sortOrder) {}

    // ─────────────────────────────────────────────────────────────
    // HOTEL DETAILS — extended data for Hotel category places
    // ─────────────────────────────────────────────────────────────

    private void seedHotelDetails() {
        hotelFor("grand-palace-hotel-vung-tau", d -> {
            d.setStarRating(4);
            d.setCheckInTime(LocalTime.of(14, 0));
            d.setCheckOutTime(LocalTime.of(12, 0));
            d.setDistanceToBeachMeters(250);
            d.setDistanceToCityCenterMeters(900);
            d.setTotalRooms(120);
            d.setAvailableRooms(38);
            d.setBreakfastIncluded(true);
            d.setAirportShuttle(true);
            d.setFreeCancellation(false);
            d.setPrepaymentRequired(false);
        });
    }

    private void hotelFor(String placeSlug, Consumer<HotelDetail> configure) {
        Place place = placeRepo.findBySlug(placeSlug).orElse(null);
        if (place == null) return;
        if (hotelDetailRepo.existsByPlaceId(place.getId())) return;
        HotelDetail d = new HotelDetail();
        d.setPlace(place);
        configure.accept(d);
        hotelDetailRepo.save(d);
    }

    // ─────────────────────────────────────────────────────────────
    // HOTEL ROOMS — sample rooms for Grand Palace Hotel
    // ─────────────────────────────────────────────────────────────

    private void seedHotelRooms() {
        Place place = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElse(null);
        if (place == null) return;
        HotelDetail detail = hotelDetailRepo.findByPlaceId(place.getId()).orElse(null);
        if (detail == null) return;

        roomFor(detail, "STD-TWIN", r -> {
            r.setRoomName("Standard Twin Room");
            r.setRoomType(RoomType.STANDARD);
            r.setBedType(BedType.TWIN);
            r.setBedCount(2);
            r.setMaxAdults(2);
            r.setMaxChildren(0);
            r.setMaxGuests(2);
            r.setRoomSizeSqm(25.0);
            r.setBreakfastIncluded(true);
            r.setFreeCancellation(false);
            r.setInstantConfirmation(true);
            r.setPriceFrom(new java.math.BigDecimal("900000.00"));
            r.setQuantity(10);
            r.setAvailableQuantity(4);
        }, List.of("tv", "private-bathroom", "air-conditioning", "free-wifi"));

        roomFor(detail, "DLX-KING", r -> {
            r.setRoomName("Deluxe King Room");
            r.setRoomType(RoomType.DELUXE);
            r.setBedType(BedType.KING);
            r.setBedCount(1);
            r.setMaxAdults(2);
            r.setMaxChildren(1);
            r.setMaxGuests(3);
            r.setRoomSizeSqm(35.0);
            r.setBreakfastIncluded(true);
            r.setFreeCancellation(true);
            r.setInstantConfirmation(true);
            r.setPriceFrom(new java.math.BigDecimal("1350000.00"));
            r.setQuantity(10);
            r.setAvailableQuantity(4);
        }, List.of("tv", "private-bathroom", "balcony", "ocean-view", "mini-bar"));

        roomFor(detail, "FAM-DBL", r -> {
            r.setRoomName("Family Double Room");
            r.setRoomType(RoomType.FAMILY);
            r.setBedType(BedType.DOUBLE);
            r.setBedCount(2);
            r.setMaxAdults(2);
            r.setMaxChildren(2);
            r.setMaxGuests(4);
            r.setRoomSizeSqm(48.0);
            r.setBreakfastIncluded(true);
            r.setFreeCancellation(true);
            r.setInstantConfirmation(true);
            r.setPriceFrom(new java.math.BigDecimal("2100000.00"));
            r.setQuantity(10);
            r.setAvailableQuantity(4);
        }, List.of("tv", "private-bathroom", "refrigerator", "safe-box"));

        roomFor(detail, "SUITE-KNG", r -> {
            r.setRoomName("Ocean Suite");
            r.setRoomType(RoomType.SUITE);
            r.setBedType(BedType.KING);
            r.setBedCount(1);
            r.setMaxAdults(2);
            r.setMaxChildren(1);
            r.setMaxGuests(3);
            r.setRoomSizeSqm(75.0);
            r.setBreakfastIncluded(true);
            r.setFreeCancellation(true);
            r.setInstantConfirmation(true);
            r.setPriceFrom(new java.math.BigDecimal("3500000.00"));
            r.setQuantity(10);
            r.setAvailableQuantity(4);
        }, List.of("tv", "private-bathroom", "bathtub", "balcony", "ocean-view", "mini-bar", "safe-box"));
    }

    // ─────────────────────────────────────────────────────────────
    // HOTEL EXPERIENCE — facilities, services, languages, payments
    // ─────────────────────────────────────────────────────────────

    private void seedHotelExperience() {
        Place place = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElse(null);
        if (place == null) return;
        HotelDetail detail = hotelDetailRepo.findByPlaceId(place.getId()).orElse(null);
        if (detail == null) return;
        if (hotelFacilityRepo.existsByHotelDetailId(detail.getId())) return;

        // Languages and payment methods
        detail.getLanguages().addAll(List.of("Vietnamese", "English"));
        detail.getPaymentMethods().addAll(List.of("Cash", "Visa", "MasterCard", "Apple Pay"));

        // Parking & internet
        detail.setParkingAvailable(true);
        detail.setParkingFree(false);
        detail.setParkingDescription("Paid parking available on-site");
        detail.setWifiAvailable(true);
        detail.setWifiFree(true);
        detail.setInternetDescription("Free high-speed WiFi in all rooms and public areas");
        hotelDetailRepo.save(detail);

        // Facilities
        facility(detail, "Pool",             FacilityGroup.WELLNESS,     "pool",                 1);
        facility(detail, "Spa",              FacilityGroup.WELLNESS,     "spa",                  2);
        facility(detail, "Gym",              FacilityGroup.WELLNESS,     "fitness_center",       3);
        facility(detail, "Restaurant",       FacilityGroup.FOOD,         "restaurant",           4);
        facility(detail, "Bar",              FacilityGroup.FOOD,         "local_bar",            5);
        facility(detail, "Garden",           FacilityGroup.OUTDOOR,      "park",                 6);
        facility(detail, "Conference Room",  FacilityGroup.BUSINESS,     "meeting_room",         7);
        facility(detail, "Elevator",         FacilityGroup.ACCESSIBILITY,"elevator",             8);
        facility(detail, "Beach Access",     FacilityGroup.OUTDOOR,      "beach_access",         9);

        // Services
        guestService(detail, "Room Service",        "room_service",            true);
        guestService(detail, "Laundry",             "local_laundry_service",   true);
        guestService(detail, "Airport Shuttle",     "airport_shuttle",         true);
        guestService(detail, "Daily Housekeeping",  "cleaning_services",       true);
        guestService(detail, "24h Reception",       "support_agent",           true);
        guestService(detail, "Wake-up Call",        "alarm",                   true);
    }

    private void facility(HotelDetail detail, String name, FacilityGroup group,
                          String icon, int sortOrder) {
        HotelFacility f = new HotelFacility();
        f.setHotelDetail(detail);
        f.setFacilityName(name);
        f.setFacilityGroup(group);
        f.setIcon(icon);
        f.setSortOrder(sortOrder);
        hotelFacilityRepo.save(f);
    }

    private void guestService(HotelDetail detail, String name, String icon, boolean available) {
        HotelService s = new HotelService();
        s.setHotelDetail(detail);
        s.setServiceName(name);
        s.setIcon(icon);
        s.setAvailable(available);
        hotelServiceRepo.save(s);
    }

    // ─────────────────────────────────────────────────────────────
    // PROMOTIONS — discount campaigns
    // ─────────────────────────────────────────────────────────────

    private void seedPromotions() {
        if (promotionRepo.count() > 0) return;
        java.time.LocalDate today = java.time.LocalDate.now();

        promo("Summer Sale",       null,          PromotionType.GENERAL,     DiscountType.PERCENTAGE,
              new BigDecimal("10"), null,          null, null,  false, 10,
              today, today.plusDays(90));

        promo("Weekend Special",   null,          PromotionType.WEEKEND,     DiscountType.PERCENTAGE,
              new BigDecimal("15"), null,          null, null,  false, 20,
              today, today.plusDays(90));

        promo("Member Discount",   "MEMBER5",     PromotionType.MEMBER,      DiscountType.PERCENTAGE,
              new BigDecimal("5"),  null,          null, null,  true,  5,
              today, today.plusDays(365));

        promo("Early Bird",        "EARLYBIRD20", PromotionType.EARLY_BIRD,  DiscountType.PERCENTAGE,
              new BigDecimal("20"), null,          3,    null,  false, 30,
              today.plusDays(30), today.plusDays(180));

        promo("Last Minute",       "LASTMIN8",    PromotionType.LAST_MINUTE, DiscountType.PERCENTAGE,
              new BigDecimal("8"),  null,          null, null,  false, 15,
              today, today.plusDays(7));
    }

    private void promo(String name, String code, PromotionType type, DiscountType discountType,
                       BigDecimal value, BigDecimal maxDiscount, Integer minStay,
                       BigDecimal minSpend, boolean stackable, int priority,
                       java.time.LocalDate start, java.time.LocalDate end) {
        Promotion p = new Promotion();
        p.setName(name);
        p.setCode(code);
        p.setPromotionType(type);
        p.setDiscountType(discountType);
        p.setDiscountValue(value);
        p.setMaxDiscountAmount(maxDiscount);
        p.setMinimumStay(minStay);
        p.setMinimumSpend(minSpend);
        p.setStackable(stackable);
        p.setPriority(priority);
        p.setStartDate(start);
        p.setEndDate(end);
        p.setTargetType(PromotionTargetType.ALL);
        promotionRepo.save(p);
    }

    // ─────────────────────────────────────────────────────────────
    // RATE PLANS — promotional pricing for demo hotel rooms
    // ─────────────────────────────────────────────────────────────

    private void seedRatePlans() {
        Place place = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElse(null);
        if (place == null) return;
        HotelDetail detail = hotelDetailRepo.findByPlaceId(place.getId()).orElse(null);
        if (detail == null) return;

        java.time.LocalDate today = java.time.LocalDate.now();
        ratePlanFor(detail, "STD-TWIN", "Summer Deal",
            RatePlanType.PROMOTIONAL, new BigDecimal("800000.00"), today, today.plusDays(30));
        ratePlanFor(detail, "SUITE-KNG", "Ocean Suite Offer",
            RatePlanType.PROMOTIONAL, new BigDecimal("2800000.00"), today, today.plusDays(14));
    }

    private void ratePlanFor(HotelDetail detail, String roomCode, String rateName,
                              RatePlanType rateType, BigDecimal price,
                              java.time.LocalDate start, java.time.LocalDate end) {
        HotelRoom room = hotelRoomRepo.findAllByHotelDetailId(detail.getId())
            .stream()
            .filter(r -> roomCode.equals(r.getRoomCode()))
            .findFirst()
            .orElse(null);
        if (room == null) return;
        if (!ratePlanRepo.findByHotelRoomIdOrderByStartDateAsc(room.getId()).isEmpty()) return;
        RatePlan plan = new RatePlan();
        plan.setHotelRoom(room);
        plan.setRateName(rateName);
        plan.setRateType(rateType);
        plan.setPricePerNight(price);
        plan.setStartDate(start);
        plan.setEndDate(end);
        ratePlanRepo.save(plan);
    }

    private void roomFor(HotelDetail detail, String code,
                         Consumer<HotelRoom> configure, List<String> amenitySlugs) {
        if (hotelRoomRepo.existsByHotelDetailIdAndRoomCode(detail.getId(), code)) return;
        HotelRoom r = new HotelRoom();
        r.setHotelDetail(detail);
        r.setRoomCode(code);
        configure.accept(r);
        hotelRoomRepo.save(r);
        for (String slug : amenitySlugs) {
            amenities.findBySlug(slug).ifPresent(amenity -> {
                RoomAmenity ra = new RoomAmenity();
                ra.setRoom(r);
                ra.setAmenity(amenity);
                roomAmenityRepo.save(ra);
            });
        }
    }

    // ─────────────────────────────────────────────────────────────
    // ROOM INVENTORY — 90 days for all demo rooms
    // ─────────────────────────────────────────────────────────────

    private void seedRoomInventory() {
        Place place = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElse(null);
        if (place == null) return;
        HotelDetail detail = hotelDetailRepo.findByPlaceId(place.getId()).orElse(null);
        if (detail == null) return;

        java.time.LocalDate today = java.time.LocalDate.now();
        List<HotelRoom> rooms = hotelRoomRepo.findAllByHotelDetailId(detail.getId());

        for (HotelRoom room : rooms) {
            if (roomInventoryRepo.existsByHotelRoomIdAndInventoryDate(room.getId(), today)) continue;
            for (int i = 0; i < 90; i++) {
                RoomInventory inv = new RoomInventory();
                inv.setHotelRoom(room);
                inv.setInventoryDate(today.plusDays(i));
                inv.setTotalInventory(20);
                inv.setAvailableInventory(18);
                inv.setBlockedInventory(1);
                inv.setSoldInventory(0);
                inv.setMaintenanceInventory(1);
                roomInventoryRepo.save(inv);
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // BOOKINGS — 2 sample bookings for demo user
    // ─────────────────────────────────────────────────────────────

    private void seedBookings() {
        if (bookingRepo.count() > 0) return;

        User demo = users.findByEmail("demo@planyourtrip.com").orElse(null);
        if (demo == null) return;

        Place hotel = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElse(null);
        if (hotel == null) return;

        HotelDetail detail = hotelDetailRepo.findByPlaceId(hotel.getId()).orElse(null);
        if (detail == null) return;

        List<HotelRoom> rooms = hotelRoomRepo.findAllByHotelDetailId(detail.getId());
        if (rooms.isEmpty()) return;

        HotelRoom stdTwin = rooms.stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode())).findFirst().orElse(null);
        HotelRoom dlxKing = rooms.stream()
            .filter(r -> "DLX-KING".equals(r.getRoomCode())).findFirst().orElse(null);
        if (stdTwin == null || dlxKing == null) return;

        java.time.LocalDate today = java.time.LocalDate.now();

        // Booking 1: CONFIRMED — STD-TWIN, 2 nights, today+60
        java.time.LocalDate ci1 = today.plusDays(60);
        java.time.LocalDate co1 = ci1.plusDays(2);
        BigDecimal price1 = stdTwin.getPriceFrom()
            .multiply(BigDecimal.valueOf(2)).setScale(2, RoundingMode.HALF_UP);
        Booking b1 = buildBooking(demo, hotel, stdTwin, ci1, co1, 2, 0, 1,
            BookingStatus.CONFIRMED, price1, "Vui lòng chuẩn bị phòng hướng biển");
        b1 = bookingRepo.save(b1);
        b1.setBookingCode(bookingCode(b1.getId(), today));
        b1.setConfirmedAt(java.time.Instant.now());
        bookingRepo.save(b1);
        roomInventoryRepo.decrementInventory(stdTwin.getId(), ci1, co1, 1);

        // Booking 2: CANCELLED — DLX-KING, 3 nights, today+50
        java.time.LocalDate ci2 = today.plusDays(50);
        java.time.LocalDate co2 = ci2.plusDays(3);
        BigDecimal price2 = dlxKing.getPriceFrom()
            .multiply(BigDecimal.valueOf(3)).setScale(2, RoundingMode.HALF_UP);
        Booking b2 = buildBooking(demo, hotel, dlxKing, ci2, co2, 2, 1, 1,
            BookingStatus.CANCELLED, price2, null);
        b2 = bookingRepo.save(b2);
        b2.setBookingCode(bookingCode(b2.getId(), today));
        b2.setCancelledAt(java.time.Instant.now());
        bookingRepo.save(b2);
    }

    private Booking buildBooking(User user, Place hotel, HotelRoom room,
                                  java.time.LocalDate checkIn, java.time.LocalDate checkOut,
                                  int adults, int children, int numRooms,
                                  BookingStatus status, BigDecimal finalPrice, String specialRequest) {
        Booking b = new Booking();
        b.setUser(user);
        b.setHotel(hotel);
        b.setRoom(room);
        b.setCheckInDate(checkIn);
        b.setCheckOutDate(checkOut);
        b.setAdults(adults);
        b.setChildren(children);
        b.setNumberOfRooms(numRooms);
        b.setStatus(status);
        b.setCurrency("VND");
        b.setBasePrice(finalPrice);
        b.setDiscountAmount(BigDecimal.ZERO.setScale(2));
        b.setFinalPrice(finalPrice);
        b.setSpecialRequest(specialRequest);
        return b;
    }

    private String bookingCode(Long id, java.time.LocalDate date) {
        return "PYT-" + date.format(DateTimeFormatter.BASIC_ISO_DATE) + "-" + String.format("%06d", id);
    }

    // ─────────────────────────────────────────────────────────────
    // PAYMENTS — one PAID payment for the seeded CONFIRMED booking
    // ─────────────────────────────────────────────────────────────

    private void seedPayments() {
        if (paymentRepo.count() > 0) return;

        User demo = users.findByEmail("demo@planyourtrip.com").orElse(null);
        if (demo == null) return;

        Booking confirmed = bookingRepo.findByUserIdOrderByCreatedAtDesc(demo.getId())
            .stream()
            .filter(b -> b.getStatus() == BookingStatus.CONFIRMED)
            .findFirst().orElse(null);
        if (confirmed == null) return;

        java.time.LocalDate today = java.time.LocalDate.now();

        Payment p = new Payment();
        p.setBooking(confirmed);
        p.setAmount(confirmed.getFinalPrice());
        p.setCurrency(confirmed.getCurrency());
        p.setPaymentMethod(PaymentMethod.MOCK);
        p.setStatus(PaymentStatus.PAID);
        p.setProvider(PaymentProvider.MOCK);
        p.setProviderTransactionId("MOCK-TXN-SEED-" + confirmed.getId());
        p.setPaidAt(java.time.Instant.now());
        p = paymentRepo.save(p);
        p.setPaymentCode("PAY-" + today.format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", p.getId()));
        paymentRepo.save(p);
    }

    // ─────────────────────────────────────────────────────────────
    // NOTIFICATIONS — sample in-app notifications for demo users
    // ─────────────────────────────────────────────────────────────

    private void seedNotifications() {
        if (notificationRepo.count() > 0) return;

        User demo = users.findByEmail("demo@planyourtrip.com").orElse(null);
        if (demo == null) return;

        Booking confirmed = bookingRepo.findByUserIdOrderByCreatedAtDesc(demo.getId())
            .stream().filter(b -> b.getStatus() == BookingStatus.CONFIRMED).findFirst().orElse(null);

        if (confirmed != null) {
            notification(demo, "Booking confirmed",
                "Your booking " + confirmed.getBookingCode() + " has been confirmed.",
                NotificationType.BOOKING, Priority.NORMAL,
                RelatedEntityType.BOOKING, confirmed.getId(), true);

            Payment paid = paymentRepo.findByBookingIdOrderByCreatedAtDesc(confirmed.getId())
                .stream().filter(p -> p.getStatus() == PaymentStatus.PAID).findFirst().orElse(null);
            if (paid != null) {
                notification(demo, "Payment successful",
                    "Your payment for booking " + confirmed.getBookingCode() + " was successful.",
                    NotificationType.PAYMENT, Priority.HIGH,
                    RelatedEntityType.PAYMENT, paid.getId(), false);
            }
        }

        notification(demo, "Welcome to Plan Your Trip",
            "Thanks for joining! Explore hotels, cafes, and attractions across Vietnam.",
            NotificationType.SYSTEM, Priority.LOW, null, null, false);

        notification(demo, "Summer Sale is live",
            "Enjoy up to 10% off selected stays this summer.",
            NotificationType.PROMOTION, Priority.NORMAL, null, null, false);

        User partner = users.findByEmail("partner@planyourtrip.com").orElse(null);
        if (partner != null) {
            notification(partner, "New booking received",
                "You have a new booking request awaiting confirmation.",
                NotificationType.PARTNER, Priority.NORMAL, null, null, false);
        }
    }

    private void notification(User recipient, String title, String message,
                               NotificationType type, Priority priority,
                               RelatedEntityType relatedEntityType, Long relatedEntityId, boolean read) {
        Notification n = new Notification();
        n.setRecipientUser(recipient);
        n.setTitle(title);
        n.setMessage(message);
        n.setNotificationType(type);
        n.setPriority(priority);
        n.setRelatedEntityType(relatedEntityType);
        n.setRelatedEntityId(relatedEntityId);
        if (read) {
            n.setRead(true);
            n.setReadAt(java.time.Instant.now());
        }
        notificationRepo.save(n);
    }
}
