import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/item/domain/models/basic_medicine_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/common_condition_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/item_bottom_sheet.dart';
import 'package:sixam_mart/features/item/screens/item_details_screen.dart';
import 'package:sixam_mart/features/item/domain/services/item_service_interface.dart';

class ItemController extends GetxController implements GetxService {
  final ItemServiceInterface itemServiceInterface;
  ItemController({required this.itemServiceInterface});

  // =============================
  // Lists
  // =============================
  List<Item>? _popularItemList;
  List<Item>? get popularItemList => _popularItemList;

  List<Item>? _reviewedItemList;
  List<Item>? get reviewedItemList => _reviewedItemList;

  List<Item>? _recommendedItemList;
  List<Item>? get recommendedItemList => _recommendedItemList;

  List<Item>? _discountedItemList;
  List<Item>? get discountedItemList => _discountedItemList;

  List<Categories>? _reviewedCategoriesList;
  List<Categories>? get reviewedCategoriesList => _reviewedCategoriesList;

  // =============================
  // Pagination (FIX: separate state لكل قائمة)
  // =============================
  int? _popularTotalSize;
  int? _reviewedTotalSize;
  int? _discountedTotalSize;

  int? get pageSize => _pageSize; // legacy (موجود في UI غالباً)
  int? _pageSize = 0;

  final Set<String> _popularOffsets = <String>{};
  final Set<String> _reviewedOffsets = <String>{};
  final Set<String> _discountedOffsets = <String>{};

  int _offset = 1;
  int get offset => _offset;

  // منع تكرار نفس الطلب (خصوصاً مع rebuilds)
  final Map<String, Future<void>> _inflight = {};

  // =============================
  // Loading
  // =============================
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // =============================
  // Item details & variations
  // =============================
  List<int>? _variationIndex;
  List<int>? get variationIndex => _variationIndex;

  List<List<bool?>> _selectedVariations = [];
  List<List<bool?>> get selectedVariations => _selectedVariations;

  int? _quantity = 1;
  int? get quantity => _quantity;

  List<bool> _addOnActiveList = [];
  List<bool> get addOnActiveList => _addOnActiveList;

  List<int?> _addOnQtyList = [];
  List<int?> get addOnQtyList => _addOnQtyList;

  final String _popularType = 'all';
  String get popularType => _popularType;

  final String _reviewedType = 'all';
  String get reviewType => _reviewedType;

  final String _discountedType = 'all';
  String get discountedType => _discountedType;

  static final List<String> _itemTypeList = ['all', 'veg', 'non_veg'];
  List<String> get itemTypeList => _itemTypeList;

  int _imageIndex = 0;
  int get imageIndex => _imageIndex;

  int _cartIndex = -1;
  int get cartIndex => _cartIndex;

  Item? _item;
  Item? get item => _item;

  int _productSelect = 0;
  int get productSelect => _productSelect;

  int _imageSliderIndex = 0;
  int get imageSliderIndex => _imageSliderIndex;

  List<bool> _collapseVariation = [];
  List<bool> get collapseVariation => _collapseVariation;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _isReadMore = false;
  bool get isReadMore => _isReadMore;

  BasicMedicineModel? _basicMedicineModel;
  BasicMedicineModel? get basicMedicineModel => _basicMedicineModel;

  List<CommonConditionModel>? _commonConditions;
  List<CommonConditionModel>? get commonConditions => _commonConditions;

  int _selectedCommonCondition = 0;
  int get selectedCommonCondition => _selectedCommonCondition;

  List<Item>? _conditionWiseProduct;
  List<Item>? get conditionWiseProduct => _conditionWiseProduct;

  ItemModel? _featuredCategoriesItem;
  ItemModel? get featuredCategoriesItem => _featuredCategoriesItem;

  int _selectedCategory = 0;
  int get selectedCategory => _selectedCategory;

  static final List<String> _sortOptions = ['default', 'a_to_z', 'z_to_a', 'high', 'low'];
  List<String> get sortOptions => _sortOptions;

  String _selectedSortOption = 'default';
  String get selectedSortOption => _selectedSortOption;

