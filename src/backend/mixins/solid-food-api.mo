// Solid Food (Primaitinimas) domain public API mixin.
//
// NOTE: the solid food endpoints are currently implemented inline in main.mo
// (addSolidFoodEntry / getSolidFoodEntriesForChild / updateSolidFoodEntry /
// deleteSolidFoodEntry / getSolidFoodStatistics / getSolidFoodStatisticsByCategory),
// which owns the persistentSolidFoodEntries stable map. This mixin is kept as
// the future extraction point for that API; for now it is intentionally empty
// so it does not duplicate or shadow the inline endpoints and does not block
// compilation. Future develop waves that move the inline endpoints into this
// mixin should add the public signatures and implementations here.
import SolidFoodTypes "../types/solid-food";

mixin {
  public type SolidFoodEntry = SolidFoodTypes.SolidFoodEntry;
  public type SolidFoodCategory = SolidFoodTypes.SolidFoodCategory;
  public type SolidFoodReaction = SolidFoodTypes.SolidFoodReaction;
};
