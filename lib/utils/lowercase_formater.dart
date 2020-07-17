import 'package:flutter/services.dart';
class LowerCaseTextFormatter extends TextInputFormatter{
  @override
TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue){
  return newValue.copyWith(text: newValue.text.toLowerCase());
}

}

class UnderscoreLowerCaseTextFormatter extends TextInputFormatter{
  @override
TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue){
  return newValue.copyWith(text: newValue.text.toLowerCase().replaceAll((" "), "_"));
}
}