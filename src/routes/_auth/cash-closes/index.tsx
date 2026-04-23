import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Plus } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/cash-closes/")({
	beforeLoad: () => requireRole("OWNER"),
	component: CashClosesPage,
});

interface CashClose {
	id: string;
	date: string;
	opening_amount: number;
	closing_amount: number;
	total_sales: number;
	total_expenses: number;
	notes?: string;
	created_at: string;
}

const closeSchema = z.object({
	date: z.string().min(1, "Requerido"),
	opening_amount: z.coerce.number().min(0),
	closing_amount: z.coerce.number().min(0),
	notes: z.string().optional(),
});

type CloseForm = z.infer<typeof closeSchema>;

function CashClosesPage() {
	const qc = useQueryClient();
	const [showForm, setShowForm] = useState(false);

	const { data: closes = [], isLoading } = useQuery<CashClose[]>({
		queryKey: ["cash-closes"],
		queryFn: () => api.get("/cash-closes").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: CloseForm) => api.post("/cash-closes", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["cash-closes"] });
			setShowForm(false);
		},
	});

	return (
		<div>
			<PageHeader
				title="Cierre de caja"
				description="Registro diario de apertura y cierre"
				action={
					<Button size="sm" onClick={() => setShowForm(true)}>
						<Plus size={14} className="mr-1" />
						Nuevo cierre
					</Button>
				}
			/>

			{showForm && (
				<CloseFormPanel
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowForm(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al registrar el cierre" : undefined}
				/>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : closes.length === 0 ? (
				<EmptyState
					title="Sin cierres registrados"
					description="Registra el cierre de caja diario"
				/>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Fecha
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Apertura
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Ventas
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Gastos
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Cierre
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Diferencia
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{closes.map((c) => {
								const expected =
									Number(c.opening_amount) + Number(c.total_sales) - Number(c.total_expenses);
								const diff = Number(c.closing_amount) - expected;
								return (
									<tr key={c.id}>
										<td className="px-4 py-3 text-foreground">
											{new Date(c.date).toLocaleDateString("es-PE", {
												day: "2-digit",
												month: "2-digit",
												year: "numeric",
											})}
										</td>
										<td className="px-4 py-3 text-right text-muted-foreground">
											S/ {Number(c.opening_amount).toFixed(2)}
										</td>
										<td className="px-4 py-3 text-right text-foreground">
											S/ {Number(c.total_sales).toFixed(2)}
										</td>
										<td className="px-4 py-3 text-right text-muted-foreground">
											S/ {Number(c.total_expenses).toFixed(2)}
										</td>
										<td className="px-4 py-3 text-right font-medium text-foreground">
											S/ {Number(c.closing_amount).toFixed(2)}
										</td>
										<td className="px-4 py-3 text-right">
											<span
												className={`text-xs font-medium ${
													Math.abs(diff) < 0.01
														? "text-muted-foreground"
														: diff > 0
															? "text-[oklch(0.4_0.1_145)]"
															: "text-[oklch(0.5_0.1_30)]"
												}`}
											>
												{diff >= 0 ? "+" : ""}S/ {diff.toFixed(2)}
											</span>
										</td>
									</tr>
								);
							})}
						</tbody>
					</table>
				</div>
			)}
		</div>
	);
}

function CloseFormPanel({
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	onSubmit: (v: CloseForm) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	const today = new Date().toISOString().split("T")[0];

	const form = useForm({
		defaultValues: {
			date: today,
			opening_amount: 0,
			closing_amount: 0,
			notes: "",
		},
		onSubmit: async ({ value }) => {
			const parsed = closeSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">Nuevo cierre de caja</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="grid grid-cols-3 gap-4"
			>
				<form.Field name="date">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Fecha</Label>
							<Input
								id={field.name}
								type="date"
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="opening_amount">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Fondo inicial (S/)</Label>
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

				<form.Field name="closing_amount">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Cierre real (S/)</Label>
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

				<form.Field name="notes">
					{(field) => (
						<div className="space-y-1.5 col-span-3">
							<Label htmlFor={field.name}>
								Notas <span className="text-muted-foreground">(opcional)</span>
							</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Observaciones del día"
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
						{isPending ? "Guardando…" : "Registrar cierre"}
					</Button>
				</div>
			</form>
		</div>
	);
}
