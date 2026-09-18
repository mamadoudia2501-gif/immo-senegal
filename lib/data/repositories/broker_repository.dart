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
}
