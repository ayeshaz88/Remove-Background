import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';

class SpiralPage extends StatelessWidget {
  final File imageFile;
  final Uint8List? backgroundRemovedImage;

  SpiralPage({required this.imageFile, this.backgroundRemovedImage});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Spiral Around Image')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(300, 300),
              painter: SpiralPainter(context, 75), // Spiral with progress
            ),
            // Check if the backgroundRemovedImage is not null, display it; otherwise, display the original image
            backgroundRemovedImage != null
                ? Image.memory(
              backgroundRemovedImage!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            )
                : Image.file(
              imageFile,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}

class SpiralPainter extends CustomPainter {
  final BuildContext context;
  final int fillPercent;

  SpiralPainter(this.context, this.fillPercent);

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 180.0;
    const double strokeWidth = 10;
    const double radiiDecrement = 30.0;
    const double centerShift = 1 + (radiiDecrement + strokeWidth) / 2;

    Offset center = Offset(0.5 * size.width, 0.5 * size.height);

    final Paint paintSpiralTargetMet = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Paint paintSpiralTargetNotMet = Paint()
      ..color = Colors.black45
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double spiralRadius = radius;
    double userProgress = fillPercent.toDouble(); // Get progress from the variable
    double arcFillPercent = (userProgress / 25);
    int arcFillCount = arcFillPercent.ceil();
    arcFillPercent = arcFillPercent - arcFillPercent.floor();

    for (var i = 1; i < 5; i++) {
      double sweepAngle = math.pi;
      double startAngle = math.pi / 4 + (math.pi * ((i - 1) % 2));
      if (i > arcFillCount) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: spiralRadius),
            startAngle, sweepAngle, false, paintSpiralTargetNotMet);
      } else if (i < arcFillCount) {
        canvas.drawArc(Rect.fromCircle(center: center, radius: spiralRadius),
            startAngle, sweepAngle, false, paintSpiralTargetMet);
      } else {
        if (arcFillPercent == 0) {
          canvas.drawArc(Rect.fromCircle(center: center, radius: spiralRadius),
              startAngle, sweepAngle, false, paintSpiralTargetMet);
        } else {
          sweepAngle = math.pi * (arcFillPercent);
          startAngle += math.pi * (1 - arcFillPercent);
          startAngle =
          startAngle > (2 * math.pi) ? (startAngle - (2 * math.pi)) : startAngle;
          canvas.drawArc(Rect.fromCircle(center: center, radius: spiralRadius),
              startAngle, sweepAngle, false, paintSpiralTargetMet);

          startAngle = math.pi / 4 + (math.pi * ((i - 1) % 2));
          startAngle =
          startAngle > (2 * math.pi) ? (startAngle - (2 * math.pi)) : startAngle;
          sweepAngle = math.pi * (1 - arcFillPercent);
          canvas.drawArc(Rect.fromCircle(center: center, radius: spiralRadius),
              startAngle, sweepAngle, false, paintSpiralTargetNotMet);
        }
      }

      spiralRadius -= radiiDecrement;
      if (i % 2 == 0) {
        center -= const Offset(centerShift, centerShift);
      } else {
        center += const Offset(centerShift, centerShift);
      }
    }

    const double smallGoalRadius = 25;
    final Paint paintCircleTargetMet = Paint()..color = Theme.of(context).colorScheme.primary;
    final Paint paintTargetNotMet = Paint()..color = Colors.black;

    List<double> smallGoalCheckPoints = [0, 12.49, 24.99, 37.49, 56.34, 81.24];
    Offset smallGoalCenter = center - Offset(radius / math.sqrt(2), radius / math.sqrt(2));
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[0] ? paintCircleTargetMet : paintTargetNotMet);
    smallGoalCenter = smallGoalCenter.translate(0, 2 * radius / math.sqrt(2));
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[1] ? paintCircleTargetMet : paintTargetNotMet);
    smallGoalCenter = smallGoalCenter.translate(2 * radius / math.sqrt(2), 0);
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[2] ? paintCircleTargetMet : paintTargetNotMet);
    smallGoalCenter = smallGoalCenter.translate(0, -2 * (radius - radiiDecrement) / math.sqrt(2));
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[3] ? paintCircleTargetMet : paintTargetNotMet);
    smallGoalCenter = center - const Offset(radius - 2 * radiiDecrement - strokeWidth / 2, -1 * centerShift);
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[4] ? paintCircleTargetMet : paintTargetNotMet);
    smallGoalCenter = smallGoalCenter.translate(
        smallGoalRadius + 2 * radius - 5 * radiiDecrement - strokeWidth, 0);
    canvas.drawCircle(
        smallGoalCenter,
        smallGoalRadius,
        userProgress > smallGoalCheckPoints[5] ? paintCircleTargetMet : paintTargetNotMet);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
