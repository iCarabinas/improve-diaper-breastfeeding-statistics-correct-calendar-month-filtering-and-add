import Time "mo:core/Time";
import List "mo:core/List";
import Text "mo:core/Text";
import Map "mo:core/Map";
import Principal "mo:core/Principal";
import Runtime "mo:core/Runtime";
import Iter "mo:core/Iter";
import Random "mo:core/Random";
import Int "mo:core/Int";
import Nat "mo:core/Nat";
import MixinObjectStorage "mo:caffeineai-object-storage/Mixin";
import AccessControl "mo:caffeineai-authorization/access-control";
import MixinAuthorization "mo:caffeineai-authorization/MixinAuthorization";
import InviteLinksModule "mo:caffeineai-invite-links/invite-links-module";
import Storage "mo:caffeineai-object-storage/Storage";
import OQL "mo:caffeineai-oql";
import Entity "mo:caffeineai-oql/Entity";
import MapEntity "mo:caffeineai-oql/MapEntity";
import RecordValue "mo:caffeineai-oql/RecordValue";
import Expose "mo:caffeineai-oql/Expose";
import Json "mo:json";
import Blob "mo:core/Blob";
import Nat8 "mo:core/Nat8";
import Array "mo:core/Array";
import ApiDocMixin "mixins/api-doc";



