// Feeding domain logic helpers.
//
// The feeding endpoints (addFeedingSession, getFeedingSessionsForChild,
// deleteFeedingSession) are implemented inline in main.mo, which owns the
// persistentFeedingSessions stable map. This module exposes pure helpers
// used by main.mo so the domain logic stays testable and DRY.
import FeedingTypes "../types/feeding";

module {
  public type FeedingSession = FeedingTypes.FeedingSession;
  public type FeedingType = FeedingTypes.FeedingType;

  // Default color applied to backfilled (pre-color) sessions during migration.
  public let defaultColor : Text = "teal";

  // Build a new FeedingSession record from the given fields.
  public func createSession(
    sessionId : Text,
    childId : Text,
    timestamp : Int,
    mlAmount : Float,
    feedingType : FeedingType,
    color : Text,
  ) : FeedingSession {
    {
      sessionId;
      childId;
      timestamp;
      mlAmount;
      feedingType;
      color;
    };
  };

  // Return only the sessions belonging to `childId`, preserving insertion order.
  public func sessionsForChild(
    sessions : [FeedingSession],
    childId : Text,
  ) : [FeedingSession] {
    sessions.filter(func(s) { s.childId == childId });
  };
};