  final List<String> _filter = [];
  List<String>? get filter => _filter;

  int? _rating;
  int? get rating => _rating;

  final List<int> _selectedCategoryIds = [];
  List<int> get selectedCategoryIds => _selectedCategoryIds;

  double _selectedMinPrice = 0;
  double get selectedMinPrice => _selectedMinPrice;

  double _selectedMaxPrice = 9999999999;
  double get selectedMaxPrice => _selectedMaxPrice;

  List<Categories>? _categoryList = [];
  List<Categories>? get categoryList => _categoryList;

  bool _isAvailableItems = false;
  bool get isAvailableItems => _isAvailableItems;

  bool _isUnAvailableItems = false;
  bool get isUnAvailableItems => _isUnAvailableItems;

  bool _isTopRated = false;
  bool get isTopRated => _isTopRated;

  bool _isMostLoved = false;
  bool get isMostLoved => _isMostLoved;

  bool _isPopular = false;
  bool get isPopular => _isPopular;

  bool _isLatest = false;
  bool get isLatest => _isLatest;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  final TextEditingController _searchController = TextEditingController(text: '');
  TextEditingController get searchController => _searchController;

  // =============================
  // Helpers (بدون update spam)
  // =============================
  void _setSearchingFromText({bool notify = false}) {
    final bool next = _searchController.text.isNotEmpty;
    if (_isSearching != next) {
      _isSearching = next;
      if (notify) update();
    } else {
      if (notify) update();
    }
  }

  String _requestKey({
    required String kind,
    required DataSourceEnum source,
    required String offset,
    required String type,
  }) {
    return [
      kind,
      source.name,
      offset,
      type,
      _searchController.text,
      _selectedCategoryIds.join(','),
      _filter.join(','),
      _rating?.toString() ?? '',
      _selectedMinPrice.toString(),
      _selectedMaxPrice.toString(),
    ].join('|');
  }

  // =============================
  // Filters / Search
  // =============================
  void clearSearch({bool withUpdate = true}) {
    _searchController.text = '';
    _isSearching = false;
    if (withUpdate) update();
  }

  void toggleCategory(int? categoryId) {
    if (categoryId == null) return;
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    update();
  }

  void setMinAndMaxPrice(double min, double max, {bool withUpdate = true}) {
    _selectedMinPrice = min;
    _selectedMaxPrice = max;
    if (withUpdate) update();
  }

  void toggleAvailableItems() {
    _isAvailableItems = !_isAvailableItems;
    if (_isAvailableItems) {
      if (!_filter.contains("available_now")) _filter.add("available_now");
    } else {
      _filter.remove("available_now");
    }
    update();
  }

  void toggleUnavailableItems() {
    _isUnAvailableItems = !_isUnAvailableItems;
    if (_isUnAvailableItems) {
      if (!_filter.contains("un_available_now")) _filter.add("un_available_now");
    } else {
      _filter.remove("un_available_now");
    }
    update();
  }

  void toggleTopRated() {
    _isTopRated = !_isTopRated;
    if (_isTopRated) {
      if (!_filter.contains("top_rated")) _filter.add("top_rated");
    } else {
      _filter.remove("top_rated");
    }
    update();
  }

  void toggleMostLoved() {
    _isMostLoved = !_isMostLoved;
    if (_isMostLoved) {
      if (!_filter.contains("most_loved")) _filter.add("most_loved");
    } else {
      _filter.remove("most_loved");
    }
    update();
  }

  void togglePopular() {
    _isPopular = !_isPopular;
    if (_isPopular) {
      if (!_filter.contains("popular")) _filter.add("popular");
    } else {
      _filter.remove("popular");
    }
    update();
  }

  void toggleLatest() {
    _isLatest = !_isLatest;
    if (_isLatest) {
      if (!_filter.contains("latest")) _filter.add("latest");
    } else {
      _filter.remove("latest");
    }
    update();
  }

  void setSelectedRating(int rating) {
    _rating = rating;
    update();
  }

