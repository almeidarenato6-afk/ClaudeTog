import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Modal } from "@/components/Modal";
import { Button } from "@/components/Button";
import { FormField } from "@/components/FormField";
import { createAudio, updateAudio, uploadAudioFile } from "@/lib/api/audios";
import type { Audio, Category } from "@/lib/api/types";

const schema = z.object({
  title: z.string().min(2, "Informe um título."),
  phraseText: z.string().min(2, "Informe o texto da frase."),
  categoryId: z.string().min(1, "Selecione uma categoria."),
  active: z.boolean(),
});

type FormValues = z.infer<typeof schema>;

interface AudioFormModalProps {
  open: boolean;
  audio: Audio | null;
  categories: Category[];
  onClose: () => void;
}

export function AudioFormModal({ open, audio, categories, onClose }: AudioFormModalProps) {
  const queryClient = useQueryClient();
  const isEditing = !!audio;
  const [file, setFile] = useState<File | null>(null);
  const [uploadPct, setUploadPct] = useState<number | null>(null);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { title: "", phraseText: "", categoryId: "", active: true },
  });

  useEffect(() => {
    if (open) {
      reset(
        audio
          ? {
              title: audio.title,
              phraseText: audio.phraseText,
              categoryId: audio.categoryId,
              active: audio.active,
            }
          : { title: "", phraseText: "", categoryId: "", active: true },
      );
      setFile(null);
      setUploadPct(null);
    }
  }, [open, audio, reset]);

  const mutation = useMutation({
    mutationFn: async (values: FormValues) => {
      if (isEditing) {
        await updateAudio({ id: audio!.id, ...values });
        return;
      }
      if (!file) {
        throw new Error("Selecione um arquivo de áudio.");
      }
      const { task, storagePath } = uploadAudioFile(file, setUploadPct);
      await task;
      await createAudio({ ...values, storagePath });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["audios"] });
      onClose();
    },
  });

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={isEditing ? "Editar áudio" : "Novo áudio"}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={mutation.isPending}>
            Cancelar
          </Button>
          <Button
            onClick={handleSubmit((values) => mutation.mutate(values))}
            loading={mutation.isPending}
          >
            {isEditing ? "Salvar alterações" : "Cadastrar áudio"}
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
            placeholder="Ex.: Bora, Márcia!"
          />
        </FormField>

        <FormField label="Texto da frase" htmlFor="phraseText" error={errors.phraseText?.message}>
          <textarea
            id="phraseText"
            {...register("phraseText")}
            rows={3}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            placeholder="Texto falado no áudio, usado para busca e legendas."
          />
        </FormField>

        <FormField label="Categoria" htmlFor="categoryId" error={errors.categoryId?.message}>
          <select
            id="categoryId"
            {...register("categoryId")}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="">Selecione…</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </FormField>

        {!isEditing && (
          <FormField
            label="Arquivo de áudio"
            htmlFor="file"
            hint="Formatos aceitos: m4a, mp3, wav. O processamento final ocorre no backend."
          >
            <input
              id="file"
              type="file"
              accept="audio/*"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
            />
            {uploadPct !== null && (
              <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-slate-100">
                <div
                  className="h-full bg-coral-500 transition-all"
                  style={{ width: `${uploadPct}%` }}
                />
              </div>
            )}
          </FormField>
        )}

        <label className="flex items-center gap-2 text-sm text-slate-700">
          <input type="checkbox" {...register("active")} className="h-4 w-4 rounded border-slate-300" />
          Ativo (visível no app)
        </label>

        {mutation.isError && (
          <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
            {mutation.error instanceof Error
              ? mutation.error.message
              : "Não foi possível salvar o áudio."}
          </p>
        )}
      </form>
    </Modal>
  );
}
