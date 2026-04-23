import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import {
	Area,
	AreaChart,
	CartesianGrid,
	ResponsiveContainer,
	Tooltip,
	XAxis,
	YAxis,
} from "recharts";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import type { Expense, Sale } from "@/types/api";

export const Route = createFileRoute("/_auth/reports/period")({
	beforeLoad: () => requireRole("OWNER"),
	component: PeriodReportPage,
});

type Period = "7d" | "30d" | "90d";

const PERIOD_LABELS: Record<Period, string> = {
	"7d": "7 días",
	"30d": "30 días",
	"90d": "90 días",
};

const PERIOD_DAYS: Record<Period, number> = { "7d": 7, "30d": 30, "90d": 90 };

function PeriodReportPage() {
	const [period, setPeriod] = useState<Period>("30d");

	const { data: sales = [] } = useQuery<Sale[]>({
		queryKey: ["sales"],
		queryFn: () => api.get("/sales").then((r) => r.data),
	});

	const { data: expenses = [] } = useQuery<Expense[]>({
		queryKey: ["expenses"],
		queryFn: () => api.get("/expenses").then((r) => r.data),
	});

	const days = PERIOD_DAYS[period];
	const cutoff = new Date();
	cutoff.setDate(cutoff.getDate() - days);

	const completedSales = sales.filter(
		(s) => s.status === "COMPLETED" && new Date(s.created_at) >= cutoff,
	);
	const periodExpenses = expenses.filter((e) => new Date(e.date) >= cutoff);

	const totalRevenue = completedSales.reduce((acc, s) => acc + Number(s.total), 0);
	const totalExpenses = periodExpenses.reduce((acc, e) => acc + Number(e.amount), 0);
	const profit = totalRevenue - totalExpenses;
	const margin = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;

	// Build daily buckets
	const buckets = Array.from({ length: days }, (_, i) => {
		const d = new Date();
		d.setDate(d.getDate() - (days - 1 - i));
		const dayStr = d.toISOString().split("T")[0];
		const revenue = completedSales
			.filter((s) => s.created_at.startsWith(dayStr))
			.reduce((acc, s) => acc + Number(s.total), 0);
		const exp = periodExpenses
			.filter((e) => e.date.startsWith(dayStr))
			.reduce((acc, e) => acc + Number(e.amount), 0);
		return {
			day: d.toLocaleDateString("es-PE", { day: "2-digit", month: "2-digit" }),
			Ingresos: revenue,
			Gastos: exp,
			Utilidad: revenue - exp,
		};
	});

	// Expense breakdown by category
	const byCategory: Record<string, number> = {};
	for (const e of periodExpenses) {
		byCategory[e.category] = (byCategory[e.category] ?? 0) + Number(e.amount);
	}
	const categoryRows = Object.entries(byCategory).sort((a, b) => b[1] - a[1]);

	return (
		<div>
			<PageHeader title="Reporte por período" description="Ingresos, gastos y utilidad" />

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

			{/* KPI strip */}
			<div className="mb-6 grid grid-cols-4 gap-4">
				{[
					{ label: "Ingresos", value: `S/ ${totalRevenue.toFixed(2)}` },
					{ label: "Gastos", value: `S/ ${totalExpenses.toFixed(2)}` },
					{ label: "Utilidad", value: `S/ ${profit.toFixed(2)}` },
					{ label: "Margen", value: `${margin.toFixed(1)}%` },
				].map((k) => (
					<div key={k.label} className="rounded-xl border border-border bg-white p-4">
						<p className="text-xs text-muted-foreground">{k.label}</p>
						<p className="mt-1 text-xl font-semibold text-foreground">{k.value}</p>
					</div>
				))}
			</div>

			{/* Area chart */}
			<div className="mb-4 rounded-xl border border-border bg-white p-5">
				<p className="mb-4 text-sm font-medium text-foreground">Evolución diaria</p>
				<ResponsiveContainer width="100%" height={220}>
					<AreaChart data={buckets}>
						<defs>
							<linearGradient id="fillRev" x1="0" y1="0" x2="0" y2="1">
								<stop offset="5%" stopColor="oklch(0.35_0_0)" stopOpacity={0.12} />
								<stop offset="95%" stopColor="oklch(0.35_0_0)" stopOpacity={0} />
							</linearGradient>
						</defs>
						<CartesianGrid strokeDasharray="3 3" stroke="oklch(0.92_0_0)" vertical={false} />
						<XAxis
							dataKey="day"
							tick={{ fontSize: 11, fill: "oklch(0.55_0_0)" }}
							axisLine={false}
							tickLine={false}
						/>
						<YAxis
							tick={{ fontSize: 11, fill: "oklch(0.55_0_0)" }}
							axisLine={false}
							tickLine={false}
							tickFormatter={(v: number) => `S/${v}`}
						/>
						<Tooltip
							contentStyle={{ fontSize: 12, borderRadius: 8, border: "1px solid oklch(0.9_0_0)" }}
							formatter={(v: number) => `S/ ${v.toFixed(2)}`}
						/>
						<Area
							type="monotone"
							dataKey="Ingresos"
							stroke="oklch(0.35_0_0)"
							fill="url(#fillRev)"
							strokeWidth={2}
							dot={false}
						/>
						<Area
							type="monotone"
							dataKey="Gastos"
							stroke="oklch(0.65_0_0)"
							fill="transparent"
							strokeWidth={1.5}
							strokeDasharray="4 2"
							dot={false}
						/>
					</AreaChart>
				</ResponsiveContainer>
			</div>

			{/* Expense breakdown */}
			{categoryRows.length > 0 && (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<div className="border-b border-border px-4 py-3">
						<p className="text-sm font-medium text-foreground">Gastos por categoría</p>
					</div>
					<table className="w-full text-sm">
						<tbody className="divide-y divide-border">
							{categoryRows.map(([cat, amount]) => (
								<tr key={cat}>
									<td className="px-4 py-3 text-foreground">{cat}</td>
									<td className="px-4 py-3 text-right font-medium text-foreground">
										S/ {amount.toFixed(2)}
									</td>
									<td className="px-4 py-3 text-right text-xs text-muted-foreground w-20">
										{totalExpenses > 0 ? ((amount / totalExpenses) * 100).toFixed(1) : 0}%
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
