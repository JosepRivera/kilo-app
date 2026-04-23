import { useMutation, useQuery } from "@tanstack/react-query";
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

interface ProductionItem {
	product_id: string;
	product_name: string;
	quantity_to_produce: number;
	ingredients: {
		ingredient_id: string;
		ingredient_name: string;
		unit: string;
		quantity_needed: number;
		stock_available: number;
		sufficient: boolean;
	}[];
}

interface ProductionPlan {
	date: string;
	items: ProductionItem[];
	generated_at: string;
}

function ProductionPlanPage() {
	const {
		data: plan,
		isLoading,
		refetch,
	} = useQuery<ProductionPlan>({
		queryKey: ["production-plan"],
		queryFn: () => api.get("/ai/production-plan").then((r) => r.data),
	});

	const refreshMutation = useMutation({
		mutationFn: () => api.post("/ai/production-plan/generate").then((r) => r.data),
		onSuccess: () => void refetch(),
	});

	return (
		<div>
			<PageHeader
				title="Plan de producción"
				description={
					plan?.generated_at
						? `Generado ${new Date(plan.generated_at).toLocaleString("es-PE", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" })}`
						: "Plan diario de producción"
				}
				action={
					<Button
						size="sm"
						variant="outline"
						onClick={() => refreshMutation.mutate()}
						disabled={refreshMutation.isPending}
					>
						<RefreshCw
							size={14}
							className={`mr-1 ${refreshMutation.isPending ? "animate-spin" : ""}`}
						/>
						Regenerar
					</Button>
				}
			/>

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando plan…</div>
			) : !plan || plan.items.length === 0 ? (
				<EmptyState
					title="Sin plan de producción"
					description="Genera el plan diario basado en ventas históricas"
					action={
						<Button
							size="sm"
							onClick={() => refreshMutation.mutate()}
							disabled={refreshMutation.isPending}
						>
							{refreshMutation.isPending ? "Generando…" : "Generar plan"}
						</Button>
					}
				/>
			) : (
				<div className="space-y-3">
					{plan.items.map((item) => {
						const hasShortage = item.ingredients.some((i) => !i.sufficient);
						return (
							<div
								key={item.product_id}
								className="rounded-xl border border-border bg-white overflow-hidden"
							>
								<div className="flex items-center justify-between border-b border-border px-4 py-3">
									<div>
										<p className="text-sm font-medium text-foreground">{item.product_name}</p>
										<p className="text-xs text-muted-foreground">
											Producir: {item.quantity_to_produce} unidades
										</p>
									</div>
									{hasShortage && (
										<span className="rounded-md bg-[oklch(0.93_0.03_60)] px-2 py-0.5 text-xs font-medium text-[oklch(0.45_0.08_60)]">
											Stock insuficiente
										</span>
									)}
								</div>
								<table className="w-full text-xs">
									<thead>
										<tr className="bg-[oklch(0.975_0_0)]">
											<th className="px-4 py-2 text-left font-medium text-muted-foreground">
												Insumo
											</th>
											<th className="px-4 py-2 text-right font-medium text-muted-foreground">
												Necesario
											</th>
											<th className="px-4 py-2 text-right font-medium text-muted-foreground">
												Disponible
											</th>
											<th className="px-4 py-2 text-right font-medium text-muted-foreground">
												Estado
											</th>
										</tr>
									</thead>
									<tbody className="divide-y divide-border">
										{item.ingredients.map((ing) => (
											<tr key={ing.ingredient_id}>
												<td className="px-4 py-2 text-foreground">{ing.ingredient_name}</td>
												<td className="px-4 py-2 text-right text-muted-foreground">
													{ing.quantity_needed} {ing.unit}
												</td>
												<td className="px-4 py-2 text-right text-muted-foreground">
													{ing.stock_available} {ing.unit}
												</td>
												<td className="px-4 py-2 text-right">
													<span
														className={
															ing.sufficient
																? "text-[oklch(0.4_0.1_145)]"
																: "text-[oklch(0.5_0.1_30)]"
														}
													>
														{ing.sufficient ? "OK" : "Falta"}
													</span>
												</td>
											</tr>
										))}
									</tbody>
								</table>
							</div>
						);
					})}
				</div>
			)}
		</div>
	);
}
