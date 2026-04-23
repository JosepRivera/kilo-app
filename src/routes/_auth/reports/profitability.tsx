import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import {
	Bar,
	BarChart,
	CartesianGrid,
	Cell,
	ResponsiveContainer,
	Tooltip,
	XAxis,
	YAxis,
} from "recharts";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import type { Recipe, Sale } from "@/types/api";

export const Route = createFileRoute("/_auth/reports/profitability")({
	beforeLoad: () => requireRole("OWNER"),
	component: ProfitabilityPage,
});

function ProfitabilityPage() {
	const { data: sales = [] } = useQuery<Sale[]>({
		queryKey: ["sales"],
		queryFn: () => api.get("/sales").then((r) => r.data),
	});

	const { data: recipes = [] } = useQuery<Recipe[]>({
		queryKey: ["recipes"],
		queryFn: () => api.get("/recipes").then((r) => r.data),
	});

	const completedSales = sales.filter((s) => s.status === "COMPLETED");

	// Build per-product profitability
	const costByProduct: Record<string, number> = {};
	for (const recipe of recipes) {
		costByProduct[recipe.product_id] = Number(recipe.total_cost);
	}

	const productStats: Record<string, { name: string; revenue: number; cost: number; qty: number }> =
		{};
	for (const sale of completedSales) {
		for (const item of sale.items ?? []) {
			const pid = item.product_id;
			if (!productStats[pid]) {
				productStats[pid] = {
					name: item.product?.name ?? pid,
					revenue: 0,
					cost: 0,
					qty: 0,
				};
			}
			productStats[pid].revenue += Number(item.subtotal);
			productStats[pid].cost += (costByProduct[pid] ?? 0) * item.quantity;
			productStats[pid].qty += item.quantity;
		}
	}

	const rows = Object.values(productStats)
		.map((p) => ({
			...p,
			profit: p.revenue - p.cost,
			margin: p.revenue > 0 ? ((p.revenue - p.cost) / p.revenue) * 100 : 0,
		}))
		.sort((a, b) => b.profit - a.profit);

	const chartData = rows.slice(0, 10).map((r) => ({
		name: r.name.length > 12 ? `${r.name.slice(0, 12)}…` : r.name,
		Margen: Number(r.margin.toFixed(1)),
		fullName: r.name,
	}));

	return (
		<div>
			<PageHeader title="Rentabilidad" description="Utilidad y margen por producto" />

			{/* Chart */}
			{chartData.length > 0 && (
				<div className="mb-4 rounded-xl border border-border bg-white p-5">
					<p className="mb-4 text-sm font-medium text-foreground">Margen por producto (%)</p>
					<ResponsiveContainer width="100%" height={220}>
						<BarChart data={chartData} layout="vertical" barSize={14}>
							<CartesianGrid strokeDasharray="3 3" stroke="oklch(0.92_0_0)" horizontal={false} />
							<XAxis
								type="number"
								domain={[0, 100]}
								tick={{ fontSize: 11, fill: "oklch(0.55_0_0)" }}
								axisLine={false}
								tickLine={false}
								tickFormatter={(v: number) => `${v}%`}
							/>
							<YAxis
								type="category"
								dataKey="name"
								tick={{ fontSize: 11, fill: "oklch(0.55_0_0)" }}
								axisLine={false}
								tickLine={false}
								width={90}
							/>
							<Tooltip
								contentStyle={{ fontSize: 12, borderRadius: 8, border: "1px solid oklch(0.9_0_0)" }}
								formatter={(v: number, _: string, props) => [
									`${v.toFixed(1)}%`,
									props.payload.fullName,
								]}
							/>
							<Bar dataKey="Margen" radius={[0, 3, 3, 0]}>
								{chartData.map((entry) => (
									<Cell
										key={entry.fullName}
										fill={
											entry.Margen >= 30
												? "oklch(0.35_0_0)"
												: entry.Margen >= 15
													? "oklch(0.55_0_0)"
													: "oklch(0.75_0_0)"
										}
									/>
								))}
							</Bar>
						</BarChart>
					</ResponsiveContainer>
				</div>
			)}

			{/* Table */}
			{rows.length === 0 ? (
				<div className="rounded-xl border border-dashed border-border bg-white py-16 text-center">
					<p className="text-sm font-medium text-foreground">Sin datos de rentabilidad</p>
					<p className="mt-1 text-xs text-muted-foreground">
						Necesitas ventas completadas y recetas con costos
					</p>
				</div>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Producto
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Vendidos
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Ingresos
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Costo
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Utilidad
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Margen
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{rows.map((r) => (
								<tr key={r.name}>
									<td className="px-4 py-3 font-medium text-foreground">{r.name}</td>
									<td className="px-4 py-3 text-right text-muted-foreground">{r.qty}</td>
									<td className="px-4 py-3 text-right text-foreground">
										S/ {r.revenue.toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-muted-foreground">
										S/ {r.cost.toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right font-medium text-foreground">
										S/ {r.profit.toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right">
										<span
											className={`text-xs font-medium ${
												r.margin >= 30
													? "text-[oklch(0.4_0.1_145)]"
													: r.margin >= 15
														? "text-foreground"
														: "text-[oklch(0.5_0.1_30)]"
											}`}
										>
											{r.margin.toFixed(1)}%
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
