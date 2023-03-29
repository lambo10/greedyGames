import 'dart:ui';

import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final Widget child;
  const GlassBox({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      //begin color
                      Colors.deepPurple.withOpacity(0.15),
                      //end color
                      Colors.deepPurple.withOpacity(0.15),
                    ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GlassMorphism extends StatelessWidget {
  const GlassMorphism({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
              BoxShadow(
                blurRadius: 24,
                spreadRadius: 16,
                color: Colors.black.withOpacity(0.2),
              )
            ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 40.0,
                  sigmaY: 40.0,
                ),
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        width: 1.5,
                        color: Colors.white.withOpacity(0.2),
                      )),
                  child: Center(
                      child: Text(
                    "Glass Morphism",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.6)),
                  )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
