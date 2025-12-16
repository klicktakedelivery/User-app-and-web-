import 'dart:async';
import 'dart:collection';

import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/track_details_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/tracking_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? contactNumber;
  const OrderTrackingScreen({super.key, required this.orderID, this.contactNumber});

  @override
  OrderTrackingScreenState createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  bool _isLoading = true;
  Set<Marker> _markers = HashSet<Marker>();
  Timer? _timer;
  bool showChatPermission = true;
  bool isHovered = false;

  void _loadData() async {
    // ✅ استخدم عنوان المستخدم فقط لو موجود وبإحداثيات صالحة
    final savedAddress = AddressHelper.getUserAddressFromSharedPref();
    LatLng? defaultLatLng;

    if (savedAddress != null &&
        savedAddress.latitude != null &&
        savedAddress.longitude != null) {
      final lat = double.tryParse(savedAddress.latitude!);
      final lng = double.tryParse(savedAddress.longitude!);
      if (lat != null && lng != null) {
        defaultLatLng = LatLng(lat, lng);
      }
    }

    await Get.find<LocationController>().getCurrentLocation(
      true,
      notify: false,
      defaultLatLng: defaultLatLng,
    );

    await Get.find<OrderController>().trackOrder(
      widget.orderID,
      null,
      true,
      contactNumber: widget.contactNumber,
    );
    _timerTrackOrder();
  }

  void _timerTrackOrder() {
    if (Get.find<OrderController>().trackModel?.orderStatus != 'delivered'
        && Get.find<OrderController>().trackModel?.orderStatus != 'failed'
        && Get.find<OrderController>().trackModel?.orderStatus != 'canceled'
    ) {
      Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(), contactNumber: widget.contactNumber);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (Get.currentRoute.contains(RouteHelper.orderDetails) || Get.currentRoute.contains(RouteHelper.orderTracking)) {
          Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(), contactNumber: widget.contactNumber);

          updateMarker(
            Get.find<OrderController>().trackModel?.store,
            Get.find<OrderController>().trackModel!.deliveryMan,
            Get.find<OrderController>().trackModel?.orderType == 'take_away'
                ? Get.find<LocationController>().position.latitude == 0
                ? Get.find<OrderController>().trackModel?.deliveryAddress
                : AddressModel(
              latitude: Get.find<LocationController>().position.latitude.toString(),
              longitude: Get.find<LocationController>().position.longitude.toString(),
              address: Get.find<LocationController>().address,
            )
                : Get.find<OrderController>().trackModel?.deliveryAddress,
            Get.find<OrderController>().trackModel?.orderType == 'take_away',
            Get.find<OrderController>().trackModel?.orderType == 'parcel',
            Get.find<OrderController>().trackModel?.moduleType == 'food',
          );
        } else {
          _timer?.cancel();
        }
      });
    } else {
      Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(), contactNumber: widget.contactNumber);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timerTrackOrder();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _controller?.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void onEntered(bool isHovered) {
    setState(() {
      this.isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'order_tracking'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<OrderController>(builder: (orderController) {
        OrderModel? track;
        if (orderController.trackModel != null) {
          track = orderController.trackModel;

          if (track!.orderType != 'parcel') {
            if (track.store!.storeBusinessModel == 'commission') {
              showChatPermission = true;
            } else if (track.store!.storeSubscription != null && track.store!.storeBusinessModel == 'subscription') {
              showChatPermission = track.store!.storeSubscription!.chat == 1;
            } else {
              showChatPermission = false;
            }
          } else {
            showChatPermission = AuthHelper.isLoggedIn();
          }
        }

        return track != null
            ? SingleChildScrollView(
          physics: isHovered || !ResponsiveHelper.isDesktop(context)
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          child: FooterView(
            child: Center(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                height: ResponsiveHelper.isDesktop(context)
                    ? 700
                    : MediaQuery.of(context).size.height * 0.85,
                child: Stack(
                  children: [
                    MouseRegion(
                      onEnter: (event) => onEntered(true),
                      onExit: (event) => onEntered(false),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            double.tryParse(track.deliveryAddress?.latitude ?? '0') ?? 0,
                            double.tryParse(track.deliveryAddress?.longitude ?? '0') ?? 0,
                          ),
                          zoom: 16,
                        ),
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                        zoomControlsEnabled: false,
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _controller = controller;
                          _isLoading = false;
                          setMarker(
                            track!.orderType == 'parcel'
                                ? Store(
                              latitude: track.receiverDetails?.latitude,
                              longitude: track.receiverDetails?.longitude,
                              address: track.receiverDetails?.address,
                              name: track.receiverDetails?.contactPersonName,
                            )
                                : track.store,
                            track.deliveryMan,
                            track.orderType == 'take_away'
                                ? Get.find<LocationController>().position.latitude == 0
                                ? track.deliveryAddress
                                : AddressModel(
                              latitude: Get.find<LocationController>().position.latitude.toString(),
                              longitude: Get.find<LocationController>().position.longitude.toString(),
                              address: Get.find<LocationController>().address,
                            )
                                : track.deliveryAddress,
                            track.orderType == 'take_away',
                            track.orderType == 'parcel',
                            track.moduleType == 'food',
                          );
                        },
                        style: Get.isDarkMode
                            ? Get.find<ThemeController>().darkMap
                            : Get.find<ThemeController>().lightMap,
                      ),
                    ),

                    _isLoading ? const Center(child: CircularProgressIndicator()) : const SizedBox(),

                    Positioned(
                      top: Dimensions.paddingSizeSmall,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                      child: TrackingStepperWidget(
                        status: track.orderStatus,
                        takeAway: track.orderType == 'take_away',
                      ),
                    ),

                    Positioned(
                      right: 15,
                      bottom: track.orderType != 'take_away' && track.deliveryMan == null ? 150 : 220,
                      child: InkWell(
                        onTap: () => _checkPermission(() async {
                          AddressModel address = await Get.find<LocationController>()
                              .getCurrentLocation(false, mapController: _controller);
                          setMarker(
                            track!.orderType == 'parcel'
                                ? Store(
                              latitude: track.receiverDetails?.latitude,
                              longitude: track.receiverDetails?.longitude,
                              address: track.receiverDetails?.address,
                              name: track.receiverDetails?.contactPersonName,
                            )
                                : track.store,
                            track.deliveryMan,
                            track.orderType == 'take_away'
                                ? Get.find<LocationController>().position.latitude == 0
                                ? track.deliveryAddress
                                : AddressModel(
                              latitude: Get.find<LocationController>().position.latitude.toString(),
                              longitude: Get.find<LocationController>().position.longitude.toString(),
                              address: Get.find<LocationController>().address,
                            )
                                : track.deliveryAddress,
                            track.orderType == 'take_away',
                            track.orderType == 'parcel',
                            track.moduleType == 'food',
                            currentAddress: address,
                            fromCurrentLocation: true,
                          );
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.my_location_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 25,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: Dimensions.paddingSizeSmall,
                      left: Dimensions.paddingSizeSmall,
                      right: Dimensions.paddingSizeSmall,
                      child: TrackDetailsViewWidget(
                        status: track.orderStatus,
                        track: track,
                        showChatPermission: showChatPermission,
                        callback: () async {
                          bool takeAway = track?.orderType == 'take_away';
                          _timer?.cancel();
                          await Get.toNamed(
                            RouteHelper.getChatRoute(
                              notificationBody: takeAway
                                  ? NotificationBodyModel(
                                restaurantId: track!.store!.id,
                                orderId: int.parse(widget.orderID!),
                              )
                                  : NotificationBodyModel(
                                deliverymanId: track!.deliveryMan!.id,
                                orderId: int.parse(widget.orderID!),
                              ),
                              user: User(
                                id: takeAway ? track.store!.id : track.deliveryMan!.id,
                                fName: takeAway ? track.store!.name : track.deliveryMan!.fName,
                                lName: takeAway ? '' : track.deliveryMan!.lName,
                                imageFullUrl: takeAway
                                    ? track.store!.logoFullUrl
                                    : track.deliveryMan!.imageFullUrl,
                              ),
                            ),
                          );
                          _timerTrackOrder();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : const Center(child: CircularProgressIndicator());
      }),
    );
  }

  void setMarker(
      Store? store,
      DeliveryMan? deliveryMan,
      AddressModel? addressModel,
      bool takeAway,
      bool parcel,
      bool isRestaurant, {
        AddressModel? currentAddress,
        bool fromCurrentLocation = false,
      }) async {
    try {
      BitmapDescriptor restaurantImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30,
        imagePath: parcel ? Images.userMarker : (isRestaurant ? Images.restaurantMarker : Images.markerStore),
      );

      BitmapDescriptor deliveryBoyImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30,
        imagePath: Images.deliveryManMarker,
      );

      BitmapDescriptor destinationImageData = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30,
        imagePath: Images.userMarker,
      );

      // ✅ حوّل الإحداثيات إلى LatLng بشكل آمن
      LatLng? storeLatLng;
      LatLng? destLatLng;

      if (store?.latitude != null && store?.longitude != null) {
        final sLat = double.tryParse(store!.latitude!);
        final sLng = double.tryParse(store.longitude!);
        if (sLat != null && sLng != null) {
          storeLatLng = LatLng(sLat, sLng);
        }
      }

      if (addressModel?.latitude != null && addressModel?.longitude != null) {
        final dLat = double.tryParse(addressModel!.latitude!);
        final dLng = double.tryParse(addressModel.longitude!);
        if (dLat != null && dLng != null) {
          destLatLng = LatLng(dLat, dLng);
        }
      }

      LatLngBounds? bounds;
      double rotation = 0;

      if (_controller != null && storeLatLng != null && destLatLng != null) {
        if (destLatLng.latitude < storeLatLng.latitude) {
          bounds = LatLngBounds(
            southwest: destLatLng,
            northeast: storeLatLng,
          );
          rotation = 0;
        } else {
          bounds = LatLngBounds(
            southwest: storeLatLng,
            northeast: destLatLng,
          );
          rotation = 180;
        }
      }

      LatLng? centerBounds;
      if (bounds != null) {
        centerBounds = LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        );
      }

      if (fromCurrentLocation && currentAddress != null && _controller != null) {
        final cLat = double.tryParse(currentAddress.latitude ?? '');
        final cLng = double.tryParse(currentAddress.longitude ?? '');
        if (cLat != null && cLng != null) {
          LatLng currentLocation = LatLng(cLat, cLng);
          _controller!.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: currentLocation,
                zoom: GetPlatform.isWeb ? 7 : 15,
              ),
            ),
          );
        }
      }

      if (!fromCurrentLocation && _controller != null && centerBounds != null && bounds != null) {
        _controller!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: centerBounds,
              zoom: GetPlatform.isWeb ? 10 : 17,
            ),
          ),
        );
        if (!ResponsiveHelper.isWeb()) {
          await zoomToFit(_controller, bounds, centerBounds, padding: GetPlatform.isWeb ? 15 : 3);
        }
      }

      /// user for normal order , but sender for parcel order
      _markers = HashSet<Marker>();

      /// current location marker
      if (currentAddress != null) {
        final cLat = double.tryParse(currentAddress.latitude ?? '');
        final cLng = double.tryParse(currentAddress.longitude ?? '');
        if (cLat != null && cLng != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              visible: true,
              draggable: false,
              zIndexInt: 2,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              position: LatLng(cLat, cLng),
              icon: destinationImageData,
            ),
          );
          setState(() {});
        }
      }

      if (currentAddress == null && destLatLng != null && addressModel != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destLatLng,
            infoWindow: InfoWindow(
              title: parcel ? 'sender'.tr : 'Destination'.tr,
              snippet: addressModel.address,
            ),
            icon: destinationImageData,
          ),
        );
      }

      /// store / receiver marker
      if (storeLatLng != null && store != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('store'),
            position: storeLatLng,
            infoWindow: InfoWindow(
              title: parcel
                  ? 'receiver'.tr
                  : Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                  ? 'store'.tr
                  : 'store'.tr,
              snippet: store.address,
            ),
            icon: restaurantImageData,
          ),
        );
      }

      /// delivery man marker
      if (deliveryMan != null) {
        final dLat = double.tryParse(deliveryMan.lat ?? '');
        final dLng = double.tryParse(deliveryMan.lng ?? '');
        if (dLat != null && dLng != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('delivery_boy'),
              position: LatLng(dLat, dLng),
              infoWindow: InfoWindow(
                title: 'delivery_man'.tr,
                snippet: deliveryMan.location,
              ),
              rotation: rotation,
              icon: deliveryBoyImageData,
            ),
          );
        }
      }
    } catch (_) {}
    setState(() {});
  }

  void updateMarker(
  Store? store,
  DeliveryMan? deliveryMan,
  AddressModel? addressModel,
  bool takeAway,
  bool parcel,
  bool isRestaurant, {
  AddressModel? currentAddress,
  bool fromCurrentLocation = false,
}) async {
  try {
    final BitmapDescriptor restaurantImageData =
        await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 30,
      imagePath: parcel
          ? Images.userMarker
          : (isRestaurant ? Images.restaurantMarker : Images.markerStore),
    );

    final BitmapDescriptor deliveryBoyImageData =
        await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 30,
      imagePath: Images.deliveryManMarker,
    );

    final BitmapDescriptor destinationImageData =
        await MarkerHelper.convertAssetToBitmapDescriptor(
      width: 30,
      imagePath: Images.userMarker,
    );

    LatLng? storeLatLng;
    LatLng? destLatLng;

    if (store?.latitude != null && store?.longitude != null) {
      final sLat = double.tryParse(store!.latitude!);
      final sLng = double.tryParse(store.longitude!);
      if (sLat != null && sLng != null) {
        storeLatLng = LatLng(sLat, sLng);
      }
    }

    if (addressModel?.latitude != null && addressModel?.longitude != null) {
      final dLat = double.tryParse(addressModel!.latitude!);
      final dLng = double.tryParse(addressModel.longitude!);
      if (dLat != null && dLng != null) {
        destLatLng = LatLng(dLat, dLng);
      }
    }

    // ✅ ما في bounds هنا (لأننا ما نستخدمه)
    double rotation = 0;
    if (_controller != null && storeLatLng != null && destLatLng != null) {
      rotation = destLatLng.latitude < storeLatLng.latitude ? 0 : 180;
    }

    _markers = HashSet<Marker>();

    if (currentAddress != null) {
      final cLat = double.tryParse(currentAddress.latitude ?? '');
      final cLng = double.tryParse(currentAddress.longitude ?? '');
      if (cLat != null && cLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            visible: true,
            draggable: false,
            zIndexInt: 2,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            position: LatLng(cLat, cLng),
            icon: destinationImageData,
          ),
        );
      }
    }

    if (currentAddress == null && destLatLng != null && addressModel != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          infoWindow: InfoWindow(
            title: parcel ? 'sender'.tr : 'Destination'.tr,
            snippet: addressModel.address,
          ),
          icon: destinationImageData,
        ),
      );
    }

    if (storeLatLng != null && store != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('store'),
          position: storeLatLng,
          infoWindow: InfoWindow(
            title: parcel
                ? 'receiver'.tr
                : (Get.find<SplashController>()
                            .configModel!
                            .moduleConfig!
                            .module!
                            .showRestaurantText!
                        ? 'store'.tr
                        : 'store'.tr),
            snippet: store.address,
          ),
          icon: restaurantImageData,
        ),
      );
    }

    if (deliveryMan != null) {
      final dLat = double.tryParse(deliveryMan.lat ?? '');
      final dLng = double.tryParse(deliveryMan.lng ?? '');
      if (dLat != null && dLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('delivery_boy'),
            position: LatLng(dLat, dLng),
            infoWindow: InfoWindow(
              title: 'delivery_man'.tr,
              snippet: deliveryMan.location,
            ),
            rotation: rotation,
            icon: deliveryBoyImageData,
          ),
        );
      }
    }
  } catch (_) {}

  if (mounted) {
    setState(() {});
  }
}


  Future<void> zoomToFit(
      GoogleMapController? controller,
      LatLngBounds? bounds,
      LatLng centerBounds, {
        double padding = 0.5,
      }) async {
    if (controller == null || bounds == null) return;

    bool keepZoomingOut = true;

    while (keepZoomingOut) {
      final LatLngBounds screenBounds = await controller.getVisibleRegion();
      if (fits(bounds, screenBounds)) {
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - padding;
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: centerBounds,
              zoom: zoomLevel,
            ),
          ),
        );
        break;
      } else {
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: centerBounds,
              zoom: zoomLevel,
            ),
          ),
        );
      }
    }
  }

  bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck =
        screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck =
        screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck =
        screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck =
        screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck &&
        northEastLongitudeCheck &&
        southWestLatitudeCheck &&
        southWestLongitudeCheck;
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    } else {
      onTap();
    }
  }
}
