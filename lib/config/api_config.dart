class ApiConfig {

  // Base URL for the API
  static const String baseUrl = 'http://172.16.0.227:5000/api';

  // Auth endpoints
  static const String authLogin = '/delivery/auth/login';
 
  // Task
  static const String taskPath = '/delivery/tasks';

  // History
  static const String history = '/delivery/tasks';
  
  //Profile
    static const String profile = '/delivery/profile';
    static const String logout = '/delivery/auth/logout';

  //Analytics
    static const String dashboard = '/delivery/home/dashboard-summary';
    static const String weeklyPerformance = '/delivery/home/weekly-performance';



  // Helper methods to build full URLs
  static String getAuthLoginUrl() => '$baseUrl$authLogin';

  static String getTaskUrl({
    required String type,
    String? status,
    String? date,
    int page = 1,
    int limit = 20,
  }) {
    final uri = Uri.parse('$baseUrl$taskPath').replace(
      queryParameters: {
        'type': type,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    return uri.toString();
  }

  static String getTaskDetailUrl({required String taskId}) {
    final encodedId = Uri.encodeComponent(taskId.trim());
    return '$baseUrl$taskPath/$encodedId';
  }

  static String getTaskStatusUrl({required String taskId}) {
    final encodedId = Uri.encodeComponent(taskId.trim());
    return '$baseUrl$taskPath/$encodedId/status';
  }

  static String getTaskVerifyOtpUrl({required String taskId}) {
    final encodedId = Uri.encodeComponent(taskId.trim());
    return '$baseUrl$taskPath/$encodedId/verify-otp';
  }

  static String getTaskPostnUrl({required String taskId}) {
    final encodedId = Uri.encodeComponent(taskId.trim());
    return '$baseUrl$taskPath/$encodedId/proof-photo';
  }

  static String getProfileUrl() => '$baseUrl$profile';

  static String getHistoryUrl() => '$baseUrl$history';

  static String getLogoutUrl() => '$baseUrl$logout';

  static String getDashboardUrl() => '$baseUrl$dashboard';

  static String getWeeklyPerformanceUrl() => '$baseUrl$weeklyPerformance';

}



//   //Profile-Setup
//   static const String profileSetup = '/vendor/auth/setup-profile';
//   static const String locationStates = '/location/states';
//   static const String locationDistricts = '/location/districts?state_id={state_id}&state_name={state_name}';
//   static const String locationCities = '/location/cities?district_id={district_id}&district_name={district_name}';

// //   //Profile-Detail
//   static const String profileDetail = '/vendor/auth/me';

// //   //Home
//   static const String dashboard = '/vendor/home/dashboard';

// //   //Product
//   static const String product = '/vendor/products/categories';
//   static const String productcard = '/vendor/products?page=1&limit=20';
//   static const String productDetail = '/vendor/products/{product_id}';

// //Cart
//   static const String cart = '/vendor/cart';
//   static const String addtocart = '/vendor/cart/add';
//   static const String deletecart = '/vendor/cart/remove/{product_id}_{pricing_id}';
//   static const String clearcart = '/vendor/cart/clear';
//   static const String updatecart = '/vendor/cart/update';
//   static const String address = '/vendor/orders/addresses';
//   static const String addressupdate = '/vendor/orders/addresses/{address_id}';
//   // static const String checkout = '/vendor/cart/checkout';

//   //Order
//   static const String orders = "/vendor/orders?status={status}&page={page}&limit={limit}";
//   static const String orderdetail = "/vendor/orders/{order_id}";

//   //Profile
//   static const String authLogout = '/vendor/auth/logout';
//   static const String accountinactive = '/vendor/auth/account';
//   static const String editprofile = '/vendor/auth/edit-profile';


//   static String getAuthVerifyOtpUrl() => '$baseUrl$authVerifyOtp';
//   static String getProfileSetupUrl() => '$baseUrl$profileSetup';
//   static String getProfileDetailUrl() => '$baseUrl$profileDetail';
//   static String getLocationStatesUrl() => '$baseUrl$locationStates';

//   static String getLocationDistrictsUrl(String stateId, String stateName) =>
//       '$baseUrl${locationDistricts.replaceAll('{state_id}', stateId).replaceAll('{state_name}', Uri.encodeComponent(stateName))}';
  
//   static String getLocationCitiesUrl(String districtId, String districtName) =>
//       '$baseUrl${locationCities.replaceAll('{district_id}', districtId).replaceAll('{district_name}', Uri.encodeComponent(districtName))}';
  
//   static String getDashboardUrl() => '$baseUrl$dashboard';

//   static String getProductUrl() => '$baseUrl$product';

//   static String getProductcardUrl() => '$baseUrl$productcard';

//   static String getProductDetailUrl(int productId) =>
//       '$baseUrl${productDetail.replaceAll('{product_id}', productId.toString())}';

//   static String getcartUrl() => '$baseUrl$cart';

//   static String getAddtocartUrl() => '$baseUrl$addtocart';

//   static String getClearcartUrl() => '$baseUrl$clearcart';

//   static String getUpdatecartUrl() => '$baseUrl$updatecart';

//   static String getDeletecartUrl(int productId, int pricingId) =>
//       '$baseUrl${deletecart.replaceAll('{product_id}', productId.toString()).replaceAll('{pricing_id}', pricingId.toString())}';

//   static String getEditprofilelUrl() =>'$baseUrl$editprofile';

//   static String getAuthLogoutUrl() => '$baseUrl$authLogout';

//   static String getAccountInactiveUrl() => '$baseUrl$accountinactive'; 

//   static String getOrdersUrl({
//     String? status,
//     int page = 1,
//     int limit = 20,
//   }) {
//     var url = '$baseUrl$orders'
//         .replaceAll('{page}', page.toString())
//         .replaceAll('{limit}', limit.toString());

//     final normalized = (status ?? '').trim();
//     if (normalized.isEmpty || normalized.toLowerCase() == 'all') {
//       url = url.replaceAll(RegExp(r'([?&])status=\{status\}&?'), r'$1');
//       url = url.replaceAll(RegExp(r'[?&]$'), '');
//       url = url.replaceAll('&&', '&').replaceAll('?&', '?');
//       return url;
//     }

//     return url.replaceAll('{status}', Uri.encodeComponent(normalized));
//   }

//   static String getOrderdetailUrl(int orderId) =>
//       '$baseUrl${orderdetail.replaceAll('{order_id}', orderId.toString())}';

//   static String getAddressUrl() =>'$baseUrl$address';

//   static String getAddressupdateUrl(int addressId) =>
//       '$baseUrl${addressupdate.replaceAll('{address_id}', addressId.toString())}';

//   static String getAddressdeleteUrl(int addressId) =>
//       '$baseUrl${addressupdate.replaceAll('{address_id}', addressId.toString())}';

  // static String getCheckoutUrl() => '$baseUrl$checkout';
