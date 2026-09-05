import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertTriangle,
  CheckCircle2,
  Download,
  FileUp,
  Loader2,
  ShieldCheck,
} from "lucide-react";
import { useRef, useState } from "react";
import { toast } from "sonner";
import type { ImportCounts, ImportResult } from "../backend";
import { useExportAllData, useImportAllData } from "../hooks/useQueries";

interface BackupSectionProps {
  onDataRestored?: () => void;
}

interface CountRow {
  key: keyof ImportCounts;
  label: string;
  sourceKey: string;
}

const COUNT_ROWS: CountRow[] = [
  { key: "childProfiles", label: "Vaikų profiliai", sourceKey: "children" },
  { key: "diaperLogs", label: "Vystyklai", sourceKey: "diaperLogs" },
  {
    key: "breastfeedingSessions",
    label: "Žindymas",
    sourceKey: "breastfeedingSessions",
  },
  {
    key: "tummyTimeSessions",
    label: "Pilvo laikas",
    sourceKey: "tummyTimeSessions",
  },
  { key: "weightEntries", label: "Svoris", sourceKey: "weightEntries" },
  { key: "heightEntries", label: "Ūgis", sourceKey: "heightEntries" },
  { key: "journalNotes", label: "Žurnalas", sourceKey: "journalNotes" },
  {
    key: "milkPumpingSessions",
    label: "Pieno nutraukimas",
    sourceKey: "milkPumpingSessions",
  },
  {
    key: "solidFoodEntries",
    label: "Primaitinimas",
    sourceKey: "solidFoodEntries",
  },
  { key: "feedingSessions", label: "Maitinimas", sourceKey: "feedingSessions" },
  {
    key: "activeTimers",
    label: "Aktyvūs laikmačiai",
    sourceKey: "activeTimers",
  },
  {
    key: "tummyTimeTimers",
    label: "Pilvo laiko laikmačiai",
    sourceKey: "tummyTimeTimers",
  },
  {
    key: "childInviteLinks",
    label: "Kvietimų nuorodos",
    sourceKey: "childInviteLinks",
  },
  {
    key: "userProfiles",
    label: "Vartotojų profiliai",
    sourceKey: "userProfile",
  },
];

function formatCount(value: bigint): string {
  return value.toString();
}

function totalCount(counts: ImportCounts): bigint {
  return Object.values(counts).reduce((sum, entry) => sum + entry.restored, 0n);
}

// Compute a preview of how many entries of each type exist in the backup file
// by reading the top-level arrays of the exported JSON. This mirrors the
// backend's ImportCounts shape so the confirmation modal can show counts.
function computePreviewCounts(parsed: Record<string, unknown>): {
  [K in keyof ImportCounts]: { restored: bigint; skipped: bigint };
} {
  const result = {} as {
    [K in keyof ImportCounts]: { restored: bigint; skipped: bigint };
  };
  for (const row of COUNT_ROWS) {
    const value = parsed[row.sourceKey];
    const count = Array.isArray(value) ? BigInt(value.length) : value ? 1n : 0n;
    result[row.key] = { restored: count, skipped: 0n };
  }
  return result;
}

