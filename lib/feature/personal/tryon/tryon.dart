/// Public API of the try-on feature.
///
/// Other features depend on this barrel — never on `tryon/` internals. It
/// exposes exactly the cross-feature surface: the coordinator (the single
/// entry point for triggering a try-on), the mode-picker sheet, the trigger
/// button, and the mode entity those callers pass around.
library;

export 'domain/entities/tryon_mode.dart';
export 'presentation/coordinators/tryon_coordinator.dart';
export 'presentation/sheets/tryon_mode_sheet.dart';
export 'presentation/widgets/tryon_fab.dart';
