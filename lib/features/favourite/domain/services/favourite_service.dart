import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/favourite/domain/repositories/favourite_repository_interface.dart';
import 'package:sixam_mart/features/favourite/domain/services/favourite_service_interface.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class FavouriteService implements FavouriteServiceInterface {
  final FavouriteRepositoryInterface favouriteRepositoryInterface;
  FavouriteService({required this.favouriteRepositoryInterface});

  @override
  Future<Response> getFavouriteList() async {
    return await favouriteRepositoryInterface.getList();
  }

  @override
  Future<ResponseModel> addFavouriteList(int? id, bool isStore) async {
    return await favouriteRepositoryInterface.add(null, isStore: isStore, id: id);
  }

  @override
  Future<ResponseModel> removeFavouriteList(int? id, bool isStore) async {
    return await favouriteRepositoryInterface.delete(id, isStore: isStore);
  }

  @override
  List<Item?> wishItemList(Item item) {
    List<Item?> wishItemList = [];

    final userAddress = AddressHelper.getUserAddressFromSharedPref();
    if (userAddress == null || userAddress.zoneData == null) return wishItemList;

    for (var zone in userAddress.zoneData!) {
      if (zone.modules == null) continue;

      for (var module in zone.modules!) {
        if (module.id == item.moduleId && module.pivot != null) {
          if (module.pivot!.zoneId == item.zoneId) {
            wishItemList.add(item);
          }
        }
      }
    }
    return wishItemList;
  }

  @override
  List<int?> wishItemIdList(Item item) {
    List<int?> wishItemIdList = [];

    final userAddress = AddressHelper.getUserAddressFromSharedPref();
    if (userAddress == null || userAddress.zoneData == null) return wishItemIdList;

    for (var zone in userAddress.zoneData!) {
      if (zone.modules == null) continue;

      for (var module in zone.modules!) {
        if (module.id == item.moduleId && module.pivot != null) {
          if (module.pivot!.zoneId == item.zoneId) {
            wishItemIdList.add(item.id);
          }
        }
      }
    }
    return wishItemIdList;
  }

  @override
  List<Store?> wishStoreList(dynamic store) {
    List<Store?> wishStoreList = [];

    final parsed = Store.fromJson(store);

    final userAddress = AddressHelper.getUserAddressFromSharedPref();
    if (userAddress == null || userAddress.zoneData == null) return wishStoreList;

    for (var zone in userAddress.zoneData!) {
      if (zone.modules == null) continue;

      for (var module in zone.modules!) {
        if (module.id == parsed.moduleId && module.pivot != null) {
          if (module.pivot!.zoneId == parsed.zoneId) {
            wishStoreList.add(parsed);
          }
        }
      }
    }
    return wishStoreList;
  }

  @override
  List<int?> wishStoreIdList(dynamic store) {
    List<int?> wishStoreIdList = [];

    final parsed = Store.fromJson(store);

    final userAddress = AddressHelper.getUserAddressFromSharedPref();
    if (userAddress == null || userAddress.zoneData == null) return wishStoreIdList;

    for (var zone in userAddress.zoneData!) {
      if (zone.modules == null) continue;

      for (var module in zone.modules!) {
        if (module.id == parsed.moduleId && module.pivot != null) {
          if (module.pivot!.zoneId == parsed.zoneId) {
            wishStoreIdList.add(parsed.id);
          }
        }
      }
    }
    return wishStoreIdList;
  }
}
