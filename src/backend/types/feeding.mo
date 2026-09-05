// Feeding domain types
// Contract: defines the FeedingSession type with the new `color` field.
// The `color` field stores the user-selected color from SolidFoodModule
// COLOR_CONFIG (red/orange/yellow/green/teal/blue/purple/pink).
module {
  public type FeedingType = { #misinukas; #mamosPienas };

  public type FeedingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    feedingType : FeedingType;
    color : Text;
  };
};
