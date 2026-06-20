// ignore: dangling_library_doc_comments
/// Strongly-typed enums for telemetry dimensions that were previously raw
/// strings. Each enum has a `wireValue` used in Firestore (kept stable even
/// if Dart enum names change) and a `fromWire` parser that fails loudly
/// (via the `unknown` sentinel) instead of silently becoming `null`.
///
/// Rationale: a typo'd string like "Sementi-Urban" used to be discoverable
/// only by auditing Firestore data after the fact. With enums, it's either
/// a compile error (if hardcoded) or lands in `.unknown` (if parsed from
/// untrusted input), which is easy to monitor for.

enum Board {
  cbse('CBSE'),
  icse('ICSE'),
  stateBoard('State Board'),
  nios('NIOS'),
  ib('IB'),
  igcse('IGCSE'),
  unknown('Unknown');

  final String wireValue;
  const Board(this.wireValue);

  static Board fromWire(String? value) => Board.values.firstWhere(
        (b) => b.wireValue == value,
        orElse: () => Board.unknown,
      );
}

enum AreaType {
  urban('Urban'),
  semiUrban('Semi-Urban'),
  rural('Rural'),
  tribal('Tribal'),
  unknown('Unknown');

  final String wireValue;
  const AreaType(this.wireValue);

  static AreaType fromWire(String? value) => AreaType.values.firstWhere(
        (a) => a.wireValue == value,
        orElse: () => AreaType.unknown,
      );
}

enum AgeGroup {
  age5to10('5-10'),
  age10to15('10-15'),
  age15to18('15-18'),
  unknown('Unknown');

  final String wireValue;
  const AgeGroup(this.wireValue);

  static AgeGroup fromWire(String? value) => AgeGroup.values.firstWhere(
        (a) => a.wireValue == value,
        orElse: () => AgeGroup.unknown,
      );
}

enum SocioeconomicStatus {
  low('Low'),
  middle('Middle'),
  high('High'),
  unknown('Unknown');

  final String wireValue;
  const SocioeconomicStatus(this.wireValue);

  static SocioeconomicStatus fromWire(String? value) =>
      SocioeconomicStatus.values.firstWhere(
        (s) => s.wireValue == value,
        orElse: () => SocioeconomicStatus.unknown,
      );
}

enum DisabilityStatus {
  none('None'),
  physical('Physical'),
  visual('Visual'),
  hearing('Hearing'),
  cognitive('Cognitive'),
  other('Other'),
  unknown('Unknown');

  final String wireValue;
  const DisabilityStatus(this.wireValue);

  static DisabilityStatus fromWire(String? value) =>
      DisabilityStatus.values.firstWhere(
        (d) => d.wireValue == value,
        orElse: () => DisabilityStatus.unknown,
      );
}

enum MinorityStatus {
  general('General'),
  obc('OBC'),
  sc('SC'),
  st('ST'),
  other('Other'),
  unknown('Unknown');

  final String wireValue;
  const MinorityStatus(this.wireValue);

  static MinorityStatus fromWire(String? value) =>
      MinorityStatus.values.firstWhere(
        (m) => m.wireValue == value,
        orElse: () => MinorityStatus.unknown,
      );
}

/// Consent is modeled as a tri-state, never defaulted to "granted".
/// Anything that isn't explicitly "Granted"/"Agreed" is treated as
/// not-consented by `StudentContext.hasValidConsent` (fail closed).
enum ConsentStatus {
  granted('Granted'),
  agreed('Agreed'),
  pending('Pending'),
  denied('Denied'),
  expired('Expired'),
  unknown('Unknown');

  final String wireValue;
  const ConsentStatus(this.wireValue);

  static ConsentStatus fromWire(String? value) =>
      ConsentStatus.values.firstWhere((c) => c.wireValue == value,
          orElse: () => ConsentStatus.unknown);

  bool get isAffirmative => this == granted || this == agreed;
}

enum NcertMapped {
  yes('Yes'),
  no('No'),
  unknown('Unknown');

  final String wireValue;
  const NcertMapped(this.wireValue);

  static NcertMapped fromWire(String? value) => NcertMapped.values.firstWhere(
        (n) => n.wireValue == value,
        orElse: () => NcertMapped.unknown,
      );
}

enum BloomsLevel {
  remember('L1_Remember'),
  understand('L2_Understand'),
  apply('L3_Apply'),
  analyze('L4_Analyze'),
  evaluate('L5_Evaluate'),
  create('L6_Create'),
  unknown('Unknown');

  final String wireValue;
  const BloomsLevel(this.wireValue);

  static BloomsLevel fromWire(String? value) => BloomsLevel.values.firstWhere(
        (b) => b.wireValue == value,
        orElse: () => BloomsLevel.unknown,
      );
}

enum ContentStatus {
  active('Active'),
  draft('Draft'),
  archived('Archived'),
  deprecated('Deprecated'),
  unknown('Unknown');

  final String wireValue;
  const ContentStatus(this.wireValue);

  static ContentStatus fromWire(String? value) =>
      ContentStatus.values.firstWhere((c) => c.wireValue == value,
          orElse: () => ContentStatus.unknown);
}

enum ArTier {
  basic('Basic'),
  advanced('Advanced'),
  none('None'),
  unknown('Unknown');

  final String wireValue;
  const ArTier(this.wireValue);

  static ArTier fromWire(String? value) => ArTier.values.firstWhere(
        (a) => a.wireValue == value,
        orElse: () => ArTier.unknown,
      );
}

enum RiskLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  unknown('Unknown');

  final String wireValue;
  const RiskLevel(this.wireValue);

  static RiskLevel fromWire(String? value) => RiskLevel.values.firstWhere(
        (r) => r.wireValue == value,
        orElse: () => RiskLevel.unknown,
      );
}

enum ConnectivityType {
  wifi('WiFi'),
  fourG('4G'),
  threeG('3G'),
  twoG('2G'),
  offline('Offline'),
  unknown('Unknown');

  final String wireValue;
  const ConnectivityType(this.wireValue);

  static ConnectivityType fromWire(String? value) =>
      ConnectivityType.values.firstWhere((c) => c.wireValue == value,
          orElse: () => ConnectivityType.unknown);
}
