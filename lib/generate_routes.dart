import 'package:flutter/material.dart';
// import 'package:laverie_privee_qrcode/main.dart';

class RouteGenerator {

  routes = buildRoutes();


  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => FirstPage());
      case '/second':
        // Validation of correct data type
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => SecondPage(
              data: args,
            ),
          );
        }
        // If args is not of the correct type, return an error page.
        // You can also throw an exception while in development.
        return _errorRoute();
      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR'),
        ),
      );
    });
  }

  Future<Map<String, Widget Function(BuildContext)>> buildRoutes() async {
    // Map machinesPerLaverie = {
    //   "75010-03": ["6kgs", "S8"],
    //   "75010-02": ["S8"]
    // };
    List laveries = [];
    await FirebaseFirestore.instance
        .collection("laveries")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        String laverie = doc.id;
        laveries.add(laverie);
        print(laverie);
        routes["/" + laverie] = (context) => MachinesScreen(laverie: laverie);

        List machines = doc["machines"];
        print(machines);
        for (var i = 0; i < machines.length; i++) {
          String machine = machines[i];
          print(machine);
          routes["/" + laverie + "_" + machine] = (context) => BlocProvider(
                create: (context) =>
                    TransactionCubit(FakeTransactionRepository()),
                child: LoadsScreen(laverie: laverie, machine: machine),
              );
        }
      });
    });
    print(laveries);
    routes["/"] = (context) => LaveriesScreen(laveries: laveries);
    return routes;
  }
}
