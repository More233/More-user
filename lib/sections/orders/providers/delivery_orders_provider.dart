import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_address_model.dart';
import '../models/delivery_banner_model.dart';
import '../models/delivery_region_model.dart';
import '../services/delivery_address_service.dart';

/// Realtime stream of active delivery regions from Supabase
final activeRegionsStreamProvider = StreamProvider<List<DeliveryRegionModel>>((ref) {
  final client = Supabase.instance.client;
  return client
      .from('delivery_regions')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final list = rows
            .map((m) => DeliveryRegionModel.fromMap(m))
            .where((r) => r.isActive)
            .toList();
        list.sort((a, b) => a.name.compareTo(b.name));
        return list;
      });
});

/// StateNotifier for the currently selected delivery address
class CurrentAddressNotifier extends StateNotifier<DeliveryAddressModel?> {
  CurrentAddressNotifier() : super(DeliveryAddressService.instance.currentAddress.value) {
    DeliveryAddressService.instance.currentAddress.addListener(_syncFromService);
  }

  void _syncFromService() {
    state = DeliveryAddressService.instance.currentAddress.value;
  }

  void setAddress(DeliveryAddressModel address) {
    DeliveryAddressService.instance.saveAddress(address);
    state = address;
  }

  @override
  void dispose() {
    DeliveryAddressService.instance.currentAddress.removeListener(_syncFromService);
    super.dispose();
  }
}

final currentAddressProvider =
    StateNotifierProvider<CurrentAddressNotifier, DeliveryAddressModel?>((ref) {
  return CurrentAddressNotifier();
});

/// StateNotifier for saved delivery addresses list
class SavedAddressesNotifier extends StateNotifier<List<DeliveryAddressModel>> {
  SavedAddressesNotifier() : super(DeliveryAddressService.instance.savedAddresses.value) {
    DeliveryAddressService.instance.savedAddresses.addListener(_syncFromService);
  }

  void _syncFromService() {
    state = List.from(DeliveryAddressService.instance.savedAddresses.value);
  }

  @override
  void dispose() {
    DeliveryAddressService.instance.savedAddresses.removeListener(_syncFromService);
    super.dispose();
  }
}

final savedAddressesProvider =
    StateNotifierProvider<SavedAddressesNotifier, List<DeliveryAddressModel>>((ref) {
  return SavedAddressesNotifier();
});

/// Dynamic coverage status checking current coordinates against active Supabase regions
final isCoveredProvider = Provider<bool>((ref) {
  final address = ref.watch(currentAddressProvider);
  if (address == null) return false;

  final regionsAsync = ref.watch(activeRegionsStreamProvider);
  final regions = regionsAsync.value ?? [];

  if (regions.isEmpty) {
    return address.isCovered;
  }

  for (final reg in regions) {
    final dist = DeliveryAddressService.calculateDistanceInKm(
      address.latitude,
      address.longitude,
      reg.latitude,
      reg.longitude,
    );
    if (dist <= reg.radiusKm) {
      return true;
    }
  }
  return false;
});

/// Realtime stream of promotional banners filtered by active state and matched region
final deliveryBannersStreamProvider = StreamProvider<List<DeliveryBannerModel>>((ref) {
  final currentAddress = ref.watch(currentAddressProvider);
  final client = Supabase.instance.client;

  return client
      .from('delivery_banners')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final regionId = currentAddress?.regionId;
        final activeList = rows
            .map((m) => DeliveryBannerModel.fromMap(m))
            .where((b) => b.isActive)
            .toList();

        if (regionId != null && regionId.isNotEmpty) {
          final matched = activeList.where((b) => b.regionId == regionId).toList();
          if (matched.isNotEmpty) {
            matched.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            return matched;
          }
        }

        activeList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return activeList;
      });
});

/// Carousel page index provider (eliminates any need for setState)
final bannerCarouselIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
