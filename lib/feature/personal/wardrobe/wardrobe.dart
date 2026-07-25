/// Public API of the wardrobe feature.
///
/// Other features depend on this barrel — never on `wardrobe/data/**`
/// internals. Exposes the domain entity plus the row decoder for consumers
/// (e.g. chat) that receive raw `wardrobe_items` rows and need to render
/// wardrobe cards.
library;

export 'data/models/wardrobe_row_mapper.dart' show decodeWardrobeItemRow;
export 'domain/entities/wardrobe_item.dart';
