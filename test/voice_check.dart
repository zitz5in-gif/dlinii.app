import '../lib/voice_selection.dart';
void main(){
  final voices=<Map<String,String>>[
    {'name':'Microsoft David - English (United States)','locale':'en-US'},
    {'name':'Microsoft Zira - English (United States)','locale':'en-US'},
    {'name':'Microsoft Hamed Online (Natural)','locale':'ar-SA'},
    {'name':'Microsoft Zariyah Online (Natural)','locale':'ar-SA'},
    {'name':'Unknown vendor voice','locale':'en-US'},
  ];
  void expect(bool value,String label){if(!value)throw StateError(label);print('PASS $label');}
  expect(selectDliniiVoice(voices,language:'en',female:true)?['name']==voices[1]['name'],'English female is Zira');
  expect(selectDliniiVoice(voices,language:'en',female:false)?['name']==voices[0]['name'],'English male is David');
  expect(selectDliniiVoice(voices,language:'ar',female:true)?['name']==voices[3]['name'],'Arabic female is Zariyah');
  expect(selectDliniiVoice(voices,language:'ar',female:false)?['name']==voices[2]['name'],'Arabic male is Hamed');
  expect(selectDliniiVoice([voices[0]],language:'en',female:true)==null,'No male fallback for female');
  expect(selectDliniiVoice([voices[4]],language:'en',female:false)==null,'Unknown gender is unavailable');
  expect(selectDliniiVoice(voices,language:'en',female:true,savedIdentity:'en-US/${voices[0]['name']}')?['name']==voices[1]['name'],'Old wrongly pinned male is rejected');
  expect(selectDliniiVoice([{'name':'Samantha','locale':'en-US','gender':'male'}],language:'en',female:false)!=null,'Explicit engine gender takes precedence');
}