  void setSelectedSortOption(String option) {
    _selectedSortOption = option;

    // تأكد أنه فقط خيار واحد من sort موجود
    for (final element in _sortOptions) {
      _filter.remove(element);
    }
    if (_selectedSortOption != 'default') {
      _filter.add(_selectedSortOption);
    }
    update();
  }

  void selectCategory(int index) {
    _selectedCategory = index;
    update();
  }

  void applyFilters({bool isPopular = false, bool isSpecial = false}) {
    if (isPopular) {
      getPopularItemList(notify: true, offset: '1', dataSource: DataSourceEnum.client);
    } else if (isSpecial) {
      getDiscountedItemList(notify: true, offset: '1', dataSource: DataSourceEnum.client);
    } else {
      getReviewedItemList(notify: true, offset: '1', dataSource: DataSourceEnum.client);
    }
  }

  void resetFilters({bool isPopular = false, bool isSpecial = false}) {
    _selectedCategoryIds.clear();
    _filter.clear();
    _rating = null;
    _selectedMinPrice = 0;
    _selectedMaxPrice = 9999999999;
    _isAvailableItems = false;
    _isUnAvailableItems = false;
    _isTopRated = false;
    _isMostLoved = false;
    _isPopular = false;
    _isLatest = false;
    _selectedSortOption = 'default';
    _searchController.text = '';

    if (isPopular) {
      getPopularItemList(offset: '1', dataSource: DataSourceEnum.client);
    } else if (isSpecial) {
      getDiscountedItemList(offset: '1', dataSource: DataSourceEnum.client);
    } else {
      getReviewedItemList(offset: '1', dataSource: DataSourceEnum.client);
    }

    update();
  }

  void clearFilters({bool isPopular = false, bool isSpecial = false}) {
    _selectedCategoryIds.clear();
    _filter.clear();
    _rating = null;
    _selectedMinPrice = 0;
    _selectedMaxPrice = 9999999999;
    _isAvailableItems = false;
    _isUnAvailableItems = false;
    _isTopRated = false;
    _isMostLoved = false;
    _isPopular = false;
    _isLatest = false;
    _selectedSortOption = 'default';
    _searchController.text = '';

    if (isPopular) {
      getPopularItemList(offset: '1', dataSource: DataSourceEnum.client, firstTimeCategoryLoad: true);
    } else if (isSpecial) {
      getDiscountedItemList(offset: '1', dataSource: DataSourceEnum.client, firstTimeCategoryLoad: true);
    } else {
      getReviewedItemList(offset: '1', dataSource: DataSourceEnum.client, firstTimeCategoryLoad: true);
    }
  }

  // =============================
  // UI misc
  // =============================
  void selectCommonCondition(int index) {
    _selectedCommonCondition = index;
    if (_commonConditions != null && _commonConditions!.isNotEmpty) {
      getConditionsWiseItem(_commonConditions![index].id!, true);
    }
    update();
  }

  void changeReadMore() {
    _isReadMore = !_isReadMore;
    update();
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if (notify) update();
  }

  void clearItemLists() {
    _popularItemList = null;
    _reviewedItemList = null;
    _discountedItemList = null;
    _featuredCategoriesItem = null;
    _recommendedItemList = null;

    _popularOffsets.clear();
    _reviewedOffsets.clear();
    _discountedOffsets.clear();

    _popularTotalSize = null;
    _reviewedTotalSize = null;
    _discountedTotalSize = null;
  }

  void showBottomLoader() {
    if (_isLoading) return;
    _isLoading = true;
    update();
  }

  void setOffset(int offset) {
    _offset = offset;
  }

  // FIX: منطق hasMoreData الصحيح: length < totalSize
  bool hasMoreData({bool isPopular = false, bool isSpecial = false}) {
    if (isPopular) {
      final total = _popularTotalSize ?? _pageSize;
      return _popularItemList != null && total != null && _popularItemList!.length < total;
    } else if (isSpecial) {
      final total = _discountedTotalSize ?? _pageSize;
      return _discountedItemList != null && total != null && _discountedItemList!.length < total;
    } else {
      final total = _reviewedTotalSize ?? _pageSize;
      return _reviewedItemList != null && total != null && _reviewedItemList!.length < total;
    }
  }

