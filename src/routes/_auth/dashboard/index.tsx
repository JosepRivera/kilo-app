import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import type { Expense, Sale } from "@/types/api";

export const Route = createFileRoute("/_auth/dashboard/")({
	beforeLoad: () => requireRole("OWNER"),
	component: DashboardPage,
});

interface StatCardProps {
	label: string;
	value: string;
	sub?: string;
}

function StatCard({ label, value, sub }: StatCardProps) {
	return (
		<div className="rounded-xl border border-border bg-white p-5">
			<p className="text-xs font-medium text-muted-foreground">{label}</p>
			<p className="mt-1 text-2xl font-semibold tracking-tight text-foreground">{value}</p>
			{sub && <p className="mt-0.5 text-xs text-muted-foreground">{sub}</p>}
		</div>
	);
}

function DashboardPage() {
	const { data: sales = [] } = useQuery<Sale[]>({
		queryKey: ["sales"],
		queryFn: () => api.get("/sales").then((r) => r.data),
	});

	const { data: expenses = [] } = useQuery<Expense[]>({
		queryKey: ["expenses"],
		queryFn: () => api.get("/expenses").then((r) => r.data),
	});

	const now = new Date();
	const isThisMonth = (dateStr: string) => {
		const d = new Date(dateStr);
		return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
	};

	const completedSales = sales.filter((s) => s.status === "COMPLETED");
	const monthSales = completedSales.filter((s) => isThisMonth(s.created_at));
	const monthRevenue = monthSales.reduce((acc, s) => acc + Number(s.total), 0);
	const monthExpenses = expenses
		.filter((e) => isThisMonth(e.date))
		.reduce((acc, e) => acc + Number(e.amount), 0);
	const monthProfit = monthRevenue - monthExpenses;

	// Daily revenue chart — last 14 days
	const last14 = Array.from({ length: 14 }, (_, i) => {
		const d = new Date();
		d.setDate(d.getDate() - (13 - i));
		return d;
	});

	const chartData = last14.map((d) => {
		const dayStr = d.toISOString().split("T")[0];
		const revenue = completedSales
			.filter((s) => s.created_at.startsWith(dayStr))
			.reduce((acc, s) => acc + Number(s.total), 0);
		return {
			day: d.toLocaleDateString("es-PE", { day: "2-digit", month: "2-digit" }),
			Ingresos: revenue,
		};
	});

	// Top products
	const productTotals: Record<string, { name: string; count: number; revenue: number }> = {};
	for (const sale of completedSales) {
		for (const item of sale.items ?? []) {
			const pid = item.product_id;
			if (!productTotals[pid]) {
				productTotals[pid] = { name: item.product?.name ?? pid, count: 0, revenue: 0 };
			}
			productTotals[pid].count += item.quantity;
			productTotals[pid].revenue += Number(item.subtotal);
		}
	}
	const topProducts = Object.values(productTotals)
		.sort((a, b) => b.revenue - a.revenue)
		.slice(0, 5);

	return (
		<div>
			<PageHeader
				title="Dashboard"
				description={`${now.toLocaleDateString("es-PE", { month: "long", year: "numeric" })}`}
			/>

			{/* KPI cards */}
			<div className="mb-6 grid grid-cols-4 gap-4">
				<StatCard
					label="Ingresos del mes"
					value={`S/ ${monthRevenue.toFixed(2)}`}
					sub={`${monthSales.length} venta${monthSales.length !== 1 ? "s" : ""}`}
				/>
				<StatCard label="Gastos del mes" value={`S/ ${monthExpenses.toFixed(2)}`} />
				<StatCard
					label="Utilidad del mes"
					value={`S/ ${monthProfit.toFixed(2)}`}
					sub={
						monthRevenue > 0
							? `${((monthProfit / monthRevenue) * 100).toFixed(1)}% margen`
							: undefined
					}
				/>
				<StatCard
					label="Total ventas (histórico)"
					value={completedSales.length.toString()}
					sub={`S/ ${completedSales.reduce((a, s) => a + Number(s.total), 0).toFixed(2)}`}
				/>
			</div>

			<div className="grid grid-cols-3 gap-4">
				{/* Revenue chart */}
				<div className="col-span-2 rounded-xl border border-border bg-white p-5">
					<p className="mb-4 text-sm font-medium text-foreground">Ingresos — últimos 14 días</p>
					<ResponsiveContainer width="100%" height={200}>
						<BarChart data={chartData} barSize={14}>
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
								contentStyle={{
									fontSize: 12,
									borderRadius: 8,
									border: "1px solid oklch(0.9_0_0)",
									color: "oklch(0.2_0_0)",
								}}
								formatter={(v: number) => [`S/ ${v.toFixed(2)}`, "Ingresos"]}
							/>
							<Bar dataKey="Ingresos" fill="oklch(0.35_0_0)" radius={[3, 3, 0, 0]} />
						</BarChart>
					</ResponsiveContainer>
				</div>

				{/* Top products */}
				<div className="rounded-xl border border-border bg-white p-5">
					<p className="mb-4 text-sm font-medium text-foreground">Productos más vendidos</p>
					{topProducts.length === 0 ? (
						<p className="text-center text-xs text-muted-foreground py-8">Sin datos</p>
					) : (
						<div className="space-y-3">
							{topProducts.map((p, i) => (
								<div key={p.name} className="flex items-center gap-3">
									<span className="w-4 shrink-0 text-xs text-muted-foreground">{i + 1}</span>
									<div className="flex-1 min-w-0">
										<p className="truncate text-xs font-medium text-foreground">{p.name}</p>
										<p className="text-xs text-muted-foreground">{p.count} unid.</p>
									</div>
									<span className="text-xs font-medium text-foreground">
										S/ {p.revenue.toFixed(0)}
									</span>
								</div>
							))}
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
