import { useActor, useInternetIdentity } from "@caffeineai/core-infrastructure";
import type { Principal } from "@icp-sdk/core/principal";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { type ExternalBlob, createActor } from "../backend";
import type { ImportResult } from "../backend";
import type {
  SolidFoodCategory,
  SolidFoodEntry,
  SolidFoodReaction,
  SolidFoodStatistics,
  SolidFoodStatisticsByCategory,
} from "../types";

// ─── Type definitions (backend types defined locally since stub is minimal) ───

export interface UserProfile {
  name: string;
  [key: string]: unknown;
}

export interface ChildProfileView {
  id: string;
  name: string;
  birthDate: bigint;
  parent: Principal;
  isPublic: boolean;
  sharedWith: Principal[];
  photo?: ExternalBlob | null;
  [key: string]: unknown;
}

export interface DiaperLog {
  logId?: string;
  childId: string;
  timestamp: bigint;
  contents: { kakis: boolean; sysius: boolean; tuscia: boolean };
  [key: string]: unknown;
}

export interface BreastfeedingSession {
  sessionId?: string;
  childId: string;
  startTime: bigint;
  duration: bigint;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  side: any;
  [key: string]: unknown;
}

export interface TummyTimeSession {
  sessionId?: string;
  childId: string;
  startTime: bigint;
  duration: bigint;
  [key: string]: unknown;
}

export interface WeightEntry {
  weightId: string;
  childId: string;
  timestamp: bigint;
  weight: number;
}

export interface HeightEntry {
  heightId: string;
  childId: string;
  timestamp: bigint;
  height: number;
}

export enum NoteColor {
  yellow = "yellow",
  green = "green",
  blue = "blue",
  pink = "pink",
  purple = "purple",
}

export interface JournalNote {
  noteId?: string;
  childId: string;
  createdAt: bigint;
  timestamp?: bigint;
  text: string;
  color: NoteColor;
  [key: string]: unknown;
}

export interface MilkPumpingSession {
  sessionId?: string;
  childId: string;
  timestamp: bigint;
  mlAmount: number;
  side: { left?: null; right?: null; both?: null };
  [key: string]: unknown;
}

export enum Variant_left_right {
  left = "left",
  right = "right",
}

// Helper to get typed actor
function useTypedActor() {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const result = useActor(createActor as any);
  return {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    actor: result.actor as any,
    isFetching: result.isFetching,
  };
}

// User Profile Queries
export function useGetCallerUserProfile() {
  const { actor, isFetching: actorFetching } = useTypedActor();

  const query = useQuery<UserProfile | null>({
    queryKey: ["currentUserProfile"],
    queryFn: async () => {
      if (!actor) throw new Error("Actor not available");
      return actor.getCallerUserProfile();
    },
    enabled: !!actor && !actorFetching,
    retry: false,
  });

  return {
    ...query,
    isLoading: actorFetching || query.isLoading,
    isFetched: !!actor && query.isFetched,
  };
}

export function useSaveCallerUserProfile() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (profile: UserProfile) => {
      if (!actor) throw new Error("Actor not available");
      return actor.saveCallerUserProfile(profile);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["currentUserProfile"] });
    },
  });
}

// Child Management Queries
export function useGetAllChildrenForUser() {
  const { actor, isFetching } = useTypedActor();
  const { identity, isInitializing } = useInternetIdentity();

  return useQuery<ChildProfileView[]>({
    queryKey: ["children", identity?.getPrincipal().toString()],
    queryFn: async () => {
      if (!actor || !identity) {
        console.log("Child query: actor or identity not ready");
        return [];
      }

      try {
        const principal = identity.getPrincipal();
        console.log("Fetching children for principal:", principal.toString());

        const ownedChildren = await actor.getChildrenByParent(principal);
        console.log("Owned children:", ownedChildren.length);

        const sharedChildren = await actor.getSharedChildren();
        console.log("Shared children:", sharedChildren.length);

        const allAccessibleChildren = [...ownedChildren, ...sharedChildren];
        console.log("Total accessible children:", allAccessibleChildren.length);

        return allAccessibleChildren;
      } catch (error) {
        console.error("Error fetching children:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!identity && !isInitializing,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchInterval: 30000,
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 10000),
  });
}

export function useGetChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<ChildProfileView | null>({
    queryKey: ["child", childId],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getChild(childId);
      } catch (error) {
        console.error("Error fetching child:", error);
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 30000,
  });
}

export function useAddChild() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      name,
      birthDate,
      photo,
      isPublic,
    }: {
      name: string;
      birthDate: bigint;
      photo: ExternalBlob | null;
      isPublic: boolean;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.addChild(name, birthDate, photo, isPublic);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["children"] });
    },
  });
}

export function useToggleChildVisibility() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.toggleChildVisibility(childId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["children"] });
      queryClient.invalidateQueries({ queryKey: ["child"] });
    },
  });
}

