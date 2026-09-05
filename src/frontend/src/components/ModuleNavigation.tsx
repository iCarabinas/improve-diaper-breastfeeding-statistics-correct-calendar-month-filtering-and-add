import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Activity,
  Apple,
  Archive,
  Baby,
  BookOpen,
  Droplets,
  Home,
  Milk,
  Scale,
  UtensilsCrossed,
} from "lucide-react";
import React from "react";

interface ModuleNavigationProps {
  activeModule:
    | "overview"
    | "diapers"
    | "breastfeeding"
    | "tummytime"
    | "weight"
    | "journal"
    | "pumping"
    | "feeding"
    | "solidfood"
    | "backup";
  onModuleChange: (
    module:
      | "overview"
      | "diapers"
      | "breastfeeding"
      | "tummytime"
      | "weight"
      | "journal"
      | "pumping"
      | "feeding"
      | "solidfood"
      | "backup",
  ) => void;
}

export default function ModuleNavigation({
  activeModule,
  onModuleChange,
}: ModuleNavigationProps) {
  const modules = [
    { id: "overview" as const, label: "Apžvalga", icon: Home },
    { id: "diapers" as const, label: "Pampersai", icon: Baby },
    { id: "breastfeeding" as const, label: "Žindymas", icon: Milk },
    { id: "tummytime" as const, label: "Pilvo Laikas", icon: Activity },
    { id: "weight" as const, label: "Svoris ir Ūgis", icon: Scale },
    { id: "journal" as const, label: "Žurnalas", icon: BookOpen },
    { id: "pumping" as const, label: "Pieno nutraukimas", icon: Droplets },
    { id: "feeding" as const, label: "Maitinimas", icon: UtensilsCrossed },
    { id: "solidfood" as const, label: "Primaitinimas", icon: Apple },
    { id: "backup" as const, label: "Atsarginė kopija", icon: Archive },
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Moduliai</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        {modules.map((module) => {
          const Icon = module.icon;
          return (
            <Button
              key={module.id}
              variant={activeModule === module.id ? "default" : "ghost"}
              className="w-full justify-start gap-2"
              onClick={() => onModuleChange(module.id)}
            >
              <Icon className="h-4 w-4" />
              {module.label}
            </Button>
          );
        })}
      </CardContent>
    </Card>
  );
}
