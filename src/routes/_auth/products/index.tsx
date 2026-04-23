import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Pencil, Plus, ToggleLeft, ToggleRight } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Product } from "@/types/api";

export const Route = createFileRoute("/_auth/products/")({
	beforeLoad: () => requireRole("OWNER"),
	component: ProductsPage,
});

const productSchema = z.object({
	name: z.string().min(2, "Mínimo 2 caracteres"),
	description: z.string().optional(),
	price: z.coerce.number().positive("Debe ser mayor a 0"),
	category: z.string().min(1, "Requerido"),
});

type ProductForm = z.infer<typeof productSchema>;

function ProductsPage() {
	const qc = useQueryClient();
	const [showForm, setShowForm] = useState(false);
	const [editProduct, setEditProduct] = useState<Product | null>(null);

	const { data: products = [], isLoading } = useQuery<Product[]>({
		queryKey: ["products"],
		queryFn: () => api.get("/products").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: ProductForm) => api.post("/products", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["products"] });
			setShowForm(false);
		},
	});

	const updateMutation = useMutation({
		mutationFn: ({ id, ...body }: ProductForm & { id: string }) =>
			api.patch(`/products/${id}`, body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["products"] });
			setEditProduct(null);
		},
	});

	const toggleMutation = useMutation({
		mutationFn: ({ id, is_active }: { id: string; is_active: boolean }) =>
			api.patch(`/products/${id}`, { is_active }),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["products"] }),
	});

	const handleEdit = (product: Product) => {
		setShowForm(false);
		setEditProduct(product);
	};

	const handleCancelEdit = () => setEditProduct(null);

	return (
		<div>
			<PageHeader
				title="Productos"
				description="Gestión del catálogo de productos"
				action={
					<Button
						size="sm"
						onClick={() => {
							setEditProduct(null);
							setShowForm(true);
						}}
					>
						<Plus size={14} className="mr-1" />
						Nuevo producto
					</Button>
				}
			/>

			{showForm && (
				<ProductForm
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowForm(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al crear el producto" : undefined}
				/>
			)}

			{editProduct && (
				<ProductForm
					initialValues={editProduct}
					onSubmit={(v) => updateMutation.mutate({ ...v, id: editProduct.id })}
					onCancel={handleCancelEdit}
					isPending={updateMutation.isPending}
					error={updateMutation.isError ? "Error al actualizar" : undefined}
				/>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : products.length === 0 ? (
				<EmptyState
					title="Sin productos registrados"
					description="Crea el primer producto del catálogo"
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
									Categoría
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Precio
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Estado
								</th>
								<th className="px-4 py-3" />
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{products.map((p) => (
								<tr key={p.id} className={cn(!p.is_active && "opacity-50")}>
									<td className="px-4 py-3 font-medium text-foreground">
										{p.name}
										{p.description && (
											<p className="text-xs text-muted-foreground font-normal">{p.description}</p>
										)}
									</td>
									<td className="px-4 py-3">
										<span className="inline-flex rounded-md bg-[oklch(0.94_0_0)] px-2 py-0.5 text-xs font-medium text-foreground">
											{p.category}
										</span>
									</td>
									<td className="px-4 py-3 text-foreground font-medium">
										S/ {Number(p.price).toFixed(2)}
									</td>
									<td className="px-4 py-3">
										<span
											className={cn(
												"text-xs",
												p.is_active ? "text-foreground" : "text-muted-foreground",
											)}
										>
											{p.is_active ? "Activo" : "Inactivo"}
										</span>
									</td>
									<td className="px-4 py-3">
										<div className="flex items-center justify-end gap-1">
											<button
												type="button"
												title="Editar"
												onClick={() => handleEdit(p)}
												className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
											>
												<Pencil size={14} />
											</button>
											<button
												type="button"
												title={p.is_active ? "Desactivar" : "Activar"}
												onClick={() => toggleMutation.mutate({ id: p.id, is_active: !p.is_active })}
												className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
											>
												{p.is_active ? <ToggleRight size={14} /> : <ToggleLeft size={14} />}
											</button>
										</div>
									</td>
								</tr>
							))}
						</tbody>
					</table>
				</div>
			)}
		</div>
	);
}

function ProductForm({
	initialValues,
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	initialValues?: Product;
	onSubmit: (v: ProductForm) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	const form = useForm({
		defaultValues: {
			name: initialValues?.name ?? "",
			description: initialValues?.description ?? "",
			price: initialValues?.price ?? 0,
			category: initialValues?.category ?? "",
		},
		onSubmit: async ({ value }) => {
			const parsed = productSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">
				{initialValues ? "Editar producto" : "Nuevo producto"}
			</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="grid grid-cols-2 gap-4"
			>
				<form.Field name="name">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Nombre</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Lomo saltado"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="category">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Categoría</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Platos de fondo"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="price">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Precio (S/)</Label>
							<Input
								id={field.name}
								type="number"
								step="0.01"
								min="0"
								value={field.state.value}
								onChange={(e) => field.handleChange(Number(e.target.value))}
								placeholder="25.00"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="description">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>
								Descripción <span className="text-muted-foreground">(opcional)</span>
							</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Descripción breve"
							/>
						</div>
					)}
				</form.Field>

				{error && <p className="col-span-2 text-xs text-destructive">{error}</p>}

				<div className="col-span-2 flex justify-end gap-2">
					<Button type="button" variant="outline" size="sm" onClick={onCancel}>
						Cancelar
					</Button>
					<Button type="submit" size="sm" disabled={isPending}>
						{isPending ? "Guardando…" : initialValues ? "Guardar cambios" : "Crear producto"}
					</Button>
				</div>
			</form>
		</div>
	);
}
