import React, { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { createFileRoute, Link } from "@tanstack/react-router";
import {
	AlertCircle,
	AlertTriangle,
	ArrowUpRight,
	Award,
	Bell,
	Clock,
	FileText,
	Medal,
	Plus,
	TrendingDown,
	TrendingUp,
	Trophy,
	Users,
} from "lucide-react";
import {
	Area,
	AreaChart,
	CartesianGrid,
	Line,
	LineChart,
	ResponsiveContainer,
	Tooltip,
	XAxis,
	YAxis,
} from "recharts";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { useAuthStore } from "@/stores/auth.store";

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
	top_products: {
		product_id: string;
		name: string;
		quantity: number;
		revenue: number;
		category?: string;
		margin?: number | null;
	}[];
	yesterday_comparison?: {
		income: { delta: number; percent: number | null };
		expenses: { delta: number; percent: number | null };
		profit: { delta: number; percent: number | null };
		tickets: { delta: number; percent: number | null };
	} | null;
	time_series?: { date: string; income: number; expenses: number; profit: number }[];
}

interface StockAlert {
	id: string;
	name: string;
	unit: string;
	stock: number;
	min_stock: number;
	shortage: number;
}

interface OperationalAlert {
	type: "cash_close" | "open_orders" | "production_plan";
	title: string;
	sub: string;
	to: string;
}

const DEV_DATE = import.meta.env.VITE_DASHBOARD_DATE as string | undefined;

// ─── helpers ─────────────────────────────────────────────────────────────────

function greeting() {
	const h = new Date().getHours();
	if (h < 12) return "Buenos días";
	if (h < 19) return "Buenas tardes";
	return "Buenas noches";
}

// ─── sub-components ──────────────────────────────────────────────────────────

function Sparkline({ data, color, fill }: { data: { v: number }[]; color: string; fill: string }) {
	return (
		<ResponsiveContainer width="100%" height={44}>
			<AreaChart data={data} margin={{ top: 2, right: 0, bottom: 0, left: 0 }}>
				<defs>
					<linearGradient id={`grad-${color.replace("#", "")}`} x1="0" y1="0" x2="0" y2="1">
						<stop offset="0%" stopColor={fill} stopOpacity={0.35} />
						<stop offset="100%" stopColor={fill} stopOpacity={0} />
					</linearGradient>
				</defs>
				<Area
					type="monotone"
					dataKey="v"
					stroke={color}
					strokeWidth={1.5}
					fill={`url(#grad-${color.replace("#", "")})`}
					dot={false}
					isAnimationActive={false}
				/>
			</AreaChart>
		</ResponsiveContainer>
	);
}

interface KpiCardProps {
	label: string;
	value: string;
	sub: string;
	delta: string;
	positive: boolean;
	sparkData: { v: number }[];
	color: string;
	fill: string;
}

