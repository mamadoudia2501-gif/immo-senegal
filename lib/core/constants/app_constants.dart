abstract final class AppConstants {
  static const name = 'Immo Sénégal';
  static const tagline = 'Trouvez votre bien au Sénégal';
  static const currency = 'FCFA';
  static const country = 'Sénégal';
  static const defaultLocale = 'fr_SN';

  /// Code WhatsApp de démo pour les annonceurs (aucun SMS réel).
  static const whatsappDemoCode = '123456';

  /// Code OTP administrateur. Ne jamais l’afficher dans l’UI.
  static const whatsappAdminCode = '12345693';

  /// Numéro admin (logique uniquement). Ne jamais l’afficher dans l’UI.
  static const adminPhoneLocal = '770000000';

  static const freeListingQuota = 4;
  static const extraListingPriceFcfa = 100;
  static const minListingPhotos = 1;
  static const maxListingPhotos = 4;

  /// Abonnement stories / statut (paiement mock).
  static const storySubscriptionFcfa = 2000;
  static const storySubscriptionDays = 30;
  static const storyTtlHours = 24;

  static String otpForLocalPhone(String localDigits) =>
      localDigits == adminPhoneLocal ? whatsappAdminCode : whatsappDemoCode;

  static const cities = <String>[
    'Dakar',
    'Thiès',
    'Saint-Louis',
    'Mbour',
    'Saly',
    'Rufisque',
    'Pikine',
    'Guédiawaye',
    'Touba',
    'Kaolack',
    'Ziguinchor',
    'Louga',
  ];
}
