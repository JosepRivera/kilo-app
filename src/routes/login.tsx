import React from "react";
import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
	Activity,
	BarChart2,
	Check,
	DollarSign,
	HardHat,
	Loader2,
	Mic,
	ShoppingBag,
	Store,
	TrendingUp,
	User,
	Users,
	X,
} from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import logoSrc from "@/assets/logo-smartbite.png";
import restauranteSrc from "@/assets/restaurante.png";
import { api } from "@/lib/api";
import { getHomeForRole, redirectIfAuth } from "@/lib/guards";
import { useAuthStore } from "@/stores/auth.store";
import type { LoginResponse } from "@/types/api";

export const Route = createFileRoute("/login")({
	beforeLoad: redirectIfAuth,
	component: LoginPage,
});

const loginSchema = z.object({
	username: z.string().min(1, "Ingresa tu usuario"),
	password: z.string().min(1, "Ingresa tu contraseña"),
});

type FeatureColor = "orange" | "violet" | "blue" | "green" | "rose" | "amber";
type Accent = { c: string; cb: string; cbr: string };

interface Feature {
	area: string;
	color: FeatureColor;
	icon: React.ElementType;
	module: string;
	name: string;
	desc: string;
}

const features: Feature[] = [
	{
		area: "cobros",
		color: "orange",
		icon: ShoppingBag,
		module: "Punto de Venta",
		name: "Cobros Rápidos",
		desc: "El mozo registra el pedido. El cajero lo cobra en segundos — efectivo, Yape, Plin o Ágora.",
	},
	{
		area: "ia",
		color: "violet",
		icon: Activity,
		module: "Inteligencia Artificial",
		name: "Predicción de Demanda",
		desc: "El sistema anticipa cuánto producir cada día. Menos desperdicio, sin quedarte corto.",
	},
	{
		area: "dashboard",
		color: "blue",
		icon: BarChart2,
		module: "Reportes",
		name: "Panel del Día",
		desc: "Ventas totales, efectivo en caja y desglose digital — actualizado en tiempo real.",
	},
	{
		area: "voz",
		color: "rose",
		icon: Mic,
		module: "Hands-Free",
		name: "Registro por Voz",
		desc: "Dictá el pedido sin soltar la bandeja. El formulario se llena solo.",
	},
	{
		area: "equipo",
		color: "amber",
		icon: Users,
		module: "Equipo",
		name: "Gestión de Personal",
		desc: "Cada rol ve solo lo que necesita: el cocinero el plan, el cajero la caja.",
	},
	{
		area: "finanzas",
		color: "green",
		icon: DollarSign,
		module: "Finanzas",
		name: "Cierre y Ganancias",
		desc: "Al cerrar el día: ingresos, gastos y ganancia neta en un registro inmutable.",
	},
];

const ACCENT: Record<FeatureColor, Accent> = {
	orange: { c: "#FF6A00", cb: "rgba(255,106,0,0.09)",   cbr: "rgba(255,106,0,0.20)" },
	violet: { c: "#7c5cbf", cb: "rgba(124,92,191,0.09)",  cbr: "rgba(124,92,191,0.20)" },
	blue:   { c: "#3b82f6", cb: "rgba(59,130,246,0.09)",  cbr: "rgba(59,130,246,0.20)" },
	green:  { c: "#22c55e", cb: "rgba(34,197,94,0.09)",   cbr: "rgba(34,197,94,0.20)" },
	rose:   { c: "#f43f5e", cb: "rgba(244,63,94,0.09)",   cbr: "rgba(244,63,94,0.20)" },
	amber:  { c: "#f59e0b", cb: "rgba(245,158,11,0.09)",  cbr: "rgba(245,158,11,0.20)" },
};

// Pre-computed constants — no randomness on render
const SPARKLINE_HX = "0,78 20,70 40,72 60,58 80,62 100,46 120,50 140,36 155,40 170,28 185,20 200,16 215,10 230,5";
const SPARKLINE_FILL = `${SPARKLINE_HX} 230,88 0,88`;
const FORECAST_HX = "230,5 250,2 265,0";
const WAVEFORM    = [5,10,18,26,34,28,38,22,36,16,32,20,36,24,30,14,26,34,18,28,8,22,32,12,24];
const WEEK_BARS   = [42, 61, 48, 74, 69, 100, 54];
const WEEK_DAYS   = ["L", "M", "M", "J", "V", "S", "D"];
const WEEK_VALS   = ["520", "754", "592", "912", "848", "1240", "666"];