actor {
  let accessControlState : AccessControl.AccessControlState;
  include MixinAuthorization(accessControlState);
  include MixinObjectStorage();
  include ApiDocMixin();

  let inviteState : InviteLinksModule.InviteLinksSystemState;

  // ---------- Data Types ----------
  public type ChildProfile = {
    id : Text;
    name : Text;
    birthDate : Int;
    photo : ?Storage.ExternalBlob;
    isPublic : Bool;
    parent : Principal;
    sharedWith : List.List<Principal>;
  };

  public type DiaperLog = {
    childId : Text;
    timestamp : Int;
    contents : {
      kakis : Bool;
      sysius : Bool;
      tuscia : Bool;
    };
  };

  public type BreastfeedingSession = {
    childId : Text;
    startTime : Int;
    duration : Int;
    side : {
      #left;
      #right;
    };
  };

  public type TummyTimeSession = {
    sessionId : Text;
    childId : Text;
    startTime : Int;
    duration : Int;
  };

  public type JournalNote = {
    childId : Text;
    text : Text;
    color : NoteColor;
    createdAt : Int;
    updatedAt : Int;
  };

  public type WeightEntry = {
    weightId : Text;
    childId : Text;
    timestamp : Int;
    weight : Float;
  };

  public type HeightEntry = {
    heightId : Text;
    childId : Text;
    timestamp : Int;
    height : Float;
  };


  public type MilkPumpingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    side : { #left; #right; #both };
  };
  public type SolidFoodEntry = {
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
      #fish;
    };
    color : Text;
    timestamp : Int;
    reaction : {
      #liked;
      #disliked;
      #unclear;
    };
    notes : ?Text;
  };

  public type FeedingSession = {
    sessionId : Text;
    childId : Text;
    timestamp : Int;
    mlAmount : Float;
    feedingType : { #misinukas; #mamosPienas };
    color : Text;
  };
  public type ActiveTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    side : {
      #left;
      #right;
    };
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  public type TummyTimeTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };

  public type UserProfile = {
    name : Text;
  };

  public type ChildProfileView = {
    id : Text;
    name : Text;
    birthDate : Int;
    photo : ?Storage.ExternalBlob;
    isPublic : Bool;
    parent : Principal;
    sharedWith : [Principal];
  };

  public type NoteColor = {
    #yellow;
    #pink;
    #blue;
    #green;
    #purple;
  };

  public type ChildInviteLink = {
    inviteCode : Text;
    childId : Text;
    createdBy : Principal;
    createdAt : Int;
    used : Bool;
  };

  // ---------- Backup / Restore Types ----------
  public type ImportCounts = {
    childProfiles : { restored : Nat; skipped : Nat };
    diaperLogs : { restored : Nat; skipped : Nat };
    breastfeedingSessions : { restored : Nat; skipped : Nat };
    tummyTimeSessions : { restored : Nat; skipped : Nat };
    journalNotes : { restored : Nat; skipped : Nat };
    weightEntries : { restored : Nat; skipped : Nat };
    heightEntries : { restored : Nat; skipped : Nat };
    milkPumpingSessions : { restored : Nat; skipped : Nat };
    solidFoodEntries : { restored : Nat; skipped : Nat };
    feedingSessions : { restored : Nat; skipped : Nat };
    activeTimers : { restored : Nat; skipped : Nat };
    tummyTimeTimers : { restored : Nat; skipped : Nat };
    childInviteLinks : { restored : Nat; skipped : Nat };
    userProfiles : { restored : Nat; skipped : Nat };
  };

  public type ImportResult = {
    success : Bool;
    totalRestored : Nat;
    totalSkipped : Nat;
    counts : ImportCounts;
  };

  // ---------- Persistent State ----------
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

  // ---------- OQL Data Intelligence ----------
  // Expose all persisted (non-transient) collections as queryable OQL entities.
  // Authorization: .controllerOnly() (default) — the Data Intelligence agent
  // reads everything as the controller; end users never read through OQL.
  // Business logic, endpoints, types, and data structures are unchanged.
  include Expose({
    entities = [
      // ChildProfile — manual (photo : ?ExternalBlob, sharedWith : List<Principal>)
      OQL.Entity.manual<(Text, ChildProfile)>("childProfile", func () = persistentChildProfiles.entries(), "ChildProfile", "id")
        .sample(("", { id = ""; name = ""; birthDate = 0; photo = null; isPublic = false; parent = Principal.fromText("aaaaa-aa"); sharedWith = List.empty<Principal>() }))
        .payload("id", func ((k, _) : (Text, ChildProfile)) : Text = k, OQL.TextValue._toRow)
        .payload("name", func ((_, v) : (Text, ChildProfile)) : Text = v.name, OQL.TextValue._toRow)
        .payload("birthDate", func ((_, v) : (Text, ChildProfile)) : Int = v.birthDate, OQL.IntValue._toRow)
        .payload("isPublic", func ((_, v) : (Text, ChildProfile)) : Bool = v.isPublic, OQL.BoolValue._toRow)
        .payload("parent", func ((_, v) : (Text, ChildProfile)) : Principal = v.parent, OQL.PrincipalValue._toRow)
        .payload("sharedWithCount", func ((_, v) : (Text, ChildProfile)) : Nat = v.sharedWith.size(), OQL.NatValue._toRow)
        .controllerOnly()
        .build(),
      // DiaperLog — manual (nested contents record; PK is Map key)
      OQL.Entity.manual<(Text, DiaperLog)>("diaperLog", func () = persistentDiaperLogs.entries(), "DiaperLog", "logId")
        .sample(("", { childId = ""; timestamp = 0; contents = { kakis = false; sysius = false; tuscia = false } }))
        .payload("logId", func ((k, _) : (Text, DiaperLog)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, DiaperLog)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, DiaperLog)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("kakis", func ((_, v) : (Text, DiaperLog)) : Bool = v.contents.kakis, OQL.BoolValue._toRow)
        .payload("sysius", func ((_, v) : (Text, DiaperLog)) : Bool = v.contents.sysius, OQL.BoolValue._toRow)
        .payload("tuscia", func ((_, v) : (Text, DiaperLog)) : Bool = v.contents.tuscia, OQL.BoolValue._toRow)
        .controllerOnly()
        .build(),
      // BreastfeedingSession — manual (variant side; PK is Map key)
      OQL.Entity.manual<(Text, BreastfeedingSession)>("breastfeedingSession", func () = persistentBreastfeedingSessions.entries(), "BreastfeedingSession", "sessionId")
        .sample(("", { childId = ""; startTime = 0; duration = 0; side = #left }))
        .payload("sessionId", func ((k, _) : (Text, BreastfeedingSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, BreastfeedingSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("startTime", func ((_, v) : (Text, BreastfeedingSession)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("duration", func ((_, v) : (Text, BreastfeedingSession)) : Int = v.duration, OQL.IntValue._toRow)
        .payload("side", func ((_, v) : (Text, BreastfeedingSession)) : Text = switch (v.side) { case (#left) "left"; case (#right) "right" }, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // TummyTimeSession — manual (PK is Map key)
      OQL.Entity.manual<(Text, TummyTimeSession)>("tummyTimeSession", func () = persistentTummyTimeSessions.entries(), "TummyTimeSession", "sessionId")
        .sample(("", { sessionId = ""; childId = ""; startTime = 0; duration = 0 }))
        .payload("sessionId", func ((k, _) : (Text, TummyTimeSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, TummyTimeSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("startTime", func ((_, v) : (Text, TummyTimeSession)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("duration", func ((_, v) : (Text, TummyTimeSession)) : Int = v.duration, OQL.IntValue._toRow)
        .controllerOnly()
        .build(),
      // JournalNote — manual (variant color; PK is Map key)
      OQL.Entity.manual<(Text, JournalNote)>("journalNote", func () = persistentJournalNotes.entries(), "JournalNote", "noteId")
        .sample(("", { childId = ""; text = ""; color = #yellow; createdAt = 0; updatedAt = 0 }))
        .payload("noteId", func ((k, _) : (Text, JournalNote)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, JournalNote)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("text", func ((_, v) : (Text, JournalNote)) : Text = v.text, OQL.TextValue._toRow)
        .payload("color", func ((_, v) : (Text, JournalNote)) : Text = switch (v.color) { case (#yellow) "yellow"; case (#pink) "pink"; case (#blue) "blue"; case (#green) "green"; case (#purple) "purple" }, OQL.TextValue._toRow)
        .payload("createdAt", func ((_, v) : (Text, JournalNote)) : Int = v.createdAt, OQL.IntValue._toRow)
        .payload("updatedAt", func ((_, v) : (Text, JournalNote)) : Int = v.updatedAt, OQL.IntValue._toRow)
        .controllerOnly()
        .build(),
      // WeightEntry — manual (all primitives, weightId is a field)
      OQL.Entity.manual<(Text, WeightEntry)>("weightEntry", func () = persistentWeightEntries.entries(), "WeightEntry", "weightId")
        .sample(("", { weightId = ""; childId = ""; timestamp = 0; weight = 0.0 }))
        .payload("weightId", func ((k, _) : (Text, WeightEntry)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, WeightEntry)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, WeightEntry)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("weight", func ((_, v) : (Text, WeightEntry)) : Float = v.weight, OQL.FloatValue._toRow)
        .controllerOnly()
        .build(),
      // HeightEntry — manual (all primitives, heightId is a field)
      OQL.Entity.manual<(Text, HeightEntry)>("heightEntry", func () = persistentHeightEntries.entries(), "HeightEntry", "heightId")
        .sample(("", { heightId = ""; childId = ""; timestamp = 0; height = 0.0 }))
        .payload("heightId", func ((k, _) : (Text, HeightEntry)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, HeightEntry)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, HeightEntry)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("height", func ((_, v) : (Text, HeightEntry)) : Float = v.height, OQL.FloatValue._toRow)
        .controllerOnly()
        .build(),
      // MilkPumpingSession — auto (sessionId is a field; variant side needs Value converter OR manual).
      // Using manual to handle the variant side safely.
      OQL.Entity.manual<(Text, MilkPumpingSession)>("milkPumpingSession", func () = persistentMilkPumpingSessions.entries(), "MilkPumpingSession", "sessionId")
        .sample(("", { sessionId = ""; childId = ""; timestamp = 0; mlAmount = 0.0; side = #left }))
        .payload("sessionId", func ((k, _) : (Text, MilkPumpingSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, MilkPumpingSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, MilkPumpingSession)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("mlAmount", func ((_, v) : (Text, MilkPumpingSession)) : Float = v.mlAmount, OQL.FloatValue._toRow)
        .payload("side", func ((_, v) : (Text, MilkPumpingSession)) : Text = switch (v.side) { case (#left) "left"; case (#right) "right"; case (#both) "both" }, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // SolidFoodEntry — manual (variants category/reaction, notes : ?Text)
      OQL.Entity.manual<(Text, SolidFoodEntry)>("solidFoodEntry", func () = persistentSolidFoodEntries.entries(), "SolidFoodEntry", "entryId")
        .sample(("", { entryId = ""; childId = ""; foodName = ""; category = #meat; color = ""; timestamp = 0; reaction = #liked; notes = null }))
        .payload("entryId", func ((k, _) : (Text, SolidFoodEntry)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, SolidFoodEntry)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("foodName", func ((_, v) : (Text, SolidFoodEntry)) : Text = v.foodName, OQL.TextValue._toRow)
        .payload("category", func ((_, v) : (Text, SolidFoodEntry)) : Text = switch (v.category) { case (#meat) "meat"; case (#vegetables) "vegetables"; case (#fruits) "fruits"; case (#berries) "berries"; case (#grains) "grains"; case (#eggs) "eggs"; case (#fish) "fish" }, OQL.TextValue._toRow)
        .payload("color", func ((_, v) : (Text, SolidFoodEntry)) : Text = v.color, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, SolidFoodEntry)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("reaction", func ((_, v) : (Text, SolidFoodEntry)) : Text = switch (v.reaction) { case (#liked) "liked"; case (#disliked) "disliked"; case (#unclear) "unclear" }, OQL.TextValue._toRow)
        .payload("notes", func ((_, v) : (Text, SolidFoodEntry)) : Text = switch (v.notes) { case null ""; case (?t) t }, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // FeedingSession — manual (variant feedingType; PK is Map key)
      OQL.Entity.manual<(Text, FeedingSession)>("feedingSession", func () = persistentFeedingSessions.entries(), "FeedingSession", "sessionId")
        .sample(("", { sessionId = ""; childId = ""; timestamp = 0; mlAmount = 0.0; feedingType = #misinukas; color = "" }))
        .payload("sessionId", func ((k, _) : (Text, FeedingSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, FeedingSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, FeedingSession)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("mlAmount", func ((_, v) : (Text, FeedingSession)) : Float = v.mlAmount, OQL.FloatValue._toRow)
        .payload("feedingType", func ((_, v) : (Text, FeedingSession)) : Text = switch (v.feedingType) { case (#misinukas) "misinukas"; case (#mamosPienas) "mamosPienas" }, OQL.TextValue._toRow)
        .payload("color", func ((_, v) : (Text, FeedingSession)) : Text = v.color, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // UserProfile — manual (PK is Principal Map key, not a field in the record)
      OQL.Entity.manual<(Principal, UserProfile)>("userProfile", func () = persistentUserProfiles.entries(), "UserProfile", "user")
        .sample((Principal.fromText("aaaaa-aa"), { name = "" }))
        .payload("user", func ((k, _) : (Principal, UserProfile)) : Principal = k, OQL.PrincipalValue._toRow)
        .payload("name", func ((_, v) : (Principal, UserProfile)) : Text = v.name, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // ChildInviteLink — manual (all primitives, inviteCode is a field)
      OQL.Entity.manual<(Text, ChildInviteLink)>("childInviteLink", func () = persistentChildInviteLinks.entries(), "ChildInviteLink", "inviteCode")
        .sample(("", { inviteCode = ""; childId = ""; createdBy = Principal.fromText("aaaaa-aa"); createdAt = 0; used = false }))
        .payload("inviteCode", func ((k, _) : (Text, ChildInviteLink)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, ChildInviteLink)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("createdBy", func ((_, v) : (Text, ChildInviteLink)) : Principal = v.createdBy, OQL.PrincipalValue._toRow)
        .payload("createdAt", func ((_, v) : (Text, ChildInviteLink)) : Int = v.createdAt, OQL.IntValue._toRow)
        .payload("used", func ((_, v) : (Text, ChildInviteLink)) : Bool = v.used, OQL.BoolValue._toRow)
        .controllerOnly()
        .build(),
      // ActiveTimerState — manual (variant side, pausedAt : ?Int; PK is Map key)
      OQL.Entity.manual<(Text, ActiveTimerState)>("activeTimer", func () = persistentActiveTimers.entries(), "ActiveTimerState", "timerId")
        .sample(("", { childId = ""; userId = Principal.fromText("aaaaa-aa"); startTime = 0; side = #left; isPaused = false; pausedAt = null; totalPausedDuration = 0 }))
        .payload("timerId", func ((k, _) : (Text, ActiveTimerState)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, ActiveTimerState)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("userId", func ((_, v) : (Text, ActiveTimerState)) : Principal = v.userId, OQL.PrincipalValue._toRow)
        .payload("startTime", func ((_, v) : (Text, ActiveTimerState)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("side", func ((_, v) : (Text, ActiveTimerState)) : Text = switch (v.side) { case (#left) "left"; case (#right) "right" }, OQL.TextValue._toRow)
        .payload("isPaused", func ((_, v) : (Text, ActiveTimerState)) : Bool = v.isPaused, OQL.BoolValue._toRow)
        .payload("pausedAt", func ((_, v) : (Text, ActiveTimerState)) : Int = switch (v.pausedAt) { case null 0; case (?t) t }, OQL.IntValue._toRow)
        .payload("totalPausedDuration", func ((_, v) : (Text, ActiveTimerState)) : Int = v.totalPausedDuration, OQL.IntValue._toRow)
        .controllerOnly()
        .build(),
      // TummyTimeTimerState — manual (pausedAt : ?Int; PK is Map key)
      OQL.Entity.manual<(Text, TummyTimeTimerState)>("tummyTimeTimer", func () = persistentTummyTimeTimers.entries(), "TummyTimeTimerState", "timerId")
        .sample(("", { childId = ""; userId = Principal.fromText("aaaaa-aa"); startTime = 0; isPaused = false; pausedAt = null; totalPausedDuration = 0 }))
        .payload("timerId", func ((k, _) : (Text, TummyTimeTimerState)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, TummyTimeTimerState)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("userId", func ((_, v) : (Text, TummyTimeTimerState)) : Principal = v.userId, OQL.PrincipalValue._toRow)
        .payload("startTime", func ((_, v) : (Text, TummyTimeTimerState)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("isPaused", func ((_, v) : (Text, TummyTimeTimerState)) : Bool = v.isPaused, OQL.BoolValue._toRow)
        .payload("pausedAt", func ((_, v) : (Text, TummyTimeTimerState)) : Int = switch (v.pausedAt) { case null 0; case (?t) t }, OQL.IntValue._toRow)
        .payload("totalPausedDuration", func ((_, v) : (Text, TummyTimeTimerState)) : Int = v.totalPausedDuration, OQL.IntValue._toRow)
        .controllerOnly()
        .build(),
    ];
  });

  // ---------- Helper Functions ----------
  // Auto-register caller as user if not already registered (survives upgrades)
  func autoRegisterUser(caller : Principal) {
    if (not caller.isAnonymous()) {
      switch (accessControlState.userRoles.get(caller)) {
        case (null) {
          accessControlState.userRoles.add(caller, #user);
        };
        case (_) {};
      };
    };
  };

  func toChildProfileView(profile : ChildProfile) : ChildProfileView {
    {
      id = profile.id;
      name = profile.name;
      birthDate = profile.birthDate;
      photo = profile.photo;
      isPublic = profile.isPublic;
      parent = profile.parent;
      sharedWith = profile.sharedWith.toArray();
    };
  };

  func toChildProfileViewArray(profiles : List.List<ChildProfile>) : [ChildProfileView] {
    let profileArray = profiles.toArray();
    profileArray.map(func(profile) { toChildProfileView(profile) });
  };

  func hasSharedAccess(child : ChildProfile, user : Principal) : Bool {
    child.sharedWith.filter(func(id) { id == user }).size() > 0;
  };

  func canAccessChild(child : ChildProfile, caller : Principal) : Bool {
    child.parent == caller or hasSharedAccess(child, caller);
  };

  func getLithuanianDayStart(ts : Int) : Int {
    ts;
  };

  func generateUniqueCode() : async Text {
    let blob = await Random.blob();
    InviteLinksModule.generateUUID(blob);
  };

  // ---------- User Profile Management ----------
  public query ({ caller }) func getCallerUserProfile() : async ?UserProfile {
    autoRegisterUser(caller);
    persistentUserProfiles.get(caller);
  };

  public query ({ caller }) func getUserProfile(user : Principal) : async ?UserProfile {
    if (caller != user and not AccessControl.isAdmin(accessControlState, caller)) {
      Runtime.trap("Neautorizuota: galima peržiūrėti tik savo profilį");
    };
    persistentUserProfiles.get(user);
  };

  public shared ({ caller }) func saveCallerUserProfile(profile : UserProfile) : async () {
    autoRegisterUser(caller);
    persistentUserProfiles.add(caller, profile);
  };

  // ---------- Admin Invite Code System (for general app access) ----------
  public shared ({ caller }) func generateInviteCode() : async Text {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Neautorizuota: tik administratoriai gali generuoti kvietimo kodus");
    };

    let blob = await Random.blob();
    let code = InviteLinksModule.generateUUID(blob);
    InviteLinksModule.generateInviteCode(inviteState, code);
    code;
  };

  public func submitRSVP(name : Text, attending : Bool, inviteCode : Text) : async () {
    // Validate that the invite code exists before allowing RSVP
    let codes = InviteLinksModule.getInviteCodes(inviteState);
    var validCode = false;
    for (code in codes.vals()) {
      if (code.code == inviteCode) {
        validCode := true;
      };
    };
    
    if (not validCode) {
      Runtime.trap("Neteisingas kvietimo kodas");
    };

    // Validate input to prevent abuse
    if (name.isEmpty() or name.size() > 100) {
      Runtime.trap("Neteisingas vardas");
    };

    InviteLinksModule.submitRSVP(inviteState, name, attending, inviteCode);
  };

  public query ({ caller }) func getAllRSVPs() : async [InviteLinksModule.RSVP] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Neautorizuota: tik administratoriai gali peržiūrėti RSVP");
    };

    InviteLinksModule.getAllRSVPs(inviteState);
  };

  public query ({ caller }) func getInviteCodes() : async [InviteLinksModule.InviteCode] {
    if (not (AccessControl.hasPermission(accessControlState, caller, #admin))) {
      Runtime.trap("Neautorizuota: tik administratoriai gali peržiūrėti kvietimo kodus");
    };

    InviteLinksModule.getInviteCodes(inviteState);
  };

  // ---------- Child Management ----------
  public shared ({ caller }) func addChild(name : Text, birthDate : Int, photo : ?Storage.ExternalBlob, isPublic : Bool) : async Text {
    autoRegisterUser(caller);

    let childId = name # birthDate.toText();
    let childProfile : ChildProfile = {
      id = childId;
      name;
      birthDate;
      photo;
      isPublic;
      parent = caller;
      sharedWith = List.empty();
    };
    persistentChildProfiles.add(childId, childProfile);
    childId;
  };

  public shared ({ caller }) func toggleChildVisibility(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.parent != caller) {
          Runtime.trap("Neautorizuota: tik tėvai gali keisti vaiko matomumą");
        };
        let updatedChild = {
          id = child.id;
          name = child.name;
          birthDate = child.birthDate;
          photo = child.photo;
          isPublic = not child.isPublic;
          parent = child.parent;
          sharedWith = child.sharedWith;
        };
        persistentChildProfiles.add(childId, updatedChild);
      };
    };
  };

  public query ({ caller }) func getChild(childId : Text) : async ChildProfileView {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) { return toChildProfileView(child) };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (child.parent == caller or hasSharedAccess(child, caller)) {
          return toChildProfileView(child);
        } else {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko profilio");
        };
      };
    };
  };

  public query func getAllPublicChildren() : async [ChildProfileView] {
    toChildProfileViewArray(
      List.fromArray(
        persistentChildProfiles.values().toArray().filter(func(c) { c.isPublic })
      )
    );
  };

  public query ({ caller }) func getChildrenByParent(parent : Principal) : async [ChildProfileView] {
    autoRegisterUser(caller);
    if (parent != caller and not AccessControl.isAdmin(accessControlState, caller)) {
      Runtime.trap("Neautorizuota: galima peržiūrėti tik savo vaikus");
    };
    toChildProfileViewArray(
      List.fromArray(
        persistentChildProfiles.values().toArray().filter(func(c) { c.parent == parent })
      )
    );
  };

  public query ({ caller }) func getSharedChildren() : async [ChildProfileView] {
    autoRegisterUser(caller);
    toChildProfileViewArray(
      List.fromArray(
        persistentChildProfiles.values().toArray().filter(func(c) { hasSharedAccess(c, caller) })
      )
    );
  };

  public query ({ caller }) func calculateAgeInDays(childId : Text) : async Nat {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
          };
        };
        let currentTime = Time.now();
        let timeDelta = currentTime - child.birthDate;
        let days = timeDelta / 86_400_000_000_000;
        days.toNat();
      };
    };
  };

  public shared ({ caller }) func regenerateChildPhoto(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) { 
        if (child.parent != caller) { 
          Runtime.trap("Neautorizuota: tik tėvai gali regeneruoti vaiko nuotrauką") 
        } 
      };
    };
  };

  public query ({ caller }) func getChildStatistics(childId : Text) : async {
    totalDiapers : Nat;
    totalBreastfeedingSessions : Nat;
    totalTummyTime : Int;
  } {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let totalDiapers = persistentDiaperLogs.filter(func((_, log)) { log.childId == childId }).size();
          let totalBreastfeedingSessions = persistentBreastfeedingSessions.filter(func((_, session)) { session.childId == childId }).size();
          var totalTummyTime : Int = 0;
          for ((_, session) in persistentTummyTimeSessions.entries()) {
            if (session.childId == childId) {
              totalTummyTime += session.duration;
            };
          };

          return {
            totalDiapers;
            totalBreastfeedingSessions;
            totalTummyTime;
          };
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };
        let totalDiapers = persistentDiaperLogs.filter(func((_, log)) { log.childId == childId }).size();
        let totalBreastfeedingSessions = persistentBreastfeedingSessions.filter(func((_, session)) { session.childId == childId }).size();
        var totalTummyTime : Int = 0;
        for ((_, session) in persistentTummyTimeSessions.entries()) {
          if (session.childId == childId) {
            totalTummyTime += session.duration;
          };
        };

        return {
          totalDiapers;
          totalBreastfeedingSessions;
          totalTummyTime;
        };
      };
    };
  };

  // ---------- Child Sharing System ----------
  public shared ({ caller }) func generateChildInviteLink(childId : Text) : async Text {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.parent != caller) {
          Runtime.trap("Neautorizuota: tik tėvai gali generuoti kvietimo nuorodas");
        };

        let inviteCode = await generateUniqueCode();
        let invite : ChildInviteLink = {
          inviteCode;
          childId;
          createdBy = caller;
          createdAt = Time.now();
          used = false;
        };
        persistentChildInviteLinks.add(inviteCode, invite);
        inviteCode;
      };
    };
  };

  public shared ({ caller }) func acceptChildInvite(inviteCode : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildInviteLinks.get(inviteCode)) {
      case (null) { Runtime.trap("Kvietimo kodas nerastas") };
      case (?invite) {
        if (invite.used) {
          Runtime.trap("Kvietimo kodas jau panaudotas");
        };

        switch (persistentChildProfiles.get(invite.childId)) {
          case (null) { Runtime.trap("Vaikas nerastas") };
          case (?child) {
            if (child.parent == caller) {
              Runtime.trap("Negalite priimti kvietimo savo vaikui");
            };

            if (hasSharedAccess(child, caller)) {
              Runtime.trap("Jau turite prieigą prie šio vaiko");
            };

            child.sharedWith.add(caller);
            let updatedChild = {
              id = child.id;
              name = child.name;
              birthDate = child.birthDate;
              photo = child.photo;
              isPublic = child.isPublic;
              parent = child.parent;
              sharedWith = child.sharedWith;
            };
            persistentChildProfiles.add(invite.childId, updatedChild);

            let usedInvite = {
              inviteCode = invite.inviteCode;
              childId = invite.childId;
              createdBy = invite.createdBy;
              createdAt = invite.createdAt;
              used = true;
            };
            persistentChildInviteLinks.add(inviteCode, usedInvite);
          };
        };
      };
    };
  };

  public shared ({ caller }) func shareChildWithUser(childId : Text, userId : Principal) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.parent != caller) {
          Runtime.trap("Neautorizuota: tik tėvai gali dalintis vaiko profiliu");
        };

        if (child.parent == userId) {
          Runtime.trap("Negalite dalintis su savimi");
        };

        if (hasSharedAccess(child, userId)) {
          Runtime.trap("Naudotojas jau turi prieigą");
        };

        child.sharedWith.add(userId);
        let updatedChild = {
          id = child.id;
          name = child.name;
          birthDate = child.birthDate;
          photo = child.photo;
          isPublic = child.isPublic;
          parent = child.parent;
          sharedWith = child.sharedWith;
        };
        persistentChildProfiles.add(childId, updatedChild);
      };
    };
  };

  public shared ({ caller }) func revokeChildAccess(childId : Text, userId : Principal) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.parent != caller) {
          Runtime.trap("Neautorizuota: tik tėvai gali atšaukti prieigą");
        };

        let updatedSharedWith = child.sharedWith.filter(func(id) { id != userId });
        let updatedChild = {
          id = child.id;
          name = child.name;
          birthDate = child.birthDate;
          photo = child.photo;
          isPublic = child.isPublic;
          parent = child.parent;
          sharedWith = updatedSharedWith;
        };
        persistentChildProfiles.add(childId, updatedChild);
      };
    };
  };

  public query ({ caller }) func getSharedUsers(childId : Text) : async [Principal] {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.parent != caller) {
          Runtime.trap("Neautorizuota: tik tėvai gali peržiūrėti bendrinamus naudotojus");
        };
        child.sharedWith.toArray();
      };
    };
  };

  // ---------- Diaper Tracking ----------
  public shared ({ caller }) func logDiaperChange(
    childId : Text,
    kakis : Bool,
    sysius : Bool,
    tuscia : Bool
  ) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let logId = Time.now().toText();
        let log : DiaperLog = {
          childId;
          timestamp = Time.now();
          contents = {
            kakis;
            sysius;
            tuscia;
          };
        };
        persistentDiaperLogs.add(logId, log);
      };
    };
  };

  public query ({ caller }) func getDiaperLogsForChild(childId : Text) : async [DiaperLog] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let logs = List.empty<DiaperLog>();
          for ((_, log) in persistentDiaperLogs.entries()) {
            if (log.childId == childId) {
              logs.add(log);
            };
          };
          return logs.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let logs = List.empty<DiaperLog>();
        for ((_, log) in persistentDiaperLogs.entries()) {
          if (log.childId == childId) {
            logs.add(log);
          };
        };
        logs.toArray();
      };
    };
  };

  // ---------- Breastfeeding Tracking ----------
  public shared ({ caller }) func startBreastfeedingSession(
    childId : Text,
    side : { #left; #right }
  ) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        let timer : ActiveTimerState = {
          childId;
          userId = caller;
          startTime = Time.now();
          side;
          isPaused = false;
          pausedAt = null;
          totalPausedDuration = 0;
        };
        persistentActiveTimers.add(timerId, timer);
      };
    };
  };

  public shared ({ caller }) func pauseBreastfeedingTimer(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentActiveTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            if (timer.isPaused) {
              Runtime.trap("Seansas jau pristabdytas");
            };
            let updatedTimer = {
              childId = timer.childId;
              userId = timer.userId;
              startTime = timer.startTime;
              side = timer.side;
              isPaused = true;
              pausedAt = ?Time.now();
              totalPausedDuration = timer.totalPausedDuration;
            };
            persistentActiveTimers.add(timerId, updatedTimer);
          };
        };
      };
    };
  };

  public shared ({ caller }) func resumeBreastfeedingTimer(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentActiveTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            if (not timer.isPaused) {
              Runtime.trap("Seansas nėra pristabdytas");
            };
            let pauseDuration = switch (timer.pausedAt) {
              case (null) { 0 };
              case (?pausedTime) { Time.now() - pausedTime };
            };
            let updatedTimer = {
              childId = timer.childId;
              userId = timer.userId;
              startTime = timer.startTime;
              side = timer.side;
              isPaused = false;
              pausedAt = null;
              totalPausedDuration = timer.totalPausedDuration + pauseDuration;
            };
            persistentActiveTimers.add(timerId, updatedTimer);
          };
        };
      };
    };
  };

  public shared ({ caller }) func completeBreastfeedingSession(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentActiveTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            let endTime = Time.now();
            let duration = endTime - timer.startTime - timer.totalPausedDuration;

            let sessionId = endTime.toText();
            let session : BreastfeedingSession = {
              childId;
              startTime = timer.startTime;
              duration;
              side = timer.side;
            };
            persistentBreastfeedingSessions.add(sessionId, session);
            persistentActiveTimers.remove(timerId);
          };
        };
      };
    };
  };

  public query ({ caller }) func getActiveBreastfeedingTimer(childId : Text) : async ?ActiveTimerState {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        persistentActiveTimers.get(timerId);
      };
    };
  };

  public query ({ caller }) func getBreastfeedingSessionsForChild(childId : Text) : async [BreastfeedingSession] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let sessions = List.empty<BreastfeedingSession>();
          for ((_, session) in persistentBreastfeedingSessions.entries()) {
            if (session.childId == childId) {
              sessions.add(session);
            };
          };
          return sessions.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let sessions = List.empty<BreastfeedingSession>();
        for ((_, session) in persistentBreastfeedingSessions.entries()) {
          if (session.childId == childId) {
            sessions.add(session);
          };
        };
        sessions.toArray();
      };
    };
  };

  public shared ({ caller }) func addManualBreastfeedingSession(
    childId : Text,
    date : Int,
    duration : Int,
    side : { #left; #right }
  ) : async () {
    autoRegisterUser(caller);

    if (duration <= 0) {
      Runtime.trap("Trukmė turi būti teigiama");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let sessionId = Time.now().toText();
        let normalizedDate = getLithuanianDayStart(date);
        let session : BreastfeedingSession = {
          childId;
          startTime = normalizedDate;
          duration;
          side;
        };
        persistentBreastfeedingSessions.add(sessionId, session);
      };
    };
  };

  // ---------- Tummy Time Tracking ----------
  public shared ({ caller }) func startTummyTimeSession(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        let timer : TummyTimeTimerState = {
          childId;
          userId = caller;
          startTime = Time.now();
          isPaused = false;
          pausedAt = null;
          totalPausedDuration = 0;
        };
        persistentTummyTimeTimers.add(timerId, timer);
      };
    };
  };

  public shared ({ caller }) func pauseTummyTimeTimer(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentTummyTimeTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            if (timer.isPaused) {
              Runtime.trap("Seansas jau pristabdytas");
            };
            let updatedTimer = {
              childId = timer.childId;
              userId = timer.userId;
              startTime = timer.startTime;
              isPaused = true;
              pausedAt = ?Time.now();
              totalPausedDuration = timer.totalPausedDuration;
            };
            persistentTummyTimeTimers.add(timerId, updatedTimer);
          };
        };
      };
    };
  };

  public shared ({ caller }) func resumeTummyTimeTimer(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentTummyTimeTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            if (not timer.isPaused) {
              Runtime.trap("Seansas nėra pristabdytas");
            };
            let pauseDuration = switch (timer.pausedAt) {
              case (null) { 0 };
              case (?pausedTime) { Time.now() - pausedTime };
            };
            let updatedTimer = {
              childId = timer.childId;
              userId = timer.userId;
              startTime = timer.startTime;
              isPaused = false;
              pausedAt = null;
              totalPausedDuration = timer.totalPausedDuration + pauseDuration;
            };
            persistentTummyTimeTimers.add(timerId, updatedTimer);
          };
        };
      };
    };
  };

  public shared ({ caller }) func completeTummyTimeSession(childId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        switch (persistentTummyTimeTimers.get(timerId)) {
          case (null) { Runtime.trap("Aktyvus seansas nerastas") };
          case (?timer) {
            let endTime = Time.now();
            let duration = endTime - timer.startTime - timer.totalPausedDuration;

            let sessionId = endTime.toText();
            let session : TummyTimeSession = {
              sessionId;
              childId;
              startTime = timer.startTime;
              duration;
            };
            persistentTummyTimeSessions.add(sessionId, session);
            persistentTummyTimeTimers.remove(timerId);
          };
        };
      };
    };
  };

  public query ({ caller }) func getActiveTummyTimeTimer(childId : Text) : async ?TummyTimeTimerState {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let timerId = childId # caller.toText();
        persistentTummyTimeTimers.get(timerId);
      };
    };
  };

  public query ({ caller }) func getTummyTimeSessionsForChild(childId : Text) : async [TummyTimeSession] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let sessions = List.empty<TummyTimeSession>();
          for ((_, session) in persistentTummyTimeSessions.entries()) {
            if (session.childId == childId) {
              sessions.add(session);
            };
          };
          return sessions.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let sessions = List.empty<TummyTimeSession>();
        for ((_, session) in persistentTummyTimeSessions.entries()) {
          if (session.childId == childId) {
            sessions.add(session);
          };
        };
        sessions.toArray();
      };
    };
  };

  public shared ({ caller }) func deleteTummyTimeSession(childId : Text, sessionId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        switch (persistentTummyTimeSessions.get(sessionId)) {
          case (null) { Runtime.trap("Seansas nerastas") };
          case (?session) {
            if (session.childId != childId) {
              Runtime.trap("Seansas nepriklauso šiam vaikui");
            };
            persistentTummyTimeSessions.remove(sessionId);
          };
        };
      };
    };
  };
  public shared ({ caller }) func addJournalNote(childId : Text, text : Text, color : NoteColor) : async () {
    autoRegisterUser(caller);

    if (text.isEmpty()) {
      Runtime.trap("Tekstas yra privalomas");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let noteId = Time.now().toText();
        let timestamp = Time.now();
        let note : JournalNote = {
          childId;
          text;
          color;
          createdAt = timestamp;
          updatedAt = timestamp;
        };
        persistentJournalNotes.add(noteId, note);
      };
    };
  };

  public query ({ caller }) func getJournalNotesForChild(childId : Text) : async [JournalNote] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let notes = List.empty<JournalNote>();
          for ((_, note) in persistentJournalNotes.entries()) {
            if (note.childId == childId) {
              notes.add(note);
            };
          };
          return notes.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        let notes = List.empty<JournalNote>();
        for ((_, note) in persistentJournalNotes.entries()) {
          if (note.childId == childId) {
            notes.add(note);
          };
        };
        notes.toArray();
      };
    };
  };

  public shared ({ caller }) func updateJournalNote(childId : Text, noteId : Text, newText : Text, newColor : ?NoteColor) : async () {
    autoRegisterUser(caller);

    if (newText.isEmpty()) {
      Runtime.trap("Tekstas yra privalomas");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        switch (persistentJournalNotes.get(noteId)) {
          case (null) { Runtime.trap("Užrašas nerastas") };
          case (?note) {
            if (note.childId != childId) {
              Runtime.trap("Užrašas nepriklauso šiam vaikui");
            };
            let updatedNote = {
              childId = note.childId;
              text = newText;
              color = switch (newColor) {
                case (?color) { color };
                case (null) { note.color };
              };
              createdAt = note.createdAt;
              updatedAt = Time.now();
            };
            persistentJournalNotes.add(noteId, updatedNote);
          };
        };
      };
    };
  };

  public shared ({ caller }) func deleteJournalNote(childId : Text, noteId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
        };

        switch (persistentJournalNotes.get(noteId)) {
          case (null) { Runtime.trap("Užrašas nerastas") };
          case (?note) {
            if (note.childId != childId) {
              Runtime.trap("Užrašas nepriklauso šiam vaikui");
            };
            persistentJournalNotes.remove(noteId);
          };
        };
      };
    };
  };

  public query ({ caller }) func searchJournalNotes(childId : Text, searchTerm : Text) : async [JournalNote] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neautorizuota: nėra prieigos prie šio vaiko duomenų");
          };
        };

        if (searchTerm.isEmpty()) {
          let notes = List.empty<JournalNote>();
          for ((_, note) in persistentJournalNotes.entries()) {
            if (note.childId == childId) {
              notes.add(note);
            };
          };
          return notes.toArray();
        };

        let filteredNotes = List.empty<JournalNote>();
        for ((_, note) in persistentJournalNotes.entries()) {
          if (note.childId == childId and note.text.contains(#text searchTerm)) {
            filteredNotes.add(note);
          };
        };

        filteredNotes.toArray();
      };
    };
  };

  // ---------- Weight Tracking ----------
  public shared ({ caller }) func addWeightEntry(
    childId : Text,
    weight : Float,
    timestamp : Int,
  ) : async () {
    autoRegisterUser(caller);

    if (weight <= 0) {
      Runtime.trap("Svorio reikšmė negali būti nulinė arba mažesnė už nulį");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        let weightId = Time.now().toText();
        let entry : WeightEntry = {
          childId = childId;
          weightId = weightId;
          weight = weight;
          timestamp = timestamp;
        };
        persistentWeightEntries.add(weightId, entry);
      };
    };
  };

  public query ({ caller }) func getWeightEntriesForChild(childId : Text) : async [WeightEntry] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let weightEntries = List.empty<WeightEntry>();
          for ((_, entry) in persistentWeightEntries.entries()) {
            if (entry.childId == childId) {
              weightEntries.add(entry);
            };
          };
          return weightEntries.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko profilio");
        };
        let weightEntries = List.empty<WeightEntry>();
        for ((_, entry) in persistentWeightEntries.entries()) {
          if (entry.childId == childId) {
            weightEntries.add(entry);
          };
        };
        weightEntries.toArray();
      };
    };
  };

  public shared ({ caller }) func updateWeightEntry(
    childId : Text,
    weightId : Text,
    newWeight : Float,
    newTimestamp : Int,
  ) : async () {
    autoRegisterUser(caller);

    if (newWeight <= 0) {
      Runtime.trap("Svorio reikšmė negali būti nulinė arba mažesnė už nulį");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentWeightEntries.get(weightId)) {
          case (null) { Runtime.trap("Svorio įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Svorio įrašas nepriklauso šiam vaikui");
            };
            let updatedEntry = {
              childId = entry.childId;
              weightId = entry.weightId;
              weight = newWeight;
              timestamp = newTimestamp;
            };
            persistentWeightEntries.add(weightId, updatedEntry);
          };
        };
      };
    };
  };

  public shared ({ caller }) func deleteWeightEntry(childId : Text, weightId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentWeightEntries.get(weightId)) {
          case (null) { Runtime.trap("Svorio įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Svorio įrašas nepriklauso šiam vaikui");
            };
            persistentWeightEntries.remove(weightId);
          };
        };
      };
    };
  };

  // ---------- Height Tracking ----------
  public shared ({ caller }) func addHeightEntry(
    childId : Text,
    heightCm : Float,
    dateTimestamp : Int,
  ) : async () {
    autoRegisterUser(caller);

    if (heightCm <= 0) {
      Runtime.trap("Ūgio reikšmė negali būti nulinė arba mažesnė už nulį");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        let heightId = Time.now().toText();
        let entry : HeightEntry = {
          childId = childId;
          heightId = heightId;
          height = heightCm;
          timestamp = dateTimestamp;
        };
        persistentHeightEntries.add(heightId, entry);
      };
    };
  };

  public query ({ caller }) func getHeightEntriesForChild(childId : Text) : async [HeightEntry] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let heightEntries = List.empty<HeightEntry>();
          for ((_, entry) in persistentHeightEntries.entries()) {
            if (entry.childId == childId) {
              heightEntries.add(entry);
            };
          };
          return heightEntries.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko profilio");
        };
        let heightEntries = List.empty<HeightEntry>();
        for ((_, entry) in persistentHeightEntries.entries()) {
          if (entry.childId == childId) {
            heightEntries.add(entry);
          };
        };
        heightEntries.toArray();
      };
    };
  };

  public shared ({ caller }) func updateHeightEntry(
    childId : Text,
    heightId : Text,
    newHeight : Float,
    newTimestamp : Int,
  ) : async () {
    autoRegisterUser(caller);

    if (newHeight <= 0) {
      Runtime.trap("Ūgio reikšmė negali būti nulinė arba mažesnė už nulį");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentHeightEntries.get(heightId)) {
          case (null) { Runtime.trap("Ūgio įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Ūgio įrašas nepriklauso šiam vaikui");
            };
            let updatedEntry = {
              childId = entry.childId;
              heightId = entry.heightId;
              height = newHeight;
              timestamp = newTimestamp;
            };
            persistentHeightEntries.add(heightId, updatedEntry);
          };
        };
      };
    };
  };

  public shared ({ caller }) func deleteHeightEntry(childId : Text, heightId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentHeightEntries.get(heightId)) {
          case (null) { Runtime.trap("Ūgio įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Ūgio įrašas nepriklauso šiam vaikui");
            };
            persistentHeightEntries.remove(heightId);
          };
        };
      };
    };
  };

  public shared ({ caller }) func addMilkPumpingSession(
    childId : Text,
    timestamp : Int,
    mlAmount : Float,
    side : { #left; #right; #both },
  ) : async () {
    autoRegisterUser(caller);
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos");
        };
        let blob = await Random.blob();
        let sessionId = InviteLinksModule.generateUUID(blob);
        let session : MilkPumpingSession = {
          sessionId;
          childId;
          timestamp;
          mlAmount;
          side;
        };
        persistentMilkPumpingSessions.add(sessionId, session);
      };
    };
  };

  public query ({ caller }) func getMilkPumpingSessionsForChild(childId : Text) : async [MilkPumpingSession] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neturite prieigos");
          };
        };
        let sessions = List.empty<MilkPumpingSession>();
        for ((_, s) in persistentMilkPumpingSessions.entries()) {
          if (s.childId == childId) {
            sessions.add(s);
          };
        };
        sessions.toArray();
      };
    };
  };

  public shared ({ caller }) func deleteMilkPumpingSession(childId : Text, sessionId : Text) : async () {
    autoRegisterUser(caller);
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos");
        };
        persistentMilkPumpingSessions.remove(sessionId);
      };
    };
  };

  public shared ({ caller }) func addFeedingSession(
    childId : Text,
    timestamp : Int,
    mlAmount : Float,
    feedingType : { #misinukas; #mamosPienas },
    color : Text,
  ) : async () {
    autoRegisterUser(caller);
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos");
        };
        let blob = await Random.blob();
        let sessionId = InviteLinksModule.generateUUID(blob);
        let session : FeedingSession = {
          sessionId;
          childId;
          timestamp;
          mlAmount;
          feedingType;
          color;
        };
        persistentFeedingSessions.add(sessionId, session);
      };
    };
  };

  public query ({ caller }) func getFeedingSessionsForChild(childId : Text) : async [FeedingSession] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neturite prieigos");
          };
        };
        let sessions = List.empty<FeedingSession>();
        for ((_, s) in persistentFeedingSessions.entries()) {
          if (s.childId == childId) {
            sessions.add(s);
          };
        };
        sessions.toArray();
      };
    };
  };

  public shared ({ caller }) func deleteFeedingSession(childId : Text, sessionId : Text) : async () {
    autoRegisterUser(caller);
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos");
        };
        persistentFeedingSessions.remove(sessionId);
      };
    };
  };

  // ---------- Solid Food (Primaitinimas) Tracking ----------
  public shared ({ caller }) func addSolidFoodEntry(
    childId : Text,
    foodName : Text,
    category : { #meat; #vegetables; #fruits; #berries; #grains; #eggs; #fish },
    color : Text,
    reaction : { #liked; #disliked; #unclear },
    notes : ?Text,
    timestamp : Int,
  ) : async () {
    autoRegisterUser(caller);

    if (foodName.isEmpty()) {
      Runtime.trap("Maisto pavadinimas yra privalomas");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        let blob = await Random.blob();
        let entryId = InviteLinksModule.generateUUID(blob);
        // Backdating support: if the caller passes 0 or a negative timestamp,
        // fall back to Time.now() (matches addFeedingSession contract).
        let effectiveTimestamp = if (timestamp <= 0) { Time.now() } else { timestamp };
        let entry : SolidFoodEntry = {
          entryId;
          childId;
          foodName;
          category;
          color;
          timestamp = effectiveTimestamp;
          reaction;
          notes;
        };
        persistentSolidFoodEntries.add(entryId, entry);
      };
    };
  };

  public query ({ caller }) func getSolidFoodEntriesForChild(childId : Text) : async [SolidFoodEntry] {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (child.isPublic) {
          let entries = List.empty<SolidFoodEntry>();
          for ((_, entry) in persistentSolidFoodEntries.entries()) {
            if (entry.childId == childId) {
              entries.add(entry);
            };
          };
          return entries.toArray();
        };
        if (caller.isAnonymous()) {
          Runtime.trap("Neautorizuota: reikalinga prisijungti");
        };
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        let entries = List.empty<SolidFoodEntry>();
        for ((_, e) in persistentSolidFoodEntries.entries()) {
          if (e.childId == childId) {
            entries.add(e);
          };
        };
        entries.toArray();
      };
    };
  };

  public shared ({ caller }) func updateSolidFoodEntry(
    childId : Text,
    entryId : Text,
    newFoodName : Text,
    newCategory : { #meat; #vegetables; #fruits; #berries; #grains; #eggs; #fish },
    newColor : Text,
    newReaction : { #liked; #disliked; #unclear },
    newNotes : ?Text,
  ) : async () {
    autoRegisterUser(caller);

    if (newFoodName.isEmpty()) {
      Runtime.trap("Maisto pavadinimas yra privalomas");
    };

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentSolidFoodEntries.get(entryId)) {
          case (null) { Runtime.trap("Primaitinimo įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Primaitinimo įrašas nepriklauso šiam vaikui");
            };
            let updatedEntry = {
              entryId = entry.entryId;
              childId = entry.childId;
              foodName = newFoodName;
              category = newCategory;
              color = newColor;
              timestamp = entry.timestamp;
              reaction = newReaction;
              notes = newNotes;
            };
            persistentSolidFoodEntries.add(entryId, updatedEntry);
          };
        };
      };
    };
  };

  public shared ({ caller }) func deleteSolidFoodEntry(childId : Text, entryId : Text) : async () {
    autoRegisterUser(caller);

    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not canAccessChild(child, caller)) {
          Runtime.trap("Neturite prieigos prie šio vaiko");
        };
        switch (persistentSolidFoodEntries.get(entryId)) {
          case (null) { Runtime.trap("Primaitinimo įrašas nerastas") };
          case (?entry) {
            if (entry.childId != childId) {
              Runtime.trap("Primaitinimo įrašas nepriklauso šiam vaikui");
            };
            persistentSolidFoodEntries.remove(entryId);
          };
        };
      };
    };
  };

  public query ({ caller }) func getSolidFoodStatistics(childId : Text) : async {
    thisWeek : Nat;
    thisMonth : Nat;
    thisYear : Nat;
  } {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neturite prieigos prie šio vaiko");
          };
        };

        let now = Time.now();
        let weekAgo = now - 7 * 86_400_000_000_000;
        let monthAgo = now - 30 * 86_400_000_000_000;
        let yearAgo = now - 365 * 86_400_000_000_000;

        var thisWeek : Nat = 0;
        var thisMonth : Nat = 0;
        var thisYear : Nat = 0;

        for ((_, entry) in persistentSolidFoodEntries.entries()) {
          if (entry.childId == childId) {
            if (entry.timestamp >= weekAgo) {
              thisWeek += 1;
            };
            if (entry.timestamp >= monthAgo) {
              thisMonth += 1;
            };
            if (entry.timestamp >= yearAgo) {
              thisYear += 1;
            };
          };
        };

        { thisWeek; thisMonth; thisYear };
      };
    };
  };

  public query ({ caller }) func getSolidFoodStatisticsByCategory(
    childId : Text,
    startDate : Int,
    endDate : Int,
  ) : async {
    meat : Nat;
    vegetables : Nat;
    fruits : Nat;
    berries : Nat;
    grains : Nat;
    eggs : Nat;
    fish : Nat;
  } {
    switch (persistentChildProfiles.get(childId)) {
      case (null) { Runtime.trap("Vaikas nerastas") };
      case (?child) {
        if (not child.isPublic) {
          if (caller.isAnonymous()) {
            Runtime.trap("Neautorizuota: reikalinga prisijungti");
          };
          if (not canAccessChild(child, caller)) {
            Runtime.trap("Neturite prieigos prie šio vaiko");
          };
        };

        var meat : Nat = 0;
        var vegetables : Nat = 0;
        var fruits : Nat = 0;
        var berries : Nat = 0;
        var grains : Nat = 0;
        var eggs : Nat = 0;
        var fish : Nat = 0;

        for ((_, entry) in persistentSolidFoodEntries.entries()) {
          if (entry.childId == childId and entry.timestamp >= startDate and entry.timestamp <= endDate) {
            switch (entry.category) {
              case (#meat) { meat += 1 };
              case (#vegetables) { vegetables += 1 };
              case (#fruits) { fruits += 1 };
              case (#berries) { berries += 1 };
              case (#grains) { grains += 1 };
              case (#eggs) { eggs += 1 };
              case (#fish) { fish += 1 };
            };
          };
        };

        { meat; vegetables; fruits; berries; grains; eggs; fish };
      };
    };
  };

  // ---------- Backup / Restore (JSON) ----------
  // Internal mutable counters used while importing (public ImportCounts is shared).
  type MutablePair = { var restored : Nat; var skipped : Nat };
  type MutableCounts = {
    var childProfiles : MutablePair;
    var diaperLogs : MutablePair;
    var breastfeedingSessions : MutablePair;
    var tummyTimeSessions : MutablePair;
    var journalNotes : MutablePair;
    var weightEntries : MutablePair;
    var heightEntries : MutablePair;
    var milkPumpingSessions : MutablePair;
    var solidFoodEntries : MutablePair;
    var feedingSessions : MutablePair;
    var activeTimers : MutablePair;
    var tummyTimeTimers : MutablePair;
    var childInviteLinks : MutablePair;
    var userProfiles : MutablePair;
  };

  func newCounters() : MutableCounts {
    {
      var childProfiles = { var restored = 0; var skipped = 0 };
      var diaperLogs = { var restored = 0; var skipped = 0 };
      var breastfeedingSessions = { var restored = 0; var skipped = 0 };
      var tummyTimeSessions = { var restored = 0; var skipped = 0 };
      var journalNotes = { var restored = 0; var skipped = 0 };
      var weightEntries = { var restored = 0; var skipped = 0 };
      var heightEntries = { var restored = 0; var skipped = 0 };
      var milkPumpingSessions = { var restored = 0; var skipped = 0 };
      var solidFoodEntries = { var restored = 0; var skipped = 0 };
      var feedingSessions = { var restored = 0; var skipped = 0 };
      var activeTimers = { var restored = 0; var skipped = 0 };
      var tummyTimeTimers = { var restored = 0; var skipped = 0 };
      var childInviteLinks = { var restored = 0; var skipped = 0 };
      var userProfiles = { var restored = 0; var skipped = 0 };
    };
  };

  func toPublicCounts(c : MutableCounts) : ImportCounts {
    {
      childProfiles = { restored = c.childProfiles.restored; skipped = c.childProfiles.skipped };
      diaperLogs = { restored = c.diaperLogs.restored; skipped = c.diaperLogs.skipped };
      breastfeedingSessions = { restored = c.breastfeedingSessions.restored; skipped = c.breastfeedingSessions.skipped };
      tummyTimeSessions = { restored = c.tummyTimeSessions.restored; skipped = c.tummyTimeSessions.skipped };
      journalNotes = { restored = c.journalNotes.restored; skipped = c.journalNotes.skipped };
      weightEntries = { restored = c.weightEntries.restored; skipped = c.weightEntries.skipped };
      heightEntries = { restored = c.heightEntries.restored; skipped = c.heightEntries.skipped };
      milkPumpingSessions = { restored = c.milkPumpingSessions.restored; skipped = c.milkPumpingSessions.skipped };
      solidFoodEntries = { restored = c.solidFoodEntries.restored; skipped = c.solidFoodEntries.skipped };
      feedingSessions = { restored = c.feedingSessions.restored; skipped = c.feedingSessions.skipped };
      activeTimers = { restored = c.activeTimers.restored; skipped = c.activeTimers.skipped };
      tummyTimeTimers = { restored = c.tummyTimeTimers.restored; skipped = c.tummyTimeTimers.skipped };
      childInviteLinks = { restored = c.childInviteLinks.restored; skipped = c.childInviteLinks.skipped };
      userProfiles = { restored = c.userProfiles.restored; skipped = c.userProfiles.skipped };
    };
  };

  // JSON value constructors
  func jstr(t : Text) : Json.Json = Json.str(t);
  func jint(i : Int) : Json.Json = Json.int(i);
  func jfloat(f : Float) : Json.Json = Json.float(f);
  func jbool(b : Bool) : Json.Json = Json.bool(b);
  func jnull() : Json.Json = Json.nullable();
  func jobj(entries : [(Text, Json.Json)]) : Json.Json = Json.obj(entries);
  func jarr(items : [Json.Json]) : Json.Json = Json.arr(items);

  func encodeBlob(b : Blob) : Json.Json {
    jarr(b.toArray().map(func(byte : Nat8) : Json.Json = jint(byte.toNat())));
  };

  func encodeOptBlob(ob : ?Blob) : Json.Json {
    switch (ob) {
      case (?b) { encodeBlob(b) };
      case null { jnull() };
    };
  };

  func encodePrincipal(p : Principal) : Json.Json = jstr(p.toText());

  func encodePrincipalList(ps : List.List<Principal>) : Json.Json {
    jarr(ps.toArray().map(func(p : Principal) : Json.Json = encodePrincipal(p)));
  };

  func encodeChildProfile(c : ChildProfile) : Json.Json {
    jobj([
      ("_key", jstr(c.id)),
      ("id", jstr(c.id)),
      ("name", jstr(c.name)),
      ("birthDate", jint(c.birthDate)),
      ("photo", encodeOptBlob(c.photo)),
      ("isPublic", jbool(c.isPublic)),
      ("parent", encodePrincipal(c.parent)),
      ("sharedWith", encodePrincipalList(c.sharedWith)),
    ]);
  };

  func encodeDiaperLog(key : Text, d : DiaperLog) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("childId", jstr(d.childId)),
      ("timestamp", jint(d.timestamp)),
      ("kakis", jbool(d.contents.kakis)),
      ("sysius", jbool(d.contents.sysius)),
      ("tuscia", jbool(d.contents.tuscia)),
    ]);
  };

  func encodeBreastfeedingSession(key : Text, s : BreastfeedingSession) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("childId", jstr(s.childId)),
      ("startTime", jint(s.startTime)),
      ("duration", jint(s.duration)),
      ("side", jstr(switch (s.side) { case (#left) "left"; case (#right) "right" })),
    ]);
  };

  func encodeTummyTimeSession(key : Text, s : TummyTimeSession) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("sessionId", jstr(s.sessionId)),
      ("childId", jstr(s.childId)),
      ("startTime", jint(s.startTime)),
      ("duration", jint(s.duration)),
    ]);
  };

  func encodeJournalNote(key : Text, n : JournalNote) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("childId", jstr(n.childId)),
      ("text", jstr(n.text)),
      ("color", jstr(switch (n.color) { case (#yellow) "yellow"; case (#pink) "pink"; case (#blue) "blue"; case (#green) "green"; case (#purple) "purple" })),
      ("createdAt", jint(n.createdAt)),
      ("updatedAt", jint(n.updatedAt)),
    ]);
  };

  func encodeWeightEntry(key : Text, e : WeightEntry) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("weightId", jstr(e.weightId)),
      ("childId", jstr(e.childId)),
      ("timestamp", jint(e.timestamp)),
      ("weight", jfloat(e.weight)),
    ]);
  };

  func encodeHeightEntry(key : Text, e : HeightEntry) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("heightId", jstr(e.heightId)),
      ("childId", jstr(e.childId)),
      ("timestamp", jint(e.timestamp)),
      ("height", jfloat(e.height)),
    ]);
  };

  func encodeMilkPumpingSession(key : Text, s : MilkPumpingSession) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("sessionId", jstr(s.sessionId)),
      ("childId", jstr(s.childId)),
      ("timestamp", jint(s.timestamp)),
      ("mlAmount", jfloat(s.mlAmount)),
      ("side", jstr(switch (s.side) { case (#left) "left"; case (#right) "right"; case (#both) "both" })),
    ]);
  };

  func encodeSolidFoodEntry(key : Text, e : SolidFoodEntry) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("entryId", jstr(e.entryId)),
      ("childId", jstr(e.childId)),
      ("foodName", jstr(e.foodName)),
      ("category", jstr(switch (e.category) { case (#meat) "meat"; case (#vegetables) "vegetables"; case (#fruits) "fruits"; case (#berries) "berries"; case (#grains) "grains"; case (#eggs) "eggs"; case (#fish) "fish" })),
      ("color", jstr(e.color)),
      ("timestamp", jint(e.timestamp)),
      ("reaction", jstr(switch (e.reaction) { case (#liked) "liked"; case (#disliked) "disliked"; case (#unclear) "unclear" })),
      ("notes", switch (e.notes) { case (?t) jstr(t); case null jnull() }),
    ]);
  };

  func encodeFeedingSession(key : Text, s : FeedingSession) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("sessionId", jstr(s.sessionId)),
      ("childId", jstr(s.childId)),
      ("timestamp", jint(s.timestamp)),
      ("mlAmount", jfloat(s.mlAmount)),
      ("feedingType", jstr(switch (s.feedingType) { case (#misinukas) "misinukas"; case (#mamosPienas) "mamosPienas" })),
      ("color", jstr(s.color)),
    ]);
  };

  func encodeActiveTimer(key : Text, t : ActiveTimerState) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("childId", jstr(t.childId)),
      ("userId", encodePrincipal(t.userId)),
      ("startTime", jint(t.startTime)),
      ("side", jstr(switch (t.side) { case (#left) "left"; case (#right) "right" })),
      ("isPaused", jbool(t.isPaused)),
      ("pausedAt", switch (t.pausedAt) { case (?p) jint(p); case null jnull() }),
      ("totalPausedDuration", jint(t.totalPausedDuration)),
    ]);
  };

  func encodeTummyTimeTimer(key : Text, t : TummyTimeTimerState) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("childId", jstr(t.childId)),
      ("userId", encodePrincipal(t.userId)),
      ("startTime", jint(t.startTime)),
      ("isPaused", jbool(t.isPaused)),
      ("pausedAt", switch (t.pausedAt) { case (?p) jint(p); case null jnull() }),
      ("totalPausedDuration", jint(t.totalPausedDuration)),
    ]);
  };

  func encodeChildInviteLink(key : Text, l : ChildInviteLink) : Json.Json {
    jobj([
      ("_key", jstr(key)),
      ("inviteCode", jstr(l.inviteCode)),
      ("childId", jstr(l.childId)),
      ("createdBy", encodePrincipal(l.createdBy)),
      ("createdAt", jint(l.createdAt)),
      ("used", jbool(l.used)),
    ]);
  };

  // JSON field accessors
  func getField(j : Json.Json, key : Text) : ?Json.Json {
    switch (j) {
      case (#object_(entries)) {
        for ((k, v) in entries.vals()) {
          if (k == key) { return ?v };
        };
        null;
      };
      case _ { null };
    };
  };

  func fieldText(j : Json.Json, key : Text) : ?Text {
    switch (getField(j, key)) {
      case (?#string(s)) { ?s };
      case _ { null };
    };
  };

  func fieldInt(j : Json.Json, key : Text) : ?Int {
    switch (getField(j, key)) {
      case (?#number(#int(n))) { ?n };
      case _ { null };
    };
  };

  func fieldFloat(j : Json.Json, key : Text) : ?Float {
    switch (getField(j, key)) {
      case (?#number(n)) {
        switch (n) {
          case (#int(i)) { ?i.toFloat() };
          case (#float(f)) { ?f };
        };
      };
      case _ { null };
    };
  };

  func fieldBool(j : Json.Json, key : Text) : ?Bool {
    switch (getField(j, key)) {
      case (?#bool(b)) { ?b };
      case _ { null };
    };
  };

  func firstText(j : Json.Json, keys : [Text]) : ?Text {
    for (k in keys.vals()) {
      switch (fieldText(j, k)) {
        case (?v) { return ?v };
        case null {};
      };
    };
    null;
  };

  // Optional-field decoders: outer ? = field valid, inner = optional value.
  func decodeOptBlob(j : Json.Json) : ?Blob {
    switch (getField(j, "photo")) {
      case (?#null_) { null };
      case (?#array(items)) {
        var ok = true;
        let bytes = Array.tabulate<Nat8>(items.size(), func i {
          switch (items[i]) {
            case (#number(#int(n))) {
              if (n >= 0 and n <= 255) { n.toNat().toNat8() } else { ok := false; 0 };
            };
            case _ { ok := false; 0 };
          };
        });
        if (ok) { ?bytes.toBlob() } else { null };
      };
      case _ { null };
    };
  };

  func decodeOptText(j : Json.Json, key : Text) : ?Text {
    switch (getField(j, key)) {
      case (?#string(s)) { ?s };
      case (?#null_) { null };
      case _ { null };
    };
  };

  func decodeOptInt(j : Json.Json, key : Text) : ?Int {
    switch (getField(j, key)) {
      case (?#number(#int(n))) { ?n };
      case (?#null_) { null };
      case _ { null };
    };
  };

  func decodePrincipalList(j : Json.Json) : ?List.List<Principal> {
    switch (getField(j, "sharedWith")) {
      case (?#array(items)) {
        let ps = List.empty<Principal>();
        for (item in items.vals()) {
          switch (item) {
            case (#string(t)) { ps.add(Principal.fromText(t)) };
            case _ { return null };
          };
        };
        ?ps;
      };
      case _ { null };
    };
  };

  // Record decoders: return null when any required field is missing/malformed.
  func decodeChildProfile(j : Json.Json) : ?(Text, ChildProfile) {
    do ? {
      let key = firstText(j, ["_key", "id"])!;
      let id = fieldText(j, "id")!;
      let name = fieldText(j, "name")!;
      let birthDate = fieldInt(j, "birthDate")!;
      let photo = decodeOptBlob(j);
      let isPublic = fieldBool(j, "isPublic")!;
      let parent = Principal.fromText(fieldText(j, "parent")!);
      let sharedWith = decodePrincipalList(j)!;
      (key, { id; name; birthDate; photo; isPublic; parent; sharedWith });
    };
  };

  func decodeDiaperLog(j : Json.Json) : ?(Text, DiaperLog) {
    do ? {
      let key = fieldText(j, "_key")!;
      let childId = fieldText(j, "childId")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let kakis = fieldBool(j, "kakis")!;
      let sysius = fieldBool(j, "sysius")!;
      let tuscia = fieldBool(j, "tuscia")!;
      (key, { childId; timestamp; contents = { kakis; sysius; tuscia } });
    };
  };

  func decodeBreastfeedingSession(j : Json.Json) : ?(Text, BreastfeedingSession) {
    do ? {
      let key = fieldText(j, "_key")!;
      let childId = fieldText(j, "childId")!;
      let startTime = fieldInt(j, "startTime")!;
      let duration = fieldInt(j, "duration")!;
      let side = switch (fieldText(j, "side")!) {
        case "left" { #left };
        case "right" { #right };
        case _ { return null };
      };
      (key, { childId; startTime; duration; side });
    };
  };

  func decodeTummyTimeSession(j : Json.Json) : ?(Text, TummyTimeSession) {
    do ? {
      let key = firstText(j, ["_key", "sessionId"])!;
      let sessionId = fieldText(j, "sessionId")!;
      let childId = fieldText(j, "childId")!;
      let startTime = fieldInt(j, "startTime")!;
      let duration = fieldInt(j, "duration")!;
      (key, { sessionId; childId; startTime; duration });
    };
  };

  func decodeJournalNote(j : Json.Json) : ?(Text, JournalNote) {
    do ? {
      let key = fieldText(j, "_key")!;
      let childId = fieldText(j, "childId")!;
      let text = fieldText(j, "text")!;
      let color = switch (fieldText(j, "color")!) {
        case "yellow" { #yellow };
        case "pink" { #pink };
        case "blue" { #blue };
        case "green" { #green };
        case "purple" { #purple };
        case _ { return null };
      };
      let createdAt = fieldInt(j, "createdAt")!;
      let updatedAt = fieldInt(j, "updatedAt")!;
      (key, { childId; text; color; createdAt; updatedAt });
    };
  };

  func decodeWeightEntry(j : Json.Json) : ?(Text, WeightEntry) {
    do ? {
      let key = firstText(j, ["_key", "weightId"])!;
      let weightId = fieldText(j, "weightId")!;
      let childId = fieldText(j, "childId")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let weight = fieldFloat(j, "weight")!;
      (key, { weightId; childId; timestamp; weight });
    };
  };

  func decodeHeightEntry(j : Json.Json) : ?(Text, HeightEntry) {
    do ? {
      let key = firstText(j, ["_key", "heightId"])!;
      let heightId = fieldText(j, "heightId")!;
      let childId = fieldText(j, "childId")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let height = fieldFloat(j, "height")!;
      (key, { heightId; childId; timestamp; height });
    };
  };

  func decodeMilkPumpingSession(j : Json.Json) : ?(Text, MilkPumpingSession) {
    do ? {
      let key = firstText(j, ["_key", "sessionId"])!;
      let sessionId = fieldText(j, "sessionId")!;
      let childId = fieldText(j, "childId")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let mlAmount = fieldFloat(j, "mlAmount")!;
      let side = switch (fieldText(j, "side")!) {
        case "left" { #left };
        case "right" { #right };
        case "both" { #both };
        case _ { return null };
      };
      (key, { sessionId; childId; timestamp; mlAmount; side });
    };
  };

  func decodeSolidFoodEntry(j : Json.Json) : ?(Text, SolidFoodEntry) {
    do ? {
      let key = firstText(j, ["_key", "entryId"])!;
      let entryId = fieldText(j, "entryId")!;
      let childId = fieldText(j, "childId")!;
      let foodName = fieldText(j, "foodName")!;
      let category = switch (fieldText(j, "category")!) {
        case "meat" { #meat };
        case "vegetables" { #vegetables };
        case "fruits" { #fruits };
        case "berries" { #berries };
        case "grains" { #grains };
        case "eggs" { #eggs };
        case "fish" { #fish };
        case _ { return null };
      };
      let color = fieldText(j, "color")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let reaction = switch (fieldText(j, "reaction")!) {
        case "liked" { #liked };
        case "disliked" { #disliked };
        case "unclear" { #unclear };
        case _ { return null };
      };
      let notes = decodeOptText(j, "notes");
      (key, { entryId; childId; foodName; category; color; timestamp; reaction; notes });
    };
  };

  func decodeFeedingSession(j : Json.Json) : ?(Text, FeedingSession) {
    do ? {
      let key = firstText(j, ["_key", "sessionId"])!;
      let sessionId = fieldText(j, "sessionId")!;
      let childId = fieldText(j, "childId")!;
      let timestamp = fieldInt(j, "timestamp")!;
      let mlAmount = fieldFloat(j, "mlAmount")!;
      let feedingType = switch (fieldText(j, "feedingType")!) {
        case "misinukas" { #misinukas };
        case "mamosPienas" { #mamosPienas };
        case _ { return null };
      };
      let color = fieldText(j, "color")!;
      (key, { sessionId; childId; timestamp; mlAmount; feedingType; color });
    };
  };

  func decodeActiveTimer(j : Json.Json) : ?(Text, ActiveTimerState) {
    do ? {
      let key = fieldText(j, "_key")!;
      let childId = fieldText(j, "childId")!;
      let userId = Principal.fromText(fieldText(j, "userId")!);
      let startTime = fieldInt(j, "startTime")!;
      let side = switch (fieldText(j, "side")!) {
        case "left" { #left };
        case "right" { #right };
        case _ { return null };
      };
      let isPaused = fieldBool(j, "isPaused")!;
      let pausedAt = decodeOptInt(j, "pausedAt");
      let totalPausedDuration = fieldInt(j, "totalPausedDuration")!;
      (key, { childId; userId; startTime; side; isPaused; pausedAt; totalPausedDuration });
    };
  };

  func decodeTummyTimeTimer(j : Json.Json) : ?(Text, TummyTimeTimerState) {
    do ? {
      let key = fieldText(j, "_key")!;
      let childId = fieldText(j, "childId")!;
      let userId = Principal.fromText(fieldText(j, "userId")!);
      let startTime = fieldInt(j, "startTime")!;
      let isPaused = fieldBool(j, "isPaused")!;
      let pausedAt = decodeOptInt(j, "pausedAt");
      let totalPausedDuration = fieldInt(j, "totalPausedDuration")!;
      (key, { childId; userId; startTime; isPaused; pausedAt; totalPausedDuration });
    };
  };

  func decodeChildInviteLink(j : Json.Json) : ?(Text, ChildInviteLink) {
    do ? {
      let key = firstText(j, ["_key", "inviteCode"])!;
      let inviteCode = fieldText(j, "inviteCode")!;
      let childId = fieldText(j, "childId")!;
      let createdBy = Principal.fromText(fieldText(j, "createdBy")!);
      let createdAt = fieldInt(j, "createdAt")!;
      let used = fieldBool(j, "used")!;
      (key, { inviteCode; childId; createdBy; createdAt; used });
    };
  };

  func decodeUserProfile(j : Json.Json) : ?(Principal, UserProfile) {
    do ? {
      let owner = Principal.fromText(fieldText(j, "_owner")!);
      let name = fieldText(j, "name")!;
      (owner, { name });
    };
  };

  func decodeArray<T>(j : Json.Json, key : Text, decoder : (Json.Json) -> ?T) : ?[T] {
    switch (getField(j, key)) {
      case (?#array(items)) {
        let result = List.empty<T>();
        for (item in items.vals()) {
          switch (decoder(item)) {
            case (?v) { result.add(v) };
            case null { return null };
          };
        };
        ?result.toArray();
      };
      case _ { null };
    };
  };

  // Export all data owned by the signed-in caller as a single JSON blob.
  public query ({ caller }) func exportAllData() : async Text {
    if (caller.isAnonymous()) {
      Runtime.trap("Neautorizuota: reikalinga prisijungti");
    };
    autoRegisterUser(caller);

    // Gather the caller's own children and their IDs.
    let children = List.empty<ChildProfile>();
    for ((_, c) in persistentChildProfiles.entries()) {
      if (c.parent == caller) {
        children.add(c);
      };
    };
    let ownedChildIds = children.toArray().map(func(c : ChildProfile) : Text = c.id);
    func isOwnedChild(childId : Text) : Bool {
      ownedChildIds.contains(childId);
    };

    let childJson = children.toArray().map(func(c : ChildProfile) : Json.Json = encodeChildProfile(c));

    let diaperJson = List.empty<Json.Json>();
    for ((k, d) in persistentDiaperLogs.entries()) {
      if (isOwnedChild(d.childId)) {
        diaperJson.add(encodeDiaperLog(k, d));
      };
    };

    let breastfeedingJson = List.empty<Json.Json>();
    for ((k, s) in persistentBreastfeedingSessions.entries()) {
      if (isOwnedChild(s.childId)) {
        breastfeedingJson.add(encodeBreastfeedingSession(k, s));
      };
    };

    let tummyTimeJson = List.empty<Json.Json>();
    for ((k, s) in persistentTummyTimeSessions.entries()) {
      if (isOwnedChild(s.childId)) {
        tummyTimeJson.add(encodeTummyTimeSession(k, s));
      };
    };

    let journalJson = List.empty<Json.Json>();
    for ((k, n) in persistentJournalNotes.entries()) {
      if (isOwnedChild(n.childId)) {
        journalJson.add(encodeJournalNote(k, n));
      };
    };

    let weightJson = List.empty<Json.Json>();
    for ((k, e) in persistentWeightEntries.entries()) {
      if (isOwnedChild(e.childId)) {
        weightJson.add(encodeWeightEntry(k, e));
      };
    };

    let heightJson = List.empty<Json.Json>();
    for ((k, e) in persistentHeightEntries.entries()) {
      if (isOwnedChild(e.childId)) {
        heightJson.add(encodeHeightEntry(k, e));
      };
    };

    let milkPumpingJson = List.empty<Json.Json>();
    for ((k, s) in persistentMilkPumpingSessions.entries()) {
      if (isOwnedChild(s.childId)) {
        milkPumpingJson.add(encodeMilkPumpingSession(k, s));
      };
    };

    let solidFoodJson = List.empty<Json.Json>();
    for ((k, e) in persistentSolidFoodEntries.entries()) {
      if (isOwnedChild(e.childId)) {
        solidFoodJson.add(encodeSolidFoodEntry(k, e));
      };
    };

    let feedingJson = List.empty<Json.Json>();
    for ((k, s) in persistentFeedingSessions.entries()) {
      if (isOwnedChild(s.childId)) {
        feedingJson.add(encodeFeedingSession(k, s));
      };
    };

    let activeTimerJson = List.empty<Json.Json>();
    for ((k, t) in persistentActiveTimers.entries()) {
      if (t.userId == caller) {
        activeTimerJson.add(encodeActiveTimer(k, t));
      };
    };

    let tummyTimeTimerJson = List.empty<Json.Json>();
    for ((k, t) in persistentTummyTimeTimers.entries()) {
      if (t.userId == caller) {
        tummyTimeTimerJson.add(encodeTummyTimeTimer(k, t));
      };
    };

    let inviteLinkJson = List.empty<Json.Json>();
    for ((k, l) in persistentChildInviteLinks.entries()) {
      if (l.createdBy == caller) {
        inviteLinkJson.add(encodeChildInviteLink(k, l));
      };
    };

    let userProfileJson = switch (persistentUserProfiles.get(caller)) {
      case (?p) { ?jobj([("_owner", encodePrincipal(caller)), ("name", jstr(p.name))]) };
      case null { null };
    };

    let exportObj = jobj([
      ("formatVersion", jint(1)),
      ("exportedAt", jint(Time.now())),
      ("userProfile", switch (userProfileJson) { case (?j) j; case null jnull() }),
      ("children", jarr(childJson)),
      ("diaperLogs", jarr(diaperJson.toArray())),
      ("breastfeedingSessions", jarr(breastfeedingJson.toArray())),
      ("tummyTimeSessions", jarr(tummyTimeJson.toArray())),
      ("journalNotes", jarr(journalJson.toArray())),
      ("weightEntries", jarr(weightJson.toArray())),
      ("heightEntries", jarr(heightJson.toArray())),
      ("milkPumpingSessions", jarr(milkPumpingJson.toArray())),
      ("solidFoodEntries", jarr(solidFoodJson.toArray())),
      ("feedingSessions", jarr(feedingJson.toArray())),
      ("activeTimers", jarr(activeTimerJson.toArray())),
      ("tummyTimeTimers", jarr(tummyTimeTimerJson.toArray())),
      ("childInviteLinks", jarr(inviteLinkJson.toArray())),
    ]);

    Json.stringify(exportObj, null);
  };

  // Restore data from a JSON backup blob, idempotently and only for caller-owned data.
  public shared ({ caller }) func importAllData(blob : Text) : async ImportResult {
    if (caller.isAnonymous()) {
      Runtime.trap("Neautorizuota: reikalinga prisijungti");
    };
    autoRegisterUser(caller);

    // 1. Parse the JSON.
    let parsed = switch (Json.parse(blob)) {
      case (#ok(j)) { j };
      case (#err(_)) { Runtime.trap("Neteisingas JSON formatas") };
    };

    // 2. Validate the format version.
    let version = switch (fieldInt(parsed, "formatVersion")) {
      case (?v) { v };
      case null { Runtime.trap("Trūksta atsarginės kopijos formato versijos") };
    };
    if (version != 1) {
      Runtime.trap("Nesuderinamas atsarginės kopijos formatas");
    };

    // 3. Decode every section up front — nothing is written until the whole
    //    file validates, so a malformed backup changes nothing.
    let children = switch (decodeArray(parsed, "children", decodeChildProfile)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let diaperLogs = switch (decodeArray(parsed, "diaperLogs", decodeDiaperLog)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let breastfeedingSessions = switch (decodeArray(parsed, "breastfeedingSessions", decodeBreastfeedingSession)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let tummyTimeSessions = switch (decodeArray(parsed, "tummyTimeSessions", decodeTummyTimeSession)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let journalNotes = switch (decodeArray(parsed, "journalNotes", decodeJournalNote)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let weightEntries = switch (decodeArray(parsed, "weightEntries", decodeWeightEntry)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let heightEntries = switch (decodeArray(parsed, "heightEntries", decodeHeightEntry)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let milkPumpingSessions = switch (decodeArray(parsed, "milkPumpingSessions", decodeMilkPumpingSession)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let solidFoodEntries = switch (decodeArray(parsed, "solidFoodEntries", decodeSolidFoodEntry)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let feedingSessions = switch (decodeArray(parsed, "feedingSessions", decodeFeedingSession)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let activeTimers = switch (decodeArray(parsed, "activeTimers", decodeActiveTimer)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let tummyTimeTimers = switch (decodeArray(parsed, "tummyTimeTimers", decodeTummyTimeTimer)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let childInviteLinks = switch (decodeArray(parsed, "childInviteLinks", decodeChildInviteLink)) {
      case (?v) { v };
      case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };
    let userProfile = switch (getField(parsed, "userProfile")) {
      case (?#null_) { null };
      case (?#object_(up)) {
        switch (decodeUserProfile(#object_(up))) {
          case (?up2) { ?up2 };
          case null { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
        };
      };
      case _ { Runtime.trap("Neteisinga atsarginės kopijos struktūra") };
    };

    // 4. Determine which children the caller owns in this backup.
    let ownedChildIds = List.empty<Text>();
    for ((_, c) in children.vals()) {
      if (c.parent == caller) {
        ownedChildIds.add(c.id);
      };
    };
    let ownedSet = ownedChildIds.toArray();
    func isOwned(childId : Text) : Bool { ownedSet.contains(childId) };

    // 5. Restore idempotently — skip entries whose stable ID already exists.
    let counts = newCounters();

    for ((key, c) in children.vals()) {
      if (c.parent == caller) {
        switch (persistentChildProfiles.get(key)) {
          case (?_ ) { counts.childProfiles.skipped += 1 };
          case null {
            persistentChildProfiles.add(key, c);
            counts.childProfiles.restored += 1;
          };
        };
      } else {
        counts.childProfiles.skipped += 1;
      };
    };

    for ((key, d) in diaperLogs.vals()) {
      if (isOwned(d.childId)) {
        switch (persistentDiaperLogs.get(key)) {
          case (?_ ) { counts.diaperLogs.skipped += 1 };
          case null {
            persistentDiaperLogs.add(key, d);
            counts.diaperLogs.restored += 1;
          };
        };
      } else {
        counts.diaperLogs.skipped += 1;
      };
    };

    for ((key, s) in breastfeedingSessions.vals()) {
      if (isOwned(s.childId)) {
        switch (persistentBreastfeedingSessions.get(key)) {
          case (?_ ) { counts.breastfeedingSessions.skipped += 1 };
          case null {
            persistentBreastfeedingSessions.add(key, s);
            counts.breastfeedingSessions.restored += 1;
          };
        };
      } else {
        counts.breastfeedingSessions.skipped += 1;
      };
    };

    for ((key, s) in tummyTimeSessions.vals()) {
      if (isOwned(s.childId)) {
        switch (persistentTummyTimeSessions.get(key)) {
          case (?_ ) { counts.tummyTimeSessions.skipped += 1 };
          case null {
            persistentTummyTimeSessions.add(key, s);
            counts.tummyTimeSessions.restored += 1;
          };
        };
      } else {
        counts.tummyTimeSessions.skipped += 1;
      };
    };

    for ((key, n) in journalNotes.vals()) {
      if (isOwned(n.childId)) {
        switch (persistentJournalNotes.get(key)) {
          case (?_ ) { counts.journalNotes.skipped += 1 };
          case null {
            persistentJournalNotes.add(key, n);
            counts.journalNotes.restored += 1;
          };
        };
      } else {
        counts.journalNotes.skipped += 1;
      };
    };

    for ((key, e) in weightEntries.vals()) {
      if (isOwned(e.childId)) {
        switch (persistentWeightEntries.get(key)) {
          case (?_ ) { counts.weightEntries.skipped += 1 };
          case null {
            persistentWeightEntries.add(key, e);
            counts.weightEntries.restored += 1;
          };
        };
      } else {
        counts.weightEntries.skipped += 1;
      };
    };

    for ((key, e) in heightEntries.vals()) {
      if (isOwned(e.childId)) {
        switch (persistentHeightEntries.get(key)) {
          case (?_ ) { counts.heightEntries.skipped += 1 };
          case null {
            persistentHeightEntries.add(key, e);
            counts.heightEntries.restored += 1;
          };
        };
      } else {
        counts.heightEntries.skipped += 1;
      };
    };

    for ((key, s) in milkPumpingSessions.vals()) {
      if (isOwned(s.childId)) {
        switch (persistentMilkPumpingSessions.get(key)) {
          case (?_ ) { counts.milkPumpingSessions.skipped += 1 };
          case null {
            persistentMilkPumpingSessions.add(key, s);
            counts.milkPumpingSessions.restored += 1;
          };
        };
      } else {
        counts.milkPumpingSessions.skipped += 1;
      };
    };

    for ((key, e) in solidFoodEntries.vals()) {
      if (isOwned(e.childId)) {
        switch (persistentSolidFoodEntries.get(key)) {
          case (?_ ) { counts.solidFoodEntries.skipped += 1 };
          case null {
            persistentSolidFoodEntries.add(key, e);
            counts.solidFoodEntries.restored += 1;
          };
        };
      } else {
        counts.solidFoodEntries.skipped += 1;
      };
    };

    for ((key, s) in feedingSessions.vals()) {
      if (isOwned(s.childId)) {
        switch (persistentFeedingSessions.get(key)) {
          case (?_ ) { counts.feedingSessions.skipped += 1 };
          case null {
            persistentFeedingSessions.add(key, s);
            counts.feedingSessions.restored += 1;
          };
        };
      } else {
        counts.feedingSessions.skipped += 1;
      };
    };

    for ((key, t) in activeTimers.vals()) {
      if (t.userId == caller) {
        switch (persistentActiveTimers.get(key)) {
          case (?_ ) { counts.activeTimers.skipped += 1 };
          case null {
            persistentActiveTimers.add(key, t);
            counts.activeTimers.restored += 1;
          };
        };
      } else {
        counts.activeTimers.skipped += 1;
      };
    };

    for ((key, t) in tummyTimeTimers.vals()) {
      if (t.userId == caller) {
        switch (persistentTummyTimeTimers.get(key)) {
          case (?_ ) { counts.tummyTimeTimers.skipped += 1 };
          case null {
            persistentTummyTimeTimers.add(key, t);
            counts.tummyTimeTimers.restored += 1;
          };
        };
      } else {
        counts.tummyTimeTimers.skipped += 1;
      };
    };

    for ((key, l) in childInviteLinks.vals()) {
      if (l.createdBy == caller) {
        switch (persistentChildInviteLinks.get(key)) {
          case (?_ ) { counts.childInviteLinks.skipped += 1 };
          case null {
            persistentChildInviteLinks.add(key, l);
            counts.childInviteLinks.restored += 1;
          };
        };
      } else {
        counts.childInviteLinks.skipped += 1;
      };
    };

    switch (userProfile) {
      case (?(owner, p)) {
        if (owner == caller) {
          switch (persistentUserProfiles.get(caller)) {
            case (?_ ) { counts.userProfiles.skipped += 1 };
            case null {
              persistentUserProfiles.add(caller, p);
              counts.userProfiles.restored += 1;
            };
          };
        } else {
          counts.userProfiles.skipped += 1;
        };
      };
      case null {};
    };

    // 6. Build the summary result.
    let publicCounts = toPublicCounts(counts);
    let totalRestored =
      publicCounts.childProfiles.restored + publicCounts.diaperLogs.restored +
      publicCounts.breastfeedingSessions.restored + publicCounts.tummyTimeSessions.restored +
      publicCounts.journalNotes.restored + publicCounts.weightEntries.restored +
      publicCounts.heightEntries.restored + publicCounts.milkPumpingSessions.restored +
      publicCounts.solidFoodEntries.restored + publicCounts.feedingSessions.restored +
      publicCounts.activeTimers.restored + publicCounts.tummyTimeTimers.restored +
      publicCounts.childInviteLinks.restored + publicCounts.userProfiles.restored;
    let totalSkipped =
      publicCounts.childProfiles.skipped + publicCounts.diaperLogs.skipped +
      publicCounts.breastfeedingSessions.skipped + publicCounts.tummyTimeSessions.skipped +
      publicCounts.journalNotes.skipped + publicCounts.weightEntries.skipped +
      publicCounts.heightEntries.skipped + publicCounts.milkPumpingSessions.skipped +
      publicCounts.solidFoodEntries.skipped + publicCounts.feedingSessions.skipped +
      publicCounts.activeTimers.skipped + publicCounts.tummyTimeTimers.skipped +
      publicCounts.childInviteLinks.skipped + publicCounts.userProfiles.skipped;

    {
      success = true;
      totalRestored;
      totalSkipped;
      counts = publicCounts;
    };
  };
};