export default function BackupSection({ onDataRestored }: BackupSectionProps) {
  const exportMutation = useExportAllData();
  const importMutation = useImportAllData();

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [pendingFile, setPendingFile] = useState<File | null>(null);
  const [pendingBlob, setPendingBlob] = useState<string | null>(null);
  const [previewCounts, setPreviewCounts] = useState<
    | {
        [K in keyof ImportCounts]: { restored: bigint; skipped: bigint };
      }
    | null
  >(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [exportedAt, setExportedAt] = useState<string | null>(null);
  const [importProgress, setImportProgress] = useState<{
    done: number;
    total: number;
  } | null>(null);

  const handleExport = () => {
    exportMutation.mutate(undefined, {
      onSuccess: (jsonText) => {
        try {
          const parsed = JSON.parse(jsonText);
          const timestamp =
            typeof parsed.exportedAt === "number"
              ? new Date(parsed.exportedAt / 1_000_000)
              : new Date();
          const dateStr = timestamp.toISOString().slice(0, 10);
          const filename = `frejos-zurnalas-backup-${dateStr}.json`;

          const blob = new Blob([jsonText], {
            type: "application/json",
          });
          const url = URL.createObjectURL(blob);
          const link = document.createElement("a");
          link.href = url;
          link.download = filename;
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
          URL.revokeObjectURL(url);

          setExportedAt(dateStr);
          toast.success("Atsarginė kopija eksportuota sėkmingai!", {
            description: `Failas ${filename} atsisiųstas.`,
          });
        } catch (_error) {
          toast.error("Eksporto duomenys netinkami", {
            description: "Nepavyko sugeneruoti atsarginės kopijos failo.",
          });
        }
      },
      onError: (error: Error) => {
        toast.error("Eksportas nepavyko", {
          description: error.message || "Bandykite dar kartą vėliau.",
        });
      },
    });
  };

  const handleFileSelected = (file: File) => {
    if (!file) return;
    if (!file.name.toLowerCase().endsWith(".json")) {
      toast.error("Netinkamas failo formatas", {
        description: "Pasirinkite .json atsarginės kopijos failą.",
      });
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const text = String(reader.result || "");
      let parsed: Record<string, unknown>;
      try {
        parsed = JSON.parse(text);
      } catch (_error) {
        toast.error("Netinkamas failo turinys", {
          description: "Failas nėra tinkama JSON atsarginė kopija.",
        });
        return;
      }
      if (parsed.formatVersion !== 1) {
        toast.error("Nesuderinamas atsarginės kopijos formatas", {
          description: "Ši programa nepalaiko šio failo formato versijos.",
        });
        return;
      }
      setPendingFile(file);
      setPendingBlob(text);
      setPreviewCounts(computePreviewCounts(parsed));
      setConfirmOpen(true);
    };
    reader.onerror = () => {
      toast.error("Nepavyko perskaityti failo", {
        description: "Bandykite pasirinkti failą dar kartą.",
      });
    };
    reader.readAsText(file);
  };

  const handleConfirmImport = () => {
    if (!pendingBlob) return;
    setConfirmOpen(false);
    setImportProgress(null);
    importMutation.mutate(
      {
        blob: pendingBlob,
        onProgress: (done, total) => setImportProgress({ done, total }),
      },
      {
        onSuccess: (result) => {
          setImportProgress(null);
          setImportResult(result);
          setPendingFile(null);
          setPendingBlob(null);
          setPreviewCounts(null);
          if (fileInputRef.current) {
            fileInputRef.current.value = "";
          }
          if (onDataRestored) {
            onDataRestored();
          }
          if (result.success) {
            toast.success("Atsarginė kopija atkūrta!", {
              description: `${result.totalRestored.toString()} įrašai atkurti.`,
            });
          } else {
            toast.error("Importas nepavyko", {
              description: "Duomenys nebuvo atkurti.",
            });
          }
        },
        onError: (error: Error) => {
          setImportProgress(null);
          setPendingFile(null);
          setPendingBlob(null);
          setPreviewCounts(null);
          if (fileInputRef.current) {
            fileInputRef.current.value = "";
          }
          toast.error("Importas nepavyko", {
            description:
              error.message || "Failas netinkamas arba nesuderinamas.",
          });
        },
      },
    );
  };

  const handleCancelImport = () => {
    setConfirmOpen(false);
    setPendingFile(null);
    setPendingBlob(null);
    setPreviewCounts(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const restoredTotal = importResult ? totalCount(importResult.counts) : 0n;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Atsarginė kopija</h2>
        <p className="mt-1 text-muted-foreground">
          Eksportuokite arba atkurkite visus savo duomenis vienu failu.
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Export card */}
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Download className="h-5 w-5 text-primary" />
              Eksportuoti
            </CardTitle>
            <CardDescription>
              Atsisiųskite visus savo duomenis kaip JSON failą — vaikų profilius
              ir visus įrašus.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <Button
              data-ocid="backup.export_button"
              className="w-full"
              size="lg"
              onClick={handleExport}
              disabled={exportMutation.isPending}
            >
              {exportMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Download className="h-4 w-4" />
              )}
              {exportMutation.isPending
                ? "Eksportuojama..."
                : "Eksportuoti duomenis"}
            </Button>
            {exportedAt && (
              <p className="text-sm text-muted-foreground">
                Paskutinė kopija: {exportedAt}
              </p>
            )}
          </CardContent>
        </Card>

        {/* Import card */}
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileUp className="h-5 w-5 text-primary" />
              Importuoti
            </CardTitle>
            <CardDescription>
              Atkurkite duomenis iš anksčiau eksportuotos atsarginės kopijos
              failo.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <input
              ref={fileInputRef}
              type="file"
              accept=".json,application/json"
              className="hidden"
              data-ocid="backup.import_input"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFileSelected(file);
              }}
            />
            <Button
              data-ocid="backup.import_button"
              variant="outline"
              className="w-full"
              size="lg"
              onClick={() => fileInputRef.current?.click()}
              disabled={importMutation.isPending}
            >
              {importMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <FileUp className="h-4 w-4" />
              )}
              {importMutation.isPending
                ? importProgress && importProgress.total > 1
                  ? `Importuojama... ${importProgress.done}/${importProgress.total}`
                  : "Importuojama..."
                : "Importuoti atsarginę kopiją"}
            </Button>
            <p className="text-xs text-muted-foreground">
              Pasirinkite .json failą, kad peržiūrėtumėte, kas bus atkurta.
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Import success summary */}
      {importResult && (
        <Card className="border-success/40 bg-success/5 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-success">
              <CheckCircle2 className="h-5 w-5" />
              Atsarginė kopija atkūrta
            </CardTitle>
            <CardDescription>
              {importResult.success
                ? `${restoredTotal.toString()} įrašai atkurti, ${importResult.totalSkipped.toString()} praleisti.`
                : "Importas nepavyko — duomenys nebuvo pakeisti."}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-hidden rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-muted/60">
                  <tr>
                    <th className="px-4 py-2 text-left font-medium">
                      Duomenų tipas
                    </th>
                    <th className="px-4 py-2 text-right font-medium">
                      Atkurta
                    </th>
                    <th className="px-4 py-2 text-right font-medium">
                      Praleista
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {COUNT_ROWS.map((row) => {
                    const entry = importResult.counts[row.key];
                    if (!entry) return null;
                    return (
                      <tr key={row.key} className="border-t border-border/60">
                        <td className="px-4 py-2">{row.label}</td>
                        <td className="px-4 py-2 text-right">
                          {formatCount(entry.restored)}
                        </td>
                        <td className="px-4 py-2 text-right">
                          {formatCount(entry.skipped)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Confirmation modal */}
      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-warning" />
              Patvirtinti importą
            </DialogTitle>
            <DialogDescription>
              Importas įrašys duomenis į programą. Ar tikrai norite tęsti?
            </DialogDescription>
          </DialogHeader>

          {pendingFile && previewCounts && (
            <div className="rounded-lg border border-border bg-muted/40 p-4">
              <p className="mb-3 text-sm font-medium">
                Failas: {pendingFile.name}
              </p>
              <div className="space-y-1.5">
                {COUNT_ROWS.map((row) => {
                  const entry = previewCounts[row.key];
                  if (!entry || entry.restored === 0n) return null;
                  return (
                    <div
                      key={row.key}
                      className="flex items-center justify-between text-sm"
                    >
                      <span className="text-muted-foreground">{row.label}</span>
                      <span className="font-medium">
                        {formatCount(entry.restored)}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          <DialogFooter>
            <Button
              data-ocid="backup.import_cancel_button"
              variant="outline"
              onClick={handleCancelImport}
            >
              Atšaukti
            </Button>
            <Button
              data-ocid="backup.import_confirm_button"
              onClick={handleConfirmImport}
              disabled={importMutation.isPending}
            >
              {importMutation.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <ShieldCheck className="h-4 w-4" />
              )}
              Patvirtinti importą
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
