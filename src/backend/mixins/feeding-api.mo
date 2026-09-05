// Feeding domain public API mixin.
//
// NOTE: the feeding endpoints are currently implemented inline in main.mo
// (addFeedingSession / getFeedingSessionsForChild / deleteFeedingSession),
// which owns the persistentFeedingSessions stable map. This mixin is kept as
// the future extraction point for that API; for now it is intentionally empty
// so it does not duplicate or shadow the inline endpoints.
//
// Marker query to avoid duplicate endpoint definitions with main.mo and to
// avoid redefining the endpoints (which would collide with main.mo's inline
// definitions), we expose only a no-op query that callers can use to verify
// the mixin is wired.
import FeedingTypes "../types/feeding";

mixin {
  // Marker query — confirms the feeding domain mixin is included without
  // duplicating the inline endpoints in main.mo.
  public query func feedingApiVersion() : async Nat { 1 };
};