  // =============================
  // Popular
  // =============================
  Future<void> getPopularItemList({
    required String offset,
    DataSourceEnum dataSource = DataSourceEnum.local,
    bool notify = false,
    bool firstTimeCategoryLoad = false,
  }) async {
    _setSearchingFromText(notify: notify);

    if (offset == '1') {
      _popularOffsets.clear();
      _offset = 1;
      _popularItemList = null;
      if (firstTimeCategoryLoad) _categoryList = null;
      if (notify) update();
    }

    if (_popularOffsets.contains(offset)) {
      if (_isLoading) {
        _isLoading = false;
        update();
      }
      return;
    }
    _popularOffsets.add(offset);

    final key = _requestKey(kind: 'popular', source: dataSource, offset: offset, type: _popularType);
    if (_inflight.containsKey(key)) {
      await _inflight[key];
      return;
    }

    final Future<void> task = () async {
      final ItemModel? itemModel = await itemServiceInterface.getPopularItemList(
        type: _popularType,
        source: dataSource,
        offset: _offset,
        search: _searchController.text,
        categoryIds: _selectedCategoryIds,
        filter: _filter,
        rating: _rating,
        minPrice: _selectedMinPrice,
        maxPrice: _selectedMaxPrice,
      );

      if (itemModel != null) {
        if (offset == '1') {
          _popularItemList = <Item>[];
          if (firstTimeCategoryLoad) _categoryList = <Categories>[];
        }
        _popularItemList ??= <Item>[];
        _popularItemList!.addAll(itemModel.items ?? const <Item>[]);

        if (firstTimeCategoryLoad && itemModel.categories != null) {
          _categoryList ??= <Categories>[];
          _categoryList!.addAll(itemModel.categories!);
        }

        _popularTotalSize = itemModel.totalSize;
        _pageSize = itemModel.totalSize; // legacy fallback
      }

      _isLoading = false;
      update();

      if (dataSource == DataSourceEnum.local) {
        await getPopularItemList(
          notify: notify,
          dataSource: DataSourceEnum.client,
          offset: '1',
          firstTimeCategoryLoad: firstTimeCategoryLoad,
        );
      }
    }();

    _inflight[key] = task;
    try {
      await task;
    } finally {
      _inflight.remove(key);
    }
  }

  // =============================
  // Reviewed
  // =============================
  Future<void> getReviewedItemList({
    required String offset,
    DataSourceEnum dataSource = DataSourceEnum.local,
    bool notify = false,
    bool firstTimeCategoryLoad = false,
  }) async {
    _setSearchingFromText(notify: notify);

    if (offset == '1') {
      _reviewedOffsets.clear();
      _offset = 1;
      _reviewedItemList = null;
      _reviewedCategoriesList = null;
      if (firstTimeCategoryLoad) _categoryList = null;
      if (notify) update();
    }

    if (_reviewedOffsets.contains(offset)) {
      if (_isLoading) {
        _isLoading = false;
        update();
      }
      return;
    }
    _reviewedOffsets.add(offset);

    final key = _requestKey(kind: 'reviewed', source: dataSource, offset: offset, type: _reviewedType);
    if (_inflight.containsKey(key)) {
      await _inflight[key];
      return;
    }

    final Future<void> task = () async {
      final ItemModel? itemModel = await itemServiceInterface.getReviewedItemList(
        type: _reviewedType,
        source: dataSource,
        offset: _offset,
        search: _searchController.text,
        categoryIds: _selectedCategoryIds,
        filter: _filter,
        rating: _rating,
        minPrice: _selectedMinPrice,
        maxPrice: _selectedMaxPrice,
      );

      if (itemModel != null) {
        if (offset == '1') {
          _reviewedItemList = <Item>[];
          _reviewedCategoriesList = <Categories>[];
          if (firstTimeCategoryLoad) _categoryList = <Categories>[];
        }

        _reviewedItemList ??= <Item>[];
        _reviewedItemList!.addAll(itemModel.items ?? const <Item>[]);

        _reviewedCategoriesList ??= <Categories>[];
        if (itemModel.categories != null) {
          _reviewedCategoriesList!.addAll(itemModel.categories!);
        }

        if (firstTimeCategoryLoad && itemModel.categories != null) {
          _categoryList ??= <Categories>[];
          _categoryList!.addAll(itemModel.categories!);
        }

        _reviewedTotalSize = itemModel.totalSize;
        _pageSize = itemModel.totalSize; // legacy fallback
      }

      _isLoading = false;
      update();

      if (dataSource == DataSourceEnum.local) {
        await getReviewedItemList(
          notify: notify,
          dataSource: DataSourceEnum.client,
          offset: '1',
          firstTimeCategoryLoad: firstTimeCategoryLoad,
        );
      }
    }();

    _inflight[key] = task;
    try {
      await task;
    } finally {
      _inflight.remove(key);
    }
  }

