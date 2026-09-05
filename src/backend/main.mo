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



actor {
  let accessControlState : AccessControl.AccessControlState;
  include MixinAuthorization(accessControlState);
  include MixinObjectStorage();

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
        .payload("sessionId", func ((k, _) : (Text, BreastfeedingSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, BreastfeedingSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("startTime", func ((_, v) : (Text, BreastfeedingSession)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("duration", func ((_, v) : (Text, BreastfeedingSession)) : Int = v.duration, OQL.IntValue._toRow)
        .payload("side", func ((_, v) : (Text, BreastfeedingSession)) : Text = switch (v.side) { case (#left) "left"; case (#right) "right" }, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // TummyTimeSession — manual (PK is Map key)
      OQL.Entity.manual<(Text, TummyTimeSession)>("tummyTimeSession", func () = persistentTummyTimeSessions.entries(), "TummyTimeSession", "sessionId")
        .payload("sessionId", func ((k, _) : (Text, TummyTimeSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, TummyTimeSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("startTime", func ((_, v) : (Text, TummyTimeSession)) : Int = v.startTime, OQL.IntValue._toRow)
        .payload("duration", func ((_, v) : (Text, TummyTimeSession)) : Int = v.duration, OQL.IntValue._toRow)
        .controllerOnly()
        .build(),
      // JournalNote — manual (variant color; PK is Map key)
      OQL.Entity.manual<(Text, JournalNote)>("journalNote", func () = persistentJournalNotes.entries(), "JournalNote", "noteId")
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
        .payload("weightId", func ((k, _) : (Text, WeightEntry)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, WeightEntry)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, WeightEntry)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("weight", func ((_, v) : (Text, WeightEntry)) : Float = v.weight, OQL.FloatValue._toRow)
        .controllerOnly()
        .build(),
      // HeightEntry — manual (all primitives, heightId is a field)
      OQL.Entity.manual<(Text, HeightEntry)>("heightEntry", func () = persistentHeightEntries.entries(), "HeightEntry", "heightId")
        .payload("heightId", func ((k, _) : (Text, HeightEntry)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, HeightEntry)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, HeightEntry)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("height", func ((_, v) : (Text, HeightEntry)) : Float = v.height, OQL.FloatValue._toRow)
        .controllerOnly()
        .build(),
      // MilkPumpingSession — auto (sessionId is a field; variant side needs Value converter OR manual).
      // Using manual to handle the variant side safely.
      OQL.Entity.manual<(Text, MilkPumpingSession)>("milkPumpingSession", func () = persistentMilkPumpingSessions.entries(), "MilkPumpingSession", "sessionId")
        .payload("sessionId", func ((k, _) : (Text, MilkPumpingSession)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, MilkPumpingSession)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("timestamp", func ((_, v) : (Text, MilkPumpingSession)) : Int = v.timestamp, OQL.IntValue._toRow)
        .payload("mlAmount", func ((_, v) : (Text, MilkPumpingSession)) : Float = v.mlAmount, OQL.FloatValue._toRow)
        .payload("side", func ((_, v) : (Text, MilkPumpingSession)) : Text = switch (v.side) { case (#left) "left"; case (#right) "right"; case (#both) "both" }, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // SolidFoodEntry — manual (variants category/reaction, notes : ?Text)
      OQL.Entity.manual<(Text, SolidFoodEntry)>("solidFoodEntry", func () = persistentSolidFoodEntries.entries(), "SolidFoodEntry", "entryId")
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
        .payload("user", func ((k, _) : (Principal, UserProfile)) : Principal = k, OQL.PrincipalValue._toRow)
        .payload("name", func ((_, v) : (Principal, UserProfile)) : Text = v.name, OQL.TextValue._toRow)
        .controllerOnly()
        .build(),
      // ChildInviteLink — manual (all primitives, inviteCode is a field)
      OQL.Entity.manual<(Text, ChildInviteLink)>("childInviteLink", func () = persistentChildInviteLinks.entries(), "ChildInviteLink", "inviteCode")
        .payload("inviteCode", func ((k, _) : (Text, ChildInviteLink)) : Text = k, OQL.TextValue._toRow)
        .payload("childId", func ((_, v) : (Text, ChildInviteLink)) : Text = v.childId, OQL.TextValue._toRow)
        .payload("createdBy", func ((_, v) : (Text, ChildInviteLink)) : Principal = v.createdBy, OQL.PrincipalValue._toRow)
        .payload("createdAt", func ((_, v) : (Text, ChildInviteLink)) : Int = v.createdAt, OQL.IntValue._toRow)
        .payload("used", func ((_, v) : (Text, ChildInviteLink)) : Bool = v.used, OQL.BoolValue._toRow)
        .controllerOnly()
        .build(),
      // ActiveTimerState — manual (variant side, pausedAt : ?Int; PK is Map key)
      OQL.Entity.manual<(Text, ActiveTimerState)>("activeTimer", func () = persistentActiveTimers.entries(), "ActiveTimerState", "timerId")
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
};