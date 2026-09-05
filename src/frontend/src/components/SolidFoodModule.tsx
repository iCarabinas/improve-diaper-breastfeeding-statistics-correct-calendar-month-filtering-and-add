import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Apple,
  Beef,
  Carrot,
  Cherry,
  ChevronLeft,
  ChevronRight,
  Egg,
  Fish,
  Loader2,
  Maximize2,
  Plus,
  ThumbsDown,
  ThumbsUp,
  Trash2,
  Wheat,
  X,
} from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import type React from "react";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import {
  useAddSolidFoodEntry,
  useDeleteSolidFoodEntry,
  useGetSolidFoodEntriesForChild,
  useGetSolidFoodStatistics,
  useGetSolidFoodStatisticsByCategory,
  useUpdateSolidFoodEntry,
} from "../hooks/useQueries";
import type { SolidFoodCategory, SolidFoodReaction } from "../types";
import { getCurrentMonthEnd, getCurrentMonthStart } from "../utils/dateRanges";

interface SolidFoodModuleProps {
  childId: string | null;
}

// ─── Types ───

export type FoodCategory =
  | "meat"
  | "vegetables"
  | "fruits"
  | "berries"
  | "grains"
  | "eggs"
  | "fish";

export type FoodColor =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "teal"
  | "blue"
  | "purple"
  | "pink";

export type Reaction = "liked" | "disliked" | "unsure";

// ─── Enum values (mirrors types/index.ts) ───

const SolidFoodCategoryEnum = {
  grains: "grains" as SolidFoodCategory,
  berries: "berries" as SolidFoodCategory,
  eggs: "eggs" as SolidFoodCategory,
  meat: "meat" as SolidFoodCategory,
  fruits: "fruits" as SolidFoodCategory,
  vegetables: "vegetables" as SolidFoodCategory,
  fish: "fish" as SolidFoodCategory,
};

const SolidFoodReactionEnum = {
  unclear: "unclear" as SolidFoodReaction,
  liked: "liked" as SolidFoodReaction,
  disliked: "disliked" as SolidFoodReaction,
};

// ─── Constants ───

const CATEGORY_CONFIG: Record<
  FoodCategory,
  { label: string; Icon: React.ElementType; color?: string }
> = {
  meat: { label: "Mėsa", Icon: Beef },
  vegetables: { label: "Daržovės", Icon: Carrot },
  fruits: { label: "Vaisiai", Icon: Apple },
  berries: { label: "Uogos", Icon: Cherry },
  grains: { label: "Grūdai", Icon: Wheat },
  eggs: { label: "Kiaušiniai", Icon: Egg },
  fish: { label: "Žuvis", Icon: Fish, color: "text-sky-400" },
};

const COLOR_CONFIG: Record<
  FoodColor,
  { bg: string; border: string; text: string; dot: string; dotHex: string }
> = {
  red: {
    bg: "bg-red-500/10",
    border: "border-red-500/30",
    text: "text-red-400",
    dot: "bg-red-500",
    dotHex: "#ef4444",
  },
  orange: {
    bg: "bg-orange-500/10",
    border: "border-orange-500/30",
    text: "text-orange-400",
    dot: "bg-orange-500",
    dotHex: "#f97316",
  },
  yellow: {
    bg: "bg-yellow-500/10",
    border: "border-yellow-500/30",
    text: "text-yellow-400",
    dot: "bg-yellow-500",
    dotHex: "#eab308",
  },
  green: {
    bg: "bg-green-500/10",
    border: "border-green-500/30",
    text: "text-green-400",
    dot: "bg-green-500",
    dotHex: "#22c55e",
  },
  teal: {
    bg: "bg-teal-500/10",
    border: "border-teal-500/30",
    text: "text-teal-400",
    dot: "bg-teal-500",
    dotHex: "#14b8a6",
  },
  blue: {
    bg: "bg-blue-500/10",
    border: "border-blue-500/30",
    text: "text-blue-400",
    dot: "bg-blue-500",
    dotHex: "#3b82f6",
  },
  purple: {
    bg: "bg-purple-500/10",
    border: "border-purple-500/30",
    text: "text-purple-400",
    dot: "bg-purple-500",
    dotHex: "#a855f7",
  },
  pink: {
    bg: "bg-pink-500/10",
    border: "border-pink-500/30",
    text: "text-pink-400",
    dot: "bg-pink-500",
    dotHex: "#ec4899",
  },
};

const REACTION_CONFIG: Record<
  Reaction,
  { label: string; Icon: React.ElementType; color: string }