// Shared Access Queries
export function useGenerateChildInviteLink() {
  const { actor } = useTypedActor();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.generateChildInviteLink(childId);
    },
  });
}

export function useAcceptChildInvite() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();
  const { identity } = useInternetIdentity();

  return useMutation({
    mutationFn: async (inviteCode: string) => {
      if (!actor) throw new Error("Aktorius nepasiekiamas");
      if (!identity)
        throw new Error("Turite būti prisijungę, kad priimtumėte kvietimą");

      return actor.acceptChildInvite(inviteCode);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["children"] });
      queryClient.invalidateQueries({ queryKey: ["child"] });
    },
  });
}

// Diaper Tracking Queries
export function useGetDiaperLogsForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<DiaperLog[]>({
    queryKey: ["diaperLogs", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getDiaperLogsForChild(childId);
      } catch (error) {
        console.error("Error fetching diaper logs:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useLogDiaperChange() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      kakis,
      sysius,
      tuscia,
    }: {
      childId: string;
      kakis: boolean;
      sysius: boolean;
      tuscia: boolean;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.logDiaperChange(childId, kakis, sysius, tuscia);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["diaperLogs", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["childStatistics", variables.childId],
      });
    },
  });
}

// Breastfeeding Queries
export function useGetBreastfeedingSessionsForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<BreastfeedingSession[]>({
    queryKey: ["breastfeedingSessions", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getBreastfeedingSessionsForChild(childId);
      } catch (error) {
        console.error("Error fetching breastfeeding sessions:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useStartBreastfeedingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      side,
    }: {
      childId: string;
      side: "left" | "right";
    }) => {
      if (!actor) throw new Error("Actor not available");
      const breastSide: Variant_left_right =
        side === "left" ? Variant_left_right.left : Variant_left_right.right;
      return actor.startBreastfeedingSession(childId, breastSide);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["activeBreastfeedingTimer", variables.childId],
      });
    },
  });
}

export function usePauseBreastfeedingTimer() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.pauseBreastfeedingTimer(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["activeBreastfeedingTimer", childId],
      });
    },
  });
}

export function useResumeBreastfeedingTimer() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.resumeBreastfeedingTimer(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["activeBreastfeedingTimer", childId],
      });
    },
  });
}

export function useCompleteBreastfeedingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.completeBreastfeedingSession(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["breastfeedingSessions", childId],
      });
      queryClient.invalidateQueries({ queryKey: ["childStatistics", childId] });
      queryClient.invalidateQueries({
        queryKey: ["activeBreastfeedingTimer", childId],
      });
    },
  });
}

export function useGetActiveBreastfeedingTimer(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery({
    queryKey: ["activeBreastfeedingTimer", childId],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getActiveBreastfeedingTimer(childId);
      } catch (error) {
        console.error("Error fetching active timer:", error);
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 1000,
  });
}

export function useAddManualBreastfeedingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      date,
      duration,
      side,
    }: {
      childId: string;
      date: bigint;
      duration: bigint;
      side: "left" | "right";
    }) => {
      if (!actor) throw new Error("Actor not available");
      const breastSide: Variant_left_right =
        side === "left" ? Variant_left_right.left : Variant_left_right.right;
      return actor.addManualBreastfeedingSession(
        childId,
        date,
        duration,
        breastSide,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["breastfeedingSessions", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["childStatistics", variables.childId],
      });
    },
  });
}

// Tummy Time Queries
export function useGetTummyTimeSessionsForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<TummyTimeSession[]>({
    queryKey: ["tummyTimeSessions", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getTummyTimeSessionsForChild(childId);
      } catch (error) {
        console.error("Error fetching tummy time sessions:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useStartTummyTimeSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.startTummyTimeSession(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["activeTummyTimeTimer", childId],
      });
    },
  });
}

export function usePauseTummyTimeTimer() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.pauseTummyTimeTimer(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["activeTummyTimeTimer", childId],
      });
    },
  });
}

export function useResumeTummyTimeTimer() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.resumeTummyTimeTimer(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["activeTummyTimeTimer", childId],
      });
    },
  });
}

export function useCompleteTummyTimeSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (childId: string) => {
      if (!actor) throw new Error("Actor not available");
      return actor.completeTummyTimeSession(childId);
    },
    onSuccess: (_, childId) => {
      queryClient.invalidateQueries({
        queryKey: ["tummyTimeSessions", childId],
      });
      queryClient.invalidateQueries({ queryKey: ["childStatistics", childId] });
      queryClient.invalidateQueries({
        queryKey: ["activeTummyTimeTimer", childId],
      });
    },
  });
}

