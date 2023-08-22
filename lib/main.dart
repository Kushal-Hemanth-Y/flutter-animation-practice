import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum CircleSide { left, right }

extension ToPath on CircleSide {
  Path toPath(Size size) {
    final path = Path();
    late Offset offset;
    late bool clockwise;

    switch (this) {
      case CircleSide.left:
        path.moveTo(size.width, 0);
        offset = Offset(size.width, size.height);
        clockwise = false;
        break;

      case CircleSide.right:
        path.moveTo(0, 0);
        offset = Offset(0, size.height);
        clockwise = true;
        break;
    }
    path.arcToPoint(
      offset,
      radius: Radius.elliptical(
        size.width / 2,
        size.height / 2,
      ),
      clockwise: clockwise,
    );
    path.close();
    return path;
  }
}

class HalfCircleClipper extends CustomClipper<Path> {
  final CircleSide side;

  HalfCircleClipper({required this.side});
  @override
  Path getClip(Size size) => side.toPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  late AnimationController _counterClockwiseRotationController;
  late Animation<double> _counterClockwiseAnimation;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    _counterClockwiseRotationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _counterClockwiseAnimation = Tween<double>(
      begin: 0,
      end: -(pi / 2),
    ).animate(CurvedAnimation(
        parent: _counterClockwiseRotationController, curve: Curves.bounceOut));

    // flip animation

    _flipController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _flipAnimation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.bounceOut));

    Future.delayed(Duration(seconds: 1), () {
      _counterClockwiseRotationController
        ..reset()
        ..forward();
    });

    _counterClockwiseRotationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flipAnimation = Tween<double>(
          begin: _flipAnimation.value,
          end: _flipAnimation.value + pi,
        ).animate(
            CurvedAnimation(parent: _flipController, curve: Curves.bounceOut));
        _flipController
          ..reset()
          ..forward();
      }
    });

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _counterClockwiseAnimation = Tween<double>(
          begin: _counterClockwiseAnimation.value,
          end: _counterClockwiseAnimation.value + -(pi / 2),
        ).animate(CurvedAnimation(
            parent: _counterClockwiseRotationController,
            curve: Curves.bounceOut));
        _counterClockwiseRotationController
          ..reset()
          ..forward();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _counterClockwiseRotationController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _counterClockwiseRotationController,
              builder: (BuildContext context, Widget? child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(_counterClockwiseAnimation.value),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _flipController,
                        builder: (BuildContext context, Widget? child) {
                          return Transform(
                            alignment: Alignment.centerRight,
                            transform: Matrix4.identity()
                              ..rotateY(_flipAnimation.value),
                            child: ClipPath(
                              clipper: HalfCircleClipper(side: CircleSide.left),
                              child: Container(
                                color: Colors.green,
                                width: 150,
                                height: 150,
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _flipController,
                        builder: (BuildContext context, Widget? child) {
                          return Transform(
                            alignment: Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..rotateY(_flipAnimation.value),
                            child: ClipPath(
                              clipper:
                                  HalfCircleClipper(side: CircleSide.right),
                              child: Container(
                                color: Colors.orangeAccent,
                                width: 150,
                                height: 150,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
