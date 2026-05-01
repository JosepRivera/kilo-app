import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Plus } from "lucide-react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/cash-closes/")({
	beforeLoad: () => requireRole("OWNER"),
	component: CashClosesPage,
});

interface CashClose {
	id: string;
	date: string;
	cash_income: number;
	digital_income: number;
	total_income: number;
	total_expenses: number;
	net_profit: number;
	closed_by: string;
	created_at: string;
}

interface PaginatedResponse {
	data: CashClose[];
	meta: { total: number; page: number; limit: number; pages: number };
}

function CashClosesPage() {
	const qc = useQueryClient();

	const { data: response, isLoading } = useQuery<PaginatedResponse>({
		queryKey: ["cash-closes"],
		queryFn: () => api.get("/cash-closes").then((r) => r.data),
	});

	const closes: CashClose[] = response?.data ?? (Array.isArray(response) ? response : []);

	const createMutation = useMutation({
		mutationFn: () => api.post("/cash-closes"),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["cash-closes"] }),
	});

	return (
		<div>
			<PageHeader
				title="Cierre de caja"
				description="Registro diario de ingresos y gastos"
				action={
					<Button
						size="sm"
						onClick={() => createMutation.mutate()}
						disabled={createMutation.isPending}
					>
						<Plus size={14} className="mr-1" />
						{createMutation.isPending ? "Generando…" : "Generar cierre de hoy"}
					</Button>
				}
			/>

			{createMutation.isError && (
				<div className="mb-4 rounded-lg border border-[oklch(0.85_0.04_30)] bg-[oklch(0.97_0.02_30)] px-4 py-3 text-sm text-[oklch(0.45_0.08_30)]">
					Error al generar el cierre. Es posible que ya exista un cierre para hoy.
				</div>
			)}

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : closes.length === 0 ? (
				<EmptyState
					title="Sin cierres registrados"
					description="Genera el cierre de caja al final del día"
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
									Efectivo
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Digital
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Ingresos
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Gastos
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Utilidad neta
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{closes.map((c) => (
								<tr key={c.id}>
									<td className="px-4 py-3 text-foreground">
										{new Date(c.date).toLocaleDateString("es-PE", {
											day: "2-digit",
											month: "2-digit",
											year: "numeric",
										})}
									</td>
									<td className="px-4 py-3 text-right text-muted-foreground">
										S/ {Number(c.cash_income).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-muted-foreground">
										S/ {Number(c.digital_income).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-foreground">
										S/ {Number(c.total_income).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-muted-foreground">
										S/ {Number(c.total_expenses).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right">
										<span
											className={`text-xs font-medium ${
												Number(c.net_profit) >= 0
													? "text-[oklch(0.4_0.1_145)]"
													: "text-[oklch(0.5_0.1_30)]"
											}`}
										>
											S/ {Number(c.net_profit).toFixed(2)}
										</span>
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
