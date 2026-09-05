// Behavioral API documentation mixin.
//
// Exposes a single static Markdown document describing the backend's current
// public API. It reads no state and takes no parameters; the document is
// authored from the current backend source.

mixin () {
  public query func getApiDoc() : async Text {
    "# Kūdikio stebėjimo programos backend API\n" #
    "\n" #
    "## Purpose\n" #
    "\n" #
    "This backend powers a baby-tracking application (kūdikio stebėjimo programa). It stores and serves data about children and their daily care: child profiles, diaper changes, breastfeeding sessions, tummy time, journal notes, weight and height entries, milk pumping, solid food (primaitinimas) entries, feeding sessions, active timers, child sharing, invite links, and user profiles. It also exposes a JSON backup/restore facility (exportAllData / importAllData) so a signed-in user can download all of their own data and re-import it losslessly.\n" #
    "\n" #
    "## Authentication\n" #
    "\n" #
    "Every endpoint that reads or writes personal data requires a signed-in (non-anonymous) Internet Identity caller. Anonymous callers are rejected on guarded endpoints with a Lithuanian trap message such as Neautorizuota: reikalinga prisijungti.\n" #
    "\n" #
    "The app's frontend pins an Internet Identity derivation origin, published at /.well-known/ii-derivation-origin when available. An agent already holding the user's Internet Identity authorization derives the correct per-app principal against that origin (for example icp identity link web <name> --app <host>). Such a delegation acts with the user's full authority in this app until it expires.\n" #
    "\n" #
    "## Authorization\n" #
    "\n" #
    "The backend uses role-based access control with admin, user, and guest roles, plus per-child ownership and sharing.\n" #
    "\n" #
    "- Admin: can generate general app invite codes (generateInviteCode), view all RSVPs (getAllRSVPs), view invite codes (getInviteCodes), and read any user profile (getUserProfile). Admin checks use AccessControl.hasPermission(accessControlState, caller, #admin).\n" #
    "- User: a signed-in caller is auto-registered as a user on first interaction (autoRegisterUser). Users manage their own children and data.\n" #
    "- Guest / anonymous: rejected on guarded endpoints.\n" #
    "\n" #
    "Child ownership and sharing. A child profile has a parent (the principal who created it) and a sharedWith list of principals. canAccessChild(child, caller) returns true when the caller is the parent or is in sharedWith. Many child-scoped endpoints (logDiaperChange, startBreastfeedingSession, addJournalNote, addWeightEntry, addHeightEntry, addMilkPumpingSession, addFeedingSession, addSolidFoodEntry, and the corresponding read/update/delete endpoints) require canAccessChild. Parent-only operations (visibility toggle, invite-link generation, sharing, revoking, viewing shared users) additionally require child.parent == caller. Public children (isPublic == true) are readable without signing in.\n" #
    "\n" #
    "Registration prerequisite. A caller becomes a registered user only by signing in through the app's own frontend (which calls autoRegisterUser). A principal that never did so is unregistered even when it belongs to the app's owner, and a signed-in caller derived against a different origin is a different principal than the one the frontend registered. Guarded endpoints trap with a Lithuanian message when the caller lacks the required role or access.\n" #
    "\n" #
    "## Units and encodings\n" #
    "\n" #
    "- Timestamps are Unix epoch milliseconds (Int). Time.now() returns nanoseconds internally, but all persisted timestamp / startTime / createdAt / updatedAt / birthDate fields are stored and returned in milliseconds.\n" #
    "- Weights are in kilograms (Float).\n" #
    "- Heights are in centimeters (Float).\n" #
    "- Milk / feeding amounts (mlAmount) are in milliliters (Float).\n" #
    "- Durations (breastfeeding, tummy time) are in milliseconds (Int).\n" #
    "- Identifiers are Text. Child IDs are name # birthDate.toText(). Most record IDs are Time.now().toText() or a generated UUID. Records whose stable ID lives in the Map key (not a field) carry a _key field in the JSON backup so the key round-trips.\n" #
    "- Optional values are encoded as JSON null (e.g. photo, notes, pausedAt).\n" #
    "- Variants are encoded as their tag text in JSON (e.g. side as left/right/both, color as yellow/pink/blue/green/purple, category as meat/vegetables/fruits/berries/grains/eggs/fish, reaction as liked/disliked/unclear, feedingType as misinukas/mamosPienas).\n" #
    "\n" #
    "## Backup / restore format\n" #
    "\n" #
    "exportAllData returns a single JSON object with formatVersion: 1, exportedAt (ms), userProfile, and one array per data domain (children, diaperLogs, breastfeedingSessions, tummyTimeSessions, journalNotes, weightEntries, heightEntries, milkPumpingSessions, solidFoodEntries, feedingSessions, activeTimers, tummyTimeTimers, childInviteLinks). Records without a stable ID field include a _key field holding the Map key. The format round-trips all data losslessly.\n" #
    "\n" #
    "## Public methods\n" #
    "\n" #
    "- getApiDoc() : async Text — this document.\n" #
    "- getCallerUserProfile() : async ?UserProfile — the caller's own profile.\n" #
    "- getUserProfile(user : Principal) : async ?UserProfile — own profile, or any profile for admins.\n" #
    "- saveCallerUserProfile(profile : UserProfile) : async () — save the caller's profile.\n" #
    "- generateInviteCode() : async Text — admin only; general app invite code.\n" #
    "- submitRSVP(name, attending, inviteCode) : async () — RSVP with a valid invite code.\n" #
    "- getAllRSVPs() : async [RSVP] — admin only.\n" #
    "- getInviteCodes() : async [InviteCode] — admin only.\n" #
    "- addChild(name, birthDate, photo, isPublic) : async Text — create a child; returns the child ID.\n" #
    "- toggleChildVisibility(childId) : async () — parent only.\n" #
    "- getChild(childId) : async ChildProfileView — public children readable; otherwise requires access.\n" #
    "- getAllPublicChildren() : async [ChildProfileView].\n" #
    "- getChildrenByParent(parent) : async [ChildProfileView] — own children, or any for admins.\n" #
    "- getSharedChildren() : async [ChildProfileView] — children shared with the caller.\n" #
    "- calculateAgeInDays(childId) : async Nat.\n" #
    "- regenerateChildPhoto(childId) : async () — parent only.\n" #
    "- getChildStatistics(childId) : async { totalDiapers; totalBreastfeedingSessions; totalTummyTime }.\n" #
    "- generateChildInviteLink(childId) : async Text — parent only.\n" #
    "- acceptChildInvite(inviteCode) : async () — grants the caller shared access.\n" #
    "- shareChildWithUser(childId, userId) : async () — parent only.\n" #
    "- revokeChildAccess(childId, userId) : async () — parent only.\n" #
    "- getSharedUsers(childId) : async [Principal] — parent only.\n" #
    "- logDiaperChange(childId, kakis, sysius, tuscia) : async ().\n" #
    "- getDiaperLogsForChild(childId) : async [DiaperLog].\n" #
    "- startBreastfeedingSession(childId, side) : async () — starts an active timer.\n" #
    "- pauseBreastfeedingTimer(childId) / resumeBreastfeedingTimer(childId) / completeBreastfeedingSession(childId) : async ().\n" #
    "- getActiveBreastfeedingTimer(childId) : async ?ActiveTimerState.\n" #
    "- getBreastfeedingSessionsForChild(childId) : async [BreastfeedingSession].\n" #
    "- addManualBreastfeedingSession(childId, date, duration, side) : async ().\n" #
    "- startTummyTimeSession(childId) / pauseTummyTimeTimer(childId) / resumeTummyTimeTimer(childId) / completeTummyTimeSession(childId) : async ().\n" #
    "- getActiveTummyTimeTimer(childId) : async ?TummyTimeTimerState.\n" #
    "- getTummyTimeSessionsForChild(childId) : async [TummyTimeSession].\n" #
    "- deleteTummyTimeSession(childId, sessionId) : async ().\n" #
    "- addJournalNote(childId, text, color) / updateJournalNote(childId, noteId, newText, newColor) / deleteJournalNote(childId, noteId) : async ().\n" #
    "- getJournalNotesForChild(childId) : async [JournalNote].\n" #
    "- searchJournalNotes(childId, searchTerm) : async [JournalNote].\n" #
    "- addWeightEntry(childId, weight, timestamp) / updateWeightEntry(childId, weightId, newWeight, newTimestamp) / deleteWeightEntry(childId, weightId) : async ().\n" #
    "- getWeightEntriesForChild(childId) : async [WeightEntry].\n" #
    "- addHeightEntry(childId, heightCm, dateTimestamp) / updateHeightEntry(childId, heightId, newHeight, newTimestamp) / deleteHeightEntry(childId, heightId) : async ().\n" #
    "- getHeightEntriesForChild(childId) : async [HeightEntry].\n" #
    "- addMilkPumpingSession(childId, timestamp, mlAmount, side) / deleteMilkPumpingSession(childId, sessionId) : async ().\n" #
    "- getMilkPumpingSessionsForChild(childId) : async [MilkPumpingSession].\n" #
    "- addFeedingSession(childId, timestamp, mlAmount, feedingType, color) / deleteFeedingSession(childId, sessionId) : async ().\n" #
    "- getFeedingSessionsForChild(childId) : async [FeedingSession].\n" #
    "- addSolidFoodEntry(childId, foodName, category, color, reaction, notes, timestamp) / updateSolidFoodEntry(childId, entryId, newFoodName, newCategory, newColor, newReaction, newNotes) / deleteSolidFoodEntry(childId, entryId) : async ().\n" #
    "- getSolidFoodEntriesForChild(childId) : async [SolidFoodEntry].\n" #
    "- getSolidFoodStatistics(childId) : async { thisWeek; thisMonth; thisYear }.\n" #
    "- getSolidFoodStatisticsByCategory(childId, startDate, endDate) : async { meat; vegetables; fruits; berries; grains; eggs; fish }.\n" #
    "- exportAllData() : async Text — returns the caller's own data as a JSON backup string.\n" #
    "- importAllData(blob : Text) : async ImportResult — restores caller-owned data from a JSON backup.\n" #
    "\n" #
    "## Lifecycle and polling\n" #
    "\n" #
    "Active breastfeeding and tummy-time sessions are tracked as timers (ActiveTimerState / TummyTimeTimerState) keyed by childId # caller.toText(). A session is started with startBreastfeedingSession / startTummyTimeSession, paused/resumed with the corresponding timer methods, and finalized with completeBreastfeedingSession / completeTummyTimeSession, which writes a permanent session record and removes the active timer. Poll getActiveBreastfeedingTimer / getActiveTummyTimeTimer to read the current timer state; a null result means no active timer for that child/caller.\n" #
    "\n" #
    "## Mutation retry safety\n" #
    "\n" #
    "All mutations are idempotent with respect to their stable IDs. Re-sending the same create (e.g. the same childId, weightId, sessionId, entryId, or noteId) overwrites or is skipped rather than duplicating. importAllData is explicitly idempotent: entries whose stable ID already exists are skipped and counted, never duplicated. There is no destructive bulk operation; individual deletes (deleteTummyTimeSession, deleteJournalNote, deleteWeightEntry, deleteHeightEntry, deleteMilkPumpingSession, deleteFeedingSession, deleteSolidFoodEntry) remove only the named record.\n" #
    "\n" #
    "## Errors\n" #
    "\n" #
    "Errors are reported as traps with Lithuanian messages, for example:\n" #
    "- Neautorizuota: reikalinga prisijungti — anonymous caller on a guarded endpoint.\n" #
    "- Neautorizuota: nėra prieigos prie šio vaiko duomenų — caller lacks access to the child.\n" #
    "- Neautorizuota: tik tėvai gali ... — parent-only operation attempted by a non-parent.\n" #
    "- Vaikas nerastas — unknown child ID.\n" #
    "- Neteisingas JSON formatas / Trūksta atsarginės kopijos formato versijos / Nesuderinamas atsarginės kopijos formatas / Neteisinga atsarginės kopijos struktūra — invalid or incompatible backup during import.\n" #
    "- Svorio reikšmė negali būti nulinė arba mažesnė už nulį / Ūgio reikšmė negali būti nulinė arba mažesnė už nulį — non-positive weight/height.\n" #
    "- Trukmė turi būti teigiama — non-positive breastfeeding duration.\n" #
    "- Tekstas yra privalomas — empty required text.\n" #
    "\n" #
    "## Non-obvious gotchas\n" #
    "\n" #
    "- Import is idempotent and skips existing IDs. Re-importing the same backup never creates duplicates; entries whose stable ID already exists are skipped and reported in the skipped counts.\n" #
    "- Export only includes caller-owned data. exportAllData includes children where parent == caller, records whose childId belongs to one of those children, active timers where userId == caller, invite links where createdBy == caller, and the caller's own user profile. Data shared with the caller but owned by someone else is not exported.\n" #
    "- Import only restores caller-owned data. importAllData restores children where parent == caller and records belonging to those children; anything else is skipped and counted.\n" #
    "- Import processes sections incrementally to bound memory. importAllData parses the file once, then decodes and restores each data section one at a time, releasing each decoded section before moving to the next. This keeps the peak heap footprint to the parsed JSON tree plus a single decoded section, rather than holding all 14 decoded arrays simultaneously. The format version is still validated before any write; a malformed later section traps after earlier sections have already been restored.\n" #
    "- Backup format version is checked. Only formatVersion == 1 is accepted; anything else traps with Nesuderinamas atsarginės kopijos formatas.\n" #
    "- Child IDs are derived from name + birthDate. Two children with the same name and birthDate collide; the later addChild overwrites the earlier profile.\n" #
    "- Active timers are per child+caller. Only one active breastfeeding/tummy-time timer exists per childId # caller pair; starting a new one overwrites the previous.\n";
  };
};
