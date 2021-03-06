import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef ColorCodeBuilder = Widget Function(BuildContext context, Color color);

/// Class for configuring hue circle picker.
class ColorPickerCircleConfig {

  /// The size of widget.
  /// Draggable area is thumb widget is included to the size,
  /// so circle is smaller than the size.
  ///
  /// Default value is 320 x 320.
  final Size size;

  /// The width of circle border.
  ///
  /// Default value is 6.
  final double strokeWidth;

  /// The size of thumb for circle picker.
  ///
  /// Default value is 32.
  final double thumbSize;

  /// The height of space between sliders.
  ///
  /// Default value is 48.
  final double spaceHeight;

  ColorPickerCircleConfig({
    this.size = const Size(320, 320),
    this.strokeWidth = 6,
    this.thumbSize = 32,
    this.spaceHeight = 48
  });
}

class ColorPickerSliderConfig {

  /// The width of slider.
  ///
  /// Default value is 180.
  final double width;

  /// The width of border.
  ///
  /// Default value is 6.
  final double strokeWidth;

  /// The size of thumb for circle picker.
  ///
  /// Default value is 26.
  final double thumbSize;

  ColorPickerSliderConfig({
    this.width = 180,
    this.strokeWidth = 6,
    this.thumbSize = 26
  });

}

class CircleColorPicker extends StatefulWidget {
  const CircleColorPicker({
    Key key,
    this.onChanged,
    this.circleConfig,
    this.sliderConfig,
    this.initialColor = const Color.fromARGB(255, 255, 0, 0),
  }) : super(key: key);

  /// Called during a drag when the user is selecting a color.
  ///
  /// This callback called with latest color that user selected.
  final ValueChanged<Color> onChanged;

  /// Config for hue circle.
  final ColorPickerCircleConfig circleConfig;

  /// Config for value and saturation sliders.
  final ColorPickerSliderConfig sliderConfig;

  /// Initial color for picker.
  /// [onChanged] callback won't be called with initial value.
  ///
  /// Default value is Red.
  final Color initialColor;

  double get initialHue => HSVColor.fromColor(initialColor).hue;

  double get initialSaturation => HSVColor.fromColor(initialColor).saturation;

  double get initialValue => HSVColor.fromColor(initialColor).value;

  @override
  _CircleColorPickerState createState() => _CircleColorPickerState();
}

