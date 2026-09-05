// Local type definitions for types not exported by backend
export interface DiaperLog {
  childId: string;
  timestamp: bigint;
  contents: {
    kakis: boolean;
    sysius: boolean;
    tuscia: boolean;
  };
}

export interface BreastfeedingSession {
  childId: string;
  startTime: bigint;
  duration: bigint;
  side: {
    left?: null;
    right?: null;
  };
}

export interface TummyTimeSession {
  sessionId?: string;
  childId: string;
  startTime: bigint;
  duration: bigint;
}

export enum SolidFoodCategory {
  grains = "grains",
  berries = "berries",
  eggs = "eggs",
  meat = "meat",
  fruits = "fruits",
  vegetables = "vegetables",
  fish = "fish",
}

export enum SolidFoodReaction {
  unclear = "unclear",
  liked = "liked",
  disliked = "disliked",
}

export interface SolidFoodEntry {
  entryId: string;
  childId: string;
  timestamp: bigint;
  foodName: string;
  category: SolidFoodCategory;
  color: string;
  reaction: SolidFoodReaction;
  notes?: string;
}

export interface SolidFoodStatistics {
  today: bigint;
  thisWeek: bigint;
  thisMonth: bigint;
  thisYear: bigint;
}

export interface SolidFoodStatisticsByCategory {
  grains: bigint;
  berries: bigint;
  eggs: bigint;
  meat: bigint;
  fruits: bigint;
  vegetables: bigint;
  fish: bigint;
}