> = {
  liked: { label: "Patiko", Icon: ThumbsUp, color: "text-green-400" },
  disliked: { label: "Nepatiko", Icon: ThumbsDown, color: "text-red-400" },
  unsure: { label: "Neaišku", Icon: X, color: "text-yellow-400" },
};

const ALL_COLORS: FoodColor[] = [
  "red",
  "orange",
  "yellow",
  "green",
  "teal",
  "blue",
  "purple",
  "pink",
];

// ─── Helpers ───

function fromNsToMs(ns: bigint): number {
  return Number(ns / 1_000_000n);
}

function formatLithuanianDateTime(tsMs: number): string {
  return new Date(tsMs).toLocaleString("lt-LT", {
    timeZone: "Europe/Vilnius",
    dateStyle: "short",
    timeStyle: "short",
  });
}

const monthNames = [
  "Sausis",
  "Vasaris",
  "Kovas",
  "Balandis",
  "Gegužė",
  "Birželis",
  "Liepa",
  "Rugpjūtis",
  "Rugsėjis",
  "Spalis",
  "Lapkritis",
  "Gruodis",
];

function getLTDayKey(tsMs: number): string {
  const d = new Date(tsMs);
  const lt = new Date(
    d.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
  );
  return `${lt.getFullYear()}-${String(lt.getMonth() + 1).padStart(2, "0")}-${String(lt.getDate()).padStart(2, "0")}`;
}

function toLTTimestamp(dateStr: string, timeStr: string): bigint {
  const dt = new Date(`${dateStr}T${timeStr}`);
  return BigInt(dt.getTime()) * 1_000_000n;
}

function todayDateStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function nowTimeStr(): string {
  const now = new Date();
  return `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
}

function mapCategoryToEnum(cat: FoodCategory): SolidFoodCategory {
  switch (cat) {
    case "meat":
      return SolidFoodCategoryEnum.meat;
    case "vegetables":
      return SolidFoodCategoryEnum.vegetables;
    case "fruits":
      return SolidFoodCategoryEnum.fruits;
    case "berries":
      return SolidFoodCategoryEnum.berries;
    case "grains":
      return SolidFoodCategoryEnum.grains;
    case "eggs":
      return SolidFoodCategoryEnum.eggs;
    case "fish":
      return SolidFoodCategoryEnum.fish;
  }
}

function mapReactionToEnum(reaction: Reaction | null): SolidFoodReaction {
  if (reaction === "liked") return SolidFoodReactionEnum.liked;
  if (reaction === "disliked") return SolidFoodReactionEnum.disliked;
  return SolidFoodReactionEnum.unclear;
}

function mapEnumToReaction(reaction: SolidFoodReaction): Reaction | null {
  switch (reaction) {
    case SolidFoodReactionEnum.liked:
      return "liked";
    case SolidFoodReactionEnum.disliked:
      return "disliked";
    case SolidFoodReactionEnum.unclear:
      return "unsure";
    default:
      return null;
  }
}

// ─── Component ───

export default function SolidFoodModule({ childId }: SolidFoodModuleProps) {
  const { data: entries = [] } = useGetSolidFoodEntriesForChild(childId);
  const addEntry = useAddSolidFoodEntry();
  const updateEntry = useUpdateSolidFoodEntry();
  const deleteEntry = useDeleteSolidFoodEntry();
  const { data: statistics } = useGetSolidFoodStatistics(childId);
  const { data: categoryStats } = useGetSolidFoodStatisticsByCategory(
    childId,
    getCurrentMonthStart(),
    getCurrentMonthEnd(),
  );

  const [formOpen, setFormOpen] = useState(false);
  const [foodName, setFoodName] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<FoodCategory | null>(
    null,
  );
  const [selectedColor, setSelectedColor] = useState<FoodColor>("green");
  const [backdated, setBackdated] = useState(false);
  const [dateStr, setDateStr] = useState(todayDateStr);
  const [timeStr, setTimeStr] = useState(nowTimeStr);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingEntryId, setEditingEntryId] = useState<string | null>(null);
  const [editReaction, setEditReaction] = useState<Reaction | null>(null);
  const [editNotes, setEditNotes] = useState("");
  const [editFoodName, setEditFoodName] = useState("");
  const [statsDialogOpen, setStatsDialogOpen] = useState(false);

  // Calendar state
  const today = new Date();
  const [calYear, setCalYear] = useState(today.getFullYear());
  const [calMonth, setCalMonth] = useState(today.getMonth());
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  const sorted = useMemo(
    () => [...entries].sort((a, b) => Number(b.timestamp - a.timestamp)),
    [entries],
  );

  // Statistics from backend
  const todayCount = useMemo(() => {
    const today = new Date();
    const todayLT = new Date(
      today.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
    );
    const todayKey = `${todayLT.getFullYear()}-${String(todayLT.getMonth() + 1).padStart(2, "0")}-${String(todayLT.getDate()).padStart(2, "0")}`;
    return entries.filter((e) => {
      const ms = fromNsToMs(e.timestamp);
      const d = new Date(ms);
      const lt = new Date(
        d.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
      );
      const key = `${lt.getFullYear()}-${String(lt.getMonth() + 1).padStart(2, "0")}-${String(lt.getDate()).padStart(2, "0")}`;
      return key === todayKey;
    }).length;
  }, [entries]);

  const weekCount = useMemo(() => {
    const now = new Date(
      new Date().toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
    );
    const dow = now.getDay() === 0 ? 6 : now.getDay() - 1;
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - dow);
    weekStart.setHours(0, 0, 0, 0);
    return entries.filter((e) => {
      const ms = fromNsToMs(e.timestamp);
      const lt = new Date(
        new Date(ms).toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
      );
      return lt >= weekStart;
    }).length;
  }, [entries]);

  const monthCount = useMemo(() => {
    const today = new Date();
    const todayLT = new Date(
      today.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
    );
    const thisMonthKey = `${todayLT.getFullYear()}-${String(todayLT.getMonth() + 1).padStart(2, "0")}`;
    return entries.filter((e) => {
      const ms = fromNsToMs(e.timestamp);
      const d = new Date(ms);
      const lt = new Date(
        d.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
      );
      const key = `${lt.getFullYear()}-${String(lt.getMonth() + 1).padStart(2, "0")}`;
      return key === thisMonthKey;
    }).length;
  }, [entries]);

  // Reaction breakdown for modal
  const reactionBreakdown = useMemo(() => {
    const counts: Record<Reaction, number> = {
      liked: 0,
      disliked: 0,
      unsure: 0,
    };
    for (const e of entries) {
      const r = mapEnumToReaction(e.reaction);
      if (r) {
        counts[r] = (counts[r] || 0) + 1;
      }
    }
    return counts;
  }, [entries]);

  // Category breakdown
  const categoryBreakdown = useMemo(() => {
    const counts: Record<FoodCategory, number> = {
      meat: 0,
      vegetables: 0,
      fruits: 0,
      berries: 0,
      grains: 0,
      eggs: 0,
      fish: 0,
    };
    for (const e of entries) {
      const cat = e.category as unknown as string;
      if (cat in counts) {
        counts[cat as FoodCategory] = (counts[cat as FoodCategory] || 0) + 1;
      }
    }
    return counts;
  }, [entries]);

  const resetForm = () => {
    setFoodName("");
    setSelectedCategory(null);
    setSelectedColor("green");
    setBackdated(false);
    setDateStr(todayDateStr());
    setTimeStr(nowTimeStr());
  };

  const handleAdd = async () => {
    if (!childId) return;
    if (!foodName.trim()) {
      toast.error("Įveskite maisto pavadinimą");
      return;
    }
    if (!selectedCategory) {
      toast.error("Pasirinkite kategoriją");
      return;
    }
    if (backdated && (!dateStr || !timeStr)) {
      toast.error("Įveskite datą ir laiką");
      return;
    }

    try {
      const timestamp = backdated
        ? toLTTimestamp(dateStr, timeStr)
        : BigInt(Date.now()) * 1_000_000n;
      await addEntry.mutateAsync({
        childId,
        foodName: foodName.trim(),
        category: mapCategoryToEnum(selectedCategory),
        color: selectedColor,
        reaction: SolidFoodReactionEnum.unclear,
        notes: null,
        timestamp,
      });
      toast.success("Primaitinimas užregistruotas");
      setFormOpen(false);
      resetForm();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      toast.error(`Nepavyko išsaugoti: ${msg}`);
    }
  };

  const handleDelete = async (entryId: string) => {
    if (!childId) return;
    try {
      await deleteEntry.mutateAsync({ childId, entryId });
      toast.success("Įrašas ištrintas");
    } catch (_err: unknown) {
      toast.error("Nepavyko ištrinti");
    }
  };

  const openEditDialog = (entry: {
    entryId: string;
    foodName: string;
    category: string;
    color: string;
    reaction: SolidFoodReaction;
    notes?: string | null;
  }) => {
    setEditingEntryId(entry.entryId);
    setEditReaction(mapEnumToReaction(entry.reaction));
    setEditNotes(entry.notes || "");
    setEditFoodName(entry.foodName);
    setEditDialogOpen(true);
  };

  const handleSaveEdit = async () => {
    if (!childId || !editingEntryId) return;
    const entry = entries.find((e) => e.entryId === editingEntryId);
    if (!entry) return;

    const trimmedName = editFoodName.trim();
    if (!trimmedName) {
      toast.error("Įveskite maisto pavadinimą");
      return;
    }

    try {
      await updateEntry.mutateAsync({
        childId,
        entryId: editingEntryId,
        newFoodName: trimmedName,
        newCategory: entry.category,
        newColor: entry.color,
        newReaction: mapReactionToEnum(editReaction),
        newNotes: editNotes.trim() || null,
      });
      setEditDialogOpen(false);
      setEditingEntryId(null);
      toast.success("Įrašas atnaujintas");
    } catch (_err: unknown) {
      toast.error("Nepavyko atnaujinti");
    }
  };

  // Calendar helpers
  const dayMap = useMemo(() => {
    const map: Record<string, { count: number }> = {};
    for (const e of entries) {
      const day = getLTDayKey(fromNsToMs(e.timestamp));
      if (!map[day]) map[day] = { count: 0 };
      map[day].count++;
    }
    return map;
  }, [entries]);

  const calDays = useMemo(() => {
    const firstDay = new Date(calYear, calMonth, 1);
    const lastDay = new Date(calYear, calMonth + 1, 0);
    const days: { key: string; day: string | null }[] = [];
    let startDow = firstDay.getDay();
    if (startDow === 0) startDow = 7;
    for (let i = 1; i < startDow; i++)
      days.push({ key: `empty-${calYear}-${calMonth}-${i}`, day: null });
    for (let d = 1; d <= lastDay.getDate(); d++) {
      const dayStr = `${calYear}-${String(calMonth + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
      days.push({ key: dayStr, day: dayStr });
    }
    return days;
  }, [calYear, calMonth]);

  const selectedDayData = selectedDay ? dayMap[selectedDay] : null;
  const selectedDayEntries = useMemo(() => {
    if (!selectedDay) return [];
    return entries
      .filter((e) => getLTDayKey(fromNsToMs(e.timestamp)) === selectedDay)
      .sort((a, b) => Number(b.timestamp - a.timestamp));
  }, [entries, selectedDay]);

  if (!childId) {
    return (
      <Card>
        <CardContent className="p-6 text-center text-muted-foreground">
          Pasirinkite vaiką, kad matytumėte primaitinimo įrašus.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">Primaitinimas</h2>
        <Button
          size="sm"
          className="gap-1"
          onClick={() => {
            if (formOpen) {
              setFormOpen(false);
              resetForm();
            } else {
              setFormOpen(true);
            }
          }}
          data-ocid="solidfood.open_modal_button"
        >
          {formOpen ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
          {formOpen ? "Uždaryti" : "Pridėti"}
        </Button>
      </div>

      {/* Inline form */}
      <AnimatePresence>
        {formOpen && (
          <motion.div
            key="solidfood-inline-form"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2, ease: "easeInOut" }}
            style={{ overflow: "hidden" }}
          >
            <Card className="border-border bg-card/80">
              <CardContent
                className="space-y-4 p-4"
                data-ocid="solidfood.panel"
              >
                {/* Food name */}
                <div>
                  <Label
                    htmlFor="food-name"
                    className="mb-1 block text-sm font-medium"
                  >
                    Maisto pavadinimas
                  </Label>
                  <Input
                    id="food-name"
                    type="text"
                    placeholder="pvz. Morkų tyrelė"
                    value={foodName}
                    onChange={(e) => setFoodName(e.target.value)}
                    data-ocid="solidfood.input"
                    autoFocus
                  />
                </div>

                {/* Category selection */}
                <div>
                  <Label className="mb-2 block text-sm font-medium">
                    Kategorija
                  </Label>
                  <div className="grid grid-cols-3 gap-2">
                    {(Object.keys(CATEGORY_CONFIG) as FoodCategory[]).map(
                      (cat) => {
                        const { label, Icon, color } = CATEGORY_CONFIG[cat];
                        const isSelected = selectedCategory === cat;
                        return (
                          <button
                            key={cat}
                            type="button"
                            onClick={() => setSelectedCategory(cat)}
                            className={`flex flex-col items-center gap-1 rounded-xl border-2 px-2 py-3 text-center text-xs font-medium transition-all hover:scale-105 ${
                              isSelected
                                ? "border-primary bg-primary/10 text-primary shadow-md"
                                : "border-border bg-card hover:border-primary/50"
                            }`}
                            data-ocid={`solidfood.category.${cat}`}
                          >
                            <Icon
                              className={`h-5 w-5 ${isSelected ? "" : (color ?? "")}`}
                            />
                            {label}
                          </button>
                        );
                      },
                    )}
                  </div>
                </div>

                {/* Color picker */}
                <div>
                  <Label className="mb-2 block text-sm font-medium">
                    Spalva
                  </Label>
                  <div className="flex flex-wrap gap-2">
                    {ALL_COLORS.map((color) => {
                      const isSelected = selectedColor === color;
                      return (
                        <button
                          key={color}
                          type="button"
                          onClick={() => setSelectedColor(color)}
                          className={`h-8 w-8 rounded-full border-2 transition-all hover:scale-110 ${
                            isSelected
                              ? "border-white shadow-lg"
                              : "border-transparent"
                          }`}
                          style={{
                            backgroundColor: COLOR_CONFIG[color].dotHex,
                          }}
                          title={color}
                          data-ocid={`solidfood.color.${color}`}
                        />
                      );
                    })}
                  </div>
                </div>

                {/* Backdated checkbox */}
                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={backdated}
                    onChange={(e) => setBackdated(e.target.checked)}
                    className="h-4 w-4 rounded border-border accent-primary"
                    data-ocid="solidfood.backdated_checkbox"
                  />
                  <span className="text-sm font-medium">Atgalinė data</span>
                </label>

                {/* Date / time when backdated */}
                <AnimatePresence>
                  {backdated && (
                    <motion.div
                      key="solidfood-backdated-fields"
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.2, ease: "easeInOut" }}
                      style={{ overflow: "hidden" }}
                    >
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <Label
                            htmlFor="solidfood-date"
                            className="mb-1 block text-sm font-medium"
                          >
                            Data
                          </Label>
                          <Input
                            id="solidfood-date"
                            type="date"
                            value={dateStr}
                            onChange={(e) => setDateStr(e.target.value)}
                            data-ocid="solidfood.date_input"
                          />
                        </div>
                        <div>
                          <Label
                            htmlFor="solidfood-time"
                            className="mb-1 block text-sm font-medium"
                          >
                            Laikas
                          </Label>
                          <Input
                            id="solidfood-time"
                            type="time"
                            value={timeStr}
                            onChange={(e) => setTimeStr(e.target.value)}
                            data-ocid="solidfood.time_input"
                          />
                        </div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>

                {!backdated && (
                  <p className="text-xs text-muted-foreground">
                    Laikas bus automatiškai užfiksuotas kaip dabar.
                  </p>
                )}

                <Button
                  className="w-full"
                  onClick={handleAdd}
                  disabled={addEntry.isPending}
                  data-ocid="solidfood.submit_button"
                >
                  {addEntry.isPending ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Saugojama...
                    </>
                  ) : (
                    "Išsaugoti"
                  )}
                </Button>
              </CardContent>
            </Card>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Statistics */}
      <div className="grid grid-cols-3 gap-3 relative">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Šiandien</p>
            <p className="text-2xl font-bold">{todayCount}</p>
            <p className="text-xs text-muted-foreground">kartų</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Ši savaitė</p>
            <p className="text-2xl font-bold">
              {statistics?.thisWeek !== undefined
                ? Number(statistics.thisWeek)
                : weekCount}
            </p>
            <p className="text-xs text-muted-foreground">kartų</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Šis mėnuo</p>
            <p className="text-2xl font-bold">
              {statistics?.thisMonth !== undefined
                ? Number(statistics.thisMonth)
                : monthCount}
            </p>
            <p className="text-xs text-muted-foreground">kartų</p>
          </CardContent>
        </Card>
        <button
          type="button"
          onClick={() => setStatsDialogOpen(true)}
          className="absolute -right-2 -top-2 flex h-7 w-7 items-center justify-center rounded-full bg-card border border-border shadow-sm text-muted-foreground hover:text-primary hover:border-primary/50 transition-all"
          data-ocid="solidfood.open_modal_button"
          aria-label="Išplėstinė statistika"
          title="Išplėstinė statistika"
        >
          <Maximize2 className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* History */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Istorija</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {sorted.length === 0 ? (
            <p
              className="text-sm text-muted-foreground"
              data-ocid="solidfood.empty_state"
            >
              Dar nėra primaitinimo įrašų.
            </p>
          ) : (
            sorted.map((entry, i) => {
              const ms = fromNsToMs(entry.timestamp);
              const catKey =
                entry.category as unknown as string as FoodCategory;
              const cfg = CATEGORY_CONFIG[catKey] ?? CATEGORY_CONFIG.vegetables;
              const colorCfg =
                COLOR_CONFIG[(entry.color as FoodColor) ?? "green"] ??
                COLOR_CONFIG.green;
              const reaction = mapEnumToReaction(entry.reaction);
              return (
                <button
                  key={entry.entryId}
                  data-ocid={`solidfood.item.${i + 1}`}
                  className={`flex items-center justify-between rounded-lg border px-3 py-2 text-left w-full ${colorCfg.border} ${colorCfg.bg}`}
                  onClick={() => openEditDialog(entry)}
                  type="button"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full ${colorCfg.bg} border ${colorCfg.border}`}
                    >
                      <cfg.Icon className={`h-4 w-4 ${colorCfg.text}`} />
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-medium truncate">
                        {entry.foodName}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {formatLithuanianDateTime(ms)}
                      </p>
                      {reaction && (
                        <div className="flex items-center gap-1 mt-0.5">
                          {(() => {
                            const rCfg = REACTION_CONFIG[reaction];
                            return (
                              <>
                                <rCfg.Icon
                                  className={`h-3 w-3 ${rCfg.color}`}
                                />
                                <span className={`text-[10px] ${rCfg.color}`}>
                                  {rCfg.label}
                                </span>
                              </>
                            );
                          })()}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-muted-foreground hover:text-destructive"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDelete(entry.entryId);
                      }}
                      data-ocid={`solidfood.delete_button.${i + 1}`}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </button>
              );
            })
          )}
        </CardContent>
      </Card>

      {/* Category breakdown */}
      {entries.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">Kategorijų statistika</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {(Object.keys(CATEGORY_CONFIG) as FoodCategory[]).map((cat) => {
                const count = categoryBreakdown[cat] || 0;
                const { label, Icon } = CATEGORY_CONFIG[cat];
                return (
                  <div
                    key={cat}
                    className="flex items-center gap-2 rounded-lg border border-border bg-card/50 px-3 py-2"
                  >
                    <Icon className="h-4 w-4 text-muted-foreground" />
                    <div>
                      <p className="text-xs text-muted-foreground">{label}</p>
                      <p className="text-sm font-semibold">{count}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Calendar */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Kalendorius</CardTitle>
            <div className="flex items-center gap-2">
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7"
                onClick={() => {
                  if (calMonth === 0) {
                    setCalMonth(11);
                    setCalYear((y) => y - 1);
                  } else setCalMonth((m) => m - 1);
                }}
                data-ocid="solidfood.calendar_prev"
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <span className="text-sm font-medium">
                {monthNames[calMonth]} {calYear}
              </span>
              <Button
                variant="ghost"
                size="icon"
                className="h-7 w-7"
                onClick={() => {
                  if (calMonth === 11) {
                    setCalMonth(0);
                    setCalYear((y) => y + 1);
                  } else setCalMonth((m) => m + 1);
                }}
                data-ocid="solidfood.calendar_next"
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-7 gap-1 text-center">
            {["Pr", "An", "Tr", "Kt", "Pn", "Št", "Sk"].map((d) => (
              <div
                key={d}
                className="py-1 text-xs font-medium text-muted-foreground"
              >
                {d}
              </div>
            ))}
            {calDays.map(({ key, day }) => {
              if (!day) return <div key={key} />;
              const data = dayMap[day];
              const isSelected = selectedDay === day;
              const isToday = day === getLTDayKey(Date.now());
              return (
                <button
                  key={key}
                  type="button"
                  onClick={() => setSelectedDay(isSelected ? null : day)}
                  className={`rounded-lg p-1 text-xs transition-all ${
                    isSelected
                      ? "bg-primary text-primary-foreground ring-2 ring-primary"
                      : data
                        ? "bg-primary/10 text-primary hover:bg-primary/20"
                        : isToday
                          ? "bg-muted font-bold"
                          : "hover:bg-muted"
                  }`}
                  data-ocid={`solidfood.calendar_day.${day}`}
                >
                  <div>{Number.parseInt(day.slice(-2))}</div>
                  {data && (
                    <div className="text-[9px] font-semibold leading-tight">
                      {data.count}×
                    </div>
                  )}
                </button>
              );
            })}
          </div>

          {/* Day popup */}
          {selectedDay && (
            <div
              className="mt-3 rounded-lg border border-border bg-muted/40 p-3"
              data-ocid="solidfood.day_popup"
            >
              <p className="text-sm font-medium">
                {(() => {
                  const [y, m, d] = selectedDay
                    .split("-")
                    .map((n) => Number.parseInt(n, 10));
                  return new Date(y, m - 1, d).toLocaleDateString("lt-LT", {
                    dateStyle: "long",
                  });
                })()}
              </p>
              {selectedDayData ? (
                <div className="mt-2 space-y-1">
                  <p className="text-sm text-muted-foreground">
                    Primaitinimų:{" "}
                    <span className="font-semibold text-foreground">
                      {selectedDayData.count}
                    </span>
                  </p>
                  <div className="mt-2 space-y-1">
                    {selectedDayEntries.map((entry, i) => {
                      const ms = fromNsToMs(entry.timestamp);
                      const catKey =
                        entry.category as unknown as string as FoodCategory;
                      const cfg =
                        CATEGORY_CONFIG[catKey] ?? CATEGORY_CONFIG.vegetables;
                      const colorCfg =
                        COLOR_CONFIG[(entry.color as FoodColor) ?? "green"] ??
                        COLOR_CONFIG.green;
                      const reaction = mapEnumToReaction(entry.reaction);
                      const rCfg = reaction ? REACTION_CONFIG[reaction] : null;
                      return (
                        <div
                          key={entry.entryId}
                          data-ocid={`solidfood.day_item.${i + 1}`}
                          className={`flex items-center justify-between rounded-md border px-2 py-1.5 ${colorCfg.border} ${colorCfg.bg}`}
                        >
                          <div className="flex items-center gap-2 min-w-0">
                            <cfg.Icon
                              className={`h-4 w-4 flex-shrink-0 ${colorCfg.text}`}
                            />
                            <span
                              className={`h-2.5 w-2.5 flex-shrink-0 rounded-full ${colorCfg.dot}`}
                            />
                            <div className="min-w-0">
                              <span className="text-sm font-medium truncate block">
                                {entry.foodName}
                              </span>
                              {rCfg && (
                                <span
                                  className={`text-[10px] ${rCfg.color} flex items-center gap-0.5`}
                                >
                                  <rCfg.Icon className="h-3 w-3" />
                                  {rCfg.label}
                                </span>
                              )}
                              {entry.notes && (
                                <span className="text-[10px] text-muted-foreground block truncate">
                                  {entry.notes}
                                </span>
                              )}
                            </div>
                          </div>
                          <span className="text-xs text-muted-foreground flex-shrink-0">
                            {new Date(ms).toLocaleTimeString("lt-LT", {
                              timeZone: "Europe/Vilnius",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ) : (
                <p className="mt-1 text-sm text-muted-foreground">
                  Šią dieną primaitinimų nebuvo.
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
        <DialogContent className="sm:max-w-md" data-ocid="solidfood.dialog">
          <DialogHeader>
            <DialogTitle>Įrašo redagavimas</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            {editingEntryId &&
              (() => {
                const entry = entries.find((e) => e.entryId === editingEntryId);
                if (!entry) return null;
                const catKey =
                  entry.category as unknown as string as FoodCategory;
                const cfg =
                  CATEGORY_CONFIG[catKey] ?? CATEGORY_CONFIG.vegetables;
                const colorCfg =
                  COLOR_CONFIG[(entry.color as FoodColor) ?? "green"] ??
                  COLOR_CONFIG.green;
                return (
                  <div className="flex items-center gap-2">
                    <div
                      className={`flex h-8 w-8 items-center justify-center rounded-full ${colorCfg.bg} border ${colorCfg.border}`}
                    >
                      <cfg.Icon className={`h-4 w-4 ${colorCfg.text}`} />
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {cfg.label}
                    </span>
                  </div>
                );
              })()}

            {/* Pavadinimas (editable title) */}
            <div>
              <Label
                htmlFor="edit-food-name"
                className="mb-1 block text-sm font-medium"
              >
                Pavadinimas
              </Label>
              <Input
                id="edit-food-name"
                type="text"
                placeholder="pvz. Morkų tyrelė"
                value={editFoodName}
                onChange={(e) => setEditFoodName(e.target.value)}
                data-ocid="solidfood.edit_input"
                autoFocus
              />
            </div>

            {/* Reaction */}
            <div>
              <Label className="mb-2 block text-sm font-medium">Reakcija</Label>
              <div className="flex gap-2">
                {(Object.keys(REACTION_CONFIG) as Reaction[]).map((r) => {
                  const { label, Icon, color } = REACTION_CONFIG[r];
                  const isSelected = editReaction === r;
                  return (
                    <button
                      key={r}
                      type="button"
                      onClick={() => setEditReaction(isSelected ? null : r)}
                      className={`flex flex-1 items-center justify-center gap-1 rounded-xl border-2 px-3 py-2 text-xs font-medium transition-all hover:scale-105 ${
                        isSelected
                          ? "border-primary bg-primary/10 text-primary shadow-md"
                          : "border-border bg-card hover:border-primary/50"
                      }`}
                      data-ocid={`solidfood.reaction.${r}`}
                    >
                      <Icon className={`h-4 w-4 ${isSelected ? "" : color}`} />
                      {label}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Notes */}
            <div>
              <Label
                htmlFor="edit-notes"
                className="mb-1 block text-sm font-medium"
              >
                Pastabos
              </Label>
              <Textarea
                id="edit-notes"
                placeholder="Pvz. Valgė labai noriai..."
                value={editNotes}
                onChange={(e) => setEditNotes(e.target.value)}
                rows={3}
                data-ocid="solidfood.textarea"
              />
            </div>

            <div className="flex gap-2">
              <Button
                variant="outline"
                className="flex-1"
                onClick={() => setEditDialogOpen(false)}
                data-ocid="solidfood.cancel_button"
              >
                Atšaukti
              </Button>
              <Button
                className="flex-1"
                onClick={handleSaveEdit}
                disabled={updateEntry.isPending}
                data-ocid="solidfood.save_button"
              >
                {updateEntry.isPending ? "Saugojama..." : "Išsaugoti"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Statistics Dialog */}
      <Dialog open={statsDialogOpen} onOpenChange={setStatsDialogOpen}>
        <DialogContent
          className="sm:max-w-lg bg-card border-border"
          data-ocid="solidfood.stats_dialog"
        >
          <DialogHeader>
            <DialogTitle className="text-lg font-bold text-foreground">
              Išplėstinė primaitinimo statistika
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-6 py-2">
            {/* Category counts */}
            <div>
              <h3 className="text-sm font-semibold text-muted-foreground mb-3">
                Kategorijų įrašai
              </h3>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                {(Object.keys(CATEGORY_CONFIG) as FoodCategory[]).map((cat) => {
                  const count = categoryBreakdown[cat] || 0;
                  const { label, Icon } = CATEGORY_CONFIG[cat];
                  return (
                    <div
                      key={cat}
                      className="flex items-center gap-2 rounded-lg border border-border bg-muted/40 px-3 py-2"
                    >
                      <Icon className="h-4 w-4 text-primary" />
                      <div>
                        <p className="text-xs text-muted-foreground">{label}</p>
                        <p className="text-sm font-semibold text-foreground">
                          {count}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Reaction breakdown */}
            <div>
              <h3 className="text-sm font-semibold text-muted-foreground mb-3">
                Reakcijos
              </h3>
              <div className="grid grid-cols-3 gap-2">
                {(Object.keys(REACTION_CONFIG) as Reaction[]).map((r) => {
                  const { label, Icon, color } = REACTION_CONFIG[r];
                  const count = reactionBreakdown[r] || 0;
                  return (
                    <div
                      key={r}
                      className="flex flex-col items-center gap-1 rounded-lg border border-border bg-muted/40 px-3 py-3"
                    >
                      <Icon className={`h-5 w-5 ${color}`} />
                      <p className="text-xs text-muted-foreground">{label}</p>
                      <p className="text-lg font-bold text-foreground">
                        {count}
                      </p>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Monthly category stats from backend */}
            {categoryStats && (
              <div>
                <h3 className="text-sm font-semibold text-muted-foreground mb-3">
                  Šio mėnesio kategorijos
                </h3>
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                  {(Object.keys(CATEGORY_CONFIG) as FoodCategory[]).map(
                    (cat) => {
                      const count = Number(
                        (categoryStats as unknown as Record<string, bigint>)[
                          cat
                        ] || 0n,
                      );
                      if (count === 0) return null;
                      const { label, Icon } = CATEGORY_CONFIG[cat];
                      return (
                        <div
                          key={cat}
                          className="flex items-center gap-2 rounded-lg border border-primary/20 bg-primary/5 px-3 py-2"
                        >
                          <Icon className="h-4 w-4 text-primary" />
                          <div>
                            <p className="text-xs text-muted-foreground">
                              {label}
                            </p>
                            <p className="text-sm font-semibold text-foreground">
                              {count}
                            </p>
                          </div>
                        </div>
                      );
                    },
                  )}
                </div>
              </div>
            )}

            <Button
              variant="outline"
              className="w-full"
              onClick={() => setStatsDialogOpen(false)}
              data-ocid="solidfood.stats_close_button"
            >
              Uždaryti
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
