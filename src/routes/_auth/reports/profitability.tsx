import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
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

export const Route = createFileRoute("/_auth/reports/profitability")({
	beforeLoad: () => requireRole("OWNER"),
	component: ProfitabilityPage,
});

type Period = "7d" | "30d" | "90d";

const PERIOD_LABELS: Record<Period, string> = {
	"7d": "7 días",
	"30d": "30 días",
	"90d": "90 días",
};

interface ProfitabilityRow {
	product_id: string;
	name: string;
	category: string;
	sale_price: number;
	unit_cost: number;
	unit_margin: number;
	margin_percentage: number;
}

function getDateRange(days: number): { from: string; to: string } {
	const to = new Date();
	const from = new Date();
	from.setDate(from.getDate() - (days - 1));
	return {
		from: from.toISOString().split("T")[0],
		to: to.toISOString().split("T")[0],
	};
}

function ProfitabilityPage() {
	const [period, setPeriod] = useState<Period>("30d");
	const { from, to } = getDateRange({ "7d": 7, "30d": 30, "90d": 90 }[period]);

	const { data: rows = [] } = useQuery<ProfitabilityRow[]>({
		queryKey: ["reports-profitability", from, to],
		queryFn: () =>
			api
				.get("/reports/profitability", { params: { from, to } })
				.then((r) => (Array.isArray(r.data) ? r.data : [])),
	});

	const chartData = rows.slice(0, 10).map((r) => ({
		name: r.name.length > 12 ? `${r.name.slice(0, 12)}…` : r.name,
		Margen: Number(r.margin_percentage.toFixed(1)),
		fullName: r.name,
	}));

	return (
		<div>
			<PageHeader title="Rentabilidad" description="Utilidad y margen por producto" />

			{/* Period selector */}
			<div className="mb-6 flex gap-1">
				{(Object.keys(PERIOD_LABELS) as Period[]).map((p) => (
					<button
						key={p}
						type="button"
						onClick={() => setPeriod(p)}
						className={`rounded-md px-3 py-1.5 text-xs font-medium transition-colors ${
							period === p
								? "bg-foreground text-background"
								: "text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
						}`}
					>
						{PERIOD_LABELS[p]}
					</button>
				))}
			</div>

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
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Categoría
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Precio
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Costo
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Margen unit.
								</th>
								<th className="px-4 py-3 text-right text-xs font-medium text-muted-foreground">
									Margen %
								</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{rows.map((r) => (
								<tr key={r.product_id}>
									<td className="px-4 py-3 font-medium text-foreground">{r.name}</td>
									<td className="px-4 py-3 text-muted-foreground">{r.category}</td>
									<td className="px-4 py-3 text-right text-foreground">
										S/ {Number(r.sale_price).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-muted-foreground">
										S/ {Number(r.unit_cost).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right font-medium text-foreground">
										S/ {Number(r.unit_margin).toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right">
										<span
											className={`text-xs font-medium ${
												r.margin_percentage >= 30
													? "text-[oklch(0.4_0.1_145)]"
													: r.margin_percentage >= 15
														? "text-foreground"
														: "text-[oklch(0.5_0.1_30)]"
											}`}
										>
											{Number(r.margin_percentage).toFixed(1)}%
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
