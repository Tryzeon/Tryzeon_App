enum FitStatus {
  perfect,
  good,
  poor,
  unknown;

  bool get isPoor => this == FitStatus.poor;
}
