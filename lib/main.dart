import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spritewidget/spritewidget.dart';

main() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) => runApp(App()));
}

var title = 'Touch the Programming';
var rand = Random();

class App extends StatelessWidget {
  build(var _) {
    var theme = ThemeData(primaryColor: Colors.grey[50]);
    return MaterialApp(title: title, theme: theme, home: Page());
  }
}

class Page extends StatefulWidget {
  _State createState() => _State();
}

class _State extends State<Page> with SingleTickerProviderStateMixin {
  List<List<List<Code>>> data = [
    [[]]
  ];
  var player = Player(Size(512, 512));
  var menu = toL(
      ['Comments', 'Assign', 'Loop', 'If', 'Wrap-up'].map((m) => Tab(text: m)));
  var _tabCon;
  @override
  initState() {
    super.initState();
    _tabCon = TabController(length: 5, vsync: this)..addListener(_syncTab);
    rootBundle.loadString('assets/data.json').then((d) => setState(() => data =
        toL((json.decode(d) as List).map((t) => toL((t as List)
            .map((l) => toL((l as List).map((c) => Code.fromJson(c)))))))));
  }

  build(var _) {
    _syncTab();
    var tabs = toL(data.map((t) => ListView(
        children: toL(t.map((l) => Container(
            height: 30,
            padding: EdgeInsets.only(left: 10),
            child: Row(children: toL(l.map((c) => _codeSpan(c))))))))));
    var tabBar = TabBar(
        controller: _tabCon,
        isScrollable: true,
        tabs: menu,
        indicatorColor: Colors.black);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(title), elevation: 0, actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _syncTab)
        ]),
        body: Column(
          children: [
            AspectRatio(aspectRatio: 1.3, child: SpriteWidget(player)),
            Container(color: Colors.grey[50], child: tabBar),
            Expanded(child: TabBarView(controller: _tabCon, children: tabs)),
          ],
        ));
  }

  _syncTab() => player.init(toL(data[_tabCon.index].expand((l) => l)));
  _codeSpan(Code c) => c.opts.isEmpty
      ? Text(c.val)
      : DropdownButton(
          value: c.val,
          onChanged: (v) => setState(() => c.val = v),
          items: toL(
              c.opts.map((o) => DropdownMenuItem(value: o, child: Text(o)))),
          iconSize: 0,
          style: TextStyle(color: Colors.red, fontSize: 16));
}

class Player extends NodeWithSize {
  Player(var s) : super(s);
  int n, i;
  List nodes, tabs;
  init(var tab) {
    n = find(tab, 'num') != null ? int.parse(find(tab, 'num')) : 1;
    nodes = [];
    tabs = [];
    removeAllChildren();
    for (var j = 0; j < n; j++) {
      i = j;
      tabs.add(toL(tab.map((c) => c.clone())));
      nodes.add(Offset(256 + _dbl('x'), 256 + _dbl('y')));
    }
  }

  paint(var c) {
    for (var j = 0; j < n; j++) {
      i = j;
      _paint(c);
    }
  }

  _paint(var c) {
    if (_val('ifx') != null) {
      if (nodes[i].dx > 256 + _dbl('ifx'))
        nodes[i] = Offset(256 + _dbl('ifxx'), nodes[i].dy);
    }
    if (_val('ify') != null) {
      if (nodes[i].dy > 256 + _dbl('ify'))
        nodes[i] = Offset(nodes[i].dx, 256 + _dbl('ifyy'));
    }
    nodes[i] = Offset(nodes[i].dx + _dbl('vx'), nodes[i].dy + _dbl('vy'));

    if (_val('l') == 'true') {
      addChild(Dot()
        ..position = nodes[i]
        ..col = _col('line')
        ..w = _dbl('linew'));
    }
    [
      ['fill', 0],
      ['str', 1]
    ].forEach((l) {
      var p = Paint()
        ..color = _col(l[0])
        ..style = PaintingStyle.values[l[1]]
        ..strokeWidth = _dbl('strw');
      var r = _dbl('r', or: 50);
      _val('sh') == 'Rect'
          ? c.drawRect(Rect.fromCircle(center: nodes[i], radius: r), p)
          : c.drawCircle(nodes[i], r, p);
    });
  }

  _val(var id) => find(tabs[i], id);
  _dbl(var id, {double or = 0}) =>
      _val(id) != null ? double.parse(_val(id)) : or;
  _col(var id) => _val(id) != null
      ? Color(int.parse(_val(id), radix: 16)).withOpacity(_dbl('${id}opa'))
      : Colors.grey;
}

class Dot extends Node {
  var col, w;
  paint(var c) => c.drawCircle(Offset.zero, w, Paint()..color = col);
}

class Code {
  Code({this.val, this.id, this.opts, this.noCache});
  var val, id, cache, noCache;
  List opts;
  factory Code.fromJson(var json) => Code(
      val: json['val'],
      id: json['id'],
      noCache: json['noCache'],
      opts: (json['opts'] as List).cast<String>());
  clone() => Code(val: val, id: id, noCache: noCache, opts: opts);
  parse() {
    if (val != 'Random') return val;
    if (cache != null) return cache;
    var i = rand.nextInt(opts.length - 1);
    var c = toL(opts.where((o) => o != 'Random'))[i];
    return noCache ? c : cache = c;
  }
}

find<E>(var tab, id) =>
    tab.firstWhere((c) => c.id == id, orElse: () => null)?.parse();
List<E> toL<E>(Iterable<E> i) => i.toList();
