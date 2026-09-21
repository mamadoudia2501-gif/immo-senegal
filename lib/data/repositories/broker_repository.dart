import '../../core/utils/phone.dart';
import '../mock/sample_data.dart';
import '../models/broker.dart';

class BrokerRepository {
  const BrokerRepository();

  List<Broker> all() => List.unmodifiable(sampleBrokers);

  Broker? byId(String id) {
    for (final broker in sampleBrokers) {
      if (broker.id == id) return broker;
    }
    return null;
  }

  Broker? byPhone(String phone) {
    final local = senegalLocalDigits(phone);
    for (final broker in sampleBrokers) {
      if (senegalLocalDigits(broker.phone) == local) return broker;
    }
    return null;
  }
}