function CobrosGraphic({ c, cb, cbr }: Accent) {
	return (
		<div style={{ marginTop: 10 }}>
			<div
				style={{
					background: "color-mix(in oklch, var(--color-card) 92%, transparent)",
					border: "1px solid color-mix(in srgb, var(--color-border) 6%, transparent)",
					borderRadius: 10,
					padding: "10px 12px",
				}}
			>
					<div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6, fontSize: 9.5, fontWeight: 600, color: "var(--login-graphic-text)" }}>
					<span>Orden #042</span>
					<span style={{ color: c }}>S/ 24.50</span>
				</div>
				{[
					{ n: "Hamburguesa Simple ×2", p: "12.00" },
					{ n: "Papas medianas ×1",     p: "6.00"  },
					{ n: "Limonada ×2",           p: "6.50"  },
				].map((item) => (
					<div key={item.n} style={{ display: "flex", justifyContent: "space-between", fontSize: 9, color: "var(--login-graphic-muted)", marginBottom: 2 }}>
						<span>{item.n}</span><span>S/ {item.p}</span>
					</div>
				))}
				<div style={{ display: "flex", gap: 4, marginTop: 8 }}>
					{["Yape", "Plin", "Efectivo"].map((m) => (
						<div key={m} style={{ flex: 1, textAlign: "center", fontSize: 9, fontWeight: 700, padding: "4px 0", borderRadius: 6, background: cb, color: c, border: `1px solid ${cbr}` }}>
							{m}
						</div>
					))}
				</div>
			</div>
			<div style={{ display: "flex", gap: 6, marginTop: 8 }}>
				<div style={{ flex: 1, background: cb, border: `1px solid ${cbr}`, borderRadius: 8, padding: "6px 8px", textAlign: "center" }}>
					<div style={{ fontSize: 8.5, color: "var(--login-graphic-subtle)", marginBottom: 2 }}>Hoy</div>
					<div style={{ fontSize: 12, fontWeight: 800, color: c }}>47 órdenes</div>
				</div>
				<div style={{ flex: 1, background: "rgba(34,197,94,0.08)", border: "1px solid rgba(34,197,94,0.2)", borderRadius: 8, padding: "6px 8px", textAlign: "center" }}>
					<div style={{ fontSize: 8.5, color: "var(--login-graphic-subtle)", marginBottom: 2 }}>Efectivo</div>
					<div style={{ fontSize: 12, fontWeight: 800, color: "var(--login-graphic-accent-green)" }}>S/ 680</div>
				</div>
			</div>
		</div>
	);
}

function IaGraphic({ c, cb, cbr }: Accent) {
	return (
		<div style={{ marginTop: 2, display: "flex", flexDirection: "column", gap: 6 }}>
			{/* Chart */}
			<div style={{ position: "relative" }}>
				<svg viewBox="0 0 280 88" style={{ width: "100%", height: "auto", maxHeight: 88, display: "block" }}>
					<defs>
						<linearGradient id="iaFill" x1="0" y1="0" x2="0" y2="1">
							<stop offset="0%" stopColor={c} stopOpacity="0.22" />
							<stop offset="100%" stopColor={c} stopOpacity="0.02" />
						</linearGradient>
						<linearGradient id="iaFore" x1="0" y1="0" x2="0" y2="1">
							<stop offset="0%" stopColor={c} stopOpacity="0.06" />
							<stop offset="100%" stopColor={c} stopOpacity="0.01" />
						</linearGradient>
					</defs>
					{/* grid lines */}
					{[22, 44, 66].map((y) => (
						<line key={y} x1="0" y1={y} x2="280" y2={y} stroke="var(--login-graphic-grid)" strokeWidth="0.5" strokeDasharray="4 4" />
					))}
					{/* historical fill + line */}
					<polygon points={SPARKLINE_FILL} fill="url(#iaFill)" />
					<polyline points={SPARKLINE_HX} fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
					{/* forecast zone */}
					<polygon points={`230,5 ${FORECAST_HX} 265,88 230,88`} fill="url(#iaFore)" />
					<polyline points={FORECAST_HX} fill="none" stroke={c} strokeWidth="2" strokeDasharray="5 4" strokeLinecap="round" />
					{/* today divider */}
					<line x1="230" y1="0" x2="230" y2="88" stroke={c} strokeWidth="0.8" strokeDasharray="3 3" opacity="0.4" />
					{/* live dot */}
					<circle cx="230" cy="5" r="5" fill={c} opacity="0.2" />
					<circle cx="230" cy="5" r="3" fill={c} />
					{/* labels */}
					<text x="3" y="85" fontSize="8" fill="var(--login-graphic-subtle)">14 días atrás</text>
					<text x="232" y="85" fontSize="8" fill={c} fontWeight="600">Predicción</text>
				</svg>
			</div>
			{/* Prediction pills */}
			<div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
				{[
					{ name: "Hamburguesa", qty: "×23" },
					{ name: "Pizza",       qty: "×14" },
					{ name: "Limonada",    qty: "×31" },
				].map((item) => (
					<div key={item.name} style={{ display: "inline-flex", alignItems: "center", gap: 4, background: cb, border: `1px solid ${cbr}`, borderRadius: 7, padding: "3px 8px", fontSize: 10, fontWeight: 600, color: c }}>
						<span>{item.name}</span>
						<span style={{ fontWeight: 800 }}>{item.qty}</span>
						<span style={{ color: "var(--login-graphic-subtle)", fontWeight: 400 }}>mañana</span>
					</div>
				))}
			</div>
		</div>
	);
}

