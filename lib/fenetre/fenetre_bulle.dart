import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Pilote la fenêtre de l'application : une bulle ancrée au bord gauche de
/// l'écran qui s'agrandit en fenêtre complète au clic, et redevient bulle
/// quand on clique ailleurs.
class FenetreBulle extends ChangeNotifier with WindowListener {
  FenetreBulle._(this._prefs);

  static const tailleBulle = Size(84, 84);
  static const largeurApp = 440.0;
  static const hauteurApp = 820.0;

  /// Espace entre la fenêtre et le bord de l'écran.
  static const marge = 8.0;

  static const _cleY = 'bulle_y';

  final SharedPreferences _prefs;
  bool _reduit = true;
  bool _enTransition = false;

  /// Vrai après un glisser de la bulle par l'utilisateur : seuls ces
  /// déplacements déclenchent le ré-ancrage (pas nos propres setBounds).
  bool _deplaceParUtilisateur = false;
  DateTime _ignorerFlouJusqua = DateTime(0);
  Timer? _ancrageDiffere;

  bool get reduit => _reduit;

  /// Prépare la fenêtre en mode bulle. À appeler avant `runApp`.
  static Future<FenetreBulle> initialiser() async {
    await windowManager.ensureInitialized();
    final fenetre = FenetreBulle._(await SharedPreferences.getInstance());
    windowManager.addListener(fenetre);

    const options = WindowOptions(
      title: 'Ma Balance',
      size: tailleBulle,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      alwaysOnTop: true,
      skipTaskbar: false,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      if (Platform.isMacOS) {
        // Sous Linux, une fenêtre non redimensionnable ignorerait aussi nos
        // propres changements de taille ; elle n'a de toute façon pas de bord.
        await windowManager.setResizable(false);
        await windowManager.setHasShadow(false);
        // La bulle suit l'utilisateur sur tous les bureaux (Spaces).
        await windowManager.setVisibleOnAllWorkspaces(true);
      }
      await windowManager.setBounds(await fenetre._rectBulle());
      await windowManager.show();
    });
    return fenetre;
  }

  /// Ombre système de la fenêtre (macOS uniquement).
  Future<void> _ombre(bool active) async {
    if (Platform.isMacOS) await windowManager.setHasShadow(active);
  }

  /// Zone utilisable de l'écran principal (sans barre de menus ni Dock).
  Future<Rect> _ecran() async {
    final d = await screenRetriever.getPrimaryDisplay();
    return (d.visiblePosition ?? Offset.zero) & (d.visibleSize ?? d.size);
  }

  double _limiter(double v, double min, double max) =>
      max < min ? min : v.clamp(min, max).toDouble();

  Future<Rect> _rectBulle({double? y}) async {
    final e = await _ecran();
    final yVoulu = y ?? _prefs.getDouble(_cleY) ?? e.center.dy - 42;
    return Rect.fromLTWH(
      e.left + marge,
      _limiter(yVoulu, e.top + marge, e.bottom - tailleBulle.height - marge),
      tailleBulle.width,
      tailleBulle.height,
    );
  }

  Future<void> agrandir() async {
    if (!_reduit || _enTransition) return;
    _enTransition = true;
    _arreterAncrage();
    try {
      final e = await _ecran();
      final bulle = await windowManager.getBounds();
      final h = math.min(hauteurApp, e.height - 2 * marge);
      // Fenêtre centrée verticalement sur la bulle, sans sortir de l'écran.
      final y = _limiter(
        bulle.center.dy - h / 2,
        e.top + marge,
        e.bottom - h - marge,
      );
      await windowManager.setBounds(
        Rect.fromLTWH(e.left + marge, y, largeurApp, h),
      );
      await _ombre(true);
      _reduit = false;
      notifyListeners();
      // Le redimensionnement peut provoquer une perte de focus passagère.
      _ignorerFlouJusqua = DateTime.now().add(
        const Duration(milliseconds: 600),
      );
      await windowManager.focus();
    } finally {
      _enTransition = false;
    }
  }

  Future<void> reduire() async {
    if (_reduit || _enTransition) return;
    _enTransition = true;
    _arreterAncrage();
    try {
      // La bulle s'affiche avant que la fenêtre rétrécisse, pour ne jamais
      // dessiner l'application complète dans une fenêtre minuscule.
      _reduit = true;
      notifyListeners();
      await _ombre(false);
      await windowManager.setBounds(await _rectBulle());
    } finally {
      _enTransition = false;
    }
  }

  /// Laisse le système déplacer la bulle ; elle est ré-ancrée au bord
  /// gauche quand le déplacement s'arrête.
  Future<void> commencerDeplacement() async {
    _deplaceParUtilisateur = true;
    // Sur macOS, revient à la fin du glisser ; sur Linux, immédiatement
    // (l'ancrage suit alors les événements de déplacement).
    await windowManager.startDragging();
    _planifierAncrage();
  }

  void _planifierAncrage() {
    _ancrageDiffere?.cancel();
    _ancrageDiffere = Timer(const Duration(milliseconds: 400), _ancrer);
  }

  void _arreterAncrage() {
    _deplaceParUtilisateur = false;
    _ancrageDiffere?.cancel();
  }

  Future<void> quitter() => windowManager.close();

  Future<void> _ancrer() async {
    if (!_reduit || _enTransition || !_deplaceParUtilisateur) return;
    final actuel = await windowManager.getBounds();
    final cible = await _rectBulle(y: actuel.top);
    await _prefs.setDouble(_cleY, cible.top);
    if ((actuel.topLeft - cible.topLeft).distance > 1) {
      await windowManager.setPosition(cible.topLeft);
    }
  }

  @override
  void onWindowMove() {
    if (_reduit && _deplaceParUtilisateur) _planifierAncrage();
  }

  @override
  void onWindowBlur() {
    if (_reduit || DateTime.now().isBefore(_ignorerFlouJusqua)) return;
    reduire();
  }

  @override
  void dispose() {
    _ancrageDiffere?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }
}
