import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

/// The shop RPC already folds in unisex products for any requested gender, so
/// this only needs to map the two concrete values.
extension UserGenderProductX on Gender {
  ProductGender toProductGender() => switch (this) {
    Gender.female => ProductGender.female,
    Gender.male => ProductGender.male,
  };
}
