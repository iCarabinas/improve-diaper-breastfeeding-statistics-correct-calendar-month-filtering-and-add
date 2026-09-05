import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Calendar as CalendarIcon,
  Clock,
  Loader2,
  Pause,
  Play,
  Square,
  Trash2,
} from "lucide-react";
import React, { useState, useEffect } from "react";
import { toast } from "sonner";
import {
  useCompleteTummyTimeSession,
  useDeleteTummyTimeSession,
  useGetActiveTummyTimeTimer,
  useGetTummyTimeSessionsForChild,
  usePauseTummyTimeTimer,
  useResumeTummyTimeTimer,
  useStartTummyTimeSession,
} from "../hooks/useQueries";
import type { TummyTimeSession } from "../types";

interface TummyTimeModuleProps {
  childId: string | null;
}

export default function TummyTimeModule({ childId }: TummyTimeModuleProps) {
  const [displayTime, setDisplayTime] = useState(0);
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());

  const { data: sessions = [] } = useGetTummyTimeSessionsForChild(childId);
  const startSession = useStartTummyTimeSession();
  const completeSession = useCompleteTummyTimeSession();
  const pauseTimer = usePauseTummyTimeTimer();
  const resumeTimer = useResumeTummyTimeTimer();
  const deleteSession = useDeleteTummyTimeSession();
  const { data: activeTimer } = useGetActiveTummyTimeTimer(childId);

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [sessionToDelete, setSessionToDelete] =
    useState<TummyTimeSession | null>(null);

  useEffect(() => {
    if (activeTimer) {
      const calculateElapsed = () => {
        const now = Date.now();
        const startTimeMs = Number(activeTimer.startTime / BigInt(1_000_000));
        const totalPausedMs = Number(
          activeTimer.totalPausedDuration / BigInt(1_000_000),
        );

        if (activeTimer.isPaused && activeTimer.pausedAt) {
          const pausedAtMs = Number(activeTimer.pausedAt / BigInt(1_000_000));
          return Math.floor((pausedAtMs - startTimeMs - totalPausedMs) / 1000);
        }
        return Math.floor((now - startTimeMs - totalPausedMs) / 1000);
      };

      setDisplayTime(calculateElapsed());
    } else {
      setDisplayTime(0);
    }
  }, [activeTimer]);

  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;

    if (activeTimer && !activeTimer.isPaused) {
      interval = setInterval(() => {
        const now = Date.now();
        const startTimeMs = Number(activeTimer.startTime / BigInt(1_000_000));
        const totalPausedMs = Number(
          activeTimer.totalPausedDuration / BigInt(1_000_000),
        );
        const elapsed = Math.floor((now - startTimeMs - totalPausedMs) / 1000);
        setDisplayTime(elapsed);
      }, 1000);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [activeTimer]);

  const handleStart = async () => {
    if (!childId) {
      toast.error("Pasirinkite vaiką");
      return;
    }

    try {
      await startSession.mutateAsync(childId);
      toast.success("Pilvo laiko sesija pradėta");
    } catch (error) {
      console.error("Error starting tummy time:", error);
      toast.error("Nepavyko pradėti sesijos");
    }
  };

  const handlePause = async () => {
    if (!childId) return;
    try {
      await pauseTimer.mutateAsync(childId);
    } catch (error) {
      console.error("Error pausing timer:", error);
      toast.error("Nepavyko pristabdyti laikmačio");
    }
  };

  const handleResume = async () => {
    if (!childId) return;
    try {
      await resumeTimer.mutateAsync(childId);
    } catch (error) {
      console.error("Error resuming timer:", error);
      toast.error("Nepavyko tęsti laikmačio");
    }
  };

  const handleStop = async () => {
    if (!childId) return;

    try {
      await completeSession.mutateAsync(childId);
      toast.success("Pilvo laiko sesija išsaugota!");
    } catch (error) {
      toast.error("Nepavyko išsaugoti sesijos");
      console.error(error);
    }
  };

  const openDeleteDialog = (session: TummyTimeSession) => {
    setSessionToDelete(session);
    setDeleteDialogOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!childId || !sessionToDelete?.sessionId) return;
    try {
      await deleteSession.mutateAsync({
        childId,
        sessionId: sessionToDelete.sessionId,
      });
      toast.success("Sesija ištrinta");
      setDeleteDialogOpen(false);
      setSessionToDelete(null);
    } catch (error) {
      console.error("Error deleting tummy time session:", error);
      toast.error("Nepavyko ištrinti sesijos");
    }
  };

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
  };

  const formatBigIntDuration = (ns: bigint) => {
    const totalSeconds = Number(ns / BigInt(1_000_000_000));
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  };

  const formatDate = (timestamp: bigint) => {
    const date = new Date(Number(timestamp / BigInt(1_000_000)));
    return date.toLocaleDateString("lt-LT", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayTimestamp = BigInt(today.getTime()) * BigInt(1_000_000);

  const weekAgo = new Date(today);
  weekAgo.setDate(weekAgo.getDate() - 7);
  const weekTimestamp = BigInt(weekAgo.getTime()) * BigInt(1_000_000);

  const monthAgo = new Date(today);
  monthAgo.setMonth(monthAgo.getMonth() - 1);
  const monthTimestamp = BigInt(monthAgo.getTime()) * BigInt(1_000_000);

  const selectedDayStart = new Date(selectedDate);
  selectedDayStart.setHours(0, 0, 0, 0);
  const selectedDayTimestamp =
    BigInt(selectedDayStart.getTime()) * BigInt(1_000_000);

  const selectedDayEnd = new Date(selectedDate);
  selectedDayEnd.setHours(23, 59, 59, 999);
  const selectedDayEndTimestamp =
    BigInt(selectedDayEnd.getTime()) * BigInt(1_000_000);

  const todayTotal = sessions
    .filter((s) => s.startTime >= todayTimestamp)
    .reduce((sum, s) => sum + s.duration, BigInt(0));

  const weekTotal = sessions
    .filter((s) => s.startTime >= weekTimestamp)
    .reduce((sum, s) => sum + s.duration, BigInt(0));

  const monthTotal = sessions
    .filter((s) => s.startTime >= monthTimestamp)
    .reduce((sum, s) => sum + s.duration, BigInt(0));

  const selectedDayTotal = sessions
    .filter(
      (s) =>
        s.startTime >= selectedDayTimestamp &&
        s.startTime <= selectedDayEndTimestamp,
    )
    .reduce((sum, s) => sum + s.duration, BigInt(0));

  const sortedSessions = [...sessions].sort((a, b) =>
    Number(b.startTime - a.startTime),
  );
  const recentSessions = sortedSessions.slice(0, 10);

  const isTimerActive = !!activeTimer;
  const isTimerPaused = activeTimer?.isPaused || false;

  if (!childId) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted-foreground">
          Pasirinkite vaiką, kad pradėtumėte sekti pilvo laiką
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6 max-w-full overflow-hidden">
      <Card>
        <CardHeader className="bg-gradient-to-r from-green-100 to-teal-100 dark:from-green-950 dark:to-teal-950">
          <CardTitle className="flex items-center gap-2">
            <img
              src="/assets/generated/tummy-time-icon-transparent.dim_100x100.png"
              alt="Pilvo Laikas"
              className="h-8 w-8"
            />
            Pilvo Laikas
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          <div className="space-y-6">
            <div className="text-center">
              <div className="mb-4 text-5xl font-bold tabular-nums text-primary">
                {formatDuration(displayTime)}
              </div>
              {isTimerPaused && (
                <p className="mb-4 text-sm font-medium text-yellow-600 dark:text-yellow-400">
                  ⏸ Pristabdyta
                </p>
              )}
              <div className="flex justify-center gap-3">
                {!isTimerActive ? (
                  <Button
                    onClick={handleStart}
                    size="lg"
                    className="gap-2"
                    disabled={startSession.isPending}
                  >
                    <Play className="h-5 w-5" />
                    Pradėti
                  </Button>
                ) : (
                  <>
                    {!isTimerPaused ? (
                      <Button
                        onClick={handlePause}
                        variant="outline"
                        size="lg"
                        className="gap-2"
                        disabled={pauseTimer.isPending}
                      >
                        <Pause className="h-5 w-5" />
                        Pauzė
                      </Button>
                    ) : (
                      <Button
                        onClick={handleResume}
                        variant="outline"
                        size="lg"
                        className="gap-2"
                        disabled={resumeTimer.isPending}
                      >
                        <Play className="h-5 w-5" />
                        Tęsti
                      </Button>
                    )}
                    <Button
                      onClick={handleStop}
                      variant="destructive"
                      size="lg"
                      className="gap-2"
                      disabled={completeSession.isPending}
                    >
                      {completeSession.isPending ? (
                        <Loader2 className="h-5 w-5 animate-spin" />
                      ) : (
                        <Square className="h-5 w-5" />
                      )}
                      Baigta
                    </Button>
                  </>
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Istorija</CardTitle>
        </CardHeader>
        <CardContent>
          {sessions.length === 0 ? (
            <p
              className="text-center text-muted-foreground py-8"
              data-ocid="tummytime.empty_state"
            >
              Dar nėra pilvo laiko sesijų
            </p>
          ) : (
            <>
              <div className="space-y-3">
                {recentSessions.map((session, i) => (
                  <div
                    key={session.sessionId}
                    data-ocid={`tummytime.item.${i + 1}`}
                    className="flex items-center justify-between rounded-lg border bg-gradient-to-r from-green-50/50 to-teal-50/50 dark:from-green-950/20 dark:to-teal-950/20 p-4 transition-all hover:shadow-md"
                  >
                    <div className="flex-1 space-y-1 min-w-0">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <CalendarIcon className="h-4 w-4 flex-shrink-0" />
                        <span className="truncate">
                          {formatDate(session.startTime)}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-primary flex-shrink-0" />
                        <span className="font-semibold text-primary">
                          {formatBigIntDuration(session.duration)}
                        </span>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 flex-shrink-0 text-muted-foreground hover:text-destructive"
                      onClick={() => openDeleteDialog(session)}
                      disabled={deleteSession.isPending}
                      aria-label="Ištrinti sesiją"
                      data-ocid={`tummytime.delete_button.${i + 1}`}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
              {sessions.length > 10 && (
                <p className="mt-4 text-center text-sm text-muted-foreground">
                  Rodoma {Math.min(10, sessions.length)} iš {sessions.length}{" "}
                  sesijų
                </p>
              )}
            </>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Statistika</CardTitle>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="today" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="today">Šiandien</TabsTrigger>
              <TabsTrigger value="week">Ši savaitė</TabsTrigger>
              <TabsTrigger value="month">Šis mėnuo</TabsTrigger>
            </TabsList>

            <TabsContent value="today" className="space-y-4">
              <div className="rounded-lg bg-gradient-to-br from-green-50 to-teal-50 dark:from-green-950/20 dark:to-teal-950/20 p-6 border border-green-200/50 dark:border-green-800/50">
                <h3 className="text-sm font-medium text-muted-foreground mb-2">
                  Šiandienos trukmė
                </h3>
                <p className="text-3xl font-bold text-green-700 dark:text-green-400">
                  {formatBigIntDuration(todayTotal)}
                </p>
              </div>
            </TabsContent>

            <TabsContent value="week" className="space-y-4">
              <div className="rounded-lg bg-gradient-to-br from-green-50 to-teal-50 dark:from-green-950/20 dark:to-teal-950/20 p-6 border border-green-200/50 dark:border-green-800/50">
                <h3 className="text-sm font-medium text-muted-foreground mb-2">
                  Savaitės trukmė
                </h3>
                <p className="text-3xl font-bold text-green-700 dark:text-green-400">
                  {formatBigIntDuration(weekTotal)}
                </p>
              </div>
            </TabsContent>

            <TabsContent value="month" className="space-y-4">
              <div className="rounded-lg bg-gradient-to-br from-green-50 to-teal-50 dark:from-green-950/20 dark:to-teal-950/20 p-6 border border-green-200/50 dark:border-green-800/50">
                <h3 className="text-sm font-medium text-muted-foreground mb-2">
                  Mėnesio trukmė
                </h3>
                <p className="text-3xl font-bold text-green-700 dark:text-green-400">
                  {formatBigIntDuration(monthTotal)}
                </p>
              </div>
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Kalendorius</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4 max-w-full overflow-x-auto">
            <div className="flex justify-center px-2">
              <Calendar
                mode="single"
                selected={selectedDate}
                onSelect={(date) => date && setSelectedDate(date)}
                className="rounded-md border mx-auto scale-90 xs:scale-100 sm:scale-110 md:scale-125 lg:scale-110 origin-center"
                classNames={{
                  months:
                    "flex flex-col sm:flex-row space-y-4 sm:space-x-4 sm:space-y-0",
                  month: "space-y-4",
                  caption: "flex justify-center pt-1 relative items-center",
                  caption_label: "text-sm sm:text-base font-medium",
                  nav: "space-x-1 flex items-center",
                  nav_button:
                    "h-8 w-8 sm:h-10 sm:w-10 bg-transparent p-0 opacity-50 hover:opacity-100",
                  nav_button_previous: "absolute left-1",
                  nav_button_next: "absolute right-1",
                  table: "w-full border-collapse space-y-1",
                  head_row: "flex",
                  head_cell:
                    "text-muted-foreground rounded-md w-12 sm:w-14 md:w-16 font-normal text-xs sm:text-sm",
                  row: "flex w-full mt-2",
                  cell: "relative p-0 text-center text-sm focus-within:relative focus-within:z-20 [&:has([aria-selected])]:bg-accent [&:has([aria-selected].day-outside)]:bg-accent/50 [&:has([aria-selected].day-range-end)]:rounded-r-md",
                  day: "h-12 w-12 sm:h-14 sm:w-14 md:h-16 md:w-16 p-0 font-normal aria-selected:opacity-100 hover:bg-accent hover:text-accent-foreground rounded-md transition-colors text-sm sm:text-base",
                  day_range_start: "day-range-start",
                  day_range_end: "day-range-end",
                  day_selected:
                    "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground focus:bg-primary focus:text-primary-foreground",
                  day_today: "bg-accent text-accent-foreground font-semibold",
                  day_outside:
                    "day-outside text-muted-foreground opacity-50 aria-selected:bg-accent/50 aria-selected:text-muted-foreground aria-selected:opacity-30",
                  day_disabled: "text-muted-foreground opacity-50",
                  day_range_middle:
                    "aria-selected:bg-accent aria-selected:text-accent-foreground",
                  day_hidden: "invisible",
                }}
              />
            </div>
            {selectedDayTotal > BigInt(0) && (
              <div className="rounded-lg bg-gradient-to-br from-green-50 to-teal-50 dark:from-green-950/20 dark:to-teal-950/20 p-4 border border-green-200/50 dark:border-green-800/50">
                <h3 className="text-sm font-medium text-muted-foreground mb-2">
                  {selectedDate.toLocaleDateString("lt-LT", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </h3>
                <p className="text-2xl font-bold text-green-700 dark:text-green-400">
                  {formatBigIntDuration(selectedDayTotal)}
                </p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      <Dialog
        open={deleteDialogOpen}
        onOpenChange={(open) => {
          setDeleteDialogOpen(open);
          if (!open) setSessionToDelete(null);
        }}
      >
        <DialogContent
          data-ocid="tummytime.delete.dialog"
          className="sm:max-w-md"
        >
          <DialogHeader>
            <DialogTitle>Patvirtinti trynimą</DialogTitle>
            <DialogDescription>
              Ar tikrai norite ištrinti šią pilvo laiko sesiją? Šio veiksmo
              neįmanoma atšaukti.
              {sessionToDelete && (
                <span className="mt-3 block rounded-md border border-border bg-muted/40 p-3 text-sm">
                  <span className="flex items-center gap-2 text-foreground">
                    <CalendarIcon className="h-4 w-4 text-muted-foreground" />
                    {formatDate(sessionToDelete.startTime)}
                  </span>
                  <span className="mt-1 flex items-center gap-2 text-foreground">
                    <Clock className="h-4 w-4 text-primary" />
                    {formatBigIntDuration(sessionToDelete.duration)}
                  </span>
                </span>
              )}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="gap-2 sm:gap-2">
            <Button
              variant="outline"
              onClick={() => {
                setDeleteDialogOpen(false);
                setSessionToDelete(null);
              }}
              disabled={deleteSession.isPending}
              data-ocid="tummytime.delete.cancel_button"
            >
              Atšaukti
            </Button>
            <Button
              variant="destructive"
              onClick={handleConfirmDelete}
              disabled={deleteSession.isPending}
              data-ocid="tummytime.delete.confirm_button"
            >
              {deleteSession.isPending ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Trynama...
                </>
              ) : (
                <>
                  <Trash2 className="h-4 w-4" />
                  Ištrinti
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
