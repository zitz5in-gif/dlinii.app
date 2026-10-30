import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlinii_app/dlinii_sheet.dart';

void main(){
  testWidgets('sheet controllers survive replacement and sibling insertion', (tester) async {
    Widget sheet(String name)=>DliniiSheet(key:ValueKey(name),builder:(context,scroll,expand)=>Material(child:ListView(controller:scroll,children:[TextButton(onPressed:expand,child:Text('expand $name')),const SizedBox(height:1000)])));
    Widget app(bool perspective)=>MaterialApp(home:Scaffold(body:Stack(children:[
      if(perspective)const Positioned.fill(child:ColoredBox(color:Colors.black)),
      Positioned.fill(key:ValueKey(perspective),child:sheet('home')),
    ])));
    await tester.pumpWidget(app(false));
    for(var i=0;i<6;i++){
      await tester.pumpWidget(app(i.isEven));
      await tester.pump();
      expect(tester.takeException(),isNull);
      await tester.tap(find.text('expand home'));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
    }
    await tester.pumpWidget(MaterialApp(home:Stack(children:[sheet('one'),sheet('two')])));
    await tester.pump();
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(),isNull);
  });
}
