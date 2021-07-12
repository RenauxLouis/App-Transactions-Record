import "package:http/http.dart" as http;
import "dart:convert";

abstract class TransactionRepository {
  Future<String> writeTransaction(laverie, machine, load, email);
}

class FakeTransactionRepository implements TransactionRepository {
  @override
  Future<String> writeTransaction(laverie, machine, load, email) async {
    http.Response response = await http.Client().get(Uri.https(
        "qrcodelaveylivrey.com", "/add_transaction_row_with_load", {
      "code": laverie,
      "machine": machine,
      "loads": load.toString(),
      "user": email
    }));
    if (response.statusCode == 200) {
      return "valid transaction";
    } else {
      print("fail http");
      print(response.statusCode);
      throw Exception("Failed to write transaction");
    }
  }
}
