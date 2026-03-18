import 'package:uuid/uuid.dart';
import 'package:dnd_app/models/enums.dart';

// Wann kann die Fähigkeit eingesetzt werden?
enum ActionType {
  action,       // Normale Aktion
  bonusAction,  // Bonusaktion
  reaction,     // Reaktion
  passive,      // Passiver Effekt, immer aktiv
  special,      // Sonderfall, z.B. 'Wenn du Schaden nimmst'
}

// Wann laden die Nutzungen wieder auf?
enum RechargeOn {
  none,           // Unbegrenzt nutzbar
  shortRest,      // Kurze Rast (oder lange Rast)
  longRest,       // Nur lange Rast
  dawn,           // Bei Tagesanbruch (manche Fähigkeiten)
}

class Ability {
  final String id;
  String name;
  String source;     // Quelle, z.B. 'Schurke 1', 'Volksmensch', 'Hausregel'

  // ── Mechanik ──────────────────────────────────────────────────────────────
  ActionType actionType;

  // Nutzungen: null = unbegrenzt, sonst feste Anzahl
  int? _maxUses;
  int? _currentUses;
  RechargeOn rechargeOn;

  // ── Angriff / Rettungswurf ────────────────────────────────────────────────
  // Fähigkeiten können einen Angriffswurf oder Rettungswurf auslösen –
  // genau wie Zauber, aber ohne Zauberschule etc.
  bool requiresAttackRoll;
  SavingThrowAttribute savingThrowAttribute;

  // ── Beschreibung ──────────────────────────────────────────────────────────
  String effectDescription;
  String? prerequisite;  // Voraussetzung, z.B. 'Benötigt Vorteil auf Angriff'

  Ability({
    String? id,
    required this.name,
    this.source = '',
    this.actionType = ActionType.action,
    int? maxUses,
    int? currentUses,
    this.rechargeOn = RechargeOn.none,
    this.requiresAttackRoll = false,
    this.savingThrowAttribute = SavingThrowAttribute.none,
    required this.effectDescription,
    this.prerequisite,
  })  : id = id ?? const Uuid().v4() {
    // Nutzungen nur validieren wenn sie überhaupt begrenzt sind
    if (maxUses != null) {
      _maxUses = maxUses.clamp(1, 999);
      // Aktuelle Nutzungen dürfen nicht über Maximum liegen
      _currentUses = (currentUses ?? maxUses).clamp(0, _maxUses!);
    }
  }

  // ── Getter & Setter ───────────────────────────────────────────────────────

  // null bedeutet unbegrenzt nutzbar
  int? get maxUses => _maxUses;
  set maxUses(int? value) {
    if (value == null) {
      // Auf unbegrenzt zurücksetzen
      _maxUses = null;
      _currentUses = null;
    } else {
      _maxUses = value.clamp(1, 999);
      // Aktuelle Nutzungen anpassen falls sie das neue Maximum überschreiten
      _currentUses = (_currentUses ?? _maxUses!).clamp(0, _maxUses!);
    }
  }

  int? get currentUses => _currentUses;
  set currentUses(int? value) {
    if (_maxUses == null || value == null) return;
    _currentUses = value.clamp(0, _maxUses!);
  }

  // Ob die Fähigkeit gerade nutzbar ist
  bool get isAvailable {
    if (_maxUses == null) return true;   // unbegrenzt → immer verfügbar
    return (_currentUses ?? 0) > 0;
  }

  // Ob die Fähigkeit einen Rettungswurf auslöst
  bool get requiresSavingThrow =>
      savingThrowAttribute != SavingThrowAttribute.none;

  // Eine Nutzung verbrauchen
  void use() {
    if (_currentUses != null && _currentUses! > 0) {
      _currentUses = _currentUses! - 1;
    }
  }

  // Nutzungen nach einer Rast wieder auffüllen
  void recharge(RechargeOn restType) {
  final shouldRecharge = switch (restType) {
    RechargeOn.none      => false,
    RechargeOn.dawn      => rechargeOn == RechargeOn.dawn,
    RechargeOn.shortRest => rechargeOn == RechargeOn.shortRest,
    RechargeOn.longRest  => rechargeOn == RechargeOn.shortRest ||
                            rechargeOn == RechargeOn.longRest,
  };

  if (shouldRecharge) _currentUses = _maxUses;
}

// Tagesanbruch separat:
void rechargeOnDawn() {
  if (rechargeOn == RechargeOn.dawn) _currentUses = _maxUses;
}

  // ── Datenbank: Konvertierung ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id':                   id,
      'name':                 name,
      'source':               source,
      'actionType':           actionType.name,
      'maxUses':              maxUses,
      'currentUses':          currentUses,
      'rechargeOn':           rechargeOn.name,
      'requiresAttackRoll':   requiresAttackRoll ? 1 : 0,
      'savingThrowAttribute': savingThrowAttribute.name,
      'effectDescription':    effectDescription,
      'prerequisite':         prerequisite,
    };
  }

  factory Ability.fromMap(Map<String, dynamic> map) {
    return Ability(
      id:                   map['id'],
      name:                 map['name'],
      source:               map['source'] ?? '',
      actionType:           ActionType.values.byName(
                              map['actionType'] ?? 'action'),
      maxUses:              map['maxUses'],
      currentUses:          map['currentUses'],
      rechargeOn:           RechargeOn.values.byName(
                              map['rechargeOn'] ?? 'none'),
      requiresAttackRoll:   map['requiresAttackRoll'] == 1,
      savingThrowAttribute: SavingThrowAttribute.values.byName(
                              map['savingThrowAttribute'] ?? 'none'),
      effectDescription:    map['effectDescription'] ?? '',
      prerequisite:         map['prerequisite'],
    );
  }
}