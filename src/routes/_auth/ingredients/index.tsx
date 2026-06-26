import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { AlertTriangle, Pencil, Plus } from "lucide-react";
import { useState } from "react";
import { VoiceFab } from "@/components/ui/VoiceFab";
import { z } from "zod";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Ingredient } from "@/types/api";

export const Route = createFileRoute("/_auth/ingredients/")({
	beforeLoad: () => requireRole("OWNER"),
	component: IngredientsPage,
});

const ingredientSchema = z.object({
	name: z.string().min(2, "Mínimo 2 caracteres"),
	unit: z.string().min(1, "Requerido"),
	stock: z.coerce.number().min(0, "Debe ser ≥ 0"),
	min_stock: z.coerce.number().min(0, "Debe ser ≥ 0"),
	cost_per_unit: z.coerce.number().positive("Debe ser mayor a 0"),
});

type IngredientForm = z.infer<typeof ingredientSchema>;

function IngredientsPage() {
	const qc = useQueryClient();
	const [showForm, setShowForm] = useState(false);
	const [editItem, setEditItem] = useState<Ingredient | null>(null);

	const { data: ingredients = [], isLoading } = useQuery<Ingredient[]>({
		queryKey: ["ingredients"],
		queryFn: () => api.get("/ingredients").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: IngredientForm) => api.post("/ingredients", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["ingredients"] });
			setShowForm(false);
		},
	});

	const updateMutation = useMutation({
		mutationFn: ({ id, ...body }: IngredientForm & { id: string }) =>
			api.patch(`/ingredients/${id}`, body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["ingredients"] });
			setEditItem(null);
		},
	});

	const lowStock = ingredients.filter((i) => i.stock <= i.minStock);

	return (
		<div>
			<PageHeader
				title="Insumos"
				description="Control de inventario y costos"
				action={
					<Button
						size="sm"
						onClick={() => {
							setEditItem(null);
							setShowForm(true);
						}}
					>
						<Plus size={14} className="mr-1" />
						Nuevo insumo
					</Button>
				}
			/>

			{lowStock.length > 0 && (
				<div className="mb-4 flex items-center gap-2 rounded-lg border border-[oklch(0.85_0.04_60)] bg-[oklch(0.97_0.02_60)] px-4 py-3 text-sm text-[oklch(0.45_0.08_60)]">
					<AlertTriangle size={14} className="shrink-0" />
					<span>
						{lowStock.length} insumo{lowStock.length > 1 ? "s" : ""} con stock bajo o agotado:&nbsp;
						{lowStock.map((i) => i.name).join(", ")}
					</span>
				</div>
			)}

			{showForm && (
				<IngredientForm
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowForm(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al crear el insumo" : undefined}
				/>
			)}

			{editItem && (
				<IngredientForm
					initialValues={editItem}
					onSubmit={(v) => updateMutation.mutate({ ...v, id: editItem.id })}
					onCancel={() => setEditItem(null)}
					isPending={updateMutation.isPending}
					error={updateMutation.isError ? "Error al actualizar" : undefined}
				/>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : ingredients.length === 0 ? (
				<EmptyState
					title="Sin insumos registrados"
					description="Agrega los insumos para el control de inventario"
				/>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Nombre
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Unidad
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Stock
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Mínimo
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Costo / U.
								</th>
								<th className="px-4 py-3" />
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{ingredients.map((ing) => {
								const isLow = ing.stock <= ing.minStock;
								return (
									<tr key={ing.id}>
										<td className="px-4 py-3 font-medium text-foreground">{ing.name}</td>
										<td className="px-4 py-3 text-muted-foreground">{ing.unit}</td>
										<td className="px-4 py-3">
											<span
												className={cn(
													"font-medium",
													isLow ? "text-[oklch(0.5_0.1_30)]" : "text-foreground",
												)}
											>
												{ing.stock}
												{isLow && <AlertTriangle size={12} className="ml-1 inline" />}
											</span>
										</td>
										<td className="px-4 py-3 text-muted-foreground">{ing.minStock}</td>
										<td className="px-4 py-3 text-foreground">
											S/ {Number(ing.costPerUnit).toFixed(2)}
										</td>
										<td className="px-4 py-3">
											<div className="flex justify-end">
												<button
													type="button"
													title="Editar"
													onClick={() => {
														setShowForm(false);
														setEditItem(ing);
													}}
													className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
												>
													<Pencil size={14} />
												</button>
											</div>
										</td>
									</tr>
								);
							})}
						</tbody>
					</table>
				</div>
			)}
		<VoiceFab formType="ingredient_update" />
		</div>
	);
}

function IngredientForm({
	initialValues,
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	initialValues?: Ingredient;
	onSubmit: (v: IngredientForm) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	const form = useForm({
		defaultValues: {
			name: initialValues?.name ?? "",
			unit: initialValues?.unit ?? "",
			stock: initialValues?.stock ?? 0,
			min_stock: initialValues?.minStock ?? 0,
			cost_per_unit: initialValues?.costPerUnit ?? 0,
		},
		onSubmit: async ({ value }) => {
			const parsed = ingredientSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">
				{initialValues ? "Editar insumo" : "Nuevo insumo"}
			</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="grid grid-cols-3 gap-4"
			>
				<form.Field name="name">
					{(field) => (
						<div className="space-y-1.5 col-span-2">
							<Label htmlFor={field.name}>Nombre</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Arroz blanco"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="unit">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Unidad</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="kg"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="stock">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Stock actual</Label>
							<Input
								id={field.name}
								type="number"
								step="0.01"
								min="0"
								value={field.state.value}
								onChange={(e) => field.handleChange(Number(e.target.value))}
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="min_stock">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Stock mínimo</Label>
							<Input
								id={field.name}
								type="number"
								step="0.01"
								min="0"
								value={field.state.value}
								onChange={(e) => field.handleChange(Number(e.target.value))}
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="cost_per_unit">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Costo / unidad (S/)</Label>
							<Input
								id={field.name}
								type="number"
								step="0.01"
								min="0"
								value={field.state.value}
								onChange={(e) => field.handleChange(Number(e.target.value))}
							/>
						</div>
					)}
				</form.Field>

				{error && <p className="col-span-3 text-xs text-destructive">{error}</p>}

				<div className="col-span-3 flex justify-end gap-2">
					<Button type="button" variant="outline" size="sm" onClick={onCancel}>
						Cancelar
					</Button>
					<Button type="submit" size="sm" disabled={isPending}>
						{isPending ? "Guardando…" : initialValues ? "Guardar cambios" : "Crear insumo"}
					</Button>
				</div>
			</form>
		</div>
	);
}
