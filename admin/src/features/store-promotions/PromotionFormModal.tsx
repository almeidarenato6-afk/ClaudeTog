import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal } from "@/components/Modal";
import { Button } from "@/components/Button";
import { FormField } from "@/components/FormField";
import { createPromotion, updatePromotion } from "@/lib/api/promotions";
import { DEFAULT_STORE_URL, type Promotion } from "@/lib/api/types";

const schema = z
  .object({
    title: z.string().min(2, "Informe um título."),
    description: z.string().min(2, "Informe uma descrição."),
    linkUrl: z.string().url("Informe uma URL válida."),
    startsAt: z.string().min(1, "Informe a data de início."),
    endsAt: z.string().optional(),
    active: z.boolean(),
  })
  .refine((v) => !v.endsAt || v.endsAt >= v.startsAt, {
    message: "A data final deve ser depois da data inicial.",
    path: ["endsAt"],
  });

type FormValues = z.infer<typeof schema>;

function toDateInput(iso: string) {
  return iso ? iso.slice(0, 10) : "";
}

interface PromotionFormModalProps {
  open: boolean;
  promotion: Promotion | null;
  onClose: () => void;
}

export function PromotionFormModal({ open, promotion, onClose }: PromotionFormModalProps) {
  const queryClient = useQueryClient();
  const isEditing = !!promotion;

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      title: "",
      description: "",
      linkUrl: DEFAULT_STORE_URL,
      startsAt: toDateInput(new Date().toISOString()),
      endsAt: "",
      active: true,
    },
  });

  useEffect(() => {
    if (open) {
      reset(
        promotion
          ? {
              title: promotion.title,
              description: promotion.description,
              linkUrl: promotion.linkUrl,
              startsAt: toDateInput(promotion.startsAt),
              endsAt: promotion.endsAt ? toDateInput(promotion.endsAt) : "",
              active: promotion.active,
            }
          : {
              title: "",
              description: "",
              linkUrl: DEFAULT_STORE_URL,
              startsAt: toDateInput(new Date().toISOString()),
              endsAt: "",
              active: true,
            },
      );
    }
  }, [open, promotion, reset]);

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      const payload = {
        title: values.title,
        description: values.description,
        linkUrl: values.linkUrl,
        startsAt: new Date(values.startsAt).toISOString(),
        endsAt: values.endsAt ? new Date(values.endsAt).toISOString() : null,
        active: values.active,
      };
      if (isEditing) {
        await updatePromotion({ id: promotion!.id, ...payload });
      } else {
        await createPromotion(payload);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["promotions"] });
      onClose();
    },
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEditing ? "Editar promoção" : "Nova promoção"}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={mutation.isPending}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit((values) => mutation.mutate(values))}
            loading={mutation.isPending}
          >
            {isEditing ? "Salvar alterações" : "Criar promoção"}
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
            placeholder="Ex.: Frete grátis na Loja TogPlay"
          />
        </FormField>

        <FormField label="Descrição" htmlFor="description" error={errors.description?.message}>
          <textarea
            id="description"
            {...register("description")}
            rows={3}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </FormField>

        <FormField
          label="Link"
          htmlFor="linkUrl"
          error={errors.linkUrl?.message}
          hint={`Padrão da Loja TogPlay: ${DEFAULT_STORE_URL}`}
        >
          <input
            id="linkUrl"
            {...register("linkUrl")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </FormField>

        <div className="grid grid-cols-2 gap-4">
          <FormField label="Início" htmlFor="startsAt" error={errors.startsAt?.message}>
            <input
              id="startsAt"
              type="date"
              {...register("startsAt")}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            />
          </FormField>
          <FormField
            label="Fim (opcional)"
            htmlFor="endsAt"
            error={errors.endsAt?.message}
            hint="Deixe em branco para promoção sem data de término."
          >
            <input
              id="endsAt"
              type="date"
              {...register("endsAt")}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            />
          </FormField>
        </div>

        <label className="flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...register("active")} className="h-4 w-4 rounded border-slate-300" />
          Ativa (visível no app)
        </label>

        {mutation.isError && (
          <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
            Não foi possível salvar a promoção.
          </p>
        )}
      </form>
    </Modal>
  );
}
