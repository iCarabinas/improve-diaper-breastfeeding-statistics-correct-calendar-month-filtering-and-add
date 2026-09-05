import Map "mo:core/Map";
import List "mo:core/List";
import AccessControl "mo:caffeineai-authorization/access-control";
import InviteLinksModule "mo:caffeineai-invite-links/invite-links-module";
import Storage "mo:caffeineai-object-storage/Storage";

module {
  // ---------- Inlined stable record types (must match main.mo) ----------
  type ChildProfile = {
    id : Text;
    name : Text;
    birthDate : Int;
    photo : ?Storage.ExternalBlob;
    isPublic : Bool;
    parent : Principal;
    sharedWith : List.List<Principal>;
  };

  type DiaperLog = {
    childId : Text;
    timestamp : Int;
    contents : { kakis : Bool; sysius : Bool; tuscia : Bool };
  };

  type BreastfeedingSession = {
    childId : Text;
    startTime : Int;
    duration : Int;
    side : { #left; #right };
  };

  type TummyTimeSession = {
    sessionId : Text;
    childId : Text;
    startTime : Int;
    duration : Int;
  };

  type NoteColor = {
    #yellow;
    #pink;
    #blue;
    #green;
    #purple;
  };

  type JournalNote = {
    childId : Text;
    text : Text;
    color : NoteColor;
    createdAt : Int;
    updatedAt : Int;
  };

  type WeightEntry = {
    weightId : Text;
    childId : Text;
    timestamp : Int;
    weight : Float;
  };

  type HeightEntry = {
    heightId : Text;
    childId : Text;
    timestamp : Int;
    height : Float;
  };

  type MilkPumpingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    side : { #left; #right; #both };
  };

  type SolidFoodEntry = {
    entryId : Text;
    childId : Text;
    foodName : Text;
    category : {
      #meat;
      #vegetables;
      #fruits;
      #berries;
      #grains;
      #eggs;
    };
    color : Text;
    timestamp : Int;
    reaction : { #liked; #disliked; #unclear };
    notes : ?Text;
  };

  type FeedingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    feedingType : { #misinukas; #mamosPienas };
    color : Text;
  };

  type ActiveTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    side : { #left; #right };
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  type TummyTimeTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  type UserProfile = {
    name : Text;
  };

  type ChildInviteLink = {
    inviteCode : Text;
    childId : Text;
    createdBy : Principal;
    createdAt : Int;
    used : Bool;
  };

  // ---------- Identity migration: legacy -> Enhanced Migration ----------
  // Stable shape is unchanged; pass data through.
  type OldActor = {
    accessControlState : AccessControl.AccessControlState;
    inviteState : InviteLinksModule.InviteLinksSystemState;
    var persistentChildProfiles : Map.Map<Text, ChildProfile>;
    var persistentDiaperLogs : Map.Map<Text, DiaperLog>;
    var persistentBreastfeedingSessions : Map.Map<Text, BreastfeedingSession>;
    var persistentTummyTimeSessions : Map.Map<Text, TummyTimeSession>;
    var persistentJournalNotes : Map.Map<Text, JournalNote>;
    var persistentWeightEntries : Map.Map<Text, WeightEntry>;
    var persistentHeightEntries : Map.Map<Text, HeightEntry>;
    var persistentMilkPumpingSessions : Map.Map<Text, MilkPumpingSession>;
    var persistentSolidFoodEntries : Map.Map<Text, SolidFoodEntry>;
    var persistentFeedingSessions : Map.Map<Text, FeedingSession>;
    var persistentUserProfiles : Map.Map<Principal, UserProfile>;
    var persistentChildInviteLinks : Map.Map<Text, ChildInviteLink>;
    var persistentActiveTimers : Map.Map<Text, ActiveTimerState>;
    var persistentTummyTimeTimers : Map.Map<Text, TummyTimeTimerState>;
  };

  type NewActor = OldActor;

  public func migration(old : OldActor) : NewActor { old };
};
