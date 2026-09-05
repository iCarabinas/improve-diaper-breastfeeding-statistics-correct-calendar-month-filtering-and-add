// Solid Food (Primaitinimas) domain logic helpers.
//
// The solid food endpoints (addSolidFoodEntry, getSolidFoodEntriesForChild,
// updateSolidFoodEntry, deleteSolidFoodEntry, statistics) are implemented
// inline in main.mo, which owns the persistentSolidFoodEntries stable map.
// This module is intentionally left empty: main.mo does not import it, so
// keeping stub bodies here would only block compilation.
// Future develop waves that extract the inline logic into this module
// should add the helper signatures and implementations here.
import SolidFoodTypes "../types/solid-food";

module {
  public type SolidFoodEntry = SolidFoodTypes.SolidFoodEntry;
  public type SolidFoodCategory = SolidFoodTypes.SolidFoodCategory;
  public type SolidFoodReaction = SolidFoodTypes.SolidFoodReaction;
};
