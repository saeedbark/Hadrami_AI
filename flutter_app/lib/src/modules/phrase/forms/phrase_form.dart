import 'package:hadrami_nlp/src/configs/phrase_translate_config.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'phrase_form.gform.dart';

@Rf()
class PhraseFormModel {
  @RfControl(
    validators: [
      RequiredValidator(),
      MinLengthValidator(PhraseTranslateConfig.minLength),
      MaxLengthValidator(PhraseTranslateConfig.maxLength),
    ],
  )
  final String phrase;

  const PhraseFormModel({this.phrase = ''});
}
