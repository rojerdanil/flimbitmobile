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
  static const String markAllUserNotificationsRead = "";
  static const String markAllAnnouncementsRead = "";
  static const String markUserNotificationRead = "";
  static const String markAnnouncementRead = "";

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
  static const String verifyPayment =
      "$baseUrl/movieInvest/payment/update-from-flutter";

  static const String movieSummaryCounts =
      "$baseUrl/movie/mobile/movie-summary";
}
