import 'package:equatable/equatable.dart';

class TryonResult extends Equatable {
  const TryonResult({required this.imageBase64});

  final String imageBase64;

  @override
  List<Object?> get props => [imageBase64];
}
