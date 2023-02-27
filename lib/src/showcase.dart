/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:ui';

import 'package:flutter/material.dart';

import 'get_position.dart';
import 'layout_overlays.dart';
import 'shape_clipper.dart';
import 'showcase_widget.dart';

class Showcase extends StatefulWidget {
  /// A key that is unique across the entire app.
  ///
  /// This Key will be used to control state of individual showcase and also
  /// used in [ShowCaseWidgetState.startShowCase] to define position of current
  /// target widget while showcasing.
  @override
  final GlobalKey key;

  /// Target widget that will be showcased or highlighted
  final Widget child;

  /// ShapeBorder of the highlighted box when target widget will be showcased.
  ///
  /// Note: If [targetBorderRadius] is specified, this parameter will be ignored.
  ///
  /// Default value is:
  /// ```dart
  /// RoundedRectangleBorder(
  ///   borderRadius: BorderRadius.all(Radius.circular(8)),
  /// ),
  /// ```
  final ShapeBorder targetShapeBorder;

  /// Radius of rectangle box while target widget is being showcased.
  final BorderRadius? targetBorderRadius;

  /// Background color of overlay during showcase.
  ///
  /// Default value is [Colors.black45]
  final Color overlayColor;

  /// Opacity apply on [overlayColor] (which ranges from 0.0 to 1.0)
  ///
  /// Default to 0.75
  final double overlayOpacity;

  /// Padding around target widget
  ///
  /// Default to [EdgeInsets.zero]
  final EdgeInsets targetPadding;

  /// Defines blur value.
  /// This will blur the background while displaying showcase.
  ///
  /// If null value is provided,
  /// [ShowCaseWidget.blurValue] will be considered.
  ///
  final double? blurValue;

  final VoidCallback onOverlayTap;

  const Showcase({
    required this.key,
    required this.child,
    this.targetShapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.overlayColor = Colors.black45,
    this.overlayOpacity = 0.75,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    this.targetBorderRadius,
    required this.onOverlayTap,
  }) : assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
            "overlay opacity must be between 0 and 1.");

  const Showcase.withWidget({
    required this.key,
    required this.child,
    this.targetShapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(8),
      ),
    ),
    this.overlayColor = Colors.black45,
    this.targetBorderRadius,
    this.overlayOpacity = 0.75,
    this.targetPadding = EdgeInsets.zero,
    this.blurValue,
    required this.onOverlayTap,
  }) : assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
            "overlay opacity must be between 0 and 1.");

  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  late Animation<double> blurAnimation;
  double blurAnimationValue = 0.0;

  late Animation<double> opacityAnimation;
  double opacityAnimationValue = 0.0;

  bool _showShowCase = false;
  bool _enableShowcase = true;
  GetPosition? position;

  ShowCaseWidgetState get showCaseWidgetState => ShowCaseWidget.of(context);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    blurAnimation =
        Tween<double>(begin: 0, end: widget.blurValue).animate(controller)
          ..addListener(() {
            setState(() {});
          });

    opacityAnimation =
        Tween<double>(begin: 0, end: widget.overlayOpacity).animate(controller)
          ..addListener(() {
            setState(() {});
          });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enableShowcase = showCaseWidgetState.enableShowcase;

    if (_enableShowcase) {
      position ??= GetPosition(
        key: widget.key,
        padding: widget.targetPadding,
        screenWidth: MediaQuery.of(context).size.width,
        screenHeight: MediaQuery.of(context).size.height,
      );

      showOverlay();
    }
  }

  /// show overlay if there is any target widget
  void showOverlay() {
    final activeStep = ShowCaseWidget.activeTargetWidget(context);
    setState(() {
      _showShowCase = activeStep == widget.key;

      if (_showShowCase) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enableShowcase) {
      return AnchoredOverlay(
        overlayBuilder: (context, rectBound, offset) {
          final size = MediaQuery.of(context).size;
          position = GetPosition(
            key: widget.key,
            padding: widget.targetPadding,
            screenWidth: size.width,
            screenHeight: size.height,
          );
          return buildOverlayOnTarget(offset, rectBound.size, rectBound, size);
        },
        showOverlay: true,
        child: widget.child,
      );
    }
    return widget.child;
  }

  Widget buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize,
  ) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onOverlayTap,
          child: ClipPath(
            clipper: RRectClipper(
              area: rectBound,
              isCircle: widget.targetShapeBorder is CircleBorder,
              radius: widget.targetBorderRadius,
              overlayPadding: widget.targetPadding,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurAnimation.value,
                sigmaY: blurAnimation.value,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color:
                      widget.overlayColor.withOpacity(opacityAnimation.value),
                ),
              ),
            ),
          ),
        ),
        _TargetWidget(
          offset: offset,
          size: size,
          radius: widget.targetBorderRadius,
          shapeBorder: widget.targetShapeBorder,
        ),
      ],
    );
  }
}

class _TargetWidget extends StatelessWidget {
  final Offset offset;
  final Size? size;
  final ShapeBorder? shapeBorder;
  final BorderRadius? radius;

  const _TargetWidget({
    Key? key,
    required this.offset,
    this.size,
    this.shapeBorder,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: IgnorePointer(
          ignoring: true,
          child: Container(
            height: size!.height + 16,
            width: size!.width + 16,
            decoration: ShapeDecoration(
              shape: radius != null
                  ? RoundedRectangleBorder(borderRadius: radius!)
                  : shapeBorder ??
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