  // =============================
  // Discounted
  // =============================
  Future<void> getDiscountedItemList({
    required String offset,
    DataSourceEnum dataSource = DataSourceEnum.local,
    bool notify = false,
    bool firstTimeCategoryLoad = false,
  }) async {
    _setSearchingFromText(notify: notify);

    if (offset == '1') {
      _discountedOffsets.clear();
      _offset = 1;
      _discountedItemList = null;
      if (firstTimeCategoryLoad) _categoryList = null;
      if (notify) update();
    }

    if (_discountedOffsets.contains(offset)) {
      if (_isLoading) {
        _isLoading = false;
        update();
      }
      return;
    }
    _discountedOffsets.add(offset);

    final key = _requestKey(kind: 'discounted', source: dataSource, offset: offset, type: _discountedType);
    if (_inflight.containsKey(key)) {
      await _inflight[key];
      return;
    }

    final Future<void> task = () async {
      final ItemModel? itemModel = await itemServiceInterface.getDiscountedItemList(
        type: _discountedType,
        source: dataSource,
        offset: _offset,
        search: _searchController.text,
        categoryIds: _selectedCategoryIds,
        filter: _filter,
        rating: _rating,
        minPrice: _selectedMinPrice,
        maxPrice: _selectedMaxPrice,
      );

      if (itemModel != null) {
        if (offset == '1') {
          _discountedItemList = <Item>[];
          if (firstTimeCategoryLoad) _categoryList = <Categories>[];
        }

        _discountedItemList ??= <Item>[];
        _discountedItemList!.addAll(itemModel.items ?? const <Item>[]);

        if (firstTimeCategoryLoad && itemModel.categories != null) {
          _categoryList ??= <Categories>[];
          _categoryList!.addAll(itemModel.categories!);
        }

        _discountedTotalSize = itemModel.totalSize;
        _pageSize = itemModel.totalSize; // legacy fallback
      }

      _isLoading = false;
      update();

      if (dataSource == DataSourceEnum.local) {
        await getDiscountedItemList(
          notify: notify,
          dataSource: DataSourceEnum.client,
          offset: '1',
          firstTimeCategoryLoad: firstTimeCategoryLoad,
        );
      }
    }();

    _inflight[key] = task;
    try {
      await task;
    } finally {
      _inflight.remove(key);
    }
  }