export function useGetActiveTummyTimeTimer(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery({
    queryKey: ["activeTummyTimeTimer", childId],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getActiveTummyTimeTimer(childId);
      } catch (error) {
        console.error("Error fetching active tummy time timer:", error);
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 1000,
  });
}

export function useDeleteTummyTimeSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      sessionId,
    }: {
      childId: string;
      sessionId: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteTummyTimeSession(childId, sessionId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["tummyTimeSessions", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["childStatistics", variables.childId],
      });
    },
  });
}

// Weight Tracking Queries
export function useGetWeightEntriesForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<WeightEntry[]>({
    queryKey: ["weightEntries", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getWeightEntriesForChild(childId);
      } catch (error) {
        console.error("Error fetching weight entries:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useAddWeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      weight,
      timestamp,
    }: {
      childId: string;
      weight: number;
      timestamp: bigint;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.addWeightEntry(childId, weight, timestamp);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["weightEntries", variables.childId],
      });
    },
  });
}

export function useUpdateWeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      weightId,
      newWeight,
      newTimestamp,
    }: {
      childId: string;
      weightId: string;
      newWeight: number;
      newTimestamp: bigint;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.updateWeightEntry(
        childId,
        weightId,
        newWeight,
        newTimestamp,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["weightEntries", variables.childId],
      });
    },
  });
}

export function useDeleteWeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      weightId,
    }: {
      childId: string;
      weightId: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteWeightEntry(childId, weightId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["weightEntries", variables.childId],
      });
    },
  });
}

// Journal Notes Queries
export function useGetJournalNotesForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<JournalNote[]>({
    queryKey: ["journalNotes", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getJournalNotesForChild(childId);
      } catch (error) {
        console.error("Error fetching journal notes:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useAddJournalNote() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      text,
      color,
    }: {
      childId: string;
      text: string;
      color: NoteColor;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.addJournalNote(childId, text, color);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["journalNotes", variables.childId],
      });
    },
  });
}

export function useDeleteJournalNote() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      noteId,
    }: {
      childId: string;
      noteId: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteJournalNote(childId, noteId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["journalNotes", variables.childId],
      });
    },
  });
}

// Statistics
export function useGetChildStatistics(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<{
    totalDiapers: bigint;
    totalBreastfeedingSessions: bigint;
    totalTummyTime: bigint;
  } | null>({
    queryKey: ["childStatistics", childId],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getChildStatistics(childId);
      } catch (error) {
        console.error("Error fetching statistics:", error);
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 30000,
  });
}

// Milk Pumping
export function useGetMilkPumpingSessionsForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery({
    queryKey: ["milkPumpingSessions", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getMilkPumpingSessionsForChild(childId);
      } catch (error) {
        console.error("Error fetching milk pumping sessions:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useAddMilkPumpingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      timestamp,
      mlAmount,
      side,
    }: {
      childId: string;
      timestamp: bigint;
      mlAmount: number;
      side: "left" | "right" | "both";
    }) => {
      if (!actor) throw new Error("Actor not available");
      const sideVariant =
        side === "left"
          ? { left: null }
          : side === "right"
            ? { right: null }
            : { both: null };
      return actor.addMilkPumpingSession(
        childId,
        timestamp,
        mlAmount,
        sideVariant,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["milkPumpingSessions", variables.childId],
      });
    },
  });
}

export function useDeleteMilkPumpingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      sessionId,
    }: { childId: string; sessionId: string }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteMilkPumpingSession(childId, sessionId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["milkPumpingSessions", variables.childId],
      });
    },
  });
}

// Solid Food (Primaitinimas) Queries
export function useGetSolidFoodEntriesForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<SolidFoodEntry[]>({
    queryKey: ["solidFoodEntries", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        return await actor.getSolidFoodEntriesForChild(childId);
      } catch (error) {
        console.error("Error fetching solid food entries:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useAddSolidFoodEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      foodName,
      category,
      color,
      reaction,
      notes,
      timestamp,
    }: {
      childId: string;
      foodName: string;
      category: SolidFoodCategory;
      color: string;
      reaction: SolidFoodReaction;
      notes: string | null;
      timestamp: bigint;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.addSolidFoodEntry(
        childId,
        foodName,
        category,
        color,
        reaction,
        notes,
        timestamp,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["solidFoodEntries", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatistics", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatisticsByCategory", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["childStatistics", variables.childId],
      });
    },
  });
}

export function useUpdateSolidFoodEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      entryId,
      newFoodName,
      newCategory,
      newColor,
      newReaction,
      newNotes,
    }: {
      childId: string;
      entryId: string;
      newFoodName: string;
      newCategory: SolidFoodCategory;
      newColor: string;
      newReaction: SolidFoodReaction;
      newNotes: string | null;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.updateSolidFoodEntry(
        childId,
        entryId,
        newFoodName,
        newCategory,
        newColor,
        newReaction,
        newNotes,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["solidFoodEntries", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatistics", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatisticsByCategory", variables.childId],
      });
    },
  });
}

