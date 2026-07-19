enum AnalyticsEventType {
  tryon('try_on'),
  purchaseClick('purchase_click'),
  view('view');

  const AnalyticsEventType(this.value);
  final String value;
}
