import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { listNotifications } from "@/lib/api/notifications";
import { PageHeader } from "@/components/PageHeader";
import { Badge } from "@/components/Badge";
import { DataTable, type DataTableColumn } from "@/components/DataTable";
import { EmptyState } from "@/components/EmptyState";
import { Spinner, ErrorState } from "@/components/Spinner";
import { Button } from "@/components/Button";
import { useRole } from "@/features/auth/useRole";
import type { NotificationRecord } from "@/lib/api/types";
import { ComposeNotificationModal } from "./ComposeNotificationModal";

const STATUS_TONE: Record<NotificationRecord["status"], "success" | "neutral" | "warning" | "danger"> = {
  sent: "success",
  sending: "warning",
  draft: "neutral",
  failed: "danger",
};

const STATUS_LABEL: Record<NotificationRecord["status"], string> = {
  sent: "Enviada",
  sending: "Enviando",
  draft: "Rascunho",
  failed: "Falhou",
};

export function NotificationsPage() {
  const { canWrite } = useRole();
  const [composeOpen, setComposeOpen] = useState(false);

  const notificationsQuery = useQuery({
    queryKey: ["notifications"],
    queryFn: listNotifications,
  });

  const columns: Array<DataTableColumn<NotificationRecord>> = [
    {
      key: "title",
      header: "Notificação",
      render: (n) => (
        <div>
          <p className="font-medium text-slate-800">{n.title}</p>
          <p className="max-w-md truncate text-xs text-slate-400">{n.body}</p>
        </div>
      ),
    },
    {
      key: "target",
      header: "Público",
      render: (n) => (n.target.type === "all" ? "Todos os usuários" : `Segmento: ${n.target.segment}`),
    },
    {
      key: "recipients",
      header: "Destinatários",
      render: (n) => n.recipientCount?.toLocaleString("pt-BR") ?? "—",
    },
    {
      key: "status",
      header: "Status",
      render: (n) => <Badge tone={STATUS_TONE[n.status]}>{STATUS_LABEL[n.status]}</Badge>,
    },
    {
      key: "sentAt",
      header: "Enviada em",
      render: (n) => (n.sentAt ? new Date(n.sentAt).toLocaleString("pt-BR") : "—"),
    },
  ];

  return (
    <div>
      <PageHeader
        title="Notificações"
        description="Envie novidades, categorias novas e avisos push para os usuários."
        action={
          canWrite && <Button onClick={() => setComposeOpen(true)}>+ Nova notificação</Button>
        }
      />

      {notificationsQuery.isLoading && <Spinner />}
      {notificationsQuery.isError && <ErrorState onRetry={() => notificationsQuery.refetch()} />}
      {notificationsQuery.isSuccess && notificationsQuery.data.length === 0 && (
        <EmptyState
          title="Nenhuma notificação enviada ainda"
          description="Use o botão acima para enviar a primeira notificação."
        />
      )}
      {notificationsQuery.isSuccess && notificationsQuery.data.length > 0 && (
        <DataTable columns={columns} rows={notificationsQuery.data} getRowKey={(n) => n.id} />
      )}

      <ComposeNotificationModal open={composeOpen} onClose={() => setComposeOpen(false)} />
    </div>
  );
}
