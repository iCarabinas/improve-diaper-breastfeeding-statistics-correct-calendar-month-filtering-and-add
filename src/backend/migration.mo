import Map "mo:core/Map";
import List "mo:core/List";
import Principal "mo:core/Principal";
import Storage "mo:caffeineai-object-storage/Storage";

module {
  // ---------- Old types (copied inline from .old/src/backend/main.mo) ----------
  type OldNoteColor = {
    #yellow;
    #pink;
    #blue;
    #green;
    #purple;
  };

  type OldChildProfile = {
    id : Text;
    name : Text;
    birthDate : Int;
    photo : ?Storage.ExternalBlob;
    isPublic : Bool;
    parent : Principal;
    sharedWith : List.List<Principal>;
  };

  type OldDiaperLog = {
    childId : Text;
    timestamp : Int;
    contents : { kakis : Bool; sysius : Bool; tuscia : Bool };
  };

  type OldBreastfeedingSession = {
    childId : Text;
    startTime : Int;
    duration : Int;
    side : { #left; #right };
  };

  type OldTummyTimeSession = {
    childId : Text;
    startTime : Int;
    duration : Int;
  };

  type OldJournalNote = {
    childId : Text;
    text : Text;
    color : OldNoteColor;
    createdAt : Int;
    updatedAt : Int;
  };

  type OldWeightEntry = {
    weightId : Text;
    childId : Text;
    timestamp : Int;
    weight : Float;
  };

  type OldHeightEntry = {
    heightId : Text;
    childId : Text;
    timestamp : Int;
    height : Float;
  };

  type OldMilkPumpingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    side : { #left; #right; #both };
  };

  type OldSolidFoodEntry = {
    entryId : Text;
    childId : Text;
    foodName : Text;
    category : { #meat; #vegetables; #fruits; #berries; #grains; #eggs; #fish };
    color : Text;
    timestamp : Int;
    reaction : { #liked; #disliked; #unclear };
    notes : ?Text;
  };

  type OldFeedingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    feedingType : { #misinukas; #mamosPienas };
    color : Text;
  };

  type OldActiveTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    side : { #left; #right };
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  type OldTummyTimeTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  type OldUserProfile = { name : Text };

  type OldChildInviteLink = {
    inviteCode : Text;
    childId : Text;
    createdBy : Principal;
    createdAt : Int;
    used : Bool;
  };

  // OldActor mirrors the previous version's stable state (field names + types).
  public type OldActor = {
    var persistentChildProfiles : Map.Map<Text, OldChildProfile>;
    var persistentDiaperLogs : Map.Map<Text, OldDiaperLog>;
    var persistentBreastfeedingSessions : Map.Map<Text, OldBreastfeedingSession>;
    var persistentTummyTimeSessions : Map.Map<Text, OldTummyTimeSession>;
    var persistentJournalNotes : Map.Map<Text, OldJournalNote>;
    var persistentWeightEntries : Map.Map<Text, OldWeightEntry>;
    var persistentHeightEntries : Map.Map<Text, OldHeightEntry>;
    var persistentMilkPumpingSessions : Map.Map<Text, OldMilkPumpingSession>;
    var persistentSolidFoodEntries : Map.Map<Text, OldSolidFoodEntry>;
    var persistentFeedingSessions : Map.Map<Text, OldFeedingSession>;
    var persistentUserProfiles : Map.Map<Principal, OldUserProfile>;
    var persistentChildInviteLinks : Map.Map<Text, OldChildInviteLink>;
    var persistentActiveTimers : Map.Map<Text, OldActiveTimerState>;
    var persistentTummyTimeTimers : Map.Map<Text, OldTummyTimeTimerState>;
  };

  // ---------- New types (imported from current main.mo via inline copy) ----------
  // Only TummyTimeSession changes shape (adds sessionId). All other types are
  // structurally identical to the old ones, so they pass through unchanged.
  type NewTummyTimeSession = {
    sessionId : Text;
    childId : Text;
    startTime : Int;
    duration : Int;
  };

  public type NewActor = {
    var persistentChildProfiles : Map.Map<Text, OldChildProfile>;
    var persistentDiaperLogs : Map.Map<Text, OldDiaperLog>;
    var persistentBreastfeedingSessions : Map.Map<Text, OldBreastfeedingSession>;
    var persistentTummyTimeSessions : Map.Map<Text, NewTummyTimeSession>;
    var persistentJournalNotes : Map.Map<Text, OldJournalNote>;
    var persistentWeightEntries : Map.Map<Text, OldWeightEntry>;
    var persistentHeightEntries : Map.Map<Text, OldHeightEntry>;
    var persistentMilkPumpingSessions : Map.Map<Text, OldMilkPumpingSession>;
    var persistentSolidFoodEntries : Map.Map<Text, OldSolidFoodEntry>;
    var persistentFeedingSessions : Map.Map<Text, OldFeedingSession>;
    var persistentUserProfiles : Map.Map<Principal, OldUserProfile>;
    var persistentChildInviteLinks : Map.Map<Text, OldChildInviteLink>;
    var persistentActiveTimers : Map.Map<Text, OldActiveTimerState>;
    var persistentTummyTimeTimers : Map.Map<Text, OldTummyTimeTimerState>;
  };

  public func run(old : OldActor) : NewActor {
    // Backfill sessionId from the Map key (the key was endTime.toText()).
    let newTummyTimeSessions = old.persistentTummyTimeSessions.map<Text, OldTummyTimeSession, NewTummyTimeSession>(
      func(sessionId, session) {
        {
          sessionId;
          childId = session.childId;
          startTime = session.startTime;
          duration = session.duration;
        };
      }
    );

    {
      var persistentChildProfiles = old.persistentChildProfiles;
      var persistentDiaperLogs = old.persistentDiaperLogs;
      var persistentBreastfeedingSessions = old.persistentBreastfeedingSessions;
      var persistentTummyTimeSessions = newTummyTimeSessions;
      var persistentJournalNotes = old.persistentJournalNotes;
      var persistentWeightEntries = old.persistentWeightEntries;
      var persistentHeightEntries = old.persistentHeightEntries;
      var persistentMilkPumpingSessions = old.persistentMilkPumpingSessions;
      var persistentSolidFoodEntries = old.persistentSolidFoodEntries;
      var persistentFeedingSessions = old.persistentFeedingSessions;
      var persistentUserProfiles = old.persistentUserProfiles;
      var persistentChildInviteLinks = old.persistentChildInviteLinks;
      var persistentActiveTimers = old.persistentActiveTimers;
      var persistentTummyTimeTimers = old.persistentTummyTimeTimers;
    };
  };
};
