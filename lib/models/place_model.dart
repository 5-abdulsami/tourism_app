class PlaceModel {
  final String name;
  final String? businessStatus;
  final Geometry geometry;
  final String? icon;
  final String? iconBackgroundColor;
  final String? iconMaskBaseUri;
  final OpeningHours? openingHours;
  final List<Photo>? photos;
  final String placeId;
  final PlusCode? plusCode;
  final double? rating;
  final String reference;
  final String scope;
  final List<String> types;
  final int? userRatingsTotal;
  final String vicinity;

  PlaceModel({
    required this.name,
    this.businessStatus,
    required this.geometry,
    this.icon,
    this.iconBackgroundColor,
    this.iconMaskBaseUri,
    this.openingHours,
    this.photos,
    required this.placeId,
    this.plusCode,
    this.rating,
    required this.reference,
    required this.scope,
    required this.types,
    this.userRatingsTotal,
    required this.vicinity,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      name: json['name'],
      businessStatus: json['business_status'],
      geometry: Geometry.fromJson(json['geometry']),
      icon: json['icon'],
      iconBackgroundColor: json['icon_background_color'],
      iconMaskBaseUri: json['icon_mask_base_uri'],
      openingHours: json['opening_hours'] != null
          ? OpeningHours.fromJson(json['opening_hours'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((e) => Photo.fromJson(e)).toList()
          : null,
      placeId: json['place_id'],
      plusCode: json['plus_code'] != null
          ? PlusCode.fromJson(json['plus_code'])
          : null,
      rating: (json['rating'] != null) ? json['rating'].toDouble() : null,
      reference: json['reference'],
      scope: json['scope'],
      types: List<String>.from(json['types']),
      userRatingsTotal: json['user_ratings_total'],
      vicinity: json['vicinity'],
    );
  }
}

class Geometry {
  final Location location;
  final Viewport viewport;

  Geometry({required this.location, required this.viewport});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location: Location.fromJson(json['location']),
      viewport: Viewport.fromJson(json['viewport']),
    );
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }
}

class Viewport {
  final Location northeast;
  final Location southwest;

  Viewport({required this.northeast, required this.southwest});

  factory Viewport.fromJson(Map<String, dynamic> json) {
    return Viewport(
      northeast: Location.fromJson(json['northeast']),
      southwest: Location.fromJson(json['southwest']),
    );
  }
}

class OpeningHours {
  final bool openNow;

  OpeningHours({required this.openNow});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['open_now'],
    );
  }
}

class Photo {
  final int height;
  final int width;
  final List<String> htmlAttributions;
  final String photoReference;

  Photo({
    required this.height,
    required this.width,
    required this.htmlAttributions,
    required this.photoReference,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      height: json['height'],
      width: json['width'],
      htmlAttributions:
          List<String>.from(json['html_attributions'].map((e) => e.toString())),
      photoReference: json['photo_reference'],
    );
  }
}

class PlusCode {
  final String compoundCode;
  final String globalCode;

  PlusCode({required this.compoundCode, required this.globalCode});

  factory PlusCode.fromJson(Map<String, dynamic> json) {
    return PlusCode(
      compoundCode: json['compound_code'],
      globalCode: json['global_code'],
    );
  }
}
