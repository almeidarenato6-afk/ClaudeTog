import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal } from "@/components/Modal";
import { Button } from "@/components/Button";
import { FormField } from "@/components/FormField";
import { createCategory, updateCategory } from "@/lib/api/categories";
import type { Category } from "@/lib/api/types";

const schema = z.object({
  name: z.string().min(2, "Informe um nome."),
  slug: z
    .string()
    .min(2, "Informe um identificador.")
    .regex(/^[a-z0-9_]+$/, "Use apenas letras minúsculas, números e underscore."),
  icon: z.string().min(1, "Informe um ícone (emoji ou nome)."),
  color: z
    .string()
    .regex(/^#[0-9a-fA-F]{6}$/, "Use uma cor hex válida, ex.: #ff4d14."),
  order: z.coerce.number().int().min(0),
  active: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

interface CategoryFormModalProps {
  open: boolean;
  category: Category | null;
  onClose: () => void;
}

export function CategoryFormModal({ open, category, onClose }: CategoryFormModalProps) {
  const queryClient = useQueryClient();
  const isEditing = !!category;

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: "",
      slug: "",
      icon: "🎾",
      color: "#ff4d14",
      order: 0,
      active: true,
    },
  });

  useEffect(() => {
    if (open) {
      reset(
        category
          ? {
              name: category.name,
              slug: category.slug,
              icon: category.icon,
              color: category.color,
              order: category.order,
              active: category.active,
            }
          : { name: "", slug: "", icon: "🎾", color: "#ff4d14", order: 0, active: true },
      );
    }
  }, [open, category, reset]);

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      if (isEditing) {
        await updateCategory({ id: category!.id, ...values });
      } else {
        await createCategory(values);
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["categories"] });
      onClose();
    },
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEditing ? "Editar categoria" : "Nova categoria"}
      size="sm"
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={mutation.isPending}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit((values) => mutation.mutate(values))}
            loading={mutation.isPending}
          >
            {isEditing ? "Salvar alterações" : "Criar categoria"}
          </Button>
        </>
      }
    >
      <form className="flex flex-col gap-4" onSubmit={(e) => e.preventDefault()}>
        <FormField label="Nome" htmlFor="name" error={errors.name?.message}>
          <input
            id="name"
            {...register("name")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            placeholder="Ex.: Motivação"
          />
        </FormField>

        <FormField
          label="Identificador (slug)"
          htmlFor="slug"
          error={errors.slug?.message}
          hint="Usado internamente pelos apps, não pode ser alterado com frequência."
        >
          <input
            id="slug"
            {...register("slug")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            placeholder="motivacao"
          />
        </FormField>

        <div className="grid grid-cols-2 gap-4">
          <FormField label="Ícone" htmlFor="icon" error={errors.icon?.message}>
            <input
              id="icon"
              {...register("icon")}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              placeholder="🔥"
            />
          </FormField>
          <FormField label="Cor" htmlFor="color" error={errors.color?.message}>
            <input
              id="color"
              type="text"
              {...register("color")}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              placeholder="#ff4d14"
            />
          </FormField>
        </div>

        <FormField label="Ordem de exibição" htmlFor="order" error={errors.order?.message}>
          <input
            id="order"
            type="number"
            {...register("order")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </FormField>

        <label className="flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...register("active")} className="h-4 w-4 rounded border-slate-300" />
          Ativa (visível no app)
        </label>

        {mutation.isError && (
          <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
            Não foi possível salvar a categoria.
          </p>
        )}
      </form>
    </Modal>
  );
}
