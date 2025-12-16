/// 오디오 장치의 연결 프로토콜 타입을 정의합니다.
enum AudioProtocol {
  /// 블루투스 A2DP (고품질 미디어 오디오)
  bluetoothA2dp,

  /// 블루투스 HFP/HSP (통화 및 마이크 사용, 저음질)
  bluetoothHfp,

  /// 블루투스 LE (저전력, 드물지만 데이터/오디오 제어용)
  bluetoothLe,

  /// 유선 (이어폰, 헤드폰, USB 오디오 통합)
  wired,

  /// 내장 스피커 (미디어)
  speaker,

  /// 내장 수화기 (통화)
  earpiece,

  /// Apple AirPlay
  airplay,

  /// WiFi / Network Audio (Chromecast, DLNA 등)
  wifi,

  /// 기타
  unknown,
}