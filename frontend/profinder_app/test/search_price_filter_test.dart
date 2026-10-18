// Normal Search price filter: an ordinary search must not carry an invisible
// maximum price; only a maximum the user deliberately set is sent.

import 'package:flutter_test/flutter_test.dart';
import 'package:profinder_app/core/constants/app_constants.dart';
import 'package:profinder_app/services/home_service.dart';

void main() {
  // The Search screen starts with its slider thumb at kPriceSliderMax and
  // passes it through maxPriceForRequest() before calling the service.
  String urlFor({required double sliderMax, double sliderMin = 0, String q = 'doctor'}) =>
      HomeService.buildNearbyUrl(
        query:    q,
        minPrice: sliderMin,
        maxPrice: maxPriceForRequest(sliderMax),
      );

  test('default slider (untouched): no max_price is sent', () {
    final url = urlFor(sliderMax: kPriceSliderMax);
    expect(url, '${AppConstants.nearby}?q=doctor');
    expect(url, isNot(contains('max_price')));
  });

  test('slider end means "no limit": maxPriceForRequest returns the sentinel', () {
    expect(maxPriceForRequest(kPriceSliderMax), kNoMaxPrice);
    expect(maxPriceForRequest(kPriceSliderMax + 500), kNoMaxPrice);
  });

  test('explicitly selected maximum is still sent', () {
    expect(urlFor(sliderMax: 800), contains('max_price=800.0'));
    expect(urlFor(sliderMax: 50),  contains('max_price=50.0'));
    // just below the slider end is a deliberate choice, not "no limit"
    expect(urlFor(sliderMax: 950), contains('max_price=950.0'));
  });

  test('explicit minimum is still sent, independently of the maximum', () {
    final url = urlFor(sliderMin: 200, sliderMax: kPriceSliderMax);
    expect(url, contains('min_price=200.0'));
    expect(url, isNot(contains('max_price')));
  });

  test('both bounds chosen are both sent', () {
    final url = urlFor(sliderMin: 100, sliderMax: 600);
    expect(url, contains('min_price=100.0'));
    expect(url, contains('max_price=600.0'));
  });

  test('callers that pass no price (home feed, category search) send none', () {
    expect(HomeService.buildNearbyUrl(categoryId: 3),
        '${AppConstants.nearby}?category_id=3');
    expect(HomeService.buildNearbyUrl(), AppConstants.nearby);
  });
}