function DashboardGraphic({ c }: Accent) {
	const maxPct = Math.max(...WEEK_BARS);
	return (
		<div style={{ marginTop: 4 }}>
			{/* Bar chart */}
			<svg viewBox="0 0 210 80" style={{ width: "100%", height: "auto", maxHeight: 90, display: "block" }}>
				{/* grid lines */}
				{[20, 40, 60].map((y) => (
					<line key={y} x1="0" y1={y} x2="210" y2={y} stroke="var(--login-graphic-grid)" strokeWidth="0.5" />
				))}
				{WEEK_BARS.map((pct, i) => {
					const h = Math.round((pct / maxPct) * 58);
					const isToday = i === 5;
					const x = i * 30 + 3;
					return (
						<React.Fragment key={i}>
							<rect x={x} y={62 - h} width="24" height={h} rx="3"
								fill={c} opacity={isToday ? 1 : 0.22} />
							{isToday && (
								<text x={x + 12} y={58 - h} fontSize="7.5" fill={c} fontWeight="700" textAnchor="middle">
									{WEEK_VALS[i]}
								</text>
							)}
						</React.Fragment>
					);
				})}
				<line x1="0" y1="63" x2="210" y2="63" stroke="var(--login-graphic-grid)" strokeWidth="0.5" />
				{WEEK_DAYS.map((d, i) => (
					<text key={i} x={i * 30 + 15} y="72" fontSize="8.5" fill={i === 5 ? c : "var(--login-graphic-subtle)"} fontWeight={i === 5 ? "700" : "400"} textAnchor="middle">
						{d}
					</text>
				))}
			</svg>
			{/* Stats row */}
			<div style={{ display: "flex", gap: 8, marginTop: 8 }}>
				{[
					{ label: "Ventas hoy", value: "S/ 1,240", color: c,          border: "rgba(59,130,246,0.25)" },
					{ label: "Efectivo",   value: "S/ 730",   color: "var(--login-graphic-accent-green)",  border: "rgba(34,197,94,0.25)"  },
					{ label: "Digital",    value: "S/ 510",   color: "#3b82f6",  border: "rgba(59,130,246,0.25)" },
				].map((stat) => (
						<div key={stat.label} style={{ flex: 1, background: "color-mix(in oklch, var(--color-card) 85%, transparent)", border: `1px solid ${stat.border}`, borderRadius: 7, padding: "5px 7px" }}>
							<div style={{ fontSize: 8, color: "var(--login-graphic-subtle)" }}>{stat.label}</div>
						<div style={{ fontSize: 11, fontWeight: 800, color: stat.color }}>{stat.value}</div>
					</div>
				))}
			</div>
		</div>
	);
}

function VozGraphic({ c }: Accent) {
	const maxH = Math.max(...WAVEFORM);
	return (
		<div style={{ marginTop: 10 }}>
			{/* Animated waveform bars */}
			<div style={{ display: "flex", alignItems: "flex-end", gap: 2.5, height: 52 }}>
				{WAVEFORM.map((h, i) => (
					<div
						key={i}
						className="wave-bar"
						style={{
							flex: 1,
							height: Math.round((h / maxH) * 46) + 6,
							borderRadius: 2,
							background: c,
							opacity: 0.3 + (h / maxH) * 0.7,
							animationDelay: `${(i * 0.065).toFixed(3)}s`,
							animationDuration: `${1.2 + (i % 4) * 0.15}s`,
						}}
					/>
				))}
			</div>
			{/* Status */}
			<div style={{ marginTop: 8, display: "flex", alignItems: "center", gap: 5, fontSize: 10, color: "var(--login-graphic-muted)" }}>
				<span className="animate-pulse" style={{ width: 7, height: 7, borderRadius: "50%", background: c, display: "inline-block", flexShrink: 0 }} />
				<span style={{ fontWeight: 600, color: c }}>Escuchando</span>
				<span style={{ color: "var(--login-graphic-subtle)" }}>· Ventas · Gastos · Stock</span>
			</div>
		</div>
	);
}

