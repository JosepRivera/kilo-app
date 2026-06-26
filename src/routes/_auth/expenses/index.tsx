import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Plus, Trash2 } from "lucide-react";
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
import type { Expense } from "@/types/api";
import { EXPENSE_CATEGORIES } from "@/types/api";

export const Route = createFileRoute("/_auth/expenses/")({
	beforeLoad: () => requireRole("OWNER"),
	component: ExpensesPage,
});

const expenseSchema = z.object({
	description: z.string().min(3, "Mínimo 3 caracteres"),
	amount: z.coerce.number().positive("Debe ser mayor a 0"),
	category: z.string().min(1, "Requerido"),
});

type ExpenseForm = z.infer<typeof expenseSchema>;

function ExpensesPage() {
	const qc = useQueryClient();
	const [showForm, setShowForm] = useState(false);

	const { data: expenses = [], isLoading } = useQuery<Expense[]>({
		queryKey: ["expenses"],
		queryFn: () => api.get("/expenses").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: ExpenseForm) => api.post("/expenses", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["expenses"] });
			setShowForm(false);
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: string) => api.delete(`/expenses/${id}`),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["expenses"] }),
	});

	const totalMonth = expenses
		.filter((e) => {
			const d = new Date(e.created_at);
			const now = new Date();
			return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
		})
		.reduce((acc, e) => acc + Number(e.amount), 0);

	return (
		<div>
			<PageHeader
				title="Gastos"
				description={`Total del mes: S/ ${totalMonth.toFixed(2)}`}
				action={
					<Button size="sm" onClick={() => setShowForm(true)}>
						<Plus size={14} className="mr-1" />
						Registrar gasto
					</Button>
				}
			/>

			{showForm && (
				<ExpenseFormPanel
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowForm(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al registrar el gasto" : undefined}
				/>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : expenses.length === 0 ? (
				<EmptyState
					title="Sin gastos registrados"
					description="Registra los gastos operativos del negocio"
				/>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Descripción
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Categoría
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Monto
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Fecha
								</th>
								<th className="px-4 py-3" />
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{expenses.map((exp) => (
								<tr key={exp.id}>
									<td className="px-4 py-3 font-medium text-foreground">{exp.description}</td>
									<td className="px-4 py-3">
										<span className="inline-flex rounded-md bg-[oklch(0.94_0_0)] px-2 py-0.5 text-xs font-medium text-foreground">
											{exp.category}
										</span>
									</td>
									<td className="px-4 py-3 font-medium text-foreground">
										S/ {Number(exp.amount).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-xs text-muted-foreground">
										{new Date(exp.created_at).toLocaleDateString("es-PE", {
											day: "2-digit",
											month: "2-digit",
											year: "numeric",
										})}
									</td>
									<td className="px-4 py-3">
										<div className="flex justify-end">
											<button
												type="button"
												title="Eliminar"
												onClick={() => deleteMutation.mutate(exp.id)}
												className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-destructive"
											>
												<Trash2 size={14} />
											</button>
										</div>
									</td>
								</tr>
							))}
						</tbody>
					</table>
				</div>
			)}
		<VoiceFab formType="expense" />
		</div>
	);
}

function ExpenseFormPanel({
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	onSubmit: (v: ExpenseForm) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	const form = useForm({
		defaultValues: {
			description: "",
			amount: 0,
			category: "",
		},
		onSubmit: async ({ value }) => {
			const parsed = expenseSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">Registrar gasto</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="grid grid-cols-2 gap-4"
			>
				<form.Field name="description">
					{(field) => (
						<div className="space-y-1.5 col-span-2">
							<Label htmlFor={field.name}>Descripción</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Compra de gas industrial"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="category">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Categoría</Label>
							<select
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
							>
								<option value="">Selecciona…</option>
								{EXPENSE_CATEGORIES.map((c) => (
									<option key={c} value={c}>
										{c}
									</option>
								))}
							</select>
						</div>
					)}
				</form.Field>

				<form.Field name="amount">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Monto (S/)</Label>
							<Input
								id={field.name}
								type="number"
								step="0.01"
								min="0"
								value={field.state.value}
								onChange={(e) => field.handleChange(Number(e.target.value))}
								placeholder="150.00"
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
						{isPending ? "Guardando…" : "Registrar gasto"}
					</Button>
				</div>
			</form>
		</div>
	);
}