class _CircleColorPickerState extends State<CircleColorPicker>
    with TickerProviderStateMixin {
  AnimationController _valueController;
  AnimationController _saturationController;
  AnimationController _hueController;

  Color get _color {
    return HSVColor.fromAHSV(
      1,
      _hueController.value,
      _saturationController.value,
      _valueController.value,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.circleConfig.size.width,
      height: widget.circleConfig.size.height,
      child: Stack(
        children: <Widget>[
          _HuePicker(
            initialHue: widget.initialHue,
            size: widget.circleConfig.size,
            strokeWidth: widget.circleConfig.strokeWidth,
            thumbSize: widget.circleConfig.thumbSize,
            onChanged: (hue) {
              _hueController.value = hue * 180 / pi;
            },
          ),
          AnimatedBuilder(
            animation: _hueController,
            builder: (context, child) {
              return AnimatedBuilder(
                animation: _valueController,
                builder: (context, _) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _SaturationSlider(
                          initialSaturation: widget.initialSaturation,
                          sliderConfig: widget.sliderConfig,
                          hue: _hueController.value,
                          onChanged: (saturation) {
                            _saturationController.value = saturation;
                          },
                        ),
                        SizedBox(height: widget.circleConfig.spaceHeight),
                        _ValueSlider(
                          initialValue: widget.initialValue,
                          sliderConfig: widget.sliderConfig,
                          hue: _hueController.value,
                          onChanged: (value) {
                            _valueController.value = value;
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _hueController = AnimationController(
      vsync: this,
      value: widget.initialHue,
      lowerBound: 0,
      upperBound: 360,
    )..addListener(_onColorChanged);
    _valueController = AnimationController(
      vsync: this,
      value: widget.initialValue,
      lowerBound: 0,
      upperBound: 1,
    )..addListener(_onColorChanged);
    _saturationController = AnimationController(
      vsync: this,
      value: widget.initialSaturation,
      lowerBound: 0,
      upperBound: 1,
    )..addListener(_onColorChanged);
  }

  void _onColorChanged() {
    widget.onChanged?.call(_color);
  }
}

class _ValueSlider extends StatefulWidget {
  const _ValueSlider({
    Key key,
    this.hue,
    this.onChanged,
    this.sliderConfig,
    this.initialValue,
  }) : super(key: key);

  final double hue;

  final ValueChanged<double> onChanged;

  final ColorPickerSliderConfig sliderConfig;

  final double initialValue;

  @override
  _ValueSliderState createState() => _ValueSliderState();
}

class _ValueSliderState extends State<_ValueSlider>
    with TickerProviderStateMixin {
  AnimationController _valueController;
  AnimationController _scaleController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.sliderConfig.width,
        height: widget.sliderConfig.thumbSize,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 12,
              margin: EdgeInsets.symmetric(
                horizontal: widget.sliderConfig.thumbSize / 3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                gradient: LinearGradient(
                  stops: [0, 0.4, 1],
                  colors: [
                    HSVColor.fromAHSV(1, widget.hue, 1, 0).toColor(),
                    HSVColor.fromAHSV(1, widget.hue, 1, 0.5).toColor(),
                    HSVColor.fromAHSV(1, widget.hue, 1, 0.9).toColor(),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _valueController,
              builder: (context, child) {
                return Positioned(
                  left: _valueController.value *
                      (widget.sliderConfig.width - widget.sliderConfig.thumbSize),
                  child: ScaleTransition(
                    scale: _scaleController,
                    child: _Thumb(
                      size: widget.sliderConfig.thumbSize,
                      color: HSVColor.fromAHSV(
                        1,
                        widget.hue,
                        1,
                        _valueController.value,
                      ).toColor(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _valueController = AnimationController(
      vsync: this,
      value: widget.initialValue,
    )..addListener(() => widget.onChanged(_valueController.value));
    _scaleController = AnimationController(
      vsync: this,
      value: 1,
      lowerBound: 0.9,
      upperBound: 1,
      duration: Duration(milliseconds: 50),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _scaleController.reverse();
    _valueController.value = details.localPosition.dx / widget.sliderConfig.width;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _valueController.value = details.localPosition.dx / widget.sliderConfig.width;
  }

  void _onPanEnd(DragEndDetails details) {
    _scaleController.forward();
  }
}

class _SaturationSlider extends StatefulWidget {
  const _SaturationSlider({
    Key key,
    this.hue,
    this.onChanged,
    this.sliderConfig,
    this.initialSaturation,
  }) : super(key: key);

  final double hue;

  final ValueChanged<double> onChanged;

  final ColorPickerSliderConfig sliderConfig;

  final double initialSaturation;

  @override
  _SaturationSliderState createState() => _SaturationSliderState();
}

class _SaturationSliderState extends State<_SaturationSlider>
    with TickerProviderStateMixin {
  AnimationController _saturationController;
  AnimationController _scaleController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.sliderConfig.width,
        height: widget.sliderConfig.thumbSize,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 12,
              margin: EdgeInsets.symmetric(
                horizontal: widget.sliderConfig.thumbSize / 3,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                gradient: LinearGradient(
                  stops: [0, 0.4, 1],
                  colors: [
                    HSVColor.fromAHSV(1, widget.hue, 0, 1).toColor(),
                    HSVColor.fromAHSV(1, widget.hue, 0.5, 1).toColor(),
                    HSVColor.fromAHSV(1, widget.hue, 0.9, 1).toColor(),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _saturationController,
              builder: (context, child) {
                return Positioned(
                  left: _saturationController.value *
                      (widget.sliderConfig.width - widget.sliderConfig.thumbSize),
                  child: ScaleTransition(
                    scale: _scaleController,
                    child: _Thumb(
                      size: widget.sliderConfig.thumbSize,
                      color: HSVColor.fromAHSV(
                        1,
                        widget.hue,
                        _saturationController.value,
                        1
                      ).toColor(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _saturationController = AnimationController(
      vsync: this,
      value: widget.initialSaturation,
    )..addListener(() => widget.onChanged(_saturationController.value));
    _scaleController = AnimationController(
      vsync: this,
      value: 1,
      lowerBound: 0.9,
      upperBound: 1,
      duration: Duration(milliseconds: 50),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _scaleController.reverse();
    _saturationController.value = details.localPosition.dx / widget.sliderConfig.width;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _saturationController.value = details.localPosition.dx / widget.sliderConfig.width;
  }

  void _onPanEnd(DragEndDetails details) {
    _scaleController.forward();
  }
}

class _HuePicker extends StatefulWidget {
  const _HuePicker({
    Key key,
    this.onChanged,
    this.size,
    this.strokeWidth,
    this.thumbSize,
    this.initialHue,
  }) : super(key: key);

  final ValueChanged<double> onChanged;

  final Size size;

  final double strokeWidth;

  final double thumbSize;

  final double initialHue;

  @override
  _HuePickerState createState() => _HuePickerState();
}

class _HuePickerState extends State<_HuePicker> with TickerProviderStateMixin {
  AnimationController _hueController;
  AnimationController _scaleController;
  Animation<Offset> _offset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: Padding(
                padding: EdgeInsets.all(
                  widget.thumbSize / 2 - widget.strokeWidth,
                ),
                child: CustomPaint(
                  painter: _CirclePickerPainter(widget.strokeWidth),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _offset,
              builder: (context, child) {
                return Positioned(
                  left: _offset.value.dx,
                  top: _offset.value.dy,
                  child: child,
                );
              },
              child: AnimatedBuilder(
                animation: _hueController,
                builder: (context, child) {
                  final hue = _hueController.value * (180 / pi);
                  return ScaleTransition(
                    scale: _scaleController,
                    child: _Thumb(
                      size: widget.thumbSize,
                      color: HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final minSize = min(widget.size.width, widget.size.height);
    _hueController = AnimationController(
      vsync: this,
      value: widget.initialHue * pi / 180,
      lowerBound: 0,
      upperBound: 2 * pi,
    )..addListener(() => widget.onChanged(_hueController.value));
    _scaleController = AnimationController(
      vsync: this,
      value: 1,
      lowerBound: 0.9,
      upperBound: 1,
      duration: Duration(milliseconds: 50),
    );
    _offset = _CircleTween(
      minSize / 2 - widget.thumbSize / 2,
    ).animate(_hueController);
  }

  void _onPanStart(DragStartDetails details) {
    _scaleController.reverse();
    _updatePosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updatePosition(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _scaleController.forward();
  }

  void _updatePosition(Offset position) {
    final radians = atan2(
      position.dy - widget.size.height / 2,
      position.dx - widget.size.width / 2,
    );
    _hueController.value = radians % (2 * pi);
  }
}

class _CircleTween extends Tween<Offset> {
  _CircleTween(this.radius)
      : super(
          begin: _radiansToOffset(0, radius),
          end: _radiansToOffset(2 * pi, radius),
        );

  final double radius;

  @override
  Offset lerp(double t) => _radiansToOffset(t, radius);

  static Offset _radiansToOffset(double radians, double radius) {
    return Offset(
      radius + radius * cos(radians),
      radius + radius * sin(radians),
    );
  }
}

class _CirclePickerPainter extends CustomPainter {
  const _CirclePickerPainter(
    this.strokeWidth,
  );

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radio = min(size.width, size.height) / 2 - strokeWidth;

    const sweepGradient = SweepGradient(
      colors: const [
        Color.fromARGB(255, 255, 0, 0),
        Color.fromARGB(255, 255, 255, 0),
        Color.fromARGB(255, 0, 255, 0),
        Color.fromARGB(255, 0, 255, 255),
        Color.fromARGB(255, 0, 0, 255),
        Color.fromARGB(255, 255, 0, 255),
        Color.fromARGB(255, 255, 0, 0),
      ],
    );

    final sweepShader = sweepGradient.createShader(
      Rect.fromCircle(center: center, radius: radio),
    );

    canvas.drawCircle(
      center,
      radio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2
        ..shader = sweepShader,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _Thumb extends StatelessWidget {
  const _Thumb({Key key, this.size, this.color}) : super(key: key);

  final double size;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(255, 255, 255, 255),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(16, 0, 0, 0),
            blurRadius: 4,
            spreadRadius: 4,
          )
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - 6,
        height: size - 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
