import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tourism_app/models/place_model.dart';
import 'package:tourism_app/services/maps_services.dart';
import 'package:tourism_app/utils/colors.dart';
import 'package:tourism_app/view/detail_screen/detail_screen.dart';
import 'package:tourism_app/view/home_screen/widgets/custom_searchbar.dart';
import 'package:tourism_app/view/home_screen/widgets/duration_dropdown.dart';
import 'package:tourism_app/view/home_screen/widgets/place_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  List<PlaceModel> _places = [];
  bool _isLoading = true;
  String _selectedDuration = '2 Hours';
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndPlaces();
  }

  Future<void> _fetchLocationAndPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentPosition = await MapsService.getCurrentLocation();
      if (_currentPosition != null) {
        await _loadPlaces();
      } else {
        throw 'Unable to retrieve location.';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlaces() async {
    if (_currentPosition == null) return;

    try {
      final List<PlaceModel> places = _searchQuery.isNotEmpty
          ? await MapsService.searchPlaces(_searchQuery, _currentPosition!)
          : await MapsService.getNearbyPlaces(
              _currentPosition!, _selectedDuration);

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load places: $e';
        _isLoading = false;
      });
    }
  }

  void _onDurationChanged(String duration) {
    setState(() {
      _selectedDuration = duration;
    });
    _loadPlaces();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // Custom Gradient AppBar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [darkBlueColor, lightBlueColor],
              ),
            ),
            padding: EdgeInsets.only(
              left: size.width * 0.05,
              top: size.height * 0.045,
              bottom: size.height * 0.015,
            ),
            child: const Text(
              "Let's Explore",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Main Content with Background Gradient
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [darkBlueColor, lightBlueColor],
                ),
              ),
              child: Column(
                children: [
                  // Search Bar & Duration Dropdown
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.02,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(onSearch: _onSearch),
                        ),
                        SizedBox(width: size.height * 0.01),
                        DurationDropdown(
                          selectedDuration: _selectedDuration,
                          onChanged: _onDurationChanged,
                        ),
                      ],
                    ),
                  ),
                  // Display Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: whiteColor),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : _places.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No places found',
                                      style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.05),
                                    itemCount: _places.length,
                                    itemBuilder: (context, index) {
                                      final place = _places[index];

                                      // Check if the place has photos
                                      String imageUrl = place.photos != null &&
                                              place.photos!.isNotEmpty
                                          ? MapsService.getPhotoUrl(place
                                              .photos!.first.photoReference)
                                          : "https://tse4.mm.bing.net/th?id=OIP.EsYGO_6MShOkVMhbMe4KWwHaEQ&pid=Api&P=0&h=180";

                                      return PlaceCard(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailScreen(
                                                placeId: place.placeId,
                                              ),
                                            ),
                                          );
                                        },
                                        imageUrl: imageUrl,
                                        name: place.name,
                                        rating: place.rating ??
                                            0.0, // Default rating to 0.0 if null
                                        reviews: place.userRatingsTotal ??
                                            0, // Default to 0 if null
                                        profileImageUrl: place.photos != null &&
                                                place.photos!.isNotEmpty
                                            ? MapsService.getPhotoUrl(
                                                place.photos!.first
                                                    .photoReference,
                                                maxWidth: 100)
                                            : "https://hebbkx1anhila5yf.public.blob.vercel-storage.com/home-w9VNMtszvgQ27HzZ4RAesxZT804Edd.png",
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
