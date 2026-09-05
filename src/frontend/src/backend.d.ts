import type { Principal } from "@icp-sdk/core/principal";
export interface Some<T> {
    __kind__: "Some";
    value: T;
}
export interface None {
    __kind__: "None";
}
export type Option<T> = Some<T> | None;
import type { ExternalBlob } from "@caffeineai/object-storage";
export type { ExternalBlob } from "@caffeineai/object-storage";
export interface SolidFoodEntry {
    color: string;
    childId: string;
    entryId: string;
    notes?: string;
    timestamp: bigint;
    category: Variant_grains_berries_eggs_fish_meat_fruits_vegetables;
    reaction: Variant_unclear_liked_disliked;
    foodName: string;
}
export interface HeightEntry {
    height: number;
    heightId: string;
    childId: string;
    timestamp: bigint;
}
export interface FeedingSession {
    color: string;
    feedingType: Variant_misinukas_mamosPienas;
    childId: string;
    timestamp: bigint;
    sessionId: string;
    mlAmount: number;
}
export type Time = bigint;
export interface TummyTimeSession {
    startTime: bigint;
    duration: bigint;
    childId: string;
    sessionId: string;
}
export interface TummyTimeTimerState {
    startTime: bigint;
    pausedAt?: bigint;
    userId: Principal;
    isPaused: boolean;
    totalPausedDuration: bigint;
    childId: string;
}
export interface DiaperLog {
    contents: {
        tuscia: boolean;
        kakis: boolean;
        sysius: boolean;
    };
    childId: string;
    timestamp: bigint;
}
export interface ChildProfileView {
    id: string;
    birthDate: bigint;
    name: string;
    sharedWith: Array<Principal>;
    isPublic: boolean;
    photo?: ExternalBlob;
    parent: Principal;
}
export interface JournalNote {
    createdAt: bigint;
    color: NoteColor;
    text: string;
    childId: string;
    updatedAt: bigint;
}
export interface InviteCode {
    created: Time;
    code: string;
    used: boolean;
}
export interface RSVP {
    name: string;
    inviteCode: string;
    timestamp: Time;
    attending: boolean;
}
export interface BreastfeedingSession {
    startTime: bigint;
    duration: bigint;
    side: Variant_left_right;
    childId: string;
}
export interface ActiveTimerState {
    startTime: bigint;
    pausedAt?: bigint;
    userId: Principal;
    isPaused: boolean;
    side: Variant_left_right;
    totalPausedDuration: bigint;
    childId: string;
}
export interface Result {
    hasMore: boolean;
    rows: Array<Array<Cell>>;
}
export interface Cell {
    value: Value;
    name: string;
}
export type Value = {
    __kind__: "int";
    int: bigint;
} | {
    __kind__: "nat";
    nat: bigint;
} | {
    __kind__: "float";
    float: number;
} | {
    __kind__: "bool";
    bool: boolean;
} | {
    __kind__: "null";
    null: null;
} | {
    __kind__: "text";
    text: string;
};
export interface WeightEntry {
    weight: number;
    childId: string;
    weightId: string;
    timestamp: bigint;
}
export interface UserProfile {
    name: string;
}
export interface MilkPumpingSession {
    side: Variant_both_left_right;
    childId: string;
    timestamp: bigint;
    sessionId: string;
    mlAmount: number;
}
export enum NoteColor {
    blue = "blue",
    pink = "pink",
    purple = "purple",
    green = "green",
    yellow = "yellow"
}
export enum UserRole {
    admin = "admin",
    user = "user",
    guest = "guest"
}
export enum Variant_both_left_right {
    both = "both",
    left = "left",
    right = "right"
}
export enum Variant_grains_berries_eggs_fish_meat_fruits_vegetables {
    grains = "grains",
    berries = "berries",
    eggs = "eggs",
    fish = "fish",
    meat = "meat",
    fruits = "fruits",
    vegetables = "vegetables"
}
export enum Variant_left_right {
    left = "left",
    right = "right"
}
export enum Variant_misinukas_mamosPienas {
    misinukas = "misinukas",
    mamosPienas = "mamosPienas"
}
export enum Variant_unclear_liked_disliked {
    unclear = "unclear",
    liked = "liked",
    disliked = "disliked"
}
export interface backendInterface {
    acceptChildInvite(inviteCode: string): Promise<void>;
    addChild(name: string, birthDate: bigint, photo: ExternalBlob | null, isPublic: boolean): Promise<string>;
    addFeedingSession(childId: string, timestamp: bigint, mlAmount: number, feedingType: Variant_misinukas_mamosPienas, color: string): Promise<void>;
    addHeightEntry(childId: string, heightCm: number, dateTimestamp: bigint): Promise<void>;
    addJournalNote(childId: string, text: string, color: NoteColor): Promise<void>;
    addManualBreastfeedingSession(childId: string, date: bigint, duration: bigint, side: Variant_left_right): Promise<void>;
    addMilkPumpingSession(childId: string, timestamp: bigint, mlAmount: number, side: Variant_both_left_right): Promise<void>;
    addSolidFoodEntry(childId: string, foodName: string, category: Variant_grains_berries_eggs_fish_meat_fruits_vegetables, color: string, reaction: Variant_unclear_liked_disliked, notes: string | null, timestamp: bigint): Promise<void>;
    addWeightEntry(childId: string, weight: number, timestamp: bigint): Promise<void>;
    assignCallerUserRole(user: Principal, role: UserRole): Promise<void>;
    calculateAgeInDays(childId: string): Promise<bigint>;
    completeBreastfeedingSession(childId: string): Promise<void>;
    completeTummyTimeSession(childId: string): Promise<void>;
    deleteFeedingSession(childId: string, sessionId: string): Promise<void>;
    deleteHeightEntry(childId: string, heightId: string): Promise<void>;
    deleteJournalNote(childId: string, noteId: string): Promise<void>;
    deleteMilkPumpingSession(childId: string, sessionId: string): Promise<void>;
    deleteSolidFoodEntry(childId: string, entryId: string): Promise<void>;
    deleteTummyTimeSession(childId: string, sessionId: string): Promise<void>;
    deleteWeightEntry(childId: string, weightId: string): Promise<void>;
    execute(qJson: string): Promise<Result>;
    generateChildInviteLink(childId: string): Promise<string>;
    generateInviteCode(): Promise<string>;
    getActiveBreastfeedingTimer(childId: string): Promise<ActiveTimerState | null>;
    getActiveTummyTimeTimer(childId: string): Promise<TummyTimeTimerState | null>;
    getAllPublicChildren(): Promise<Array<ChildProfileView>>;
    getAllRSVPs(): Promise<Array<RSVP>>;
    getBreastfeedingSessionsForChild(childId: string): Promise<Array<BreastfeedingSession>>;
    getCallerUserProfile(): Promise<UserProfile | null>;
    getCallerUserRole(): Promise<UserRole>;
    getChild(childId: string): Promise<ChildProfileView>;
    getChildStatistics(childId: string): Promise<{
        totalDiapers: bigint;
        totalBreastfeedingSessions: bigint;
        totalTummyTime: bigint;
    }>;
    getChildrenByParent(parent: Principal): Promise<Array<ChildProfileView>>;
    getDiaperLogsForChild(childId: string): Promise<Array<DiaperLog>>;
    getFeedingSessionsForChild(childId: string): Promise<Array<FeedingSession>>;
    getHeightEntriesForChild(childId: string): Promise<Array<HeightEntry>>;
    getInviteCodes(): Promise<Array<InviteCode>>;
    getJournalNotesForChild(childId: string): Promise<Array<JournalNote>>;
    getMilkPumpingSessionsForChild(childId: string): Promise<Array<MilkPumpingSession>>;
    getSharedChildren(): Promise<Array<ChildProfileView>>;
    getSharedUsers(childId: string): Promise<Array<Principal>>;
    getSolidFoodEntriesForChild(childId: string): Promise<Array<SolidFoodEntry>>;
    getSolidFoodStatistics(childId: string): Promise<{
        thisWeek: bigint;
        thisYear: bigint;
        thisMonth: bigint;
    }>;
    getSolidFoodStatisticsByCategory(childId: string, startDate: bigint, endDate: bigint): Promise<{
        grains: bigint;
        berries: bigint;
        eggs: bigint;
        fish: bigint;
        meat: bigint;
        fruits: bigint;
        vegetables: bigint;
    }>;
    getTummyTimeSessionsForChild(childId: string): Promise<Array<TummyTimeSession>>;
    getUserProfile(user: Principal): Promise<UserProfile | null>;
    getWeightEntriesForChild(childId: string): Promise<Array<WeightEntry>>;
    isCallerAdmin(): Promise<boolean>;
    logDiaperChange(childId: string, kakis: boolean, sysius: boolean, tuscia: boolean): Promise<void>;
    pauseBreastfeedingTimer(childId: string): Promise<void>;
    pauseTummyTimeTimer(childId: string): Promise<void>;
    regenerateChildPhoto(childId: string): Promise<void>;
    resumeBreastfeedingTimer(childId: string): Promise<void>;
    resumeTummyTimeTimer(childId: string): Promise<void>;
    revokeChildAccess(childId: string, userId: Principal): Promise<void>;
    saveCallerUserProfile(profile: UserProfile): Promise<void>;
    schema(): Promise<string>;
    searchJournalNotes(childId: string, searchTerm: string): Promise<Array<JournalNote>>;
    shareChildWithUser(childId: string, userId: Principal): Promise<void>;
    startBreastfeedingSession(childId: string, side: Variant_left_right): Promise<void>;
    startTummyTimeSession(childId: string): Promise<void>;
    submitRSVP(name: string, attending: boolean, inviteCode: string): Promise<void>;
    toggleChildVisibility(childId: string): Promise<void>;
    updateHeightEntry(childId: string, heightId: string, newHeight: number, newTimestamp: bigint): Promise<void>;
    updateJournalNote(childId: string, noteId: string, newText: string, newColor: NoteColor | null): Promise<void>;
    updateSolidFoodEntry(childId: string, entryId: string, newFoodName: string, newCategory: Variant_grains_berries_eggs_fish_meat_fruits_vegetables, newColor: string, newReaction: Variant_unclear_liked_disliked, newNotes: string | null): Promise<void>;
    updateWeightEntry(childId: string, weightId: string, newWeight: number, newTimestamp: bigint): Promise<void>;
}
