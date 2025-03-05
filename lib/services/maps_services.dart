import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:tourism_app/models/place_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../api_key.dart';

class DirectionsResult {
  final List<PointLatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  final int distanceValue;
  final int durationValue;

  DirectionsResult({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.distanceValue,
    required this.durationValue,
  });
}

class MapsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Get Directions (Updated)
  static Future<DirectionsResult?> getDirections(
      double startLat, double startLng, double endLat, double endLng) async {
    final url =
        '$_directionsUrl?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List?;

          if (legs == null || legs.isEmpty) {
            throw Exception('No route legs found.');
          }

          final leg = legs[0];
          final distance = leg['distance'];
          final duration = leg['duration'];

          if (distance == null || duration == null) {
            throw Exception('Invalid distance or duration data.');
          }

          // Decode polyline
          final polylinePoints = PolylinePoints()
              .decodePolyline(route['overview_polyline']['points']);

          return DirectionsResult(
            polylinePoints: polylinePoints,
            distanceText: distance['text'],
            durationText: duration['text'],
            distanceValue: distance['value'],
            durationValue: duration['value'],
          );
        }
      }
    } catch (e) {
      log('Error fetching directions: $e');
    }
    return null;
  }

  // Get current location with permission handling
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
              'Location permissions denied. Enable them in settings.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      log('Error fetching location: $e');
      return null;
    }
  }

  // Search for places based on query
  static Future<List<PlaceModel>> searchPlaces(
      String query, Position position) async {
    final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=$query&location=${position.latitude},${position.longitude}&radius=50000&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          throw Exception('No places found.');
        }
        return results.map((place) => PlaceModel.fromJson(place)).toList();
      } else {
        throw Exception('Failed to search places: ${response.body}');
      }
    } catch (e) {
      log('Error searching places: $e');
      return [];
    }
  }

  // Get nearby places based on duration selection
  static Future<List<PlaceModel>> getNearbyPlaces(
      Position position, String duration) async {
    int radius = _getRadiusFromDuration(duration);
    if (radius == -1) return await getDistantPlaces(position);

    final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?location=${position.latitude},${position.longitude}&radius=$radius&type=tourist_attraction&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("------------------API response in getNearbyPlaces :");
        log(response.body);
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          throw Exception('No nearby places found.');
        }

        List<PlaceModel> places =
            results.map((place) => PlaceModel.fromJson(place)).toList();
        return await _fetchDetailedPlaces(places);
      } else {
        throw Exception('Failed to fetch nearby places: ${response.body}');
      }
    } catch (e) {
      log('Error getting nearby places: $e');
      return [];
    }
  }

  // Get places in different cities for multi-day trips
  static Future<List<PlaceModel>> getDistantPlaces(Position position) async {
    final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=cities&location=${position.latitude},${position.longitude}&radius=300000&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results == null || results.isEmpty) {
          throw Exception('No distant cities found.');
        }

        List<dynamic> distantCities = results.where((city) {
          double lat = city['geometry']['location']['lat'];
          double lng = city['geometry']['location']['lng'];
          double distance = Geolocator.distanceBetween(
                  position.latitude, position.longitude, lat, lng) /
              1000;
          return distance > 50;
        }).toList();

        return await _fetchAttractionsFromCities(
            distantCities.take(3).toList());
      } else {
        throw Exception('Failed to get distant places: ${response.body}');
      }
    } catch (e) {
      log('Error fetching distant places: $e');
      return [];
    }
  }

  // Get place details including photos, reviews, etc.
  static Future<PlaceModel> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&fields=name,rating,formatted_phone_number,formatted_address,geometry,photo,review,url,website,price_level,opening_hours&key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log("-------------------------------");
        log(response.body);
        return PlaceModel.fromJson(data['result']);
      } else {
        throw Exception('Failed to fetch place details: ${response.body}');
      }
    } catch (e) {
      log('Error fetching place details: $e');
      throw Exception('Error fetching place details');
    }
  }

  // Helper method to get radius from duration
  static int _getRadiusFromDuration(String duration) {
    switch (duration) {
      case '2 Hours':
      case '4 Hours':
        return 15000;
      case '8 Hours':
      case '12 Hours':
        return 35000;
      case '1 Day':
        return 50000;
      case '2 Day':
      case '3 Day':
      case '5 Day':
        return -1; // Indicates multi-day trip
      default:
        return 20000;
    }
  }

  // Fetch detailed place information
  static Future<List<PlaceModel>> _fetchDetailedPlaces(
      List<PlaceModel> places) async {
    List<PlaceModel> detailedPlaces = [];
    for (var place in places) {
      try {
        final details = await getPlaceDetails(place.placeId);
        detailedPlaces.add(details);
      } catch (e) {
        debugPrint('Error getting details for ${place.name}: $e');
        detailedPlaces.add(place);
      }
    }
    return detailedPlaces;
  }

  // Fetch attractions from cities
  static Future<List<PlaceModel>> _fetchAttractionsFromCities(
      List<dynamic> cities) async {
    List<PlaceModel> allPlaces = [];
    for (var city in cities) {
      double lat = city['geometry']['location']['lat'];
      double lng = city['geometry']['location']['lng'];
      final url = Uri.parse(
          '$_baseUrl/nearbysearch/json?location=$lat,$lng&radius=20000&type=tourist_attraction&key=$apiKey');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;
          allPlaces.addAll(results.map((place) => PlaceModel.fromJson(place)));
        }
      } catch (e) {
        log('Error fetching attractions: $e');
      }
    }
    return await _fetchDetailedPlaces(allPlaces.take(10).toList());
  }

  // Get photo URL from photo reference
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    if (photoReference.isEmpty) {
      throw Exception('Photo reference is empty.');
    }
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$apiKey';
  }
}

