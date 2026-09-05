import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Edit2,
  Minus,
  Plus,
  Ruler,
  Scale,
  Trash2,
  TrendingDown,
  TrendingUp,
} from "lucide-react";
import type React from "react";
import { useState } from "react";
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { toast } from "sonner";
import {
  type HeightEntry,
  type WeightEntry,
  useAddHeightEntry,
  useAddWeightEntry,
  useDeleteHeightEntry,
  useDeleteWeightEntry,
  useGetHeightEntriesForChild,
  useGetWeightEntriesForChild,
  useUpdateHeightEntry,
  useUpdateWeightEntry,
} from "../hooks/useQueries";

interface WeightModuleProps {
  childId: string | null;
}

// ─── Weight Section ──────────────────────────────────────────────────────────

function WeightSection({ childId }: { childId: string }) {
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [weight, setWeight] = useState("");
  const [editingEntry, setEditingEntry] = useState<WeightEntry | null>(null);
  const [deletingEntry, setDeletingEntry] = useState<WeightEntry | null>(null);

  const { data: weightEntries = [] } = useGetWeightEntriesForChild(childId);
  const addWeightEntry = useAddWeightEntry();
  const updateWeightEntry = useUpdateWeightEntry();
  const deleteWeightEntry = useDeleteWeightEntry();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const weightValue = Number.parseFloat(weight);
    if (Number.isNaN(weightValue) || weightValue <= 0) {
      toast.error("Įveskite teisingą svorio reikšmę");
      return;
    }
    try {
      const selectedDate = new Date(date);
      selectedDate.setHours(12, 0, 0, 0);
      const timestamp = BigInt(selectedDate.getTime()) * BigInt(1_000_000);
      await addWeightEntry.mutateAsync({
        childId,
        weight: weightValue,
        timestamp,
      });
      toast.success("Svorio įrašas pridėtas!");
      setIsAddDialogOpen(false);
      setWeight("");
      setDate(new Date().toISOString().split("T")[0]);
    } catch (error) {
      console.error("Error adding weight entry:", error);
      toast.error("Nepavyko pridėti svorio įrašo");
    }
  };

  const handleEditClick = (entry: WeightEntry) => {
    setEditingEntry(entry);
    setWeight(entry.weight.toString());
    const entryDate = new Date(Number(entry.timestamp / BigInt(1_000_000)));
    setDate(entryDate.toISOString().split("T")[0]);
    setIsEditDialogOpen(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEntry) return;
    const weightValue = Number.parseFloat(weight);
    if (Number.isNaN(weightValue) || weightValue <= 0) {
      toast.error("Įveskite teisingą svorio reikšmę");
      return;
    }
    try {
      const selectedDate = new Date(date);
      selectedDate.setHours(12, 0, 0, 0);
      const timestamp = BigInt(selectedDate.getTime()) * BigInt(1_000_000);
      await updateWeightEntry.mutateAsync({
        childId,
        weightId: editingEntry.weightId,
        newWeight: weightValue,
        newTimestamp: timestamp,
      });
      toast.success("Svorio įrašas atnaujintas!");
      setIsEditDialogOpen(false);
      setEditingEntry(null);
      setWeight("");
      setDate(new Date().toISOString().split("T")[0]);
    } catch (error) {
      console.error("Error updating weight entry:", error);
      toast.error("Nepavyko atnaujinti svorio įrašo");
    }
  };

  const handleDeleteClick = (entry: WeightEntry) => {
    setDeletingEntry(entry);
    setIsDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!deletingEntry) return;
    try {
      await deleteWeightEntry.mutateAsync({
        childId,
        weightId: deletingEntry.weightId,
      });
      toast.success("Svorio įrašas ištrintas!");
      setIsDeleteDialogOpen(false);
      setDeletingEntry(null);
    } catch (error) {
      console.error("Error deleting weight entry:", error);
      toast.error("Nepavyko ištrinti svorio įrašo");
    }
  };

  const sortedEntries = [...weightEntries].sort((a, b) =>
    Number(a.timestamp - b.timestamp),
  );
  const chartData = sortedEntries.map((entry) => ({
    date: new Date(
      Number(entry.timestamp / BigInt(1_000_000)),
    ).toLocaleDateString("lt-LT", { month: "short", day: "numeric" }),
    weight: entry.weight,
    fullDate: new Date(
      Number(entry.timestamp / BigInt(1_000_000)),
    ).toLocaleDateString("lt-LT"),
  }));
  const latestEntry = sortedEntries[sortedEntries.length - 1];
  const previousEntry = sortedEntries[sortedEntries.length - 2];
  const weightChange =
    latestEntry && previousEntry
      ? latestEntry.weight - previousEntry.weight
      : 0;

  return (
    <>
      <Card>
        <CardHeader className="bg-gradient-to-r from-blue-100 to-indigo-100 dark:from-blue-950 dark:to-indigo-950">
          <CardTitle className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <img
                src="/assets/generated/weight-icon-transparent.dim_100x100.png"
                alt="Svoris"
                className="h-8 w-8 flex-shrink-0 object-contain"
              />
              <span className="truncate">Svoris</span>
            </div>
            <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
              <DialogTrigger asChild>
                <Button
                  size="sm"
                  className="gap-2"
                  data-ocid="weight.open_modal_button"
                >
                  <Plus className="h-4 w-4" />
                  Pridėti
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Pridėti svorio įrašą</DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <Label htmlFor="weight-date">Data</Label>
                    <Input
                      id="weight-date"
                      type="date"
                      value={date}
                      onChange={(e) => setDate(e.target.value)}
                      required
                      data-ocid="weight.date.input"
                    />
                  </div>
                  <div>
                    <Label htmlFor="weight-value">Svoris (kg)</Label>
                    <Input
                      id="weight-value"
                      type="number"
                      step="0.01"
                      min="0"
                      value={weight}
                      onChange={(e) => setWeight(e.target.value)}
                      placeholder="pvz., 4.5"
                      required
                      data-ocid="weight.input"
                    />
                  </div>
                  <div className="flex gap-3 justify-end">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => setIsAddDialogOpen(false)}
                    >
                      Atšaukti
                    </Button>
                    <Button
                      type="submit"
                      disabled={addWeightEntry.isPending}
                      data-ocid="weight.submit_button"
                    >
                      {addWeightEntry.isPending ? "Saugoma..." : "Išsaugoti"}
                    </Button>
                  </div>
                </form>
              </DialogContent>
            </Dialog>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          {sortedEntries.length === 0 ? (
            <div
              className="text-center py-12 text-muted-foreground"
              data-ocid="weight.empty_state"
            >
              <Scale className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Dar nėra svorio įrašų</p>
              <p className="text-sm mt-2">
                Pradėkite pridėdami pirmąjį matavimą
              </p>
            </div>
          ) : (
            <div className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="rounded-lg bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950/20 dark:to-indigo-950/20 p-4 border border-blue-200/50 dark:border-blue-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Dabartinis svoris
                  </h3>
                  <p className="text-2xl font-bold text-blue-700 dark:text-blue-400">
                    {latestEntry?.weight.toFixed(2)} kg
                  </p>
                </div>
                <div className="rounded-lg bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950/20 dark:to-indigo-950/20 p-4 border border-blue-200/50 dark:border-blue-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Pokytis
                  </h3>
                  <div className="flex items-center gap-2">
                    {weightChange > 0 ? (
                      <TrendingUp className="h-5 w-5 text-green-600 dark:text-green-400" />
                    ) : weightChange < 0 ? (
                      <TrendingDown className="h-5 w-5 text-red-600 dark:text-red-400" />
                    ) : (
                      <Minus className="h-5 w-5 text-muted-foreground" />
                    )}
                    <p
                      className={`text-2xl font-bold ${weightChange > 0 ? "text-green-700 dark:text-green-400" : weightChange < 0 ? "text-red-700 dark:text-red-400" : "text-muted-foreground"}`}
                    >
                      {weightChange > 0 ? "+" : ""}
                      {weightChange.toFixed(2)} kg
                    </p>
                  </div>
                </div>
                <div className="rounded-lg bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950/20 dark:to-indigo-950/20 p-4 border border-blue-200/50 dark:border-blue-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Įrašų skaičius
                  </h3>
                  <p className="text-2xl font-bold text-blue-700 dark:text-blue-400">
                    {sortedEntries.length}
                  </p>
                </div>
              </div>

              {chartData.length > 1 && (
                <div className="rounded-lg border bg-card p-4">
                  <h3 className="text-lg font-semibold mb-4">Augimo kreivė</h3>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={chartData}>
                      <CartesianGrid
                        strokeDasharray="3 3"
                        className="stroke-muted"
                      />
                      <XAxis
                        dataKey="date"
                        className="text-xs"
                        tick={{ fill: "hsl(var(--muted-foreground))" }}
                      />
                      <YAxis
                        className="text-xs"
                        tick={{ fill: "hsl(var(--muted-foreground))" }}
                        domain={["dataMin - 0.5", "dataMax + 0.5"]}
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "hsl(var(--card))",
                          border: "1px solid hsl(var(--border))",
                          borderRadius: "8px",
                        }}
                        labelStyle={{ color: "hsl(var(--foreground))" }}
                        formatter={(value: number) => [
                          `${value.toFixed(2)} kg`,
                          "Svoris",
                        ]}
                      />
                      <Line
                        type="monotone"
                        dataKey="weight"
                        stroke="hsl(var(--primary))"
                        strokeWidth={2}
                        dot={{ fill: "hsl(var(--primary))", r: 4 }}
                        activeDot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              )}

              <div className="rounded-lg border bg-card">
                <div className="p-4 border-b">
                  <h3 className="text-lg font-semibold">Istorija</h3>
                </div>
                <div className="divide-y max-h-96 overflow-y-auto">
                  {[...sortedEntries].reverse().map((entry, idx) => (
                    <div
                      key={entry.weightId}
                      className="p-4 flex justify-between items-center hover:bg-muted/50 transition-colors"
                      data-ocid={`weight.item.${idx + 1}`}
                    >
                      <div>
                        <p className="font-medium">
                          {entry.weight.toFixed(2)} kg
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {new Date(
                            Number(entry.timestamp / BigInt(1_000_000)),
                          ).toLocaleDateString("lt-LT", {
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </p>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleEditClick(entry)}
                          className="gap-2"
                          data-ocid={`weight.edit_button.${idx + 1}`}
                        >
                          <Edit2 className="h-4 w-4" />
                          Redaguoti
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => handleDeleteClick(entry)}
                          className="gap-2"
                          data-ocid={`weight.delete_button.${idx + 1}`}
                        >
                          <Trash2 className="h-4 w-4" />
                          Ištrinti
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Redaguoti svorio įrašą</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleEditSubmit} className="space-y-4">
            <div>
              <Label htmlFor="edit-weight-date">Data</Label>
              <Input
                id="edit-weight-date"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="edit-weight-value">Svoris (kg)</Label>
              <Input
                id="edit-weight-value"
                type="number"
                step="0.01"
                min="0"
                value={weight}
                onChange={(e) => setWeight(e.target.value)}
                placeholder="pvz., 4.5"
                required
              />
            </div>
            <div className="flex gap-3 justify-end">
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  setIsEditDialogOpen(false);
                  setEditingEntry(null);
                  setWeight("");
                  setDate(new Date().toISOString().split("T")[0]);
                }}
              >
                Atšaukti
              </Button>
              <Button
                type="submit"
                disabled={updateWeightEntry.isPending}
                data-ocid="weight.save_button"
              >
                {updateWeightEntry.isPending ? "Saugoma..." : "Išsaugoti"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog
        open={isDeleteDialogOpen}
        onOpenChange={setIsDeleteDialogOpen}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Ar tikrai norite ištrinti šį įrašą?
            </AlertDialogTitle>
            <AlertDialogDescription>
              Šis veiksmas negrįžtamas. Svorio įrašas bus visam laikui
              ištrintas.
              {deletingEntry && (
                <div className="mt-4 p-3 bg-muted rounded-md">
                  <p className="font-medium">
                    {deletingEntry.weight.toFixed(2)} kg
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(
                      Number(deletingEntry.timestamp / BigInt(1_000_000)),
                    ).toLocaleDateString("lt-LT", {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </p>
                </div>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setDeletingEntry(null)}>
              Atšaukti
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteConfirm}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteWeightEntry.isPending}
              data-ocid="weight.confirm_button"
            >
              {deleteWeightEntry.isPending ? "Trinama..." : "Ištrinti"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

// ─── Height Section ───────────────────────────────────────────────────────────

function HeightSection({ childId }: { childId: string }) {
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [height, setHeight] = useState("");
  const [editingEntry, setEditingEntry] = useState<HeightEntry | null>(null);
  const [deletingEntry, setDeletingEntry] = useState<HeightEntry | null>(null);

  const { data: heightEntries = [] } = useGetHeightEntriesForChild(childId);
  const addHeightEntry = useAddHeightEntry();
  const updateHeightEntry = useUpdateHeightEntry();
  const deleteHeightEntry = useDeleteHeightEntry();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const heightValue = Number.parseFloat(height);
    if (Number.isNaN(heightValue) || heightValue <= 0) {
      toast.error("Įveskite teisingą ūgio reikšmę");
      return;
    }
    try {
      const selectedDate = new Date(date);
      selectedDate.setHours(12, 0, 0, 0);
      const timestamp = BigInt(selectedDate.getTime()) * BigInt(1_000_000);
      await addHeightEntry.mutateAsync({
        childId,
        height: heightValue,
        timestamp,
      });
      toast.success("Ūgio įrašas pridėtas!");
      setIsAddDialogOpen(false);
      setHeight("");
      setDate(new Date().toISOString().split("T")[0]);
    } catch (error) {
      console.error("Error adding height entry:", error);
      toast.error("Nepavyko pridėti ūgio įrašo");
    }
  };

  const handleEditClick = (entry: HeightEntry) => {
    setEditingEntry(entry);
    setHeight(entry.height.toString());
    const entryDate = new Date(Number(entry.timestamp / BigInt(1_000_000)));
    setDate(entryDate.toISOString().split("T")[0]);
    setIsEditDialogOpen(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingEntry) return;
    const heightValue = Number.parseFloat(height);
    if (Number.isNaN(heightValue) || heightValue <= 0) {
      toast.error("Įveskite teisingą ūgio reikšmę");
      return;
    }
    try {
      const selectedDate = new Date(date);
      selectedDate.setHours(12, 0, 0, 0);
      const timestamp = BigInt(selectedDate.getTime()) * BigInt(1_000_000);
      await updateHeightEntry.mutateAsync({
        childId,
        heightId: editingEntry.heightId,
        newHeight: heightValue,
        newTimestamp: timestamp,
      });
      toast.success("Ūgio įrašas atnaujintas!");
      setIsEditDialogOpen(false);
      setEditingEntry(null);
      setHeight("");
      setDate(new Date().toISOString().split("T")[0]);
    } catch (error) {
      console.error("Error updating height entry:", error);
      toast.error("Nepavyko atnaujinti ūgio įrašo");
    }
  };

  const handleDeleteClick = (entry: HeightEntry) => {
    setDeletingEntry(entry);
    setIsDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!deletingEntry) return;
    try {
      await deleteHeightEntry.mutateAsync({
        childId,
        heightId: deletingEntry.heightId,
      });
      toast.success("Ūgio įrašas ištrintas!");
      setIsDeleteDialogOpen(false);
      setDeletingEntry(null);
    } catch (error) {
      console.error("Error deleting height entry:", error);
      toast.error("Nepavyko ištrinti ūgio įrašo");
    }
  };

  const sortedEntries = [...heightEntries].sort((a, b) =>
    Number(a.timestamp - b.timestamp),
  );
  const chartData = sortedEntries.map((entry) => ({
    date: new Date(
      Number(entry.timestamp / BigInt(1_000_000)),
    ).toLocaleDateString("lt-LT", { month: "short", day: "numeric" }),
    height: entry.height,
    fullDate: new Date(
      Number(entry.timestamp / BigInt(1_000_000)),
    ).toLocaleDateString("lt-LT"),
  }));
  const latestEntry = sortedEntries[sortedEntries.length - 1];
  const previousEntry = sortedEntries[sortedEntries.length - 2];
  const heightChange =
    latestEntry && previousEntry
      ? latestEntry.height - previousEntry.height
      : 0;

  return (
    <>
      <Card>
        <CardHeader className="bg-gradient-to-r from-emerald-100 to-teal-100 dark:from-emerald-950 dark:to-teal-950">
          <CardTitle className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <Ruler className="h-8 w-8 flex-shrink-0 text-emerald-600 dark:text-emerald-400" />
              <span className="truncate">Ūgis</span>
            </div>
            <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
              <DialogTrigger asChild>
                <Button
                  size="sm"
                  className="gap-2 bg-emerald-600 hover:bg-emerald-700 text-white"
                  data-ocid="height.open_modal_button"
                >
                  <Plus className="h-4 w-4" />
                  Pridėti
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Pridėti ūgio įrašą</DialogTitle>
                </DialogHeader>
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <Label htmlFor="height-date">Data</Label>
                    <Input
                      id="height-date"
                      type="date"
                      value={date}
                      onChange={(e) => setDate(e.target.value)}
                      required
                      data-ocid="height.date.input"
                    />
                  </div>
                  <div>
                    <Label htmlFor="height-value">Ūgis (cm)</Label>
                    <Input
                      id="height-value"
                      type="number"
                      step="0.1"
                      min="0"
                      max="200"
                      value={height}
                      onChange={(e) => setHeight(e.target.value)}
                      placeholder="pvz., 54.5"
                      required
                      data-ocid="height.input"
                    />
                  </div>
                  <div className="flex gap-3 justify-end">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => setIsAddDialogOpen(false)}
                    >
                      Atšaukti
                    </Button>
                    <Button
                      type="submit"
                      disabled={addHeightEntry.isPending}
                      data-ocid="height.submit_button"
                    >
                      {addHeightEntry.isPending ? "Saugoma..." : "Išsaugoti"}
                    </Button>
                  </div>
                </form>
              </DialogContent>
            </Dialog>
          </CardTitle>
        </CardHeader>
        <CardContent className="pt-6">
          {sortedEntries.length === 0 ? (
            <div
              className="text-center py-12 text-muted-foreground"
              data-ocid="height.empty_state"
            >
              <Ruler className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Dar nėra ūgio įrašų</p>
              <p className="text-sm mt-2">
                Pradėkite pridėdami pirmąjį matavimą
              </p>
            </div>
          ) : (
            <div className="space-y-6">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div className="rounded-lg bg-gradient-to-br from-emerald-50 to-teal-50 dark:from-emerald-950/20 dark:to-teal-950/20 p-4 border border-emerald-200/50 dark:border-emerald-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Dabartinis ūgis
                  </h3>
                  <p className="text-2xl font-bold text-emerald-700 dark:text-emerald-400">
                    {latestEntry?.height.toFixed(1)} cm
                  </p>
                </div>
                <div className="rounded-lg bg-gradient-to-br from-emerald-50 to-teal-50 dark:from-emerald-950/20 dark:to-teal-950/20 p-4 border border-emerald-200/50 dark:border-emerald-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Pokytis
                  </h3>
                  <div className="flex items-center gap-2">
                    {heightChange > 0 ? (
                      <TrendingUp className="h-5 w-5 text-green-600 dark:text-green-400" />
                    ) : heightChange < 0 ? (
                      <TrendingDown className="h-5 w-5 text-red-600 dark:text-red-400" />
                    ) : (
                      <Minus className="h-5 w-5 text-muted-foreground" />
                    )}
                    <p
                      className={`text-2xl font-bold ${heightChange > 0 ? "text-green-700 dark:text-green-400" : heightChange < 0 ? "text-red-700 dark:text-red-400" : "text-muted-foreground"}`}
                    >
                      {heightChange > 0 ? "+" : ""}
                      {heightChange.toFixed(1)} cm
                    </p>
                  </div>
                </div>
                <div className="rounded-lg bg-gradient-to-br from-emerald-50 to-teal-50 dark:from-emerald-950/20 dark:to-teal-950/20 p-4 border border-emerald-200/50 dark:border-emerald-800/50">
                  <h3 className="text-sm font-medium text-muted-foreground mb-1">
                    Įrašų skaičius
                  </h3>
                  <p className="text-2xl font-bold text-emerald-700 dark:text-emerald-400">
                    {sortedEntries.length}
                  </p>
                </div>
              </div>

              {chartData.length > 1 && (
                <div className="rounded-lg border bg-card p-4">
                  <h3 className="text-lg font-semibold mb-4">Ūgio kreivė</h3>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={chartData}>
                      <CartesianGrid
                        strokeDasharray="3 3"
                        className="stroke-muted"
                      />
                      <XAxis
                        dataKey="date"
                        className="text-xs"
                        tick={{ fill: "hsl(var(--muted-foreground))" }}
                      />
                      <YAxis
                        className="text-xs"
                        tick={{ fill: "hsl(var(--muted-foreground))" }}
                        domain={["dataMin - 1", "dataMax + 1"]}
                        unit=" cm"
                      />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: "hsl(var(--card))",
                          border: "1px solid hsl(var(--border))",
                          borderRadius: "8px",
                        }}
                        labelStyle={{ color: "hsl(var(--foreground))" }}
                        formatter={(value: number) => [
                          `${value.toFixed(1)} cm`,
                          "Ūgis",
                        ]}
                      />
                      <Line
                        type="monotone"
                        dataKey="height"
                        stroke="hsl(var(--primary))"
                        strokeWidth={2}
                        dot={{ fill: "hsl(var(--primary))", r: 4 }}
                        activeDot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              )}

              <div className="rounded-lg border bg-card">
                <div className="p-4 border-b">
                  <h3 className="text-lg font-semibold">Istorija</h3>
                </div>
                <div className="divide-y max-h-96 overflow-y-auto">
                  {[...sortedEntries].reverse().map((entry, idx) => (
                    <div
                      key={entry.heightId}
                      className="p-4 flex justify-between items-center hover:bg-muted/50 transition-colors"
                      data-ocid={`height.item.${idx + 1}`}
                    >
                      <div>
                        <p className="font-medium">
                          {entry.height.toFixed(1)} cm
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {new Date(
                            Number(entry.timestamp / BigInt(1_000_000)),
                          ).toLocaleDateString("lt-LT", {
                            year: "numeric",
                            month: "long",
                            day: "numeric",
                          })}
                        </p>
                      </div>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleEditClick(entry)}
                          className="gap-2"
                          data-ocid={`height.edit_button.${idx + 1}`}
                        >
                          <Edit2 className="h-4 w-4" />
                          Redaguoti
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => handleDeleteClick(entry)}
                          className="gap-2"
                          data-ocid={`height.delete_button.${idx + 1}`}
                        >
                          <Trash2 className="h-4 w-4" />
                          Ištrinti
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Redaguoti ūgio įrašą</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleEditSubmit} className="space-y-4">
            <div>
              <Label htmlFor="edit-height-date">Data</Label>
              <Input
                id="edit-height-date"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="edit-height-value">Ūgis (cm)</Label>
              <Input
                id="edit-height-value"
                type="number"
                step="0.1"
                min="0"
                max="200"
                value={height}
                onChange={(e) => setHeight(e.target.value)}
                placeholder="pvz., 54.5"
                required
              />
            </div>
            <div className="flex gap-3 justify-end">
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  setIsEditDialogOpen(false);
                  setEditingEntry(null);
                  setHeight("");
                  setDate(new Date().toISOString().split("T")[0]);
                }}
              >
                Atšaukti
              </Button>
              <Button
                type="submit"
                disabled={updateHeightEntry.isPending}
                data-ocid="height.save_button"
              >
                {updateHeightEntry.isPending ? "Saugoma..." : "Išsaugoti"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog
        open={isDeleteDialogOpen}
        onOpenChange={setIsDeleteDialogOpen}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              Ar tikrai norite ištrinti šį įrašą?
            </AlertDialogTitle>
            <AlertDialogDescription>
              Šis veiksmas negrįžtamas. Ūgio įrašas bus visam laikui ištrintas.
              {deletingEntry && (
                <div className="mt-4 p-3 bg-muted rounded-md">
                  <p className="font-medium">
                    {deletingEntry.height.toFixed(1)} cm
                  </p>
                  <p className="text-sm text-muted-foreground">
                    {new Date(
                      Number(deletingEntry.timestamp / BigInt(1_000_000)),
                    ).toLocaleDateString("lt-LT", {
                      year: "numeric",
                      month: "long",
                      day: "numeric",
                    })}
                  </p>
                </div>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setDeletingEntry(null)}>
              Atšaukti
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteConfirm}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              disabled={deleteHeightEntry.isPending}
              data-ocid="height.confirm_button"
            >
              {deleteHeightEntry.isPending ? "Trinama..." : "Ištrinti"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}

// ─── WeightModule (parent) ────────────────────────────────────────────────────

export default function WeightModule({ childId }: WeightModuleProps) {
  if (!childId) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted-foreground">
          Pasirinkite vaiką, kad pradėtumėte sekti svorį ir ūgį
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-8 max-w-full overflow-hidden">
      <WeightSection childId={childId} />

      {/* Separator */}
      <div className="flex items-center gap-4">
        <div className="flex-1 h-px bg-border" />
        <span className="text-sm font-semibold text-muted-foreground uppercase tracking-wider px-2">
          Ūgio sekimas
        </span>
        <div className="flex-1 h-px bg-border" />
      </div>

      <HeightSection childId={childId} />
    </div>
  );
}
