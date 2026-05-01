import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { ChevronDown, ChevronUp, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import type { Ingredient, Product, Recipe } from "@/types/api";

export const Route = createFileRoute("/_auth/recipes/")({
	beforeLoad: () => requireRole("OWNER"),
	component: RecipesPage,
});

function RecipesPage() {
	const [expanded, setExpanded] = useState<string | null>(null);
	const [editingProduct, setEditingProduct] = useState<string | null>(null);

	const { data: products = [], isLoading } = useQuery<Product[]>({
		queryKey: ["products"],
		queryFn: () => api.get("/products").then((r) => r.data),
	});

	const { data: ingredients = [] } = useQuery<Ingredient[]>({
		queryKey: ["ingredients"],
		queryFn: () => api.get("/ingredients").then((r) => r.data),
	});

	const activeProducts = products.filter((p) => p.isActive);

	return (
		<div>
			<PageHeader title="Recetas" description="Composición de insumos por producto" />

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : activeProducts.length === 0 ? (
				<EmptyState
					title="Sin productos activos"
					description="Crea productos antes de definir recetas"
				/>
			) : (
				<div className="space-y-2">
					{activeProducts.map((product) => (
						<ProductRecipeRow
							key={product.id}
							product={product}
							ingredients={ingredients}
							isExpanded={expanded === product.id}
							isEditing={editingProduct === product.id}
							onToggle={() => setExpanded((prev) => (prev === product.id ? null : product.id))}
							onEdit={() => setEditingProduct(product.id)}
							onCancelEdit={() => setEditingProduct(null)}
						/>
					))}
				</div>
			)}
		</div>
	);
}

function ProductRecipeRow({
	product,
	ingredients,
	isExpanded,
	isEditing,
	onToggle,
	onEdit,
	onCancelEdit,
}: {
	product: Product;
	ingredients: Ingredient[];
	isExpanded: boolean;
	isEditing: boolean;
	onToggle: () => void;
	onEdit: () => void;
	onCancelEdit: () => void;
}) {
	const qc = useQueryClient();

	const { data: recipe, isLoading } = useQuery<Recipe>({
		queryKey: ["recipes", product.id],
		queryFn: () => api.get(`/recipes/${product.id}`).then((r) => r.data),
		enabled: isExpanded || isEditing,
		retry: false,
	});

	const saveMutation = useMutation({
		mutationFn: (items: { ingredient_id: string; quantity: number }[]) =>
			api.put(`/recipes/${product.id}`, { items }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["recipes", product.id] });
			onCancelEdit();
		},
	});

	return (
		<div className="rounded-xl border border-border bg-white overflow-hidden">
			<div className="flex items-center justify-between px-4 py-3">
				<div>
					<p className="text-sm font-medium text-foreground">{product.name}</p>
					<p className="text-xs text-muted-foreground">{product.category}</p>
				</div>
				<div className="flex items-center gap-1">
					{isExpanded && !isEditing && (
						<button
							type="button"
							title="Editar receta"
							onClick={onEdit}
							className="rounded p-1 text-xs text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
						>
							<Plus size={14} />
						</button>
					)}
					<button
						type="button"
						onClick={onToggle}
						className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
					>
						{isExpanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
					</button>
				</div>
			</div>

			{isExpanded && !isEditing && (
				<div className="border-t border-border bg-[oklch(0.975_0_0)]">
					{isLoading ? (
						<p className="px-4 py-3 text-xs text-muted-foreground">Cargando…</p>
					) : !recipe || recipe.items.length === 0 ? (
						<div className="flex items-center justify-between px-4 py-3">
							<p className="text-xs text-muted-foreground">Sin receta definida</p>
							<button
								type="button"
								onClick={onEdit}
								className="text-xs text-muted-foreground hover:text-foreground"
							>
								Crear receta
							</button>
						</div>
					) : (
						<table className="w-full text-xs">
							<thead>
								<tr className="border-b border-border">
									<th className="px-4 py-2 text-left font-medium text-muted-foreground">Insumo</th>
									<th className="px-4 py-2 text-right font-medium text-muted-foreground">Cant.</th>
									<th className="px-4 py-2 text-left font-medium text-muted-foreground">Unidad</th>
								</tr>
							</thead>
							<tbody className="divide-y divide-border">
								{recipe.items.map((item) => (
									<tr key={item.id}>
										<td className="px-4 py-2 text-foreground">{item.ingredient_name}</td>
										<td className="px-4 py-2 text-right text-muted-foreground">{item.quantity}</td>
										<td className="px-4 py-2 text-muted-foreground">{item.unit}</td>
									</tr>
								))}
							</tbody>
						</table>
					)}
				</div>
			)}

			{isEditing && (
				<RecipeEditor
					productId={product.id}
					initialItems={recipe?.items ?? []}
					ingredients={ingredients}
					onSave={(items) => saveMutation.mutate(items)}
					onCancel={onCancelEdit}
					isPending={saveMutation.isPending}
					error={saveMutation.isError ? "Error al guardar la receta" : undefined}
				/>
			)}
		</div>
	);
}

function RecipeEditor({
	productId: _productId,
	initialItems,
	ingredients,
	onSave,
	onCancel,
	isPending,
	error,
}: {
	productId: string;
	initialItems: Recipe["items"];
	ingredients: Ingredient[];
	onSave: (items: { ingredient_id: string; quantity: number }[]) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	let seq = initialItems.length;
	const [items, setItems] = useState(
		initialItems.length > 0
			? initialItems.map((i, idx) => ({
					_key: idx,
					ingredient_id: i.ingredient_id,
					quantity: i.quantity,
				}))
			: [{ _key: 0, ingredient_id: "", quantity: 1 }],
	);

	const addItem = () =>
		setItems((prev) => [...prev, { _key: ++seq, ingredient_id: "", quantity: 1 }]);
	const removeItem = (key: number) => setItems((prev) => prev.filter((i) => i._key !== key));
	const updateItem = (key: number, field: "ingredient_id" | "quantity", val: string | number) =>
		setItems((prev) => prev.map((i) => (i._key === key ? { ...i, [field]: val } : i)));

	const handleSave = () => {
		const valid = items.filter((i) => i.ingredient_id && i.quantity > 0);
		if (valid.length === 0) return;
		onSave(valid.map(({ ingredient_id, quantity }) => ({ ingredient_id, quantity })));
	};

	return (
		<div className="border-t border-border bg-[oklch(0.975_0_0)] p-4 space-y-3">
			<div className="flex items-center justify-between">
				<p className="text-xs font-medium text-foreground">Insumos de la receta</p>
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
						className="flex-1 rounded-md border border-input bg-white px-3 py-1.5 text-xs focus:outline-none focus:ring-2 focus:ring-ring"
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
						className="w-20 text-xs h-8"
						placeholder="Cant."
					/>
					{items.length > 1 && (
						<button
							type="button"
							onClick={() => removeItem(item._key)}
							className="rounded p-1 text-muted-foreground hover:text-destructive"
						>
							<Trash2 size={12} />
						</button>
					)}
				</div>
			))}

			{error && <p className="text-xs text-destructive">{error}</p>}

			<div className="flex justify-end gap-2">
				<Button type="button" variant="outline" size="sm" onClick={onCancel}>
					Cancelar
				</Button>
				<Button type="button" size="sm" onClick={handleSave} disabled={isPending}>
					{isPending ? "Guardando…" : "Guardar receta"}
				</Button>
			</div>
		</div>
	);
}
