import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { listAudios, deleteAudio, setAudioActive } from "@/lib/api/audios";
import { listCategories } from "@/lib/api/categories";
import { PageHeader } from "@/components/PageHeader";
import { Button } from "@/components/Button";
import { Badge } from "@/components/Badge";
import { DataTable, type DataTableColumn } from "@/components/DataTable";
import { EmptyState } from "@/components/EmptyState";
import { Spinner, ErrorState } from "@/components/Spinner";
import { ConfirmDialog } from "@/components/ConfirmDialog";
import { useRole } from "@/features/auth/useRole";
import type { Audio } from "@/lib/api/types";
import { AudioFormModal } from "./AudioFormModal";

export function AudiosPage() {
  const { canWrite } = useRole();
  const queryClient = useQueryClient();

  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [statusFilter, setStatusFilter] = useState<"" | "active" | "inactive">("");
  const [search, setSearch] = useState("");

  const [formOpen, setFormOpen] = useState(false);
  const [editingAudio, setEditingAudio] = useState<Audio | null>(null);
  const [deletingAudio, setDeletingAudio] = useState<Audio | null>(null);

  const categoriesQuery = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
  });

  const audiosQuery = useQuery({
    queryKey: ["audios", categoryFilter, statusFilter],
    queryFn: () =>
      listAudios({
        categoryId: categoryFilter || undefined,
        active:
          statusFilter === "active" ? true : statusFilter === "inactive" ? false : undefined,
      }),
  });

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      setAudioActive(id, active),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["audios"] }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteAudio(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["audios"] });
      setDeletingAudio(null);
    },
  });

  const categoryById = useMemo(() => {
    const map = new Map<string, string>();
    for (const c of categoriesQuery.data ?? []) map.set(c.id, c.name);
    return map;
  }, [categoriesQuery.data]);

  const filteredAudios = useMemo(() => {
    const items = audiosQuery.data ?? [];
    if (!search.trim()) return items;
    const needle = search.trim().toLowerCase();
    return items.filter(
      (a) =>
        a.title.toLowerCase().includes(needle) ||
        a.phraseText.toLowerCase().includes(needle),
    );
  }, [audiosQuery.data, search]);

  const columns: Array<DataTableColumn<Audio>> = [
    {
      key: "title",
      header: "Título",
      render: (a) => (
        <div>
          <p className="font-medium text-slate-800">{a.title}</p>
          <p className="max-w-xs truncate text-xs text-slate-400">{a.phraseText}</p>
        </div>
      ),
    },
    {
      key: "category",
      header: "Categoria",
      render: (a) => categoryById.get(a.categoryId) ?? a.categoryId,
    },
    {
      key: "plays",
      header: "Reproduções",
      render: (a) => a.playCount.toLocaleString("pt-BR"),
    },
    {
      key: "status",
      header: "Status",
      render: (a) => (
        <Badge tone={a.active ? "success" : "neutral"}>
          {a.active ? "Ativo" : "Inativo"}
        </Badge>
      ),
    },
    {
      key: "actions",
      header: "",
      className: "text-right",
      render: (a) =>
        canWrite ? (
          <div className="flex justify-end gap-2">
            <Button
              variant="ghost"
              className="px-2 py-1 text-xs"
              onClick={() => toggleActiveMutation.mutate({ id: a.id, active: !a.active })}
              loading={
                toggleActiveMutation.isPending &&
                toggleActiveMutation.variables?.id === a.id
              }
            >
              {a.active ? "Desativar" : "Ativar"}
            </Button>
            <Button
              variant="secondary"
              className="px-2 py-1 text-xs"
              onClick={() => {
                setEditingAudio(a);
                setFormOpen(true);
              }}
            >
              Editar
            </Button>
            <Button
              variant="danger"
              className="px-2 py-1 text-xs"
              onClick={() => setDeletingAudio(a)}
            >
              Excluir
            </Button>
          </div>
        ) : null,
    },
  ];

  return (
    <div>
      <PageHeader
        title="Áudios"
        description="Gerencie as frases motivacionais disponíveis no app."
        action={
          canWrite && (
            <Button
              onClick={() => {
                setEditingAudio(null);
                setFormOpen(true);
              }}
            >
              + Novo áudio
            </Button>
          )
        }
      />

      <div className="mb-4 flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar por título ou frase…"
          className="w-64 rounded-lg border border-slate-300 px-3 py-2 text-sm"
        />
        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="">Todas as categorias</option>
          {(categoriesQuery.data ?? []).map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
          className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="">Todos os status</option>
          <option value="active">Ativos</option>
          <option value="inactive">Inativos</option>
        </select>
      </div>

      {audiosQuery.isLoading && <Spinner />}
      {audiosQuery.isError && (
        <ErrorState onRetry={() => audiosQuery.refetch()} />
      )}
      {audiosQuery.isSuccess && filteredAudios.length === 0 && (
        <EmptyState
          title="Nenhum áudio encontrado"
          description="Ajuste os filtros ou cadastre um novo áudio."
        />
      )}
      {audiosQuery.isSuccess && filteredAudios.length > 0 && (
        <DataTable columns={columns} rows={filteredAudios} getRowKey={(a) => a.id} />
      )}

      <AudioFormModal
        open={formOpen}
        audio={editingAudio}
        categories={categoriesQuery.data ?? []}
        onClose={() => setFormOpen(false)}
      />

      <ConfirmDialog
        open={!!deletingAudio}
        title="Excluir áudio"
        description={`Tem certeza que deseja excluir "${deletingAudio?.title}"? Esta ação remove o áudio de todos os clientes.`}
        confirmLabel="Excluir"
        loading={deleteMutation.isPending}
        onCancel={() => setDeletingAudio(null)}
        onConfirm={() => deletingAudio && deleteMutation.mutate(deletingAudio.id)}
      />
    </div>
  );
}
