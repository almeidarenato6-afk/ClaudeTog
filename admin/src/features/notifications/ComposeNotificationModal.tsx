import { useEffect } from "react";
import { useForm, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal } from "@/components/Modal";
import { Button } from "@/components/Button";
import { FormField } from "@/components/FormField";
import { sendNotification } from "@/lib/api/notifications";

const schema = z.object({
  title: z.string().min(2, "Informe um título.").max(65, "Máximo de 65 caracteres."),
  body: z.string().min(2, "Informe o texto da notificação.").max(240, "Máximo de 240 caracteres."),
  targetType: z.enum(["all", "segment"]),
  segment: z.string().optional(),
}).refine((v) => v.targetType === "all" || !!v.segment?.trim(), {
  message: "Informe o segmento de destino.",
  path: ["segment"],
});

type FormValues = z.infer<typeof schema>;

export function ComposeNotificationModal({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const queryClient = useQueryClient();

  const {
    register,
    handleSubmit,
    reset,
    control,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { title: "", body: "", targetType: "all", segment: "" },
  });

  const targetType = useWatch({ control, name: "targetType" });

  useEffect(() => {
    if (open) reset({ title: "", body: "", targetType: "all", segment: "" });
  }, [open, reset]);

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      sendNotification({
        title: values.title,
        body: values.body,
        target:
          values.targetType === "all"
            ? { type: "all" }
            : { type: "segment", segment: values.segment!.trim() },
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
      onClose();
    },
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Nova notificação"
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={mutation.isPending}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit((values) => mutation.mutate(values))}
            loading={mutation.isPending}
          >
            Enviar agora
          </Button>
        </>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={(e) => e.preventDefault()}>
        <FormField label="Título" htmlFor="title" error={errors.title?.message}>
          <input
            id="title"
            {...register("title")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            placeholder="Ex.: Categoria nova no ar!"
          />
        </FormField>

        <FormField label="Mensagem" htmlFor="body" error={errors.body?.message}>
          <textarea
            id="body"
            {...register("body")}
            rows={3}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            placeholder="Texto exibido na notificação push."
          />
        </FormField>

        <FormField label="Público-alvo" htmlFor="targetType">
          <select
            id="targetType"
            {...register("targetType")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="all">Todos os usuários</option>
            <option value="segment">Segmento específico</option>
          </select>
        </FormField>

        {targetType === "segment" && (
          <FormField
            label="Segmento"
            htmlFor="segment"
            error={errors.segment?.message}
            hint="Identificador do segmento definido no backend (ex.: usuarios_ativos_7d)."
          >
            <input
              id="segment"
              {...register("segment")}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              placeholder="usuarios_ativos_7d"
            />
          </FormField>
        )}

        {mutation.isError && (
          <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
            Não foi possível enviar a notificação.
          </p>
        )}
      </form>
    </Modal>
  );
}
