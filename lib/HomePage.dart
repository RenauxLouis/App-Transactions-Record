// @dart=2.9
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cubit/transaction_cubit.dart';
import 'data/transaction_repository.dart';

class ScreenArguments {
  final String email;
  ScreenArguments(this.email);
}

class MyAppWrap extends StatefulWidget {
  MyAppWrap({Key key, this.email}) : super(key: key);
  final String email;

  @override
  _MyAppWrapState createState() => _MyAppWrapState();
}

class _MyAppWrapState extends State<MyAppWrap> {
  Future<Map<String, Widget Function(BuildContext)>> routes;

  @override
  initState() {
    super.initState();
    routes = buildRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Widget Function(BuildContext)>>(
        future: routes,
        builder: (context, snapshot) {
          print(snapshot.hasData);
          if (snapshot.hasData) {
            return MyApp(routes: snapshot.data, email: widget.email);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return Center(
              child: Container(
                  child: CircularProgressIndicator(),
                  width: 48.0,
                  height: 48.0));
        });
  }

  Future<Map<String, Widget Function(BuildContext)>> buildRoutes() async {
    List laveries = [];
    Map<String, Widget Function(BuildContext)> routes = {};
    await FirebaseFirestore.instance
        .collection("laveries")
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        String laverie = doc.id;
        laveries.add(laverie);
        print(laverie);

        List machines = doc["machines"];
        print(machines);
        for (var i = 0; i < machines.length; i++) {
          String machine = machines[i];
          print(machine);
          routes["/" + laverie + "_" + machine] = (context) => BlocProvider(
                create: (context) =>
                    TransactionCubit(FakeTransactionRepository()),
                child: LoadsScreen(
                    laverie: laverie, machine: machine, email: widget.email),
              );
          routes["/" + laverie] =
              (context) => MachinesScreen(laverie: laverie, machines: machines);
        }
      });
    });
    print(laveries);
    routes["/"] = (context) => LaveriesScreen(laveries: laveries);

    print(routes);
    return routes;
  }
}

class MyApp extends StatefulWidget {
  MyApp({Key key, this.routes, this.email}) : super(key: key);
  final Map<String, Widget Function(BuildContext)> routes;
  String email;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Laverie Privée",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: "/",
        routes: widget.routes);
  }
}

class LaveriesScreen extends StatefulWidget {
  LaveriesScreen({Key key, this.laveries}) : super(key: key);
  final List laveries;

  @override
  _LaveriesScreenState createState() => _LaveriesScreenState();
}

class _LaveriesScreenState extends State<LaveriesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Veuillez sélectionner une laverie"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
                child: ListView(
              padding: const EdgeInsets.all(8),
              children: buildListeLaveries(widget.laveries),
            ))
          ],
        ),
      ),
    );
  }

  List<Widget> buildListeLaveries(laveries) {
    List<Widget> widgets = [];
    for (var i = 0; i < laveries.length; i++) {
      String laverie = laveries[i];
      Widget listWidget = ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
          onPrimary: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, "/" + laverie);
        },
        child: Text("Laverie " + laverie),
      );
      widgets.add(listWidget);
    }
    return widgets;
  }
}

class MachinesScreen extends StatefulWidget {
  MachinesScreen({Key key, this.laverie, this.machines}) : super(key: key);
  final String laverie;
  final List machines;

  @override
  _MachinesScreenState createState() => _MachinesScreenState();
}

class _MachinesScreenState extends State<MachinesScreen> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Veuillez sélectionner une machine"),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
                child: ListView(
              padding: const EdgeInsets.all(8),
              children: buildListeMachines(widget.laverie, widget.machines),
            ))
          ],
        ),
      ),
    );
  }

  List<Widget> buildListeMachines(laverie, machines) {
    List<Widget> widgets = [];
    for (var i = 0; i < machines.length; i++) {
      String machine = machines[i];
      Widget listWidget = ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
          onPrimary: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, "/" + laverie + "_" + machine);
        },
        child: Text(machine),
      );
      widgets.add(listWidget);
    }
    return widgets;
  }
}

class LoadsScreen extends StatefulWidget {
  LoadsScreen({Key key, this.laverie, this.machine, this.email})
      : super(key: key);
  final String laverie;
  final String machine;
  final String email;

  @override
  _LoadsScreenState createState() => _LoadsScreenState();
}

class _LoadsScreenState extends State<LoadsScreen> {
  String load = "2";

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Combien de machines?"),
      ),
      body: BlocConsumer<TransactionCubit, TransactionState>(
          listener: (context, state) {
        if (state is TransactionError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is TransactionLoaded) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Success")));
        }
      }, builder: (context, state) {
        if (state is TransactionInitial) {
          return buildInitialLoadScreen();
        } else if (state is TransactionLoading) {
          return buildLoading();
        } else if (state is TransactionLoaded) {
          return buildInitialLoadScreen();
        } else {
          // (state is TickerError)
          return buildInitialLoadScreen();
        }
      }),
    );
  }

  Widget buildInitialLoadScreen() {
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            onPressed: () {
              sendHttpCall(
                  context, widget.laverie, widget.machine, 1, widget.email);
            },
            child: Text("1"),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dropDownLoads(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                ),
                onPressed: () {
                  sendHttpCall(context, widget.laverie, widget.machine, load,
                      widget.email);
                },
                child: Text("SEND"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildLoading() {
    return Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      CircularProgressIndicator(),
      Text("Sauvegarde de la transaction", style: TextStyle(fontSize: 20))
    ]));
  }

  Widget dropDownLoads() {
    return DropdownButton<String>(
      value: load,
      icon: const Icon(Icons.arrow_downward),
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.blue),
      underline: Container(
        height: 2,
        color: Colors.blue,
      ),
      onChanged: (newValue) {
        setState(() {
          load = newValue;
        });
      },
      items: <String>[for (var i = 0; i < 20; i += 1) i.toString()]
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  sendHttpCall(context, laverie, machine, load, email) {
    print(laverie);
    print(machine);
    print(load);
    final transactionCubit = BlocProvider.of<TransactionCubit>(context);
    transactionCubit.writeTransaction(laverie, machine, load, email);
  }
}