function EquipoGraphic({ c, cb, cbr }: Accent) {
	const matrix = [
		{ role: "Dueño",    ventas: true,  caja: true,  plan: true  },
		{ role: "Cajero",   ventas: true,  caja: true,  plan: false },
		{ role: "Mozo",     ventas: true,  caja: false, plan: false },
		{ role: "Cocinero", ventas: false, caja: false, plan: true  },
	];
	const cols = "72px 1fr 1fr 1fr";
	return (
		<div style={{ marginTop: 6 }}>
			{/* Header */}
			<div style={{ display: "grid", gridTemplateColumns: cols, gap: 4, marginBottom: 5, alignItems: "center" }}>
				<span />
				{["Ventas", "Caja", "Plan"].map((col) => (
					<span key={col} style={{ fontSize: 9, fontWeight: 600, color: "var(--login-graphic-muted)", textAlign: "center", textTransform: "uppercase", letterSpacing: "0.3px" }}>{col}</span>
				))}
			</div>
			{/* Rows */}
			{matrix.map((row) => (
				<div key={row.role} style={{ display: "grid", gridTemplateColumns: cols, gap: 4, marginBottom: 4, alignItems: "center" }}>
					<span style={{ fontSize: 9.5, fontWeight: 600, color: "var(--login-graphic-text)", whiteSpace: "nowrap" }}>{row.role}</span>
					{[row.ventas, row.caja, row.plan].map((has, i) => (
						<div key={i} style={{ display: "flex", alignItems: "center", justifyContent: "center", height: 24, borderRadius: 5, background: has ? cb : "rgba(220,220,230,0.18)", border: `1px solid ${has ? cbr : "rgba(200,200,215,0.5)"}` }}>
							{has
								? <Check className="w-3 h-3" style={{ color: c }} />
								: <X className="w-3 h-3" style={{ color: "var(--login-graphic-subtle)" }} />
							}
						</div>
					))}
				</div>
			))}
		</div>
	);
}

const WEEKLY_REVENUE = [890, 1020, 760, 1150, 980, 1240, 870];
const WEEKLY_LABELS  = ["L", "M", "M", "J", "V", "S", "D"];

function FinanzasGraphic({ c, cb, cbr }: Accent) {
	const maxRev = Math.max(...WEEKLY_REVENUE);
	const W = 200, H = 48;
	const pts = WEEKLY_REVENUE.map((v, i) =>
		`${Math.round((i / 6) * W)},${Math.round(H - (v / maxRev) * (H - 4) - 4)}`
	).join(" ");
	const fillPts = `0,${H} ${pts} ${W},${H}`;

	return (
		<div style={{ marginTop: 2 }}>
			{/* Sparkline */}
			<div style={{ position: "relative" }}>
				<svg viewBox={`0 0 ${W} ${H + 12}`} style={{ width: "100%", height: "auto", maxHeight: 56, display: "block" }}>
					<defs>
						<linearGradient id="finFill" x1="0" y1="0" x2="0" y2="1">
							<stop offset="0%" stopColor={c} stopOpacity="0.18" />
							<stop offset="100%" stopColor={c} stopOpacity="0.02" />
						</linearGradient>
					</defs>
					<polygon points={fillPts} fill="url(#finFill)" />
					<polyline points={pts} fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
					{/* Saturday highlight dot */}
					{(() => {
						const [sx, sy] = pts.split(" ")[5].split(",");
						return <circle cx={sx} cy={sy} r="3.5" fill={c} />;
					})()}
					{/* Day labels */}
					{WEEKLY_LABELS.map((d, i) => (
						<text key={d + i} x={Math.round((i / 6) * W)} y={H + 11} fontSize="8" fill={i === 5 ? c : "var(--login-graphic-subtle)"} fontWeight={i === 5 ? "700" : "400"} textAnchor="middle">
							{d}
						</text>
					))}
				</svg>
			</div>
			{/* KPI pills */}
			<div style={{ display: "flex", gap: 7, marginTop: 8 }}>
				<div style={{ flex: 1, background: cb, border: `1px solid ${cbr}`, borderRadius: 8, padding: "5px 8px" }}>
					<div style={{ fontSize: 8.5, color: "var(--login-graphic-subtle)", marginBottom: 1 }}>Utilidad semana</div>
					<div style={{ fontSize: 12, fontWeight: 800, color: c }}>S/ 2,500</div>
					<div style={{ display: "flex", alignItems: "center", gap: 2, marginTop: 2, fontSize: 8.5, color: "var(--login-graphic-accent-green)" }}>
						<TrendingUp className="w-2.5 h-2.5" />
						<span>+12% vs anterior</span>
					</div>
				</div>
				<div style={{ flex: 1, background: "rgba(34,197,94,0.08)", border: "1px solid rgba(34,197,94,0.2)", borderRadius: 8, padding: "5px 8px" }}>
					<div style={{ fontSize: 8.5, color: "var(--login-graphic-subtle)", marginBottom: 1 }}>Margen promedio</div>
					<div style={{ fontSize: 12, fontWeight: 800, color: "var(--login-graphic-accent-green)" }}>34.2%</div>
					<div style={{ display: "flex", alignItems: "center", gap: 2, marginTop: 2, fontSize: 8.5, color: "var(--login-graphic-accent-green)" }}>
						<TrendingUp className="w-2.5 h-2.5" />
						<span>+2.1 pts</span>
					</div>
				</div>
			</div>
			<div style={{ display: "flex", alignItems: "center", gap: 4, marginTop: 7, fontSize: 9, color: "var(--login-graphic-subtle)" }}>
				<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-2.5 h-2.5 flex-shrink-0">
					<rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
				</svg>
				<span>Registro inmutable · Sin modificaciones post-cierre</span>
			</div>
		</div>
	);
}

