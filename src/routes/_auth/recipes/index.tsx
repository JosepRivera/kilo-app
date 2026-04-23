import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { ChevronDown, ChevronUp, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import type { Ingredient, Product, Recipe } from "@/types/api";

export const Route = createFileRoute("/_auth/recipes/")({
	beforeLoad: () => requireRole("OWNER"),
	component: RecipesPage,
});

const recipeSchema = z.object({
	product_id: z.string().min(1, "Selecciona un producto"),
	items: z
		.array(z.object({ ingredient_id: z.string().min(1), quantity: z.coerce.number().positive() }))
		.min(1, "Agrega al menos un insumo"),
});

type RecipeForm = z.infer<typeof recipeSchema>;

function RecipesPage() {
	const qc = useQueryClient();
	const [showForm, setShowForm] = useState(false);
	const [expanded, setExpanded] = useState<string | null>(null);

	const { data: recipes = [], isLoading } = useQuery<Recipe[]>({
		queryKey: ["recipes"],
		queryFn: () => api.get("/recipes").then((r) => r.data),
	});

	const { data: products = [] } = useQuery<Product[]>({
		queryKey: ["products"],
		queryFn: () => api.get("/products").then((r) => r.data),
	});

	const { data: ingredients = [] } = useQuery<Ingredient[]>({
		queryKey: ["ingredients"],
		queryFn: () => api.get("/ingredients").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: RecipeForm) => api.post("/recipes", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["recipes"] });
			setShowForm(false);
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: string) => api.delete(`/recipes/${id}`),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["recipes"] }),
	});

	return (
		<div>
			<PageHeader
				title="Recetas"
				description="Composición y costos por producto"
				action={
					<Button size="sm" onClick={() => setShowForm(true)}>
						<Plus size={14} className="mr-1" />
						Nueva receta
					</Button>
				}
			/>

			{showForm && (
				<RecipeFormPanel
					products={products}
					ingredients={ingredients}
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowForm(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al crear la receta" : undefined}
				/>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : recipes.length === 0 ? (
				<EmptyState
					title="Sin recetas registradas"
					description="Crea recetas para calcular costos y gestionar producción"
				/>
			) : (
				<div className="space-y-2">
					{recipes.map((recipe) => (
						<div
							key={recipe.id}
							className="rounded-xl border border-border bg-white overflow-hidden"
						>
							<div className="flex items-center justify-between px-4 py-3">
								<div>
									<p className="text-sm font-medium text-foreground">{recipe.product?.name}</p>
									<p className="text-xs text-muted-foreground">
										Costo total: S/ {Number(recipe.total_cost).toFixed(2)}
									</p>
								</div>
								<div className="flex items-center gap-1">
									<button
										type="button"
										title="Eliminar receta"
										onClick={() => deleteMutation.mutate(recipe.id)}
										className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-destructive"
									>
										<Trash2 size={14} />
									</button>
									<button
										type="button"
										onClick={() => setExpanded(expanded === recipe.id ? null : recipe.id)}
										className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
									>
										{expanded === recipe.id ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
									</button>
								</div>
							</div>

							{expanded === recipe.id && (
								<div className="border-t border-border bg-[oklch(0.975_0_0)]">
									<table className="w-full text-xs">
										<thead>
											<tr className="border-b border-border">
												<th className="px-4 py-2 text-left font-medium text-muted-foreground">
													Insumo
												</th>
												<th className="px-4 py-2 text-left font-medium text-muted-foreground">
													Cantidad
												</th>
												<th className="px-4 py-2 text-left font-medium text-muted-foreground">
													Unidad
												</th>
												<th className="px-4 py-2 text-right font-medium text-muted-foreground">
													Subtotal
												</th>
											</tr>
										</thead>
										<tbody className="divide-y divide-border">
											{recipe.items?.map((item) => (
												<tr key={item.id}>
													<td className="px-4 py-2 text-foreground">{item.ingredient?.name}</td>
													<td className="px-4 py-2 text-muted-foreground">{item.quantity}</td>
													<td className="px-4 py-2 text-muted-foreground">
														{item.ingredient?.unit}
													</td>
													<td className="px-4 py-2 text-right text-foreground">
														S/ {(item.quantity * (item.ingredient?.cost_per_unit ?? 0)).toFixed(2)}
													</td>
												</tr>
											))}
										</tbody>
									</table>
								</div>
							)}
						</div>
					))}
				</div>
			)}
		</div>
	);
}

function RecipeFormPanel({
	products,
	ingredients,
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	products: Product[];
	ingredients: Ingredient[];
	onSubmit: (v: RecipeForm) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	let itemSeq = 0;
	const [items, setItems] = useState([{ _key: ++itemSeq, ingredient_id: "", quantity: 1 }]);

	const form = useForm({
		defaultValues: { product_id: "" },
		onSubmit: async ({ value }) => {
			const parsed = recipeSchema.safeParse({ ...value, items });
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	const addItem = () =>
		setItems((prev) => [...prev, { _key: ++itemSeq, ingredient_id: "", quantity: 1 }]);
	const removeItem = (key: number) => setItems((prev) => prev.filter((item) => item._key !== key));
	const updateItem = (key: number, field: "ingredient_id" | "quantity", val: string | number) => {
		setItems((prev) => prev.map((item) => (item._key === key ? { ...item, [field]: val } : item)));
	};

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">Nueva receta</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="space-y-4"
			>
				<form.Field name="product_id">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Producto</Label>
							<select
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
							>
								<option value="">Selecciona un producto…</option>
								{products
									.filter((p) => p.is_active)
									.map((p) => (
										<option key={p.id} value={p.id}>
											{p.name}
										</option>
									))}
							</select>
						</div>
					)}
				</form.Field>

				<div className="space-y-2">
					<div className="flex items-center justify-between">
						<Label>Insumos</Label>
						<button
							type="button"
							onClick={addItem}
							className="text-xs text-muted-foreground hover:text-foreground"
						>
							+ Agregar insumo
						</button>
					</div>

					{items.map((item) => (
						<div key={item._key} className="flex items-center gap-2">
							<select
								value={item.ingredient_id}
								onChange={(e) => updateItem(item._key, "ingredient_id", e.target.value)}
								className="flex-1 rounded-md border border-input bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
							>
								<option value="">Insumo…</option>
								{ingredients.map((ing) => (
									<option key={ing.id} value={ing.id}>
										{ing.name} ({ing.unit})
									</option>
								))}
							</select>
							<Input
								type="number"
								step="0.01"
								min="0.01"
								value={item.quantity}
								onChange={(e) => updateItem(item._key, "quantity", Number(e.target.value))}
								className="w-24"
								placeholder="Cant."
							/>
							{items.length > 1 && (
								<button
									type="button"
									onClick={() => removeItem(item._key)}
									className="rounded p-1 text-muted-foreground hover:text-destructive"
								>
									<Trash2 size={14} />
								</button>
							)}
						</div>
					))}
				</div>

				{error && <p className="text-xs text-destructive">{error}</p>}

				<div className="flex justify-end gap-2">
					<Button type="button" variant="outline" size="sm" onClick={onCancel}>
						Cancelar
					</Button>
					<Button type="submit" size="sm" disabled={isPending}>
						{isPending ? "Creando…" : "Crear receta"}
					</Button>
				</div>
			</form>
		</div>
	);
}
