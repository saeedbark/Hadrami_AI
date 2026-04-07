import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'ask_form.gform.dart';

@Rf()
class AskFormModel {
  @RfControl(validators: [RequiredValidator(), MinLengthValidator(2)])
  final String question;

  const AskFormModel({this.question = ''});
}
