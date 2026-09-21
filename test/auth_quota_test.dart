import 'package:flutter_test/flutter_test.dart';
import 'package:immo_senegal/core/constants/app_constants.dart';
import 'package:immo_senegal/data/models/app_user.dart';
import 'package:immo_senegal/data/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthRepository> repo() async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthRepository(
      preferences: await SharedPreferences.getInstance(),
    );
    await auth.load();
    return auth;
  }

  test('annonceur : 4 gratuites puis paiement mock', () async {
    final auth = await repo();
    await auth.requestCode(phone: '771112233', name: 'Awa');
    expect(await auth.verifyDemoCode('000000'), isFalse);
    expect(await auth.verifyDemoCode(AppConstants.whatsappDemoCode), isTrue);
    expect(auth.currentUser?.role, UserRole.advertiser);
    expect(auth.currentUser?.freeListingsRemaining, 4);

    for (var i = 0; i < 4; i++) {
      expect(await auth.reserveListingSlot(), ListingSlot.free);
    }
    expect(auth.currentUser?.freeListingsRemaining, 0);
    expect(auth.previewListingSlot(), ListingSlot.needsPayment);
    expect(await auth.reserveListingSlot(), ListingSlot.needsPayment);
    expect(await auth.reserveListingSlot(pay: true), ListingSlot.paid);
    expect(auth.currentUser?.paidCount, 1);
    expect(auth.currentUser?.publishedCount, 5);
  });

  test('admin : publication gratuite illimitée', () async {
    final auth = await repo();
    await auth.requestCode(phone: AppConstants.adminPhoneLocal);
    expect(await auth.verifyDemoCode(AppConstants.whatsappDemoCode), isTrue);
    expect(auth.isAdmin, isTrue);
    for (var i = 0; i < 6; i++) {
      expect(await auth.reserveListingSlot(), ListingSlot.adminUnlimited);
    }
    expect(auth.previewListingSlot(), ListingSlot.adminUnlimited);
    expect(auth.currentUser?.paidCount, 0);
  });
}
