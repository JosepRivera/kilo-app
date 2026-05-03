import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/dashboard/")({
	beforeLoad: () => requireRole("OWNER"),
	component: DashboardPage,
});

interface DashboardData {
	cash_income: number;
	digital_income: number;
	total_income: number;
	open_orders: number;
	paid_orders: number;
	total_expenses: number;
	estimated_profit: number;
	top_products: { product_id: string; name: string; quantity: number; revenue: number }[];
}

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
	const now = new Date();

	const { data, isLoading } = useQuery<DashboardData>({
		queryKey: ["dashboard"],
		queryFn: () => api.get("/dashboard").then((r) => r.data),
		refetchInterval: 60_000,
	});

	const chartData = data
		? [
				{ label: "Efectivo", Ingresos: Number(data.cash_income) },
				{ label: "Digital", Ingresos: Number(data.digital_income) },
			]
		: [];

	if (isLoading) {
		return (
			<div>
				<PageHeader
					title="Dashboard"
					description={now.toLocaleDateString("es-PE", { month: "long", year: "numeric" })}
				/>
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			</div>
		);
	}

	const d = data ?? {
		cash_income: 0,
		digital_income: 0,
		total_income: 0,
		open_orders: 0,
		paid_orders: 0,
		total_expenses: 0,
		estimated_profit: 0,
		top_products: [],
	};

	return (
		<div>
			<PageHeader
				title="Dashboard"
				description={now.toLocaleDateString("es-PE", { month: "long", year: "numeric" })}
			/>

			{/* KPI cards */}
			<div className="mb-6 grid grid-cols-4 gap-4">
				<StatCard
					label="Ingresos del día"
					value={`S/ ${Number(d.total_income).toFixed(2)}`}
					sub={`${d.paid_orders} venta${d.paid_orders !== 1 ? "s" : ""} completadas`}
				/>
				<StatCard
					label="Órdenes abiertas"
					value={d.open_orders.toString()}
					sub="pendientes de cobro"
				/>
				<StatCard label="Gastos del día" value={`S/ ${Number(d.total_expenses).toFixed(2)}`} />
				<StatCard
					label="Utilidad estimada"
					value={`S/ ${Number(d.estimated_profit).toFixed(2)}`}
					sub={
						d.total_income > 0
							? `${((d.estimated_profit / d.total_income) * 100).toFixed(1)}% margen`
							: undefined
					}
				/>
			</div>

			<div className="grid grid-cols-2 gap-4">
				{/* Income by method */}
				<div className="rounded-xl border border-border bg-white p-5">
					<p className="mb-4 text-sm font-medium text-foreground">Ingresos por método de pago</p>
					<ResponsiveContainer width="100%" height={200}>
						<BarChart data={chartData} barSize={40}>
							<CartesianGrid strokeDasharray="3 3" stroke="oklch(0.92_0_0)" vertical={false} />
							<XAxis
								dataKey="label"
								tick={{ fontSize: 12, fill: "oklch(0.55_0_0)" }}
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
					{d.top_products.length === 0 ? (
						<p className="py-8 text-center text-xs text-muted-foreground">Sin datos</p>
					) : (
						<div className="space-y-3">
							{d.top_products.map((p, i) => (
								<div key={p.product_id} className="flex items-center gap-3">
									<span className="w-4 shrink-0 text-xs text-muted-foreground">{i + 1}</span>
									<div className="min-w-0 flex-1">
										<p className="truncate text-xs font-medium text-foreground">{p.name}</p>
										<p className="text-xs text-muted-foreground">{p.quantity} unid.</p>
									</div>
									<span className="text-xs font-medium text-foreground">
										S/ {Number(p.revenue).toFixed(0)}
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
