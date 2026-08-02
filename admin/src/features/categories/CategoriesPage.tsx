import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { listCategories, setCategoryActive } from "@/lib/api/categories";
import { PageHeader } from "@/components/PageHeader";
import { Button } from "@/components/Button";
import { Badge } from "@/components/Badge";
import { DataTable, type DataTableColumn } from "@/components/DataTable";
import { EmptyState } from "@/components/EmptyState";
import { Spinner, ErrorState } from "@/components/Spinner";
import { useRole } from "@/features/auth/useRole";
import type { Category } from "@/lib/api/types";
import { CategoryFormModal } from "./CategoryFormModal";

export function CategoriesPage() {
  const { canWrite } = useRole();
  const queryClient = useQueryClient();
  const [formOpen, setFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  const categoriesQuery = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      setCategoryActive(id, active),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["categories"] }),
  });

  const columns: Array<DataTableColumn<Category>> = [
    {
      key: "name",
      header: "Nome",
      render: (c) => (
        <div className="flex items-center gap-2">
          <span
            className="flex h-7 w-7 items-center justify-center rounded-full text-sm"
            style={{ backgroundColor: `${c.color}22` }}
            aria-hidden
          >
            {c.icon}
          </span>
          <span className="font-medium text-slate-800">{c.name}</span>
        </div>
      ),
    },
    { key: "slug", header: "Slug", render: (c) => <code className="text-xs text-slate-500">{c.slug}</code> },
    { key: "order", header: "Ordem", render: (c) => c.order },
    {
      key: "status",
      header: "Status",
      render: (c) => (
        <Badge tone={c.active ? "success" : "neutral"}>{c.active ? "Ativa" : "Inativa"}</Badge>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (c) =>
        canWrite ? (
          <div className="flex justify-end gap-2">
            <Button
              variant="ghost"
              className="px-2 py-1 text-xs"
              onClick={() => toggleActiveMutation.mutate({ id: c.id, active: !c.active })}
              loading={
                toggleActiveMutation.isPending &&
                toggleActiveMutation.variables?.id === c.id
              }
            >
              {c.active ? "Desativar" : "Ativar"}
            </Button>
            <Button
              variant="secondary"
              className="px-2 py-1 text-xs"
              onClick={() => {
                setEditingCategory(c);
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
        title="Categorias"
        description="Organize as categorias de áudio exibidas no app."
        action={
          canWrite && (
            <Button
              onClick={() => {
                setEditingCategory(null);
                setFormOpen(true);
              }}
            >
              + Nova categoria
            </Button>
          )
        }
      />

      {categoriesQuery.isLoading && <Spinner />}
      {categoriesQuery.isError && <ErrorState onRetry={() => categoriesQuery.refetch()} />}
      {categoriesQuery.isSuccess && categoriesQuery.data.length === 0 && (
        <EmptyState
          title="Nenhuma categoria cadastrada"
          description="Crie a primeira categoria para organizar os áudios."
        />
      )}
      {categoriesQuery.isSuccess && categoriesQuery.data.length > 0 && (
        <DataTable columns={columns} rows={categoriesQuery.data} getRowKey={(c) => c.id} />
      )}

      <CategoryFormModal
        open={formOpen}
        category={editingCategory}
        onClose={() => setFormOpen(false)}
      />
    </div>
  );
}
