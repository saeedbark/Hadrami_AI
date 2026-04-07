// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

part of 'phrase_form.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactivePhraseFormModelFormConsumer extends StatelessWidget {
  const ReactivePhraseFormModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
          BuildContext context, PhraseFormModelForm formModel, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactivePhraseFormModelForm.of(context);

    if (formModel is! PhraseFormModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class PhraseFormModelFormInheritedStreamer extends InheritedStreamer<dynamic> {
  const PhraseFormModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final PhraseFormModelForm form;
}

class ReactivePhraseFormModelForm extends StatelessWidget {
  const ReactivePhraseFormModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final PhraseFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  static PhraseFormModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              PhraseFormModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        PhraseFormModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as PhraseFormModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return PhraseFormModelFormInheritedStreamer(
      form: form,
      stream: form.form.statusChanged,
      child: ReactiveFormPopScope(
        canPop: canPop,
        onPopInvoked: onPopInvoked,
        child: child,
      ),
    );
  }
}

extension ReactiveReactivePhraseFormModelFormExt on BuildContext {
  PhraseFormModelForm? phraseFormModelFormWatch() =>
      ReactivePhraseFormModelForm.of(this);

  PhraseFormModelForm? phraseFormModelFormRead() =>
      ReactivePhraseFormModelForm.of(this, listen: false);
}

class PhraseFormModelFormBuilder extends StatefulWidget {
  const PhraseFormModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final PhraseFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  final Widget Function(
          BuildContext context, PhraseFormModelForm formModel, Widget? child)
      builder;

  final void Function(BuildContext context, PhraseFormModelForm formModel)?
      initState;

  @override
  _PhraseFormModelFormBuilderState createState() =>
      _PhraseFormModelFormBuilderState();
}

class _PhraseFormModelFormBuilderState
    extends State<PhraseFormModelFormBuilder> {
  late PhraseFormModelForm _formModel;

  @override
  void initState() {
    _formModel = PhraseFormModelForm(
        PhraseFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant PhraseFormModelFormBuilder oldWidget) {
    if (widget.model != oldWidget.model) {
      _formModel.updateValue(widget.model);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _formModel.form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactivePhraseFormModelForm(
      key: ObjectKey(_formModel),
      form: _formModel,
      // canPop: widget.canPop,
      // onPopInvoked: widget.onPopInvoked,
      child: ReactiveFormBuilder(
        form: () => _formModel.form,
        canPop: widget.canPop,
        onPopInvoked: widget.onPopInvoked,
        builder: (context, formGroup, child) =>
            widget.builder(context, _formModel, widget.child),
        child: widget.child,
      ),
    );
  }
}

class PhraseFormModelForm implements FormModel<PhraseFormModel> {
  PhraseFormModelForm(
    this.form,
    this.path,
  );

  static const String phraseControlName = "phrase";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String phraseControlPath() => pathBuilder(phraseControlName);

  String get _phraseValue => phraseControl.value ?? "";

  bool get containsPhrase {
    try {
      form.control(phraseControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object> get phraseErrors => phraseControl.errors;

  void get phraseFocus => form.focus(phraseControlPath());

  void phraseValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phraseControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phraseValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phraseControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phraseValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      phraseControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  FormControl<String> get phraseControl =>
      form.control(phraseControlPath()) as FormControl<String>;

  void phraseSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      phraseControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      phraseControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  PhraseFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'PhraseFormModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return PhraseFormModel(phrase: _phraseValue);
  }

  @override
  void toggleDisabled({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    final currentFormInstance = currentForm;

    if (currentFormInstance is! FormGroup) {
      return;
    }

    if (_disabled.isEmpty) {
      currentFormInstance.controls.forEach((key, control) {
        _disabled[key] = control.disabled;
      });

      currentForm.markAsDisabled(
          updateParent: updateParent, emitEvent: emitEvent);
    } else {
      currentFormInstance.controls.forEach((key, control) {
        if (_disabled[key] == false) {
          currentFormInstance.controls[key]?.markAsEnabled(
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }

        _disabled.remove(key);
      });
    }
  }

  @override
  bool equalsTo(PhraseFormModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      PhraseFormModelForm.formElements(other).rawValue,
    );
  }

  @override
  void submit({
    required void Function(PhraseFormModel model) onValid,
    void Function()? onNotValid,
  }) {
    currentForm.markAllAsTouched();
    if (currentForm.valid) {
      onValid(model);
    } else {
      onNotValid?.call();
    }
  }

  AbstractControl<dynamic> get currentForm {
    return path == null ? form : form.control(path!);
  }

  @override
  void updateValue(
    PhraseFormModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(PhraseFormModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    PhraseFormModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(PhraseFormModel? phraseFormModel) => FormGroup({
        phraseControlName: FormControl<String>(
            value: phraseFormModel?.phrase,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false)
      },
          validators: [],
          asyncValidators: [],
          asyncValidatorsDebounceTime: 250,
          disabled: false);
}

class ReactivePhraseFormModelFormArrayBuilder<
    ReactivePhraseFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactivePhraseFormModelFormArrayBuilder({
    Key? key,
    this.control,
    this.formControl,
    this.builder,
    required this.itemBuilder,
  })  : assert(control != null || formControl != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final FormArray<ReactivePhraseFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactivePhraseFormModelFormArrayBuilderT>? Function(
      PhraseFormModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      PhraseFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactivePhraseFormModelFormArrayBuilderT? item,
      PhraseFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactivePhraseFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactivePhraseFormModelFormArrayBuilderT>(
      formArray: formControl ?? control?.call(formModel),
      builder: (context, formArray, child) {
        final values = formArray.controls.map((e) => e.value).toList();
        final itemList = values
            .asMap()
            .map((i, item) {
              return MapEntry(
                i,
                itemBuilder(
                  context,
                  i,
                  item,
                  formModel,
                ),
              );
            })
            .values
            .toList();

        return builder?.call(
              context,
              itemList,
              formModel,
            ) ??
            Column(children: itemList);
      },
    );
  }
}

class ReactivePhraseFormModelFormFormGroupArrayBuilder<
    ReactivePhraseFormModelFormFormGroupArrayBuilderT> extends StatelessWidget {
  const ReactivePhraseFormModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactivePhraseFormModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactivePhraseFormModelFormFormGroupArrayBuilderT>>
      Function(PhraseFormModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      PhraseFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactivePhraseFormModelFormFormGroupArrayBuilderT? item,
      PhraseFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactivePhraseFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactivePhraseFormModelFormFormGroupArrayBuilderT>[])
            .asMap()
            .map((i, item) => MapEntry(
                  i,
                  itemBuilder(
                    context,
                    i,
                    item,
                    formModel,
                  ),
                ))
            .values
            .toList();

        return builder?.call(
              context,
              itemList,
              formModel,
            ) ??
            Column(children: itemList);
      },
    );
  }
}
