import type { ImportCounts, ImportResult } from "../backend";

// A full backup restored in ONE `importAllData` call parses the whole JSON on
// the canister and hits the IC's 40B-instruction limit per message (IC0522)
// once the journal has a few thousand entries. `importAllData` is idempotent
// (existing IDs are skipped) and scopes ownership by the `children` array in
// the payload, so the frontend can restore the same file as a sequence of
// small payloads: first the children + user profile, then one section at a
// time in batches. Every payload carries every key the backend expects
// (a missing array or a missing `userProfile` key traps on the canister).

export const ARRAY_SECTIONS = [
  "diaperLogs",
  "breastfeedingSessions",
  "tummyTimeSessions",
  "journalNotes",
  "weightEntries",
  "heightEntries",
  "milkPumpingSessions",
  "solidFoodEntries",
  "feedingSessions",
  "activeTimers",
  "tummyTimeTimers",
  "childInviteLinks",
] as const;

type ArraySection = (typeof ARRAY_SECTIONS)[number];

// Which ImportCounts entry a payload section maps to.
const SECTION_COUNT_KEY: Record<ArraySection, keyof ImportCounts> = {
  diaperLogs: "diaperLogs",
  breastfeedingSessions: "breastfeedingSessions",
  tummyTimeSessions: "tummyTimeSessions",
  journalNotes: "journalNotes",
  weightEntries: "weightEntries",
  heightEntries: "heightEntries",
  milkPumpingSessions: "milkPumpingSessions",
  solidFoodEntries: "solidFoodEntries",
  feedingSessions: "feedingSessions",
  activeTimers: "activeTimers",
  tummyTimeTimers: "tummyTimeTimers",
  childInviteLinks: "childInviteLinks",
};

export const DEFAULT_CHUNK_SIZE = 150;

export interface ImportChunk {
  json: string;
  // The count entries this chunk is authoritative for. Children are re-sent
  // with every chunk (the backend derives ownership from them) and come back
  // as "skipped" after the first chunk, so only the first chunk's
  // child/profile counts are kept.
  countKeys: (keyof ImportCounts)[];
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

export function buildImportChunks(
  parsed: Record<string, unknown>,
  chunkSize: number = DEFAULT_CHUNK_SIZE,
): ImportChunk[] {
  const children = asArray(parsed.children);
  const emptySections = Object.fromEntries(
    ARRAY_SECTIONS.map((section) => [section, [] as unknown[]]),
  ) as Record<ArraySection, unknown[]>;
  const base = {
    formatVersion: parsed.formatVersion,
    exportedAt: parsed.exportedAt,
    children,
    ...emptySections,
    userProfile: null as unknown,
  };

  const chunks: ImportChunk[] = [
    {
      json: JSON.stringify({
        ...base,
        userProfile: parsed.userProfile ?? null,
      }),
      countKeys: ["childProfiles", "userProfiles"],
    },
  ];

  for (const section of ARRAY_SECTIONS) {
    const entries = asArray(parsed[section]);
    for (let start = 0; start < entries.length; start += chunkSize) {
      chunks.push({
        json: JSON.stringify({
          ...base,
          [section]: entries.slice(start, start + chunkSize),
        }),
        countKeys: [SECTION_COUNT_KEY[section]],
      });
    }
  }

  return chunks;
}

function emptyCounts(): ImportCounts {
  return {
    childProfiles: { restored: 0n, skipped: 0n },
    diaperLogs: { restored: 0n, skipped: 0n },
    breastfeedingSessions: { restored: 0n, skipped: 0n },
    tummyTimeSessions: { restored: 0n, skipped: 0n },
    journalNotes: { restored: 0n, skipped: 0n },
    weightEntries: { restored: 0n, skipped: 0n },
    heightEntries: { restored: 0n, skipped: 0n },
    milkPumpingSessions: { restored: 0n, skipped: 0n },
    solidFoodEntries: { restored: 0n, skipped: 0n },
    feedingSessions: { restored: 0n, skipped: 0n },
    activeTimers: { restored: 0n, skipped: 0n },
    tummyTimeTimers: { restored: 0n, skipped: 0n },
    childInviteLinks: { restored: 0n, skipped: 0n },
    userProfiles: { restored: 0n, skipped: 0n },
  };
}

export function mergeImportResults(
  results: { chunk: ImportChunk; result: ImportResult }[],
): ImportResult {
  const counts = emptyCounts();
  let success = results.length > 0;
  for (const { chunk, result } of results) {
    if (!result.success) success = false;
    for (const key of chunk.countKeys) {
      const entry = result.counts[key];
      if (!entry) continue;
      counts[key] = {
        restored: counts[key].restored + entry.restored,
        skipped: counts[key].skipped + entry.skipped,
      };
    }
  }
  let totalRestored = 0n;
  let totalSkipped = 0n;
  for (const entry of Object.values(counts)) {
    totalRestored += entry.restored;
    totalSkipped += entry.skipped;
  }
  return { success, totalRestored, totalSkipped, counts };
}