function FeatureGraphic({ area, accent }: { area: string; accent: Accent }) {
	switch (area) {
		case "cobros":    return <CobrosGraphic    {...accent} />;
		case "ia":        return <IaGraphic        {...accent} />;
		case "dashboard": return <DashboardGraphic {...accent} />;
		case "voz":       return <VozGraphic       {...accent} />;
		case "equipo":    return <EquipoGraphic    {...accent} />;
		case "finanzas":  return <FinanzasGraphic  {...accent} />;
		default:          return null;
	}
}

function ForgotPasswordModal({ onClose }: { onClose: () => void }) {
	const [email, setEmail] = useState("");
	const [sent, setSent] = useState(false);

	const mutation = useMutation({
		mutationFn: (e: string) => api.post("/auth/forgot-password", { email: e }).then((r) => r.data),
		onSuccess: () => setSent(true),
	});

	return (
		<div
			className="fixed inset-0 z-50 flex items-center justify-center"
			style={{ background: "rgba(10,5,30,0.55)", backdropFilter: "blur(6px)" }}
			onClick={onClose}
		>
			<div
				style={{
					background: "rgba(255,255,255,0.97)",
					borderRadius: 18,
					padding: "28px 28px 24px",
					width: "min(420px, 90vw)",
					boxShadow: "0 20px 60px rgba(50,30,100,0.22)",
					border: "1px solid rgba(255,255,255,0.95)",
				}}
				onClick={(e) => e.stopPropagation()}
			>
				<div className="flex items-start justify-between" style={{ marginBottom: 18 }}>
					<div>
						<p className="text-foreground" style={{ fontSize: 18, fontWeight: 700, letterSpacing: "-0.4px" }}>
							Recuperar contraseña
						</p>
						<p className="text-muted-foreground" style={{ fontSize: 12, marginTop: 3 }}>
							El procedimiento depende de tu rol.
						</p>
					</div>
					<button
						type="button"
						onClick={onClose}
						className="text-muted-foreground"
						style={{ background: "none", border: "none", cursor: "pointer", fontSize: 20, lineHeight: 1, padding: "0 0 0 8px" }}
						aria-label="Cerrar"
					>
						×
					</button>
				</div>

				{/* Dueño section */}
				<div style={{ background: "rgba(255,106,0,0.05)", border: "1px solid rgba(255,106,0,0.15)", borderRadius: 12, padding: "14px 16px", marginBottom: 12 }}>
					<p style={{ fontSize: 12, fontWeight: 700, color: "#FF6A00", marginBottom: 6, textTransform: "uppercase", letterSpacing: "0.4px", display: "flex", alignItems: "center", gap: 5 }}>
						<User className="w-3 h-3" /> Si eres el dueño
					</p>
					<p className="text-muted-foreground" style={{ fontSize: 12, lineHeight: 1.55, marginBottom: 10 }}>
						Ingresa tu email de registro. Recibirás un enlace para restablecer tu contraseña.
					</p>
					{sent ? (
						<div style={{ fontSize: 12, color: "var(--login-graphic-accent-green)", fontWeight: 600, padding: "8px 12px", background: "color-mix(in srgb, var(--login-graphic-accent-green) 8%, transparent)", borderRadius: 8, border: "1px solid color-mix(in srgb, var(--login-graphic-accent-green) 20%, transparent)", display: "flex", alignItems: "center", gap: 6 }}>
							<Check className="w-3.5 h-3.5 flex-shrink-0" /> Si el email existe, recibirás las instrucciones en tu correo.
						</div>
					) : (
						<div className="flex gap-2">
							<input
								type="email"
								placeholder="tu@email.com"
								value={email}
								onChange={(e) => setEmail(e.target.value)}
								className="login-input"
								style={{ flex: 1, paddingLeft: 12 }}
							/>
							<button
								type="button"
								disabled={mutation.isPending || !email}
								onClick={() => mutation.mutate(email)}
								style={{ padding: "0 14px", height: 40, borderRadius: 10, background: "linear-gradient(90deg,#FF4500,#FF8C00)", color: "#fff", fontSize: 12, fontWeight: 700, border: "none", cursor: "pointer", opacity: (!email || mutation.isPending) ? 0.6 : 1, whiteSpace: "nowrap" }}
							>
								{mutation.isPending ? "…" : "Enviar"}
							</button>
						</div>
					)}
				</div>

				{/* Empleado section */}
				<div style={{ background: "rgba(80,60,180,0.05)", border: "1px solid rgba(80,60,180,0.12)", borderRadius: 12, padding: "14px 16px" }}>
					<p style={{ fontSize: 12, fontWeight: 700, color: "var(--login-graphic-accent-purple)", marginBottom: 6, textTransform: "uppercase", letterSpacing: "0.4px", display: "flex", alignItems: "center", gap: 5 }}>
						<HardHat className="w-3 h-3" /> Si eres empleado
					</p>
					<p className="text-muted-foreground" style={{ fontSize: 12, lineHeight: 1.55 }}>
						Los empleados usan cuentas internas — no hay recuperación por email. Contacta al <strong>dueño del local</strong> para que restablezca tu contraseña desde el panel de Empleados.
					</p>
				</div>
			</div>
		</div>
	);
}