export function useDeleteSolidFoodEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      entryId,
    }: {
      childId: string;
      entryId: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteSolidFoodEntry(childId, entryId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["solidFoodEntries", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatistics", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["solidFoodStatisticsByCategory", variables.childId],
      });
      queryClient.invalidateQueries({
        queryKey: ["childStatistics", variables.childId],
      });
    },
  });
}

export function useGetSolidFoodStatistics(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<SolidFoodStatistics | null>({
    queryKey: ["solidFoodStatistics", childId],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getSolidFoodStatistics(childId);
      } catch (error) {
        console.error("Error fetching solid food statistics:", error);
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 30000,
  });
}

export function useGetSolidFoodStatisticsByCategory(
  childId: string | null,
  startDate: bigint,
  endDate: bigint,
) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<SolidFoodStatisticsByCategory | null>({
    queryKey: ["solidFoodStatisticsByCategory", childId, startDate, endDate],
    queryFn: async () => {
      if (!actor || !childId) return null;
      try {
        return await actor.getSolidFoodStatisticsByCategory(
          childId,
          startDate,
          endDate,
        );
      } catch (error) {
        console.error(
          "Error fetching solid food statistics by category:",
          error,
        );
        return null;
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 30000,
  });
}

// Feeding Queries
export function useGetFeedingSessionsForChild(childId: string | null) {
  const { actor } = useTypedActor();
  return useQuery({
    queryKey: ["feedingSessions", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      return await actor.getFeedingSessionsForChild(childId);
    },
    enabled: !!actor && !!childId,
  });
}

export function useAddFeedingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      timestamp,
      mlAmount,
      feedingType,
      color,
    }: {
      childId: string;
      timestamp: bigint;
      mlAmount: number;
      feedingType: "misinukas" | "mamosPienas";
      color: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      const typeVariant =
        feedingType === "misinukas"
          ? { misinukas: null }
          : { mamosPienas: null };
      return actor.addFeedingSession(
        childId,
        timestamp,
        mlAmount,
        typeVariant as any,
        color,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["feedingSessions", variables.childId],
      });
    },
  });
}

export function useDeleteFeedingSession() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      sessionId,
    }: { childId: string; sessionId: string }) => {
      if (!actor) throw new Error("Actor not available");
      return actor.deleteFeedingSession(childId, sessionId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["feedingSessions", variables.childId],
      });
    },
  });
}

// Height Tracking Queries
export function useGetHeightEntriesForChild(childId: string | null) {
  const { actor, isFetching } = useTypedActor();

  return useQuery<HeightEntry[]>({
    queryKey: ["heightEntries", childId],
    queryFn: async () => {
      if (!actor || !childId) return [];
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return await (actor as any).getHeightEntriesForChild(childId);
      } catch (error) {
        console.error("Error fetching height entries:", error);
        return [];
      }
    },
    enabled: !!actor && !isFetching && !!childId,
    refetchInterval: 10000,
  });
}

export function useAddHeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      height,
      timestamp,
    }: {
      childId: string;
      height: number;
      timestamp: bigint;
    }) => {
      if (!actor) throw new Error("Actor not available");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return (actor as any).addHeightEntry(childId, height, timestamp);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["heightEntries", variables.childId],
      });
    },
  });
}

export function useUpdateHeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      heightId,
      newHeight,
      newTimestamp,
    }: {
      childId: string;
      heightId: string;
      newHeight: number;
      newTimestamp: bigint;
    }) => {
      if (!actor) throw new Error("Actor not available");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return (actor as any).updateHeightEntry(
        childId,
        heightId,
        newHeight,
        newTimestamp,
      );
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["heightEntries", variables.childId],
      });
    },
  });
}

export function useDeleteHeightEntry() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({
      childId,
      heightId,
    }: {
      childId: string;
      heightId: string;
    }) => {
      if (!actor) throw new Error("Actor not available");
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return (actor as any).deleteHeightEntry(childId, heightId);
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({
        queryKey: ["heightEntries", variables.childId],
      });
    },
  });
}

// Backup / Restore Queries
export function useExportAllData() {
  const { actor } = useTypedActor();

  return useMutation({
    mutationFn: async () => {
      if (!actor) throw new Error("Aktorius nepasiekiamas");
      return actor.exportAllData();
    },
  });
}

export function useImportAllData() {
  const { actor } = useTypedActor();
  const queryClient = useQueryClient();

  return useMutation<ImportResult, Error, string>({
    mutationFn: async (blob: string) => {
      if (!actor) throw new Error("Aktorius nepasiekiamas");
      return actor.importAllData(blob);
    },
    onSuccess: () => {
      // Invalidate all data queries so the UI reflects restored data
      queryClient.invalidateQueries();
    },
  });
}
