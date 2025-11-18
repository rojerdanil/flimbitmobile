class ApiEndpoints {
  static const String baseUrl = "http://localhost:8090";

  // Auth endpoints
  static const String phoneVerify = "$baseUrl/login/sendregotp";
  static const String getUserProfile = "$baseUrl/user/profile";

  //announcement
  static const String userSpecificRemainder =
      "$baseUrl/announcements/mobile/findUserSpecific-remainder";

  static const String userNotificationCount =
      "$baseUrl/announcements/mobile/find-remainder-count";

  static const String userMoiveRemainder =
      "$baseUrl/announcements/mobile/findMoive-remainder";
  static const String markUserNotificationRead =
      "$baseUrl/announcements/mobile/user_specific/mark-read";
  static const String markAnnouncementRead =
      "$baseUrl/announcements/mobile/annoncement_specific/mark-read";

  static const String posterRead = "$baseUrl/announcements/mobile/find-poster";

  static const String recommandedMovie =
      "$baseUrl/movie/mobile/recommended-movies";

  static const String winners = "$baseUrl/user-winners/mobile/star-winner";
  static const String upcommingMovies = "$baseUrl/movie/mobile/upcoming-movies";
  static const String topInvestors =
      "$baseUrl/user-winners/mobile/star-invester";
  static const String boxOfficeMovies = "$baseUrl/movie/mobile/running-movies";
  static const String topProfitHolders =
      "$baseUrl/user-winners/mobile/star-profitholder";
  static const String searchMovies = "$baseUrl/movie/mobile/movies-filter";
  static const String languages = "$baseUrl/languages/alllangugage";
  static const String genres = "$baseUrl/movie-types/alltypes";
  static const String movieStatus = "$baseUrl/movie-status/allstatus";
  static const String summary = "$baseUrl/userShare/user_invested_summory";
  static const String userShare_movies =
      "$baseUrl/userShare/mobile/movies-invested";
  static const String userPortfolio = "$baseUrl/portFolio/portfolioSummery";
  static const String last3Activity =
      "$baseUrl/portFolio/mobile/userlastactivity";
  static const String rewards =
      "$baseUrl/user-winners/mobile/user-win-all-star-offer";
  static const String portfolioChart =
      "$baseUrl/dashboard/mobile/userInvesteddashBoardChart";
  static const String userProfileData = "$baseUrl/users/mobile/userProfile";
  static const String userWalletBalance = "$baseUrl/wallet/mobile/user-balance";
  static const String userInvestmentSummary =
      "$baseUrl/user-profile/mobile/user-portfolio";
  static const String walletTransactions =
      "$baseUrl/wallet/mobile/read-user-wallet-trx";
  static const String movieView = "$baseUrl/movie/mobile/movie-view/";
  static const String movieOffers = "$baseUrl/offers/mobile/movie_all_offers/";
  static const String movieActors =
      "$baseUrl/actors-in-movie/actorsInMovieById?id=";
  static const String topProfitHolder =
      "$baseUrl/user-winners/mobile/star-profitholder";
  static const String readMovieStarConnectOffer =
      "$baseUrl/movie-bigoffers/readBigOFferMovie/";
  static const String readMovieWinner =
      "$baseUrl/user-winners/mobile/movie-offer-winner";
  static const String starConnectOfferDetails =
      "$baseUrl/movie-bigoffers/mobile/readBigOffer/";

  static const String shareDetails = "$baseUrl/share-types/mobile/movie/";
  static const String flimbitOffer =
      "$baseUrl/offer-mappings/mobile/readShareOffer/";
  static const String readCinemaNews =
      "$baseUrl/movie-news/mobile/read_movie_news";
  static const String readCollectionReport =
      "$baseUrl/movie-collection/mobile/movie-collection";
  static const String userInvestmentHistory =
      "$baseUrl/transactions/mobile/user-investment-history";
  static const String buyShares =
      "$baseUrl/transactions/mobile/user-investment-history";

  static const String gatewayFees = "$baseUrl/login/payment-methods";

  static const String movieInvestCountSummary =
      "$baseUrl/movie/mobile/movie-invest-count-summary/";
  static const String calculateOffer = "$baseUrl/movieInvest/calculate-offer";
  static const String calculateFee = "$baseUrl/login/calculate-fee";

  static const String redirectToPayment =
      "$baseUrl/movieInvest/redirect-to-payment";
  static const String verifyPaymentBuyShare =
      "$baseUrl/movieInvest/payment/update-from-flutter";

  static const String movieSummaryCounts =
      "$baseUrl/movie/mobile/movie-summary";

  static const String movieStarConnectOffer =
      "$baseUrl/movie-bigoffers/mobile/read-star-offer";
  static const String movieStarConnectOfferTypes =
      "$baseUrl/star-connector-offers/all_offer";

  static const String cinemaBuzzMovies =
      "$baseUrl/transactions/mobile/cinema-buzz";

  static const String usertopInvestedMovies =
      "$baseUrl/movieInvest/mobile/user-top-invested-movie";

  static const String userlatestProfitMovies =
      "$baseUrl/user-winners/mobile/user-top-profited-movie";

  static const String investmentGrowthChart =
      "$baseUrl/dashboard/mobile/overall_investement_chat";

  static const String topLiveInvestingMovies =
      "$baseUrl/movieInvest/mobile/top-invested-movie-live";

  static const String topProdcutionCompany =
      "$baseUrl/production-company/mobile/top_production_company";

  static const String readtopProdcutionCompanyMovies =
      "$baseUrl/production-company/mobile/read_movies";

  static const String userInvestedMovieSummary =
      "$baseUrl/userShare/mobile/user_invested_movie_summary/";
  static const String userInvestedMovieShare =
      "$baseUrl/userShare/mobile/user_movie_share/";
  static const String movieShareCalculateOfferSummary =
      "$baseUrl/userShare/mobile/movie_offer_summary/";

  static const String movieShareSoldCountummary =
      "$baseUrl/transactions/mobile/user-share-sold-history-summary/";

  static const String verifySellSharesSummary =
      "$baseUrl/sell-share/mobile/verify-sell-share";

  static const String startShellShare =
      "$baseUrl/sell-share/mobile/start-sell-share";
  static const String userBankAccountsDetails =
      "$baseUrl/user-bank/mobile/user-gateway-service";
  static const String addBankAccount = "$baseUrl/user-bank/mobile/add-bank";
  static const String addUpiAccount = "$baseUrl/security/mobile/verify-pin";
  static const String deleteBankAccount = "$baseUrl/security/mobile/verify-pin";

  static const String deleteUpiAccount = "$baseUrl/security/mobile/verify-pin";

  static const String verifyPin = "$baseUrl/security/mobile/verify-pin";
  static const String loginVerifyPin =
      "$baseUrl/login/mobile/relogin-bin-validation";

  static const String inactivateUserPan =
      "$baseUrl/users/mobile/deactivate/pan";
  static const String verifyAndSavePan = "$baseUrl/users/mobile/initiatePan";
  static const String inactivateUserEmail =
      "$baseUrl/users/mobile/deactivate/email";
  static const String sendEmailOtp =
      "$baseUrl/users/mobile/sendVerificationEmail";
  static const String verifyEmailOtp = "$baseUrl/users/mobile/verifyEmail/";

  static const String uploadProfileImage =
      "$baseUrl/users/mobile/upload-profile-image";

  static const String walletAddMoneySummary =
      "$baseUrl/wallet/mobile/add-money-summary";
  static const String walletVerifyPaymentSummary =
      "$baseUrl/wallet/mobile/verify-payment-summary";
  static const String walletMonyeySuccess =
      "$baseUrl/wallet/mobile/verify-payment-done";
  static const String withdrawMoney = "$baseUrl/wallet/moblie/cash-withdraw";

  static const String reward_star_connect_summary =
      "$baseUrl/user-winners/mobile/user-star-connet-summary";
  static const String reward_flim_bit_summary =
      "$baseUrl/user-winners/mobile/user-flimbit-summary";

  static const String reward_star_connect_movie_list =
      "$baseUrl/user-winners/mobile/user-star-connet-movie";
  static const String reward_filmbit_movie_list =
      "$baseUrl/user-winners/mobile/user-flimbit-connet-movie";
  static const String companyContact = "$baseUrl/login/mobile/company-details";

  static const String security_change_pin =
      "$baseUrl/security/mobile/change-pin";

  static const String user_setting_read =
      "$baseUrl/user-setting/mobile/read-user-setting";
  static const String user_setting_update =
      "$baseUrl/user-setting/mobile/user-setting-update";
  static const String logOut = "$baseUrl/security/mobile/logout";

  static const String validateUser = "$baseUrl/users/mobile/validateUser";
  static const String createToken = "$baseUrl/login/mobile/createToken";

  static const String sendRecoverOtp = "$baseUrl/login/mobile/recover-otp";
  static const String verifyRecoverOtp =
      "$baseUrl/login/mobile/recover-otp-validate";
  static const String verifyRecoverPin =
      "$baseUrl/login/mobile/recover-bin-validation";

  static const String registerSendOtp = "$baseUrl/loginss/mobile/sendregotp";
  static const String registerVerifyOtp =
      "$baseUrl/login/mobile/validateRegOtp";

  static const String registerAllLanguage =
      "$baseUrl/login/mobile/alllangugage";
}