// get place details method return : 
// {
//          "html_attributions" : [],
//          "result" : 
//          {
//             "formatted_address" : "H3P3+MMF, Iftikhar Janjua Road, Rawalpindi, 46000, Pakistan",
//             "formatted_phone_number" : "(051) 5147630",
//             "geometry" : 
//             {
//                "location" : 
//                {
//                   "lat" : 33.586685,
//                   "lng" : 73.0541679
//                },
//                "viewport" : 
//                {
//                   "northeast" : 
//                   {
//                      "lat" : 33.5877436302915,
//                      "lng" : 73.0560943802915
//                   },
//                   "southwest" : 
//                   {
//                      "lat" : 33.5850456697085,
//                      "lng" : 73.05339641970849
//                   }
//                }
//             },
//             "name" : "Army Museum",
//             "opening_hours" : 
//             {
//                "open_now" : false,
//                "periods" : 
//                [
//                   {
//                      "close" : 
//                      {
//                         "day" : 0,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 0,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 1,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 1,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 2,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 2,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 3,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 3,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 4,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 4,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 5,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 5,
//                         "time" : "0900"
//                      }
//                   },
//                   {
//                      "close" : 
//                      {
//                         "day" : 6,
//                         "time" : "1500"
//                      },
//                      "open" : 
//                      {
//                         "day" : 6,
//                         "time" : "0900"
//                      }
//                   }
//                ],
//                "weekday_text" : 
//                [
//                   "Monday: 9:00 AM – 3:00 PM",
//                   "Tuesday: 9:00 AM – 3:00 PM",
//                   "Wednesday: 9:00 AM – 3:00 PM",
//                   "Thursday: 9:00 AM – 3:00 PM",
//                   "Friday: 9:00 AM – 3:00 PM",
//                   "Saturday: 9:00 AM – 3:00 PM",
//                   "Sunday: 9:00 AM – 3:00 PM"
//                ]
//             },
//             "photos" : 
//             [
//                {
//                   "height" : 3024,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/104252660977178010623\"\u003eMaha Khan\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ0XdrV96phTDjbi-KSLKQqS9QojiiHsWssXmuN2wcKmfewf_17m3ga569eP1TIeJRsiow9hj6nNIna54PKnaeLLKb-rUsuOGe-UZpeZf15vglLHD8_Nh2jLSpQ1jN5LDuzMqGDRM3fl2BWPDFKK0YJdUPRK-Mq3AatJ9DyZk2AOsNF_sgApM9xwDF2aHYP-Df6zGXdvrHQMFOuGHGSWLDtbbPk78zvtwtXKj68HuzQvk8G10Gq9LjSnhvwQU6R51Hc7USeI9A6tqpNfgjguTo2gqItS4eRUCjHnJ5dLPP5UapbmgH-FHdylu283eK_nfd3HHs8gY83sM_BpEqldmNTIARrESbojI3svowDUJjIRxbVr1CJpmRS61uxMgOA_i-gD8b08NO0XZfiOLJA1YajNbuz24CVKb0LNyEk8haAtKg",
//                   "width" : 4032
//                },
//                {
//                   "height" : 3456,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/104072400450352141103\"\u003eMuhammad amir\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ2BBaE7LUgxYx8LfqQtfzB-rlGfHycs1TRJhLagu3da227OaebZK2OMiw1c6NlmLPvWZP50lAQAIZ4soRUrJCW5VyQnPtI14genJHzrVvEnc5MSWw5QexZSSj3NKG06wmvdRHBHxEfW8G7Bzttz7KK_wU6wz9cQF1w5ez-HmhPoJ9o9YLm-NaO0W1e6Fc7LuQlDo9EvEWDyDKnbQAegBiGra095Ae_Bv5JSIfsjdNND_6uWB5WeIHFcDhz244a6ogoLczmvGO5Sy6HjO6spwQsC_S44fjfxbwq2IlbKuKM2xKOWGk2-KciJhrjUqtSNrJIjtZ231ovrlpA099ZlWy2erJDeWYLescThKD252cEiQuWtJE_j0K68fdmkbzlo-GDfwKs8_J7bo6TNWCeJNMb3jZNKECdHZofJAxTSZsrbvSi_",
//                   "width" : 4608
//                },
//                {
//                   "height" : 4608,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/108099221735983949874\"\u003eKamaal Khan\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ1nXJCYIV3Rix58YcAccZx9713xc0YqqoK8FpIbGAVSuvC5UIbDPqGj9rm-UgzXieKZqXdGSy1leYgvODI_ZIMcoWhn97lGDT3BSWL0jFBQGeBZRo1NfqNJ9ZJ9Hz2ZmWK7Q5XxQ8cuGo5neO9sAHhlDHA9PGtJ-Tm2mWLrFAjVWWWYCTGTNTJa7Tx3VjGK06OG6ejraeTn7-gUDZiGPo4SJSL1GgcrCfuYYAQfsOuex3oT-5rqILDrRtPuDW4nY4xsZMsCpc9HIIQ4TVq-EVTi9QggCZ8qXbZrcaGXwPP6KpNJb8GfcPwppjs88MN8W4tyXqpeLruI9LPbvGdOzsZTN4ZznIJgwKo0k2vfB0-KbUc7Cg64ozapnY7OhejL4SlzH3ObagIBes_r73KJ8dl6sRkMelXxcnhBnFuIm85s",
//                   "width" : 2592
//                },
//                {
//                   "height" : 3456,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/113636837583109717542\"\u003eZagham Awan\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3QScYS30TfB0fTrcetMP-Dq0P8GU4UR6unkCp_hISLBGCaBmT3OkJ2U_-BjbF4TBGWASgMjWu6WdI3XO7255RiAUI0_hb6SHAKcN2Xkt8XmP0AOz1OGBTr1XSQFG6-kzpt4U4Omj8INmNuKHeP-ANKtlcW-_Aw6uLcuCrcpSjRm-uQga8-Y565-mGqYIOvKjBPILV0o7EVlzC68RJ90ce7NpMg5rILOmFN-IJDLRRZH5QQukvXJdA-Z-aIPqmcX-Qno-BH_ySD3CkAcathdlMSYJl_10ScmjKMc0tFUBZm-Qb5_t-XA1Wnh7CUCihsP1WlcsSEWwb141fq9MbvqDuI0q1LxHrMY4qptJHRb6pl7VJyMhZecqBZZb5GmTwojckWAF6lhDs3O8jD6nQrzwrtzjAPYRlJn6ezrhJjBZovENtD",
//                   "width" : 4608
//                },
//                {
//                   "height" : 4608,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/117121183575092561019\"\u003eHishaam Bin Masood\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3St1eTHzcs78jvSodZzLOq4_kNC3wFIxtAFrUu1vuvrwOzlQI2xg60JFMnhPNaxr-mjbkHW4ZmESQ8Fumh2h9SQdyPZ9sLb7QeqbUYiE5YD_MCuZ58B3zDEs_ZbmxO1UAP_UZnM0wXJwZE91YYSPR-Sisu7C3BKgxcWcvxebaRC3TwV6pqVzkuXlQ8Col8xnu8qo0N8J7bMz7BLKIR5Uth-5aqb5f5TC0AWdLAICvTKANGiaTSGe5_c6I4cMUAj-ErH-KcHfmeKJd0RLzytDHHPDCl0KI_8XxR1VHekJz64gpiovXEM9TZrtyszDqFSiMxbGYzbBogLKuHlpwYWrsSQ2J3yRE1T3C6tGoaBVs4jseRNa7w_T4y9Cfs1F_o53ruh0gnwZCGIhxTlNZVsXnv3PRa3tm7pXWUt-uaK4U",
//                   "width" : 3456
//                },
//                {
//                   "height" : 12288,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/106079426149722605366\"\u003eZikriya Habib\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3_L0ZEHpc-DDKo4OZUDLCVKwJ6ZtV_DM_TR3nsDZrAs_vksiwuf_fj48cQe_bgHFiK8M9gAwOE8aRkKSyaGxrktiozyEAc8w9d4yIWqdb23Vs7ZLltTOFetZt_pTEpM62D1cwudD1vHMN3m1QwEIJmSqK4u6Ea7K0elo5JH86dCBWPJY7OfIVBy-ZHlnNHfgz2pV5STo4ic3oMtc-1cmrS-P2zebo_wSsUh_qL6jbURvhXStZcDV0wfhQ4UIhBRPO4IFi17kss3W3gnP3dXctbWT0aEMAO4Rb-TjB7jPWudZSxyet_4vHASn3m5ERe0gwSvKtHwj9kqvTBwub2SZz1CTHypPsVlSTrlOW0Y5UxQvueiU2SzIuvP9U9GafkWrlF0njxrEMLbAttjuFBg8h4179LrkBzNu2lk7W-pw4",
//                   "width" : 16320
//                },
//                {
//                   "height" : 480,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/117533726976349409029\"\u003eMuhammad Usama\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3-6NLZ7KdqIv0KFESiFY9Ge9HMx_tJtQjzmRS12uRm96lTVNanWuR2MTbs1CXyUK3wFWvkU4OZEsQmiOP6EVK9hmsPrCilRfclbr0rs1qVgawpKRy7UeXim3eJRyp7dPfW5o6hkW-dPYGhVEgCkkhaygZvAI6Wmv-lVhzzKcdJZvw7CAK-idcMnxxAAlhjYwVlcN92gY9kJ6QoKKgVUiTSk2LoTVET3HJCEFjlOS_1GpOX7nUUbV8SDQcNy0mjSjQ71zQDYa_yC8H4VzdUGPBn_o-2iJf41gRK05iOCmjXEXPrk4YCs87xYv1fZOffx20D8z6ulQKdSJK3fFqagScQB9OZVnYBysYLJBypHbrIIc8piJWmHkEhFtkDE-iFFEJFv7rcvZ8GfjcJaNfuFx0PrZJJBN3kQ4mPYNN_9TO4",
//                   "width" : 640
//                },
//                {
//                   "height" : 4608,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/109032242054521197831\"\u003eMedia Light Production Film Street Production\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3Zy4vZqFuDwmknjEXBncB-pba--lr6UiSj1fGKC9xQ-3kg60X9pgo9AFM4q2p8LOegKHuEjEjl9OZhuz8dLIuYsELU_2wSx05CYPndIc6XjLbVOKTrP2e2CAvJ-Wbzc3b__V22HFXl0_AOo1eraFt_WgXLiVhrxgSwpuxn6BsIaXeU4i2-ln0WH6qDeUq4J7jrjE07OBtnpeQOksGPvLAc-dicVnbLMYEtbdtniy4tRS6zuF3CW3zzNICcLNpDHxZDQq8iTHrppW7r5-WVcZtu9qtKDUQBT5DlUjIkL7tJZmfcbjwaQ-OYC5WOeWXDQkRe6wANgABAhsPqPyBqiXXywza0HaWPELKloiitWZArUsAAtPPv55v1Wvn0KRIYjQ8Zhx6BbJ0v602FU2KaOH1EepRzJ-mDQGptEHB21Fz4",
//                   "width" : 3456
//                },
//                {
//                   "height" : 3120,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/115123450497692597621\"\u003eAbdul Rahman Khan\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ1vFBVscQicPs54MQJ22ZnjoaoOuc2JVZbceFHkDDAiJ-s2ZWmAnpBy8jmEUrz86aidLU3P_cwBjQ1GEGklogZ8OtN07PxcXNPGvIXsqpolP8WWNc81pamYli_risidxGlXAOt-U1NXMJwypgxwYUU1_Qgmsc9Ez36adba9GFy_XuS8OuPg0ndl7pga9E2DjaUfa7a7Ioe-L_BhLKLXxPKcy-jN31z4XAkTjBweq7004QirbGudorYGPFtNf38BL2jMi3_tsE2iFIBracdUaOTU1fd6KxMI-Qy9PGfKXmTWsgEmHYThwGp89zY26rqhmUbK4hz1LJ-7bX6vLdltIKvshnRVnITVBGNsbahAvfmrtXYs1ElySAJG50wXSl_Xr0ONI4V4198KRv8Vhim4gSonIdz3dJbW1iA7SuOvCmjDjm4C",
//                   "width" : 4160
//                },
//                {
//                   "height" : 4160,
//                   "html_attributions" : 
//                   [
//                      "\u003ca href=\"https://maps.google.com/maps/contrib/108938086117922397731\"\u003eQamar Mahmood\u003c/a\u003e"
//                   ],
//                   "photo_reference" : "AUy1YQ3ApCCbkq7OxpXEomB0EFut6lvIzbgofhRWlg-ILpClLAdIp6w5suvkMUdtumuLFbMEuo6HOUnShpvChBFFJGxyoBgwQKn1hZoOB4flQBe_bmC4eTu9c-iTBPzro8nVxjWHmrOX4TQSsxTILZ1ViGWcdBoaVfxrJm_qeZTWaL2rI0pvjnhl54NKlYehgW3kWndufvcPVX8O3yQlbCmVUzkfopTvKVqme3kVZoBnWp145Z-XtL3MuF45r73nY6s9Sg_uqvA3MkIrX06Ox2cGhLcGuAQ2xWTZL3LOKy2-VgiohBhdpYhMQ0TVYf1sV5I7zfUhN2W1qD6ccprGS7_FYk-AjaF6tPybg2q6VvdhtX6VoqbxMMXSbuM8MNhir0CjQZqB9DIYvb-M1Y4FCfYIYA_uWLFWwCcyPZONlKLqaILC2Q",
//                   "width" : 3120
//                }
//             ],
//             "rating" : 4.7,
//             "reviews" : 
//             [
//                {
//                   "author_name" : "Zohaib Altaf",
//                   "author_url" : "https://www.google.com/maps/contrib/108360452426276694361/reviews",
//                   "language" : "en",
//                   "original_language" : "en",
//                   "profile_photo_url" : "https://lh3.googleusercontent.com/a-/ALV-UjXT1j2q1bAX5zpaxme-BnFMajK7BwxFt2LgRtPCfRCMjArKXvzc=s128-c0x00000000-cc-rp-mo-ba3",
//                   "rating" : 5,
//                   "relative_time_description" : "2 months ago",
//                   "text" : "The Pakistan Army Museum is a must-visit for anyone interested in history and patriotism. It beautifully showcases Pakistan’s military journey since independence, with an impressive collection of artifacts, from military vehicles and weapons to personal belongings of shuhada (martyrs). Each exhibit tells a powerful story of courage and sacrifice.\n\nThe museum is vast, and a full visit can take 3 to 4 hours, but it’s worth every moment. Guided tours by knowledgeable staff make the experience even more enriching, bringing history to life with detailed explanations.\n\nFrom tanks and fighter planes to indoor displays filled with historical treasures, the museum offers something for everyone. It’s an inspiring and humbling tribute to our armed forces. Highly recommended!",
//                   "time" : 1735214544,
//                   "translated" : false
//                },
//                {
//                   "author_name" : "Saima Hussain",
//                   "author_url" : "https://www.google.com/maps/contrib/115017227403876195262/reviews",
//                   "language" : "en",
//                   "original_language" : "en",
//                   "profile_photo_url" : "https://lh3.googleusercontent.com/a-/ALV-UjXehiI2l8ien760BZRk_KVmezZ3cl0bmBTF4v6ykUkcfM-q8NlMGA=s128-c0x00000000-cc-rp-mo",
//                   "rating" : 5,
//                   "relative_time_description" : "3 weeks ago",
//                   "text" : "Had really good time while i visited with my family last year. If you kids are interesting in heavy weapons and missile, thn this is the best place to take them in.",
//                   "time" : 1738927463,
//                   "translated" : false
//                },
//                {
//                   "author_name" : "Muhammad Alfahad",
//                   "author_url" : "https://www.google.com/maps/contrib/114728700052248036934/reviews",
//                   "language" : "en",
//                   "original_language" : "en",
//                   "profile_photo_url" : "https://lh3.googleusercontent.com/a-/ALV-UjXCSd0GjKEwnQzND4e3_Vv35D6TnzD1mpKwP9GYt_CotqofPTir=s128-c0x00000000-cc-rp-mo-ba4",
//                   "rating" : 5,
//                   "relative_time_description" : "8 months ago",
//                   "text" : "**Discover the Rich Military Heritage at the Army Museum Rawalpindi**\n\nAre you a history enthusiast or simply curious about the military legacy of Pakistan? The Army Museum in Rawalpindi is a must-visit destination that offers a deep dive into the illustrious history of the Pakistan Army.\n\nEstablished in 1961, this museum stands as a testament to the bravery and sacrifices of the Pakistani armed forces. As you step inside, prepare to be captivated by a vast collection of military artifacts, including an impressive array of weapons, uniforms, medals, and vehicles that span decades of Pakistan’s military history.\n\n**What to Expect:**\n\n1. **Historical Artifacts:**\nThe museum boasts an extensive collection of items used in various wars and operations. From vintage rifles and cannons to modern weaponry, the exhibits provide a comprehensive overview of the evolution of military technology.\n\n2. **Uniforms and Medals:**\nMarvel at the meticulously preserved uniforms of soldiers from different eras. The medal section showcases the highest honors awarded for acts of valor and distinguished service.\n\n3. **Vehicles and Equipment:**\nThe outdoor display area features an array of military vehicles, including tanks, armored personnel carriers, and aircraft, offering a tangible glimpse into the mechanized might of the Pakistan Army.\n\n4. **Educational Exhibits:**\nLearn about key historical events and battles through detailed exhibits and interactive displays. The museum highlights significant campaigns and the strategic prowess that has shaped the nation's history.\n\n5. **Tributes to Heroes:**\nPay your respects at the dedicated sections honoring the heroes who have laid down their lives in service to the nation. Their stories of courage and sacrifice are both humbling and inspiring.\n\n**Plan Your Visit:**\n\nTo fully appreciate the wealth of information and exhibits, it is recommended to allocate at least 5 hours for your visit. This allows ample time to explore the museum's extensive collections and delve into the rich history of the Pakistan Army.\n\nWhether you are a local resident or a tourist, the Army Museum Rawalpindi offers a unique and educational experience that showcases the valor and dedication of Pakistan's armed forces. Don’t miss the opportunity to connect with the past and gain a deeper understanding of the sacrifices made to safeguard the nation.\n\nFeel free to visit the Army Museum and immerse yourself in the proud military heritage of Pakistan. I really recommend it.",
//                   "time" : 1719819803,
//                   "translated" : false
//                },
//                {
//                   "author_name" : "Anwar Aziz Chandio",
//                   "author_url" : "https://www.google.com/maps/contrib/113347516559791761615/reviews",
//                   "language" : "en",
//                   "original_language" : "en",
//                   "profile_photo_url" : "https://lh3.googleusercontent.com/a-/ALV-UjVdpw84c-JgivxpIRj6b6OPAx_3PW2ng6CU59Qxs-Hh37nD9c0j=s128-c0x00000000-cc-rp-mo-ba7",
//                   "rating" : 5,
//                   "relative_time_description" : "7 months ago",
//                   "text" : "A very beautiful and well equipped museum at Rawalpindi... I qhve visited first time... Like it's location and beauty.",
//                   "time" : 1722679971,
//                   "translated" : false
//                },
//                {
//                   "author_name" : "Honey Malik",
//                   "author_url" : "https://www.google.com/maps/contrib/115783422585592645869/reviews",
//                   "language" : "en",
//                   "original_language" : "en",
//                   "profile_photo_url" : "https://lh3.googleusercontent.com/a-/ALV-UjUcSP4kNjyDYqyCON8vX72DfA4AkP2Q64QC2LXPKchDN52gCr0P=s128-c0x00000000-cc-rp-mo-ba3",
//                   "rating" : 5,
//                   "relative_time_description" : "2 weeks ago",
//                   "text" : "Very informative place we learned about our Heroes sacrifices And military equipment",
//                   "time" : 1739783976,
//                   "translated" : false
//                }
//             ],
//             "url" : "https://maps.google.com/?cid=4332330638883057311"
//          },
//          "status" : "OK"
//       }     