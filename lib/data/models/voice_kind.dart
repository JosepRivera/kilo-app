enum VoiceKind {
  close('Cierre de hoy'),
  purchase('Compra');

  const VoiceKind(this.title);

  final String title;

  static VoiceKind forTime(DateTime time) =>
      time.hour >= 17 || time.hour < 6 ? close : purchase;
}
