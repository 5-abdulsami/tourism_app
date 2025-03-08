import 'dart:convert';

class PlaceModel {
  final String placeId;
  final String name;
  final double? rating;
  final int? userRatingsTotal;
  final String? phoneNumber;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String>? photoReferences;
  final List<String>? types;
  final String? website;
  final String? url;
  final int? priceLevel;
  final bool? permanentlyClosed;
  final String? businessStatus;
  final List<Review>? reviews;
  final OpeningHours? openingHours;
  final String? editorialSummary;

  PlaceModel({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.phoneNumber,
    this.address,
    this.photoReferences,
    this.types,
    this.website,
    this.url,
    this.priceLevel,
    this.permanentlyClosed,
    this.businessStatus,
    this.reviews,
    this.openingHours,
    this.editorialSummary,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['place_id'],
      name: json['name'] ?? '',
      latitude: json['geometry']['location']['lat'],
      longitude: json['geometry']['location']['lng'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      phoneNumber: json['formatted_phone_number'],
      address: json['formatted_address'],
      website: json['website'],
      url: json['url'],
      priceLevel: json['price_level'],
      permanentlyClosed: json['permanently_closed'],
      businessStatus: json['business_status'],
      types: (json['types'] as List?)?.map((e) => e.toString()).toList(),
      photoReferences: (json['photos'] as List?)
          ?.map((e) => e['photo_reference'].toString())
          .toList(),
      editorialSummary: json['editorial_summary']?['overview'],
      openingHours: json['current_opening_hours'] != null
          ? OpeningHours.fromJson(json['current_opening_hours'])
          : null,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((review) => Review.fromJson(review))
              .toList()
          : [],
    );
  }
}

// Opening Hours Model
class OpeningHours {
  final bool openNow;
  final List<String>? weekdayText;

  OpeningHours({required this.openNow, this.weekdayText});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'] ?? false,
      weekdayText:
          (json['weekday_text'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

// Reviews Model
class Review {
  final String authorName;
  final double rating;
  final String text;
  final String? profilePhotoUrl;
  final int time;

  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    this.profilePhotoUrl,
    required this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'] ?? 'Anonymous',
      rating: json['rating']?.toDouble() ?? 0.0,
      text: json['text'] ?? '',
      profilePhotoUrl: json['profile_photo_url'],
      time: json['time'],
    );
  }
}
