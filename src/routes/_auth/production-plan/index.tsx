import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { RefreshCw } from "lucide-react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/production-plan/")({
	beforeLoad: () => requireRole("OWNER", "CASHIER", "WAITER", "COOK"),
	component: ProductionPlanPage,
});

interface PlanItem {
	id: string;
	product_id: string;
	product_name: string;
	quantity: number;
	prediction_source: string;
}

interface ProductionPlan {
	date: string;
	items: PlanItem[];
}

function ProductionPlanPage() {
	const qc = useQueryClient();

	const {
		data: plan,
		isLoading,
		isError,
	} = useQuery<ProductionPlan>({
		queryKey: ["production-plan"],
		queryFn: () => api.get("/production-plans/today").then((r) => r.data),
		retry: false,
	});

	const regenerateMutation = useMutation({
		mutationFn: () => api.put("/production-plans/current"),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["production-plan"] }),
	});

	const planDate = plan?.date
		? new Date(plan.date).toLocaleDateString("es-PE", {
				weekday: "long",
				day: "2-digit",
				month: "long",
			})
		: undefined;

	return (
		<div>
			<PageHeader
				title="Plan de producción"
				description={planDate ?? "Plan diario basado en demanda histórica"}
				action={
					<Button
						size="sm"
						variant="outline"
						onClick={() => regenerateMutation.mutate()}
						disabled={regenerateMutation.isPending}
					>
						<RefreshCw
							size={14}
							className={`mr-1 ${regenerateMutation.isPending ? "animate-spin" : ""}`}
						/>
						Regenerar
					</Button>
				}
			/>

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : isError || !plan || plan.items.length === 0 ? (
				<EmptyState
					title="Sin plan de producción"
					description="Genera el plan diario basado en ventas históricas"
					action={
						<Button
							size="sm"
							onClick={() => regenerateMutation.mutate()}
							disabled={regenerateMutation.isPending}
						>
							{regenerateMutation.isPending ? "Generando…" : "Generar plan"}
						</Button>
					}
				/>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Producto
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Cantidad a preparar
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Fuente
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{plan.items.map((item) => (
								<tr key={item.id}>
									<td className="px-4 py-3 font-medium text-foreground">{item.product_name}</td>
									<td className="px-4 py-3 text-right text-foreground font-medium">
										{item.quantity}
									</td>
									<td className="px-4 py-3 text-right">
										<span className="rounded-md bg-[oklch(0.94_0_0)] px-2 py-0.5 text-xs text-muted-foreground">
											{item.prediction_source}
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