function KpiCard({ label, value, sub, delta, positive, sparkData, color, fill }: KpiCardProps) {
	return (
		<div className="flex flex-col justify-between rounded-xl border border-gray-100 bg-white p-4 shadow-sm">
			<div className="flex items-start justify-between">
				<div>
					<p className="text-xs text-gray-400">{label}</p>
					<p className="mt-1 text-2xl font-bold tracking-tight text-gray-900">{value}</p>
				</div>
				<span
					className={`flex items-center gap-0.5 rounded-full px-2 py-0.5 text-xs font-semibold ${
						positive ? "bg-green-50 text-green-600" : "bg-red-50 text-red-500"
					}`}
				>
					{positive ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
					{delta}
				</span>
			</div>
			<Sparkline data={sparkData} color={color} fill={fill} />
			<p className="mt-1 text-[11px] text-gray-400">{sub}</p>
		</div>
	);
}

type ChartPeriod = "7d" | "14d" | "30d";

function ChartTooltip({ active, payload, label }: { active?: boolean; payload?: { dataKey: string; value: number }[]; label?: string }) {
	if (!active || !payload?.length) return null;
	const ventas = payload.find((p) => p.dataKey === "ventas")?.value ?? 0;
	const ganancia = payload.find((p) => p.dataKey === "ganancia")?.value ?? 0;
	const marginPct = ventas > 0 ? ((ganancia / ventas) * 100).toFixed(1) : "0.0";
	return (
		<div className="min-w-[172px] rounded-xl border border-gray-200 bg-white p-3 shadow-lg">
			<p className="mb-2 text-xs font-semibold text-gray-700">Día {label}</p>
			<div className="space-y-1.5 text-xs">
				<div className="flex items-center justify-between gap-6">
					<span className="flex items-center gap-1.5 text-gray-500">
						<span className="inline-block h-2 w-2 rounded-full bg-blue-500" />
						Ventas
					</span>
					<span className="font-semibold text-gray-800">S/ {ventas.toLocaleString("es-PE")}</span>
				</div>
				<div className="flex items-center justify-between gap-6">
					<span className="flex items-center gap-1.5 text-gray-500">
						<span className="inline-block h-2 w-2 rounded-full bg-violet-500" />
						Ganancia
					</span>
					<span className="font-semibold text-gray-800">S/ {ganancia.toLocaleString("es-PE")}</span>
				</div>
				<div className="mt-2 flex items-center justify-between border-t border-gray-100 pt-2">
					<span className="text-gray-400">Margen neto</span>
					<span className={`font-bold ${Number(marginPct) >= 35 ? "text-green-600" : "text-amber-500"}`}>
						{marginPct}%
					</span>
				</div>
			</div>
		</div>
	);
}

function SalesChart({ data30d, dashboard }: { data30d: { d: string; ventas: number; ganancia: number }[]; dashboard: DashboardData }) {
	const [period, setPeriod] = useState<ChartPeriod>("14d");
	const sliceMap: Record<ChartPeriod, number> = { "7d": 7, "14d": 14, "30d": 30 };
	const chartData = data30d.slice(-sliceMap[period]);
	const periodLabel = period === "7d" ? "7" : period === "14d" ? "14" : "30";

	const digitalPct = dashboard.total_income > 0 ? Math.round((dashboard.digital_income / dashboard.total_income) * 100) : 0;
	const cashPct = dashboard.total_income > 0 ? Math.round((dashboard.cash_income / dashboard.total_income) * 100) : 0;

	const footerItems = [
		{
			label: "PRODUCTO TOP",
			value: dashboard.top_products[0]?.name ?? "Sin datos",
			sub: dashboard.top_products[0] ? `${dashboard.top_products[0].quantity} unidades` : "—",
		},
		{
			label: "PAGO DIGITAL",
			value: digitalPct > 0 ? `${digitalPct}%` : "—",
			sub: dashboard.digital_income > 0 ? `S/ ${Math.round(dashboard.digital_income).toLocaleString("es-PE")}` : "Sin transacciones",
		},
		{
			label: "EFECTIVO",
			value: cashPct > 0 ? `${cashPct}%` : "—",
			sub: dashboard.cash_income > 0 ? `S/ ${Math.round(dashboard.cash_income).toLocaleString("es-PE")}` : "Sin transacciones",
		},
		{
			label: "ÓRDENES HOY",
			value: dashboard.paid_orders.toString(),
			sub: dashboard.open_orders > 0 ? `${dashboard.open_orders} pendientes` : "Todas cerradas",
		},
	];

	return (
		<div className="rounded-xl border border-gray-100 bg-white p-5 shadow-sm">
			<div className="mb-4 flex items-center justify-between">
				<p className="text-sm font-semibold text-gray-800">
					Ventas — últimos {periodLabel} días
				</p>
				<div className="flex items-center gap-3">
					<div className="flex items-center gap-2 text-xs text-gray-400">
						<span className="inline-block h-2 w-4 rounded-full bg-blue-500" />
						Ventas
						<span className="ml-2 inline-block h-2 w-4 rounded-full bg-violet-500" />
						Ganancia
					</div>
					<div className="flex overflow-hidden rounded-lg border border-gray-200 text-xs">
						{(["7d", "14d", "30d"] as ChartPeriod[]).map((p) => (
							<button
								key={p}
								type="button"
								onClick={() => setPeriod(p)}
								className={`px-2.5 py-1 transition-colors ${
									period === p ? "bg-gray-900 text-white" : "bg-white text-gray-500 hover:bg-gray-50"
								}`}
							>
								{p}
							</button>
						))}
					</div>
				</div>
			</div>
			<ResponsiveContainer width="100%" height={200}>
				<LineChart data={chartData} margin={{ top: 4, right: 8, bottom: 0, left: 0 }}>
					<CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
					<XAxis dataKey="d" tick={{ fontSize: 11, fill: "#94a3b8" }} axisLine={false} tickLine={false} />
					<YAxis
						tick={{ fontSize: 11, fill: "#94a3b8" }}
						axisLine={false}
						tickLine={false}
						tickFormatter={(v: number) => `${(v / 1000).toFixed(1)}k`}
						width={36}
					/>
					<Tooltip content={<ChartTooltip />} />
					<Line type="monotone" dataKey="ventas" stroke="#3b82f6" strokeWidth={2} dot={false} activeDot={{ r: 4, fill: "#3b82f6" }} />
					<Line type="monotone" dataKey="ganancia" stroke="#8b5cf6" strokeWidth={2} dot={false} activeDot={{ r: 4, fill: "#8b5cf6" }} />
				</LineChart>
			</ResponsiveContainer>
			<div className="mt-4 grid grid-cols-2 divide-gray-100 border-t border-gray-100 pt-4 gap-y-3 lg:grid-cols-4 lg:divide-x">
				{footerItems.map((item) => (
					<div key={item.label} className="px-4 first:pl-0 last:pr-0">
						<p className="text-[10px] font-semibold uppercase tracking-wider text-gray-400">{item.label}</p>
						<p className="mt-1 text-sm font-semibold text-gray-800">{item.value}</p>
						<p className="text-[11px] text-gray-400">{item.sub}</p>
					</div>
				))}
			</div>
		</div>
	);
}

const OPERATIONAL_ICONS: Record<string, React.ReactNode> = {
	cash_close: <Clock size={15} className="text-orange-500" />,
	open_orders: <FileText size={15} className="text-blue-500" />,
	production_plan: <Users size={15} className="text-slate-500" />,
};

const OPERATIONAL_BG: Record<string, string> = {
	cash_close: "bg-orange-50",
	open_orders: "bg-blue-50",
	production_plan: "bg-slate-50",
};

const MARGIN_COLOR = (m: number) =>
	m >= 50 ? "text-green-600" : m >= 35 ? "text-amber-600" : "text-gray-500";

// ─── page ─────────────────────────────────────────────────────────────────────

function DashboardPage() {
	const { user } = useAuthStore();
	const now = new Date();

	const dateLabel = now.toLocaleDateString("es-PE", { weekday: "long", day: "numeric", month: "long" });
	const timeLabel = now.toLocaleTimeString("es-PE", { hour: "2-digit", minute: "2-digit" });

	const dashboardUrl = DEV_DATE ? `/dashboard?date=${DEV_DATE}` : "/dashboard";

	const { data, isLoading } = useQuery<DashboardData>({
		queryKey: ["dashboard", DEV_DATE],
		queryFn: () => api.get(dashboardUrl).then((r) => r.data),
		refetchInterval: 60_000,
		staleTime: 30_000,
	});

	const { data: stockAlerts = [] } = useQuery<StockAlert[]>({
		queryKey: ["alerts-stock"],
		queryFn: () => api.get("/alerts/stock").then((r) => r.data),
		refetchInterval: 60_000,
		staleTime: 30_000,
	});

	const { data: operationalAlerts = [] } = useQuery<OperationalAlert[]>({
		queryKey: ["alerts-operational"],
		queryFn: () => api.get("/alerts/operational").then((r) => r.data),
		refetchInterval: 60_000,
		staleTime: 30_000,
	});

	const d = data ?? {
		cash_income: 0,
		digital_income: 0,
		total_income: 0,
		open_orders: 0,
		paid_orders: 0,
		total_expenses: 0,
		estimated_profit: 0,
		top_products: [],
		yesterday_comparison: null,
		time_series: [],
	};

	const totalQty = d.top_products.reduce((s, p) => s + p.quantity, 0);
	const margin = d.total_income > 0 ? ((d.estimated_profit / d.total_income) * 100).toFixed(1) : "0.0";

	// Sparkline data from time_series (last 7 days)
	const sparkSales = useMemo(
		() => (d.time_series ?? []).slice(-7).map((t) => ({ v: t.income })),
		[d.time_series],
	);
	const sparkProfit = useMemo(
		() => (d.time_series ?? []).slice(-7).map((t) => ({ v: t.profit })),
		[d.time_series],
	);
	const sparkOrders = useMemo(() => {
		// Use real sparkline if time_series has data, fallback to simple pattern
		const ts = d.time_series ?? [];
		if (ts.length > 0) return ts.slice(-7).map((t) => ({ v: t.income }));
		return Array.from({ length: 7 }, () => ({ v: 0 }));
	}, [d.time_series]);
	const sparkProducts = useMemo(() => {
		const ts = d.time_series ?? [];
		if (ts.length > 0) return ts.slice(-7).map((t) => ({ v: t.profit }));
		return Array.from({ length: 7 }, () => ({ v: 0 }));
	}, [d.time_series]);

	// Chart data from time_series
	const chart30d = useMemo(
		() =>
			(d.time_series ?? []).map((t) => ({
				d: t.date.slice(8), // DD from YYYY-MM-DD
				ventas: t.income,
				ganancia: t.profit,
			})),
		[d.time_series],
	);

	// Format KPI delta from yesterday_comparison
	const formatDelta = (delta: number, percent: number | null | undefined): { text: string; positive: boolean } => {
		if (percent == null) {
			return { text: delta >= 0 ? `+${delta}` : `${delta}`, positive: delta >= 0 };
		}
		const sign = percent >= 0 ? "+" : "";
		return { text: `${sign}${percent.toFixed(1)}%`, positive: percent >= 0 };
	};

	const salesDelta = d.yesterday_comparison
		? formatDelta(d.yesterday_comparison.income.delta, d.yesterday_comparison.income.percent)
		: { text: "N/A", positive: true };
	const profitDelta = d.yesterday_comparison
		? formatDelta(d.yesterday_comparison.profit.delta, d.yesterday_comparison.profit.percent)
		: { text: "N/A", positive: true };
	const ordersDelta = d.yesterday_comparison
		? formatDelta(d.yesterday_comparison.tickets.delta, d.yesterday_comparison.tickets.percent)
		: { text: "N/A", positive: true };

	const totalAlerts = stockAlerts.length + operationalAlerts.length;

	return (
		<div className="space-y-5">
			{/* ── header ── */}
			<div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
				<div>
					<h1 className="text-xl font-bold text-gray-900 lg:text-2xl">
						{greeting()}, {user?.name?.split(" ")[0]}.
					</h1>
					<p className="mt-0.5 flex flex-wrap items-center gap-1.5 text-sm text-gray-400">
						<span className="capitalize">{dateLabel}</span>
						<span>·</span>
						<span>{timeLabel}</span>
						<span>·</span>
						<span className="flex items-center gap-1 text-orange-500">
							<AlertCircle size={13} />
							{totalAlerts} alertas pendientes
						</span>
					</p>
				</div>
				<div className="flex flex-wrap items-center gap-2">
					<Link
						to="/cash-closes"
						className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm font-medium text-gray-700 shadow-sm transition-colors hover:bg-gray-50"
					>
						<FileText size={14} />
						Cierre del día
					</Link>
					<Link
						to="/sales/new"
						className="flex items-center gap-1.5 rounded-lg bg-orange-500 px-3 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-orange-600"
					>
						<Plus size={14} />
						Nueva venta
					</Link>
				</div>
			</div>

			{/* ── KPI cards ── */}
			{isLoading ? (
				<div className="grid grid-cols-2 gap-3 lg:grid-cols-4 lg:gap-4">
					{Array.from({ length: 4 }).map((_, i) => (
						<div key={i} className="h-32 animate-pulse rounded-xl bg-gray-100" />
					))}
				</div>
			) : (
				<div className="grid grid-cols-2 gap-3 lg:grid-cols-4 lg:gap-4">
					<KpiCard
						label="Ventas hoy"
						value={`S/ ${Number(d.total_income).toLocaleString("es-PE", { maximumFractionDigits: 0 })}`}
						sub={d.yesterday_comparison ? "vs. ayer" : "Sin datos previos"}
						delta={salesDelta.text}
						positive={salesDelta.positive}
						sparkData={sparkSales}
						color="#f97316"
						fill="#f97316"
					/>
					<KpiCard
						label="Ganancia neta"
						value={`S/ ${Number(d.estimated_profit).toLocaleString("es-PE", { maximumFractionDigits: 0 })}`}
						sub={`margen ${margin}%`}
						delta={profitDelta.text}
						positive={profitDelta.positive}
						sparkData={sparkProfit}
						color="#22c55e"
						fill="#22c55e"
					/>
					<KpiCard
						label="Órdenes"
						value={d.paid_orders.toString()}
						sub={`ticket promedio S/ ${d.paid_orders > 0 ? (Number(d.total_income) / d.paid_orders).toFixed(2) : "0.00"}`}
						delta={ordersDelta.text}
						positive={ordersDelta.positive}
						sparkData={sparkOrders}
						color="#64748b"
						fill="#64748b"
					/>
					<KpiCard
						label="Productos vendidos"
						value={totalQty.toString()}
						sub={`${d.top_products.length} SKUs activos`}
						delta={d.yesterday_comparison ? `${d.yesterday_comparison.tickets.delta >= 0 ? "+" : ""}${d.yesterday_comparison.tickets.delta}` : "N/A"}
						positive={d.yesterday_comparison ? d.yesterday_comparison.tickets.delta >= 0 : true}
						sparkData={sparkProducts}
						color="#ef4444"
						fill="#ef4444"
					/>
				</div>
			)}

			{/* ── chart + alerts side by side ── */}
			<div className="grid grid-cols-1 gap-4 xl:grid-cols-[1fr_340px]">
				<SalesChart data30d={chart30d} dashboard={d} />

				{/* alerts panel */}
				<div className="rounded-xl border border-gray-100 bg-white shadow-sm">
					<div className="flex items-center justify-between border-b border-gray-100 px-5 py-4">
						<p className="text-sm font-semibold text-gray-800">Alertas operativas</p>
						<span className="rounded-full bg-red-50 px-2 py-0.5 text-xs font-semibold text-red-500">
							{totalAlerts} activas
						</span>
					</div>
					<div className="divide-y divide-gray-50">
						{/* real stock alerts from API */}
						{stockAlerts.map((a) => (
							<div key={a.id} className="flex items-start gap-3 px-5 py-3.5">
								<div className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-red-50">
									<AlertTriangle size={15} className="text-red-500" />
								</div>
								<div className="min-w-0 flex-1">
									<p className="text-xs font-semibold text-gray-800">{a.name} bajo mínimo</p>
									<p className="text-[11px] text-gray-400">
										{a.stock} {a.unit} · déficit {a.shortage} {a.unit}
									</p>
								</div>
								<Link
									to="/ingredients"
									className="flex shrink-0 items-center gap-0.5 text-[11px] font-semibold text-blue-600 hover:text-blue-700"
								>
									Ver
									<ArrowUpRight size={11} />
								</Link>
							</div>
						))}
						{/* operational alerts from API */}
						{operationalAlerts.map((alert) => (
							<div key={alert.type} className="flex items-start gap-3 px-5 py-3.5">
								<div
									className={`mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-full ${OPERATIONAL_BG[alert.type] ?? "bg-gray-50"}`}
								>
									{OPERATIONAL_ICONS[alert.type]}
								</div>
								<div className="min-w-0 flex-1">
									<p className="text-xs font-semibold text-gray-800">{alert.title}</p>
									<p className="text-[11px] text-gray-400">{alert.sub}</p>
								</div>
								<Link
									to={alert.to}
									className="flex shrink-0 items-center gap-0.5 text-[11px] font-semibold text-blue-600 hover:text-blue-700"
								>
									Ver
									<ArrowUpRight size={11} />
								</Link>
							</div>
						))}
					</div>
				</div>
			</div>

			{/* ── products table (full width) ── */}
			<div className="rounded-xl border border-gray-100 bg-white shadow-sm">
				<div className="flex items-center justify-between border-b border-gray-100 px-5 py-4">
					<p className="text-sm font-semibold text-gray-800">Productos más vendidos</p>
					<p className="text-xs text-gray-400">hoy · {d.paid_orders} órdenes</p>
				</div>
				{d.top_products.length === 0 ? (
					<p className="py-10 text-center text-xs text-gray-400">Sin datos por ahora</p>
				) : (
					<div className="overflow-x-auto">
					<table className="w-full min-w-[500px] text-xs">
						<thead>
							<tr className="border-b border-gray-100">
								<th className="px-5 py-2.5 text-left font-semibold uppercase tracking-wide text-gray-400">Producto</th>
								<th className="px-3 py-2.5 text-left font-semibold uppercase tracking-wide text-gray-400">Categoría</th>
								<th className="px-3 py-2.5 text-right font-semibold uppercase tracking-wide text-gray-400">Unidades</th>
								<th className="px-3 py-2.5 text-right font-semibold uppercase tracking-wide text-gray-400">Ingreso</th>
								<th className="px-5 py-2.5 text-right font-semibold uppercase tracking-wide text-gray-400">Margen</th>
							</tr>
						</thead>
						<tbody className="divide-y divide-gray-50">
							{d.top_products.map((p, i) => {
								const m = p.margin ?? null;
								return (
									<tr key={p.product_id} className="hover:bg-gray-50">
										<td className="px-5 py-3">
											<div className="flex items-center gap-2.5">
												{i === 0 ? (
													<span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-amber-100">
														<Trophy size={13} className="text-amber-500" />
													</span>
												) : i === 1 ? (
													<span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-slate-100">
														<Medal size={13} className="text-slate-400" />
													</span>
												) : i === 2 ? (
													<span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-orange-100">
														<Award size={13} className="text-orange-600" />
													</span>
												) : (
													<span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gray-100 text-[10px] font-bold text-gray-400">
														{i + 1}
													</span>
												)}
												<span className="font-medium text-gray-800">{p.name}</span>
											</div>
										</td>
										<td className="px-3 py-3 text-gray-400">{p.category ?? "Otros"}</td>
										<td className="px-3 py-3 text-right font-medium text-gray-700">{p.quantity}</td>
										<td className="px-3 py-3 text-right font-medium text-gray-700">
											S/ {Number(p.revenue).toLocaleString("es-PE", { maximumFractionDigits: 2 })}
										</td>
										<td className={`px-5 py-3 text-right font-bold ${m != null ? MARGIN_COLOR(m) : "text-gray-400"}`}>
											{m != null ? `${m}%` : "N/A"}
										</td>
									</tr>
								);
							})}
						</tbody>
					</table>
					</div>
				)}
			</div>

			{/* ── voice FAB ── */}
			<div className="pointer-events-none fixed bottom-6 right-6">
				<button
					type="button"
					className="pointer-events-auto flex items-center gap-2 rounded-full bg-gray-900 px-4 py-2.5 text-xs font-medium text-white shadow-lg transition-colors hover:bg-gray-800"
				>
					<Bell size={14} className="text-orange-400" />
					<span>
						Registro por voz
						<br />
						<span className="text-[10px] font-normal text-gray-400">Mantén · Espacio</span>
					</span>
				</button>
			</div>
		</div>
	);
}
