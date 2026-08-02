import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { listPromotions, setPromotionActive } from "@/lib/api/promotions";
import { PageHeader } from "@/components/PageHeader";
import { Button } from "@/components/Button";
import { Badge } from "@/components/Badge";
import { DataTable, type DataTableColumn } from "@/components/DataTable";
import { EmptyState } from "@/components/EmptyState";
import { Spinner, ErrorState } from "@/components/Spinner";
import { useRole } from "@/features/auth/useRole";
import { DEFAULT_STORE_URL, type Promotion } from "@/lib/api/types";
import { PromotionFormModal } from "./PromotionFormModal";

function promotionStatus(p: Promotion): { label: string; tone: "success" | "neutral" | "warning" } {
  if (!p.active) return { label: "Inativa", tone: "neutral" };
  const now = Date.now();
  const starts = new Date(p.startsAt).getTime();
  const ends = p.endsAt ? new Date(p.endsAt).getTime() : null;
  if (starts > now) return { label: "Agendada", tone: "warning" };
  if (ends && ends < now) return { label: "Expirada", tone: "neutral" };
  return { label: "No ar", tone: "success" };
}

export function StorePromotionsPage() {
  const { canWrite } = useRole();
  const queryClient = useQueryClient();
  const [formOpen, setFormOpen] = useState(false);
  const [editingPromotion, setEditingPromotion] = useState<Promotion | null>(null);

  const promotionsQuery = useQuery({
    queryKey: ["promotions"],
    queryFn: listPromotions,
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      setPromotionActive(id, active),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["promotions"] }),
  });

  const columns: Array<DataTableColumn<Promotion>> = [
    {
      key: "title",
      header: "Promoção",
      render: (p) => (
        <div>
          <p className="font-medium text-slate-800">{p.title}</p>
          <p className="max-w-sm truncate text-xs text-slate-400">{p.description}</p>
        </div>
      ),
    },
    {
      key: "period",
      header: "Período",
      render: (p) => (
        <span className="text-xs text-slate-500">
          {new Date(p.startsAt).toLocaleDateString("pt-BR")} —{" "}
          {p.endsAt ? new Date(p.endsAt).toLocaleDateString("pt-BR") : "sem data final"}
        </span>
      ),
    },
    {
      key: "link",
      header: "Link",
      render: (p) => (
        <a
          href={p.linkUrl}
          target="_blank"
          rel="noreferrer"
          className="text-xs text-coral-600 underline underline-offset-2"
        >
          {p.linkUrl.replace(/^https?:\/\//, "")}
        </a>
      ),
    },
    {
      key: "status",
      header: "Status",
      render: (p) => {
        const status = promotionStatus(p);
        return <Badge tone={status.tone}>{status.label}</Badge>;
      },
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (p) =>
        canWrite ? (
          <div className="flex justify-end gap-2">
            <Button
              variant="ghost"
              className="px-2 py-1 text-xs"
              onClick={() => toggleActiveMutation.mutate({ id: p.id, active: !p.active })}
              loading={
                toggleActiveMutation.isPending &&
                toggleActiveMutation.variables?.id === p.id
              }
            >
              {p.active ? "Desativar" : "Ativar"}
            </Button>
            <Button
              variant="secondary"
              className="px-2 py-1 text-xs"
              onClick={() => {
                setEditingPromotion(p);
                setFormOpen(true);
              }}
            >
              Editar
            </Button>
          </div>
        ) : null,
    },
  ];

  return (
    <div>
      <PageHeader
        title="Loja & Promoções"
        description={`Conteúdo exibido na área "Loja TogPlay" do app e no banner permanente. Link padrão: ${DEFAULT_STORE_URL}`}
        action={
          canWrite && (
            <Button
              onClick={() => {
                setEditingPromotion(null);
                setFormOpen(true);
              }}
            >
              + Nova promoção
            </Button>
          )
        }
      />

      {promotionsQuery.isLoading && <Spinner />}
      {promotionsQuery.isError && <ErrorState onRetry={() => promotionsQuery.refetch()} />}
      {promotionsQuery.isSuccess && promotionsQuery.data.length === 0 && (
        <EmptyState
          title="Nenhuma promoção cadastrada"
          description="Crie uma promoção para exibir na Loja TogPlay do app."
        />
      )}
      {promotionsQuery.isSuccess && promotionsQuery.data.length > 0 && (
        <DataTable columns={columns} rows={promotionsQuery.data} getRowKey={(p) => p.id} />
      )}

      <PromotionFormModal
        open={formOpen}
        promotion={editingPromotion}
        onClose={() => setFormOpen(false)}
      />
    </div>
  );
}
