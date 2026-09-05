import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ChevronLeft, ChevronRight, Plus, Trash2, X } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import React, { useState, useMemo } from "react";
import { toast } from "sonner";
import {
  useAddFeedingSession,
  useDeleteFeedingSession,
  useGetFeedingSessionsForChild,
} from "../hooks/useQueries";

interface FeedingModuleProps {
  childId: string | null;
}

type FeedingColor =
  | "red"
  | "orange"
  | "yellow"
  | "green"
  | "teal"
  | "blue"
  | "purple"
  | "pink";

type FeedingType = "misinukas" | "mamosPienas";

const COLOR_CONFIG: Record<
  FeedingColor,
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

const ALL_COLORS: FeedingColor[] = [
  "red",
  "orange",
  "yellow",
  "green",
  "teal",
  "blue",
  "purple",
  "pink",
];

const TYPE_LABELS: Record<FeedingType, string> = {
  misinukas: "Mišinukas",
  mamosPienas: "Mamos pienas",
};

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

function fromNsToMs(ns: bigint): number {
  return Number(ns / 1_000_000n);
}

function getLTDayKey(tsMs: number): string {
  const d = new Date(tsMs);
  const lt = new Date(
    d.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
  );
  return `${lt.getFullYear()}-${String(lt.getMonth() + 1).padStart(2, "0")}-${String(lt.getDate()).padStart(2, "0")}`;
}