  // =============================
  // Featured categories items
  // =============================
  Future<void> getFeaturedCategoriesItemList(
      bool reload,
      bool notify, {
        DataSourceEnum dataSource = DataSourceEnum.local,
        bool fromRecall = false,
      }) async {
    if (reload) {
      _featuredCategoriesItem = null;
    }
    if (notify) update();

    if (_featuredCategoriesItem == null || reload || fromRecall) {
      if (dataSource == DataSourceEnum.local) {
        _featuredCategoriesItem = await itemServiceInterface.getFeaturedCategoriesItemList(dataSource);
        update();
        getFeaturedCategoriesItemList(false, notify, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        _featuredCategoriesItem = await itemServiceInterface.getFeaturedCategoriesItemList(dataSource);
        update();
      }
    }
  }

  // =============================
  // Recommended
  // =============================
  Future<void> getRecommendedItemList(
      bool reload,
      String type,
      bool notify, {
        DataSourceEnum dataSource = DataSourceEnum.local,
        bool fromRecall = false,
      }) async {
    if (reload) {
      _recommendedItemList = null;
    }
    if (notify) update();

    if (_recommendedItemList == null || reload || fromRecall) {
      List<Item>? items;
      if (dataSource == DataSourceEnum.local) {
        items = await itemServiceInterface.getRecommendedItemList(type, dataSource);
        if (items != null) {
          _recommendedItemList = <Item>[...items];
        }
        update();
        getRecommendedItemList(false, type, notify, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        items = await itemServiceInterface.getRecommendedItemList(type, dataSource);
        if (items != null) {
          _recommendedItemList = <Item>[...items];
        }
        update();
      }
    }
  }

  // =============================
  // Pharmacy
  // =============================
  Future<void> getBasicMedicine(
      bool reload,
      bool notify, {
        DataSourceEnum dataSource = DataSourceEnum.local,
        bool fromRecall = false,
      }) async {
    if (reload) {
      _basicMedicineModel = null;
    }
    if (notify) update();

    if (_basicMedicineModel == null || reload || fromRecall) {
      if (dataSource == DataSourceEnum.local) {
        _basicMedicineModel = await itemServiceInterface.getBasicMedicine(DataSourceEnum.local);
        _isLoading = false;
        update();
        getBasicMedicine(false, notify, fromRecall: true, dataSource: DataSourceEnum.client);
      } else {
        _basicMedicineModel = await itemServiceInterface.getBasicMedicine(DataSourceEnum.client);
        _isLoading = false;
        update();
      }
    }
  }

  Future<void> getConditionsWiseItem(int id, bool notify) async {
    _conditionWiseProduct = null;
    if (notify) update();

    final List<Item>? items = await itemServiceInterface.getConditionsWiseItems(id);
    if (items != null) {
      _conditionWiseProduct = <Item>[...items];
      _isLoading = false;
    }
    update();
  }

  Future<void> getCommonConditions(bool notify) async {
    _commonConditions = <CommonConditionModel>[];
    if (notify) update();

    final List<CommonConditionModel>? conditions = await itemServiceInterface.getCommonConditions();
    if (conditions != null) {
      _commonConditions!.addAll(conditions);
      _isLoading = false;
    }
    update();
  }

  // =============================
  // Item details & cart
  // =============================
  Future<void> getItemDetails({required int itemId, CartModel? cart, Item? item}) async {
    _item = null;

    if (item?.name != null) {
      _item = item;
    } else {
      _item = await itemServiceInterface.getItemDetails(itemId);
    }

    if (_item != null) {
      initData(_item, cart);
      setExistInCart(_item, _selectedVariations);
    }
    if (item == null) update();
  }

  void initData(Item? item, CartModel? cart) {
    _variationIndex = [];
    _addOnQtyList = [];
    _addOnActiveList = [];
    _selectedVariations = [];
    _collapseVariation = [];

    if (item == null) return;

    if (cart != null) {
      _quantity = cart.quantity;
      _addOnActiveList.addAll(itemServiceInterface.initializeCartAddonActiveList(cart.addOnIds, item.addOns));
      _addOnQtyList.addAll(itemServiceInterface.initializeCartAddonsQtyList(cart.addOnIds, item.addOns));

      if (ModuleHelper.getModuleConfig(item.moduleType).newVariation!) {
        _selectedVariations.addAll(cart.foodVariations ?? const []);
        _collapseVariation.addAll(itemServiceInterface.collapseVariation(item.foodVariations ?? const []));
      } else {
        _variationIndex = itemServiceInterface.initializeCartVariationIndexes(cart.variation, item.choiceOptions);
      }
    } else {
      if (ModuleHelper.getModuleConfig(item.moduleType).newVariation!) {
        _selectedVariations.addAll(itemServiceInterface.initializeSelectedVariation(item.foodVariations));
        _collapseVariation.addAll(itemServiceInterface.initializeCollapseVariation(item.foodVariations));
      } else {
        _variationIndex = itemServiceInterface.initializeVariationIndexes(item.choiceOptions);
      }

      _quantity = 1;
      _addOnActiveList.addAll(itemServiceInterface.initializeAddonActiveList(item.addOns));
      _addOnQtyList.addAll(itemServiceInterface.initializeAddonQtyList(item.addOns));

      setExistInCart(item, _selectedVariations, notify: true);
    }
  }

  void cartIndexSet() {
    _cartIndex = -1;
  }

  Future<int> setExistInCart(
      Item? item,
      List<List<bool?>>? selectedVariations, {
        bool notify = false,
      }) async {
    if (item == null) return -1;

    final String variationType = await itemServiceInterface.prepareVariationType(item.choiceOptions, _variationIndex);

    final bool useNewVariation = ModuleHelper.getModuleConfig(
      ModuleHelper.getModule() != null ? ModuleHelper.getModule()!.moduleType : ModuleHelper.getCacheModule()!.moduleType,
    ).newVariation!;

    if (useNewVariation) {
      _cartIndex = await itemServiceInterface.isExistInCartForBottomSheet(
        Get.find<CartController>().cartList,
        item.id,
        null,
        selectedVariations,
      );
    } else {
      _cartIndex = Get.find<CartController>().isExistInCart(item.id, variationType, false, null);
    }

    if (_cartIndex != -1) {
      _quantity = Get.find<CartController>().cartList[_cartIndex].quantity;
      _addOnActiveList = itemServiceInterface.initializeCartAddonActiveList(
        Get.find<CartController>().cartList[_cartIndex].addOnIds,
        item.addOns,
      );
      _addOnQtyList = itemServiceInterface.initializeCartAddonsQtyList(
        Get.find<CartController>().cartList[_cartIndex].addOnIds,
        item.addOns,
      );
    } else {
      _quantity = 1;
    }

    if (notify) update();
    return _cartIndex;
  }

  void setAddOnQuantity(bool isIncrement, int index) {
    _addOnQtyList[index] = itemServiceInterface.setAddOnQuantity(isIncrement, _addOnQtyList[index]!);
    update();
  }

  Future<void> setQuantity(bool isIncrement, int? stock, int? quantityLimit, {bool getxSnackBar = false}) async {
    _quantity = await itemServiceInterface.setQuantity(
      isIncrement,
      Get.find<SplashController>().configModel!.moduleConfig!.module!.stock!,
      stock,
      _quantity!,
      quantityLimit,
      getxSnackBar: getxSnackBar,
    );
    update();
  }

  void setCartVariationIndex(int index, int i, Item? item) {
    _variationIndex![index] = i;
    _quantity = 1;
    setExistInCart(item, _selectedVariations);
    update();
  }

  void showMoreSpecificSection(int index) {
    _collapseVariation[index] = !_collapseVariation[index];
    update();
  }

  void setNewCartVariationIndex(int index, int i, Item item) {
    _selectedVariations = itemServiceInterface.setNewCartVariationIndex(
      index,
      i,
      item.foodVariations!,
      _selectedVariations,
    );
    setExistInCart(item, _selectedVariations);
    update();
  }

  int selectedVariationLength(List<List<bool?>> selectedVariations, int index) {
    return itemServiceInterface.selectedVariationLength(selectedVariations, index);
  }

  void addAddOn(bool isAdd, int index) {
    _addOnActiveList[index] = isAdd;
    update();
  }

  void setImageIndex(int index, bool notify) {
    _imageIndex = index;
    if (notify) update();
  }

  void setSelect(int select, bool notify) {
    _productSelect = select;
    if (notify) update();
  }

  void setImageSliderIndex(int index) {
    _imageSliderIndex = index;
    update();
  }

  double? getStartingPrice(Item item) {
    return itemServiceInterface.getStartingPrice(item);
  }

  bool isAvailable(Item item) {
    return DateConverter.isAvailable(item.availableTimeStarts, item.availableTimeEnds);
  }

  double? getDiscount(Item item) => item.discount;
  String? getDiscountType(Item item) => item.discountType;

  void navigateToItemPage(Item? item, BuildContext context, {bool inStore = false, bool isCampaign = false}) {
    if (item == null) return;

    if (Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! || item.moduleType == 'food') {
      ResponsiveHelper.isMobile(context)
          ? Get.bottomSheet(
        ItemBottomSheet(itemId: item.id!, inStorePage: inStore, isCampaign: isCampaign, item: item),
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
      )
          : Get.dialog(
        Dialog(
          child: ItemBottomSheet(itemId: item.id!, inStorePage: inStore, isCampaign: isCampaign, item: item),
        ),
      );
    } else {
      Get.toNamed(
        RouteHelper.getItemDetailsRoute(item.id, inStore),
        arguments: ItemDetailsScreen(itemId: item.id!, inStorePage: inStore, isCampaign: isCampaign, item: item),
      );
    }
  }

  void itemDirectlyAddToCart(Item? item, BuildContext context, {bool inStore = false, bool isCampaign = false}) {
    if (item == null) return;

    getItemDetails(itemId: item.id!).then((value) {
      if (_item == null) return;

      final bool isFoodModule = (Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ||
          _item?.moduleType == AppConstants.food);

      final bool noVariations =
      (((_item!.foodVariations != null && _item!.foodVariations!.isEmpty) && _item?.moduleType == AppConstants.food) ||
          ((_item?.variations != null && _item!.variations!.isEmpty) && _item?.moduleType != AppConstants.food));

      if (noVariations) {
        final double price = _item!.price!;
        final double discount = _item!.discount ?? 0;
        final double discountPrice = PriceConverter.convertWithDiscount(price, discount, _item!.discountType) ?? price;

        final CartModel cartModel = CartModel(
          null,
          price,
          discount,
          [],
          [],
          (price - discountPrice),
          1,
          [],
          [],
          isCampaign,
          _item?.stock,
          _item,
          _item?.quantityLimit,
        );

        final OnlineCart onlineCart = OnlineCart(
          null,
          isCampaign ? null : _item?.id,
          isCampaign ? _item?.id : null,
          price.toString(),
          '',
          null,
          ModuleHelper.getModuleConfig(_item?.moduleType).newVariation! ? [] : null,
          1,
          [],
          [],
          [],
          'Item',
        );

        if (Get.find<SplashController>().configModel!.moduleConfig!.module!.stock! && (_item!.stock ?? 0) <= 0) {
          showCustomSnackBar('out_of_stock'.tr);
        } else if (Get.find<CartController>().existAnotherStoreItem(
          cartModel.item!.storeId,
          ModuleHelper.getModule() != null ? ModuleHelper.getModule()?.id : ModuleHelper.getCacheModule()?.id,
        )) {
          Get.dialog(
            ConfirmationDialog(
              icon: Images.warning,
              title: 'are_you_sure_to_reset'.tr,
              description: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                  ? 'if_you_continue'.tr
                  : 'if_you_continue_without_another_store'.tr,
              onYesPressed: () {
                Get.find<CartController>().clearCartOnline().then((success) async {
                  if (success) {
                    await Get.find<CartController>().addToCartOnline(onlineCart);
                    Get.back();
                    showCartSnackBar();
                  }
                });
              },
            ),
            barrierDismissible: false,
          );
        } else {
          Get.find<CartController>().addToCartOnline(onlineCart);
          showCartSnackBar();
        }
      } else if (isFoodModule) {
        ResponsiveHelper.isMobile(Get.context)
            ? Get.bottomSheet(
          ItemBottomSheet(itemId: _item!.id!, inStorePage: inStore, isCampaign: isCampaign),
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
        )
            : Get.dialog(
          Dialog(child: ItemBottomSheet(itemId: _item!.id!, inStorePage: inStore, isCampaign: isCampaign)),
        );
      } else {
        Get.toNamed(
          RouteHelper.getItemDetailsRoute(_item!.id, inStore),
          arguments: ItemDetailsScreen(itemId: _item!.id!, inStorePage: inStore),
        );
      }
    });
  }
}
