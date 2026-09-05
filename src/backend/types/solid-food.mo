// Solid Food (Primaitinimas) domain types.
//
// Contract: defines the SolidFoodEntry type used by the primaitinimo
// (solid food introduction) tracking endpoints. Mirrors the shape already
// stored in main.mo's persistentSolidFoodEntries stable map.
//
// The `timestamp` field is the entry's creation time in nanoseconds. New
// entries accept a caller-supplied timestamp (backdating support, matching
// addFeedingSession); when the caller passes 0 or a negative value the
// backend falls back to Time.now().
module {
  public type SolidFoodCategory = {
    #meat;
    #vegetables;
    #fruits;
    #berries;
    #grains;
    #eggs;
    #fish;
  };

  public type SolidFoodReaction = {
    #liked;
    #disliked;
    #unclear;
  };

  public type SolidFoodEntry = {
    entryId : Text;
    childId : Text;
    foodName : Text;
    category : SolidFoodCategory;
    color : Text;
    timestamp : Int;
    reaction : SolidFoodReaction;
    notes : ?Text;
  };
};