function getLTMonthKey(tsMs: number): string {
  const d = new Date(tsMs);
  const lt = new Date(
    d.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
  );
  return `${lt.getFullYear()}-${String(lt.getMonth() + 1).padStart(2, "0")}`;
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

export default function FeedingModule({ childId }: FeedingModuleProps) {
  const { data: sessions = [] } = useGetFeedingSessionsForChild(childId);
  const addSession = useAddFeedingSession();
  const deleteSession = useDeleteFeedingSession();

  const [formOpen, setFormOpen] = useState(false);
  const [selectedType, setSelectedType] = useState<FeedingType>("misinukas");
  const [selectedColor, setSelectedColor] = useState<FeedingColor>("teal");
  const [mlAmount, setMlAmount] = useState("");
  const [backdated, setBackdated] = useState(false);
  const [dateStr, setDateStr] = useState(todayDateStr);
  const [timeStr, setTimeStr] = useState(nowTimeStr);

  // Calendar state
  const today = new Date();
  const [calYear, setCalYear] = useState(today.getFullYear());
  const [calMonth, setCalMonth] = useState(today.getMonth());
  const [selectedDay, setSelectedDay] = useState<string | null>(null);

  const resetForm = () => {
    setMlAmount("");
    setSelectedType("misinukas");
    setSelectedColor("teal");
    setBackdated(false);
    setDateStr(todayDateStr());
    setTimeStr(nowTimeStr());
  };

  const handleAdd = async () => {
    if (!childId) return;
    const ml = Number.parseFloat(mlAmount);
    if (Number.isNaN(ml) || ml <= 0) {
      toast.error("Įveskite teisingą ml kiekį");
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
      await addSession.mutateAsync({
        childId,
        timestamp,
        mlAmount: ml,
        feedingType: selectedType,
        color: selectedColor,
      });
      toast.success("Maitinimas išsaugotas");
      setFormOpen(false);
      resetForm();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      toast.error(`Nepavyko išsaugoti: ${msg}`);
    }
  };

  const handleDelete = async (sessionId: string) => {
    if (!childId) return;
    try {
      await deleteSession.mutateAsync({ childId, sessionId });
      toast.success("Įrašas ištrintas");
    } catch (_err: unknown) {
      toast.error("Nepavyko ištrinti");
    }
  };

  const sorted = useMemo(
    () => [...sessions].sort((a, b) => Number(b.timestamp - a.timestamp)),
    [sessions],
  );

  const todayLT = new Date(
    today.toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
  );
  const todayKey = `${todayLT.getFullYear()}-${String(todayLT.getMonth() + 1).padStart(2, "0")}-${String(todayLT.getDate()).padStart(2, "0")}`;
  const thisMonthKey = `${todayLT.getFullYear()}-${String(todayLT.getMonth() + 1).padStart(2, "0")}`;

  const todaySessions = useMemo(
    () =>
      sessions.filter((s) => getLTDayKey(fromNsToMs(s.timestamp)) === todayKey),
    [sessions, todayKey],
  );

  const thisWeekSessions = useMemo(() => {
    const now = new Date(
      new Date().toLocaleString("en-US", { timeZone: "Europe/Vilnius" }),
    );
    const dow = now.getDay() === 0 ? 6 : now.getDay() - 1;
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - dow);
    weekStart.setHours(0, 0, 0, 0);
    return sessions.filter((s) => {
      const lt = new Date(
        new Date(fromNsToMs(s.timestamp)).toLocaleString("en-US", {
          timeZone: "Europe/Vilnius",
        }),
      );
      return lt >= weekStart;
    });
  }, [sessions]);

  const thisMonthSessions = useMemo(
    () =>
      sessions.filter(
        (s) => getLTMonthKey(fromNsToMs(s.timestamp)) === thisMonthKey,
      ),
    [sessions, thisMonthKey],
  );

  // Calendar helpers
  const dayMap = useMemo(() => {
    const map: Record<string, { count: number; totalMl: number }> = {};
    for (const s of sessions) {
      const day = getLTDayKey(fromNsToMs(s.timestamp));
      if (!map[day]) map[day] = { count: 0, totalMl: 0 };
      map[day].count++;
      map[day].totalMl += s.mlAmount;
    }
    return map;
  }, [sessions]);

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
  const selectedDaySessions = useMemo(() => {
    if (!selectedDay) return [];
    return sessions
      .filter((s) => getLTDayKey(fromNsToMs(s.timestamp)) === selectedDay)
      .sort((a, b) => Number(b.timestamp - a.timestamp));
  }, [sessions, selectedDay]);

  if (!childId) {
    return (
      <Card>
        <CardContent className="p-6 text-center text-muted-foreground">
          Pasirinkite vaiką, kad matytumėte maitinimo sesijas.
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-bold">Maitinimas</h2>
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
          data-ocid="feeding.open_modal_button"
        >
          {formOpen ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
          {formOpen ? "Uždaryti" : "Pridėti"}
        </Button>
      </div>

      {/* Inline form */}
      <AnimatePresence>
        {formOpen && (
          <motion.div
            key="feeding-inline-form"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2, ease: "easeInOut" }}
            style={{ overflow: "hidden" }}
          >
            <Card className="border-border bg-card/80">
              <CardContent className="space-y-4 p-4" data-ocid="feeding.panel">
                {/* Type selector */}
                <div>
                  <Label className="mb-2 block text-sm font-medium">
                    Tipas
                  </Label>
                  <div className="flex gap-2">
                    {(Object.keys(TYPE_LABELS) as FeedingType[]).map((t) => {
                      const isSelected = selectedType === t;
                      return (
                        <button
                          key={t}
                          type="button"
                          onClick={() => setSelectedType(t)}
                          className={`flex-1 rounded-lg border px-3 py-2 text-sm font-medium transition-all ${
                            isSelected
                              ? "border-primary bg-primary/10 text-primary ring-2 ring-primary/40"
                              : "border-border bg-card text-muted-foreground hover:border-primary/50"
                          }`}
                          data-ocid={`feeding.type.${t}`}
                        >
                          {TYPE_LABELS[t]}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* ML amount */}
                <div>
                  <Label
                    htmlFor="feed-ml"
                    className="mb-1 block text-sm font-medium"
                  >
                    Kiekis (ml)
                  </Label>
                  <Input
                    id="feed-ml"
                    type="number"
                    min="0"
                    step="0.5"
                    placeholder="pvz. 120"
                    value={mlAmount}
                    onChange={(e) => setMlAmount(e.target.value)}
                    data-ocid="feeding.input"
                    autoFocus
                  />
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
                              ? "border-white shadow-lg ring-2 ring-primary"
                              : "border-transparent"
                          }`}
                          style={{
                            backgroundColor: COLOR_CONFIG[color].dotHex,
                          }}
                          title={color}
                          data-ocid={`feeding.color.${color}`}
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
                    data-ocid="feeding.backdated_checkbox"
                  />
                  <span className="text-sm font-medium">Atgalinė data</span>
                </label>

                {/* Date / time when backdated */}
                <AnimatePresence>
                  {backdated && (
                    <motion.div
                      key="backdated-fields"
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.2, ease: "easeInOut" }}
                      style={{ overflow: "hidden" }}
                    >
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <Label
                            htmlFor="feed-date"
                            className="mb-1 block text-sm font-medium"
                          >
                            Data
                          </Label>
                          <Input
                            id="feed-date"
                            type="date"
                            value={dateStr}
                            onChange={(e) => setDateStr(e.target.value)}
                            data-ocid="feeding.date_input"
                          />
                        </div>
                        <div>
                          <Label
                            htmlFor="feed-time"
                            className="mb-1 block text-sm font-medium"
                          >
                            Laikas
                          </Label>
                          <Input
                            id="feed-time"
                            type="time"
                            value={timeStr}
                            onChange={(e) => setTimeStr(e.target.value)}
                            data-ocid="feeding.time_input"
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
                  disabled={addSession.isPending}
                  data-ocid="feeding.submit_button"
                >
                  {addSession.isPending ? "Saugoma..." : "Išsaugoti"}
                </Button>
              </CardContent>
            </Card>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Šiandien</p>
            <p className="text-2xl font-bold">{todaySessions.length}</p>
            <p className="text-xs text-muted-foreground">
              {todaySessions.reduce((s, x) => s + x.mlAmount, 0).toFixed(0)} ml
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Ši savaitė</p>
            <p className="text-2xl font-bold">{thisWeekSessions.length}</p>
            <p className="text-xs text-muted-foreground">
              {thisWeekSessions.reduce((s, x) => s + x.mlAmount, 0).toFixed(0)}{" "}
              ml
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted-foreground">Šis mėnuo</p>
            <p className="text-2xl font-bold">{thisMonthSessions.length}</p>
            <p className="text-xs text-muted-foreground">
              {thisMonthSessions.reduce((s, x) => s + x.mlAmount, 0).toFixed(0)}{" "}
              ml
            </p>
          </CardContent>
        </Card>
      </div>

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
                data-ocid="feeding.calendar_prev"
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
                data-ocid="feeding.calendar_next"
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
                  data-ocid={`feeding.calendar_day.${day}`}
                >
                  <div>{Number.parseInt(day.slice(-2))}</div>
                  {data && (
                    <div className="text-[9px] font-semibold leading-tight">
                      {data.totalMl.toFixed(0)}ml
                    </div>
                  )}
                </button>
              );
            })}
          </div>

          {/* Day popup */}
          {selectedDay && (
            <div className="mt-3 rounded-lg border border-border bg-muted/40 p-3">
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
                    Maitinimų:{" "}
                    <span className="font-semibold text-foreground">
                      {selectedDayData.count}
                    </span>
                  </p>
                  <p className="text-sm text-muted-foreground">
                    Iš viso:{" "}
                    <span className="font-semibold text-foreground">
                      {selectedDayData.totalMl.toFixed(0)} ml
                    </span>
                  </p>
                  <div className="mt-2 space-y-1">
                    {selectedDaySessions.map((s, i) => {
                      const ms = fromNsToMs(s.timestamp);
                      const typeKey =
                        typeof s.feedingType === "object"
                          ? "misinukas" in s.feedingType
                            ? "misinukas"
                            : "mamosPienas"
                          : (s.feedingType as FeedingType);
                      const colorKey = (s.color as FeedingColor) ?? "teal";
                      const colorCfg =
                        COLOR_CONFIG[colorKey] ?? COLOR_CONFIG.teal;
                      return (
                        <div
                          key={s.sessionId}
                          data-ocid={`feeding.day_item.${i + 1}`}
                          className={`flex items-center justify-between rounded-md border px-2 py-1.5 ${colorCfg.border} ${colorCfg.bg}`}
                        >
                          <div className="flex items-center gap-2">
                            <span
                              className={`h-2.5 w-2.5 rounded-full ${colorCfg.dot}`}
                            />
                            <span className="text-sm font-medium">
                              {s.mlAmount.toFixed(0)} ml
                            </span>
                            <span className="text-xs text-muted-foreground">
                              {TYPE_LABELS[typeKey] ?? typeKey}
                            </span>
                          </div>
                          <span className="text-xs text-muted-foreground">
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
                  Šią dieną maitinimų nebuvo.
                </p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* History */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Istorija</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {sorted.length === 0 ? (
            <p
              className="text-sm text-muted-foreground"
              data-ocid="feeding.empty_state"
            >
              Dar nėra įrašų.
            </p>
          ) : (
            sorted.slice(0, 20).map((s, i) => {
              const ms = fromNsToMs(s.timestamp);
              const typeKey =
                typeof s.feedingType === "object"
                  ? "misinukas" in s.feedingType
                    ? "misinukas"
                    : "mamosPienas"
                  : (s.feedingType as FeedingType);
              const colorKey = (s.color as FeedingColor) ?? "teal";
              const colorCfg = COLOR_CONFIG[colorKey] ?? COLOR_CONFIG.teal;
              return (
                <div
                  key={s.sessionId}
                  data-ocid={`feeding.item.${i + 1}`}
                  className={`flex items-center justify-between rounded-lg border px-3 py-2 ${colorCfg.border} ${colorCfg.bg}`}
                >
                  <div className="flex items-center gap-2">
                    <span
                      className={`h-3 w-3 flex-shrink-0 rounded-full ${colorCfg.dot}`}
                    />
                    <div>
                      <p className="text-sm font-medium">
                        {s.mlAmount.toFixed(0)} ml &bull;{" "}
                        {TYPE_LABELS[typeKey] ?? typeKey}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {new Date(ms).toLocaleString("lt-LT", {
                          timeZone: "Europe/Vilnius",
                          dateStyle: "short",
                          timeStyle: "short",
                        })}
                      </p>
                    </div>
                  </div>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 text-muted-foreground hover:text-destructive"
                    onClick={() => handleDelete(s.sessionId)}
                    data-ocid={`feeding.delete_button.${i + 1}`}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              );
            })
          )}
        </CardContent>
      </Card>
    </div>
  );
}