function LoginPage() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);
	const [showPassword] = useState(false);
	const [forgotOpen, setForgotOpen] = useState(false);

	const loginMutation = useMutation({
		mutationFn: (data: { username: string; password: string }) =>
			api.post<LoginResponse>("/auth/login", data).then((r) => r.data),
		onSuccess: (data) => {
			setAuth({ accessToken: data.access_token, refreshToken: data.refresh_token }, data.user);
			void navigate({ to: getHomeForRole(data.user.role) });
		},
	});

	const form = useForm({
		defaultValues: { username: "", password: "" },
		onSubmit: async ({ value }) => {
			const username = value.username.replace(/@smartbite\.local$/i, "").trim();
			const parsed = loginSchema.safeParse({ username, password: value.password });
			if (!parsed.success) return;
			await loginMutation.mutateAsync(parsed.data);
		},
	});

	return (
		<>
		{forgotOpen && <ForgotPasswordModal onClose={() => setForgotOpen(false)} />}
		<div
			className="min-h-screen flex flex-col overflow-auto"
			style={{
				padding: "clamp(16px, 3vh, 40px) clamp(16px, 3vw, 52px)",
				background: `
					radial-gradient(ellipse 70% 60% at 15% 20%, rgba(200,205,240,0.65) 0%, transparent 60%),
					radial-gradient(ellipse 55% 55% at 85% 80%, rgba(220,200,245,0.55) 0%, transparent 55%),
					radial-gradient(ellipse 50% 40% at 65% 5%, rgba(255,180,120,0.13) 0%, transparent 50%),
					linear-gradient(135deg, #e8eaf6 0%, #dde3f0 45%, #ede8f5 100%)
				`,
			}}
		>
			{/* Main row — stacks on mobile, side-by-side on desktop */}
			<div
				className="flex-1 min-h-0 flex flex-col md:grid md:items-stretch"
				style={{ gridTemplateColumns: "minmax(min(320px,100%),420px) 1fr", gap: "clamp(20px, 4vw, 56px)" }}
			>
				{/* ── LOGIN CARD ── */}
				<div
					className="relative flex flex-col justify-center overflow-hidden"
					style={{
						background: "color-mix(in oklch, var(--color-card) 84%, transparent)",
						border: "1px solid color-mix(in oklch, var(--color-card) 96%, transparent)",
						borderRadius: 22,
						padding: "clamp(22px, 3vh, 38px) clamp(20px, 2.5vw, 34px)",
						boxShadow: "0 8px 40px rgba(80,60,140,0.11), 0 2px 8px rgba(80,60,140,0.06)",
						backdropFilter: "blur(20px)",
					}}
				>
					{/* Decorative orbs */}
					<div className="absolute inset-0 pointer-events-none overflow-hidden" style={{ borderRadius: 22 }}>
						<svg width="100%" height="100%" viewBox="0 0 380 520" preserveAspectRatio="xMidYMid slice" fill="none">
							<circle cx="340" cy="40"  r="130" fill="rgba(255,106,0,0.05)" />
							<circle cx="360" cy="480" r="170" fill="rgba(124,92,191,0.04)" />
							<circle cx="-30" cy="260" r="110" fill="rgba(255,140,0,0.03)" />
						</svg>
					</div>

					<div className="relative">
						{/* Brand inside form */}
						<div className="flex items-center justify-center gap-2.5" style={{ marginBottom: "clamp(16px, 2.5vh, 28px)" }}>
							<img src={logoSrc} alt="SmartBite" style={{ height: 38, width: "auto" }} />
							<span className="text-foreground" style={{ fontFamily: "'Bebas Neue', 'Plus Jakarta Sans Variable', sans-serif", fontSize: 28, letterSpacing: "2px", lineHeight: 1 }}>
								SMARTBITE
							</span>
						</div>

						{/* Restaurant name + icon inline */}
						<div className="flex items-center gap-3" style={{ marginBottom: 4 }}>
							<div style={{ width: 40, height: 40, background: "rgba(255,106,0,0.1)", border: "1px solid rgba(255,106,0,0.18)", borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
								<Store className="w-4.5 h-4.5" style={{ color: "#FF6A00" }} />
							</div>
							<h1 className="font-bold text-foreground" style={{ fontSize: "clamp(16px, 1.8vw, 20px)", letterSpacing: "-0.4px", lineHeight: 1.2 }}>
								Adrian Shawarma Pizza
							</h1>
						</div>
							<p className="text-muted-foreground" style={{ fontSize: "clamp(11px, 1.1vw, 13.5px)", lineHeight: 1.5, marginBottom: "clamp(10px, 1.5vh, 16px)", marginLeft: 52 }}>
							Restaurante de comida rápida.
						</p>

						{/* Restaurant photo — Ghibli-style warm effect */}
						<div style={{ position: "relative", borderRadius: 12, overflow: "hidden", marginBottom: "clamp(14px, 2vh, 22px)" }}>
							<img
								src={restauranteSrc}
								alt="Adrian Shawarma Pizza"
								style={{
									width: "100%",
									height: "clamp(110px, 16vh, 160px)",
									objectFit: "cover",
									objectPosition: "center 30%",
									display: "block",
									filter: "saturate(1.22) contrast(1.04) sepia(0.12) brightness(1.04) hue-rotate(-4deg)",
								}}
							/>
							{/* Vignette + warm tone overlay */}
							<div style={{
								position: "absolute",
								inset: 0,
								background: "radial-gradient(ellipse at center, transparent 45%, rgba(30,15,5,0.28) 100%)",
								pointerEvents: "none",
							}} />
							{/* Bottom fade to card background */}
							<div style={{
								position: "absolute",
								bottom: 0,
								left: 0,
								right: 0,
								height: "40%",
								background: "linear-gradient(to bottom, transparent, rgba(255,253,250,0.72))",
								pointerEvents: "none",
							}} />
						</div>

						<form onSubmit={(e) => { e.preventDefault(); void form.handleSubmit(); }}>
							{/* Username */}
							<form.Field
								name="username"
								validators={{ onChange: ({ value }) => value.length === 0 ? "Ingresa tu usuario" : undefined }}
							>
								{(field) => (
									<div style={{ marginBottom: "clamp(10px, 1.5vh, 16px)" }}>
										<label htmlFor={field.name} className="block font-medium text-foreground" style={{ fontSize: 12, marginBottom: 5 }}>
											Usuario
										</label>
										<div className="relative">
										<span className="absolute left-3 top-1/2 -translate-y-1/2 flex items-center pointer-events-none text-muted-foreground">
											<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-3.5 h-3.5">
												<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />
											</svg>
										</span>
											<input id={field.name} type="text" placeholder="ej: owner" autoComplete="username" value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} onBlur={field.handleBlur} aria-invalid={field.state.meta.errors.length > 0} className="login-input" />
										</div>
										{field.state.meta.errors.length > 0 && (
											<p className="text-xs mt-1 text-destructive">{field.state.meta.errors[0]}</p>
										)}
									</div>
								)}
							</form.Field>

							{/* Password */}
							<form.Field
								name="password"
								validators={{ onChange: ({ value }) => value.length === 0 ? "Ingresa tu contraseña" : undefined }}
							>
								{(field) => (
									<div style={{ marginBottom: "clamp(10px, 1.5vh, 16px)" }}>
											<div className="flex items-center justify-between" style={{ marginBottom: 5 }}>
												<label htmlFor={field.name} className="font-medium text-foreground" style={{ fontSize: 12 }}>Contraseña</label>
											<button type="button" onClick={() => setForgotOpen(true)} className="font-medium hover:opacity-75 transition-opacity" style={{ fontSize: "11.5px", color: "#FF6A00", textDecoration: "none", background: "none", border: "none", cursor: "pointer", padding: 0 }}>¿Olvidaste tu contraseña?</button>
										</div>
										<div className="relative">
										<span className="absolute left-3 top-1/2 -translate-y-1/2 flex items-center pointer-events-none text-muted-foreground">
											<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-3.5 h-3.5">
												<rect x="3" y="11" width="18" height="11" rx="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
											</svg>
										</span>
										<input id={field.name} type={showPassword ? "text" : "password"} placeholder="••••••••" autoComplete="current-password" value={field.state.value} onChange={(e) => field.handleChange(e.target.value)} onBlur={field.handleBlur} aria-invalid={field.state.meta.errors.length > 0} className="login-input" style={{ paddingRight: 38 }} />
										</div>
										{field.state.meta.errors.length > 0 && (
											<p className="text-xs mt-1 text-destructive">{field.state.meta.errors[0]}</p>
										)}
									</div>
								)}
							</form.Field>

							{loginMutation.error && (
								<div className="rounded-lg px-3 py-2.5 mb-3 text-destructive" style={{ fontSize: 13, background: "rgba(239,68,68,0.06)", border: "1px solid rgba(239,68,68,0.15)" }}>
									{loginMutation.error instanceof Error && loginMutation.error.message.includes("Network Error")
										? "Sin conexión con el servidor."
										: "Usuario o contraseña incorrectos"}
								</div>
							)}

							<button
								type="submit"
								disabled={loginMutation.isPending}
								className="w-full flex items-center justify-center gap-2 font-semibold border-0 cursor-pointer transition-[opacity,transform,box-shadow] duration-200 hover:opacity-90 hover:-translate-y-px active:translate-y-0 disabled:opacity-70 disabled:cursor-not-allowed"
								style={{ height: 44, background: loginMutation.isPending ? "#c0c0c8" : "linear-gradient(90deg, #FF4500 0%, #FF8C00 100%)", borderRadius: 11, color: "#fff", fontSize: 14, letterSpacing: "-0.2px", boxShadow: loginMutation.isPending ? "none" : "0 4px 20px rgba(255,100,0,0.35)", marginTop: 4 }}
							>
								{loginMutation.isPending ? (
									<><Loader2 className="w-4 h-4 animate-spin" /> Verificando...</>
								) : (
									<>
										<span>Ingresar</span>
										<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4">
											<path d="M5 12h14M12 5l7 7-7 7" />
										</svg>
									</>
								)}
							</button>
						</form>

						<div className="text-center border-t text-muted-foreground" style={{ marginTop: "clamp(10px, 1.5vh, 18px)", paddingTop: "clamp(8px, 1.2vh, 14px)", fontSize: 12 }}>
							¿Necesitas soporte?{" "}
							<a href="mailto:josepdanton1518@gmail.com" style={{ color: "#FF6A00", fontWeight: 500, textDecoration: "none" }}>Contacta a IT</a>
						</div>
					</div>
				</div>

				{/* ── FEATURES BENTO ── */}
				<div className="hidden md:flex flex-col min-h-0 login-bento-wrapper" style={{ gap: "clamp(10px, 1.5vh, 18px)" }}>
					{/* Heading */}
					<div className="flex-shrink-0">
						<h2 className="font-extrabold leading-[1.2] text-foreground" style={{ fontSize: "clamp(20px, 2.2vw, 28px)", letterSpacing: "-0.7px" }}>
							Todo lo que necesitas
							<br />
							<span style={{ background: "linear-gradient(90deg, #FF4500, #FF8C00)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
								en un solo sistema.
							</span>
						</h2>
						<p className="text-muted-foreground" style={{ fontSize: "12.5px", marginTop: 4 }}>
							Tu restaurante, a la vista. Pedidos, pagos y ganancias en tiempo real.
						</p>
					</div>

					{/* Bento grid */}
					<div className="flex-1 min-h-0 login-bento">
						{features.map(({ area, color, icon: Icon, module, name, desc }) => {
							const accent = ACCENT[color];
							const { c, cb, cbr } = accent;
							return (
								<div
									key={area}
									className={`flex flex-col overflow-hidden bento-card bento-${area}`}
									style={{
										background: "color-mix(in oklch, var(--color-card) 84%, transparent)",
										border: "1px solid color-mix(in oklch, var(--color-card) 96%, transparent)",
										borderRadius: 14,
										padding: "clamp(12px, 1.5vh, 16px) clamp(14px, 1.5vw, 18px)",
										boxShadow: "0 2px 14px rgba(80,60,140,0.07)",
										backdropFilter: "blur(14px)",
									}}
								>
									{/* Header: icon + module */}
									<div className="flex items-center gap-2.5 flex-shrink-0">
										<div style={{ width: 32, height: 32, borderRadius: 8, background: cb, border: `1px solid ${cbr}`, color: c, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
											<Icon className="w-3.5 h-3.5" />
										</div>
										<div style={{ fontSize: 9.5, fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.5px", color: c }}>{module}</div>
											</div>

										{/* Name */}
										<div className="font-bold leading-tight flex-shrink-0 text-foreground" style={{ fontSize: "clamp(12px, 1.1vw, 14px)", letterSpacing: "-0.2px", marginTop: 6 }}>
										{name}
									</div>

										{/* Description */}
										<div className="text-muted-foreground" style={{ fontSize: "clamp(10.5px, 0.85vw, 12px)", lineHeight: 1.45, marginTop: 3, flexShrink: 0, display: "-webkit-box", WebkitLineClamp: 2, WebkitBoxOrient: "vertical", overflow: "hidden" }}>
										{desc}
									</div>

									{/* Graphic */}
									<div className="flex-1 min-h-0 flex flex-col justify-center">
										<FeatureGraphic area={area} accent={accent} />
									</div>
								</div>
							);
						})}
					</div>
				</div>
			</div>
		</div>
		</>
	);
}
