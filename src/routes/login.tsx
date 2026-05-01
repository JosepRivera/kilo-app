import { useState } from "react";
import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
	BarChart3,
	ChefHat,
	Eye,
	EyeOff,
	Package,
	TrendingUp,
	UtensilsCrossed,
} from "lucide-react";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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

const features = [
	{
		icon: UtensilsCrossed,
		title: "Ventas en segundos",
		desc: "Registra órdenes y cobra sin demoras ni errores",
	},
	{
		icon: ChefHat,
		title: "Cocina conectada",
		desc: "Las comandas llegan al instante, sin gritos",
	},
	{
		icon: Package,
		title: "Stock inteligente",
		desc: "Alertas automáticas antes de quedarte sin ingredientes",
	},
	{
		icon: BarChart3,
		title: "Cierre de caja",
		desc: "El resumen del día y la rentabilidad, de un vistazo",
	},
];

const demoCredentials = [
	{ role: "Dueño", username: "owner", password: "owner1234" },
	{ role: "Cajera", username: "cajera01", password: "cashier1234" },
	{ role: "Cocinero", username: "cocinero01", password: "cook1234" },
];

function LoginPage() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);
	const [showPassword, setShowPassword] = useState(false);

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
			// Strip @smartbite.local if user accidentally types the email
			const username = value.username.replace(/@smartbite\.local$/i, "").trim();
			const parsed = loginSchema.safeParse({ username, password: value.password });
			if (!parsed.success) return;
			await loginMutation.mutateAsync(parsed.data);
		},
	});

	return (
		<div
			className="relative flex min-h-screen overflow-hidden"
			style={{
				backgroundColor: "#f8f5f0",
				fontFamily: "'Plus Jakarta Sans Variable', sans-serif",
			}}
		>
			{/* ── Left brand panel with diagonal right edge ── */}
			<div
				className="relative hidden lg:flex lg:flex-col flex-none"
				style={{
					width: "58%",
					background:
						"linear-gradient(150deg, #061410 0%, #0a1e16 45%, #0f2a1c 80%, #122e1f 100%)",
					clipPath: "polygon(0 0, 100% 0, 88% 100%, 0 100%)",
				}}
			>
				{/* Glow layers */}
				<div
					className="absolute inset-0 pointer-events-none"
					style={{
						background:
							"radial-gradient(ellipse 60% 50% at 20% 20%, rgba(52,211,153,0.12) 0%, transparent 70%)",
					}}
				/>
				<div
					className="absolute inset-0 pointer-events-none"
					style={{
						background:
							"radial-gradient(ellipse 50% 40% at 80% 80%, rgba(16,185,129,0.08) 0%, transparent 70%)",
					}}
				/>

				{/* Dot pattern */}
				<div
					className="absolute inset-0 opacity-[0.07] pointer-events-none"
					style={{
						backgroundImage:
							"radial-gradient(circle at 1px 1px, #6ee7b7 1px, transparent 0)",
						backgroundSize: "28px 28px",
					}}
				/>

				{/* Diagonal accent lines */}
				<div className="absolute inset-0 overflow-hidden pointer-events-none">
					<div
						className="absolute"
						style={{
							width: "2px",
							height: "200%",
							top: "-50%",
							right: "18%",
							background:
								"linear-gradient(to bottom, transparent, rgba(52,211,153,0.15), transparent)",
							transform: "rotate(-15deg)",
						}}
					/>
					<div
						className="absolute"
						style={{
							width: "1px",
							height: "200%",
							top: "-50%",
							right: "28%",
							background:
								"linear-gradient(to bottom, transparent, rgba(52,211,153,0.08), transparent)",
							transform: "rotate(-15deg)",
						}}
					/>
				</div>

				<div className="relative flex flex-1 flex-col justify-between px-14 py-12 pr-28">
					{/* Brand */}
					<div className="flex items-center gap-3">
						<div
							className="flex h-10 w-10 items-center justify-center rounded-xl"
							style={{
								background: "rgba(52,211,153,0.12)",
								border: "1px solid rgba(52,211,153,0.25)",
							}}
						>
							<UtensilsCrossed className="h-5 w-5" style={{ color: "#6ee7b7" }} />
						</div>
						<span
							className="text-xl font-bold tracking-tight"
							style={{ color: "#f0fdf4" }}
						>
							SmartBite
						</span>
					</div>

					{/* Hero copy */}
					<div>
						<p
							className="mb-3 text-xs font-bold uppercase tracking-[0.25em]"
							style={{ color: "rgba(110,231,183,0.6)" }}
						>
							Gestión de restaurantes
						</p>
						<h2
							className="text-[2.4rem] font-extrabold leading-[1.1]"
							style={{ color: "#ffffff" }}
						>
							Tu restaurante,
							<br />
							<span
								style={{
									background: "linear-gradient(90deg, #34d399, #6ee7b7, #a7f3d0)",
									WebkitBackgroundClip: "text",
									WebkitTextFillColor: "transparent",
									backgroundClip: "text",
								}}
							>
								bajo control.
							</span>
						</h2>
						<p
							className="mt-4 max-w-[18rem] text-[0.88rem] leading-relaxed"
							style={{ color: "rgba(209,250,229,0.5)" }}
						>
							Todo lo que necesita tu negocio en un solo lugar — desde la primera orden hasta el
							cierre de caja.
						</p>

						{/* Features */}
						<div className="mt-10 space-y-5">
							{features.map(({ icon: Icon, title, desc }) => (
								<div key={title} className="flex items-start gap-4">
									<div
										className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl"
										style={{
											background: "rgba(52,211,153,0.1)",
											border: "1px solid rgba(52,211,153,0.18)",
										}}
									>
										<Icon className="h-4 w-4" style={{ color: "#34d399" }} />
									</div>
									<div>
										<p
											className="text-sm font-semibold leading-tight"
											style={{ color: "#d1fae5" }}
										>
											{title}
										</p>
										<p
											className="mt-0.5 text-xs leading-snug"
											style={{ color: "rgba(167,243,208,0.45)" }}
										>
											{desc}
										</p>
									</div>
								</div>
							))}
						</div>

						{/* Social proof strip */}
						<div
							className="mt-12 flex items-center gap-3 rounded-2xl px-4 py-3"
							style={{
								background: "rgba(52,211,153,0.06)",
								border: "1px solid rgba(52,211,153,0.12)",
							}}
						>
							<TrendingUp className="h-4 w-4 shrink-0" style={{ color: "#34d399" }} />
							<p className="text-xs" style={{ color: "rgba(167,243,208,0.6)" }}>
								Menos errores en cocina, más tiempo para lo que importa.
							</p>
						</div>
					</div>

					{/* Footer */}
					<p className="text-[11px]" style={{ color: "rgba(110,231,183,0.25)" }}>
						© 2026 SmartBite — Sistema de gestión para restaurantes
					</p>
				</div>
			</div>

			{/* ── Right form panel ── */}
			<div className="flex flex-1 flex-col items-center justify-center px-6 py-12 lg:px-10">
				{/* Mobile brand */}
				<div className="mb-8 flex items-center gap-2 lg:hidden">
					<UtensilsCrossed className="h-5 w-5" style={{ color: "#059669" }} />
					<span className="text-lg font-bold" style={{ color: "#111827" }}>
						SmartBite
					</span>
				</div>

				<div className="w-full max-w-[21rem]">
					{/* Heading */}
					<div className="mb-8">
						<h1
							className="text-[1.7rem] font-extrabold tracking-tight"
							style={{ color: "#111827" }}
						>
							Bienvenido de vuelta
						</h1>
						<p className="mt-1.5 text-sm" style={{ color: "#6b7280" }}>
							Ingresa para continuar
						</p>
					</div>

					{/* Form card */}
					<div
						className="rounded-2xl px-7 py-7"
						style={{
							background: "#ffffff",
							border: "1px solid rgba(0,0,0,0.07)",
							boxShadow: "0 4px 24px rgba(0,0,0,0.06)",
						}}
					>
						<form
							onSubmit={(e) => {
								e.preventDefault();
								void form.handleSubmit();
							}}
							className="space-y-5"
						>
							{/* Username */}
							<form.Field
								name="username"
								validators={{
									onChange: ({ value }) =>
										value.length === 0 ? "Ingresa tu usuario" : undefined,
								}}
							>
								{(field) => (
									<div className="space-y-1.5">
										<Label
											htmlFor={field.name}
											className="text-sm font-semibold"
											style={{ color: "#374151" }}
										>
											Usuario
										</Label>
										<Input
											id={field.name}
											type="text"
											placeholder="ej: owner"
											autoComplete="username"
											value={field.state.value}
											onChange={(e) => field.handleChange(e.target.value)}
											onBlur={field.handleBlur}
											aria-invalid={field.state.meta.errors.length > 0}
											className="h-10 rounded-xl"
										/>
										{field.state.meta.errors.length > 0 && (
											<p className="text-xs text-destructive">
												{field.state.meta.errors[0]}
											</p>
										)}
									</div>
								)}
							</form.Field>

							{/* Password with show/hide */}
							<form.Field
								name="password"
								validators={{
									onChange: ({ value }) =>
										value.length === 0 ? "Ingresa tu contraseña" : undefined,
								}}
							>
								{(field) => (
									<div className="space-y-1.5">
										<Label
											htmlFor={field.name}
											className="text-sm font-semibold"
											style={{ color: "#374151" }}
										>
											Contraseña
										</Label>
										<div className="relative">
											<Input
												id={field.name}
												type={showPassword ? "text" : "password"}
												placeholder="••••••••"
												autoComplete="current-password"
												value={field.state.value}
												onChange={(e) => field.handleChange(e.target.value)}
												onBlur={field.handleBlur}
												aria-invalid={field.state.meta.errors.length > 0}
												className="h-10 rounded-xl pr-10"
											/>
											<button
												type="button"
												onClick={() => setShowPassword((v) => !v)}
												className="absolute inset-y-0 right-0 flex items-center px-3 transition-colors"
												style={{ color: "#9ca3af" }}
												aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
											>
												{showPassword ? (
													<EyeOff className="h-4 w-4" />
												) : (
													<Eye className="h-4 w-4" />
												)}
											</button>
										</div>
										{field.state.meta.errors.length > 0 && (
											<p className="text-xs text-destructive">
												{field.state.meta.errors[0]}
											</p>
										)}
									</div>
								)}
							</form.Field>

							{/* Error */}
							{loginMutation.error && (
								<div
									className="rounded-xl px-4 py-3 text-sm"
									style={{
										background: "rgba(239,68,68,0.06)",
										border: "1px solid rgba(239,68,68,0.15)",
										color: "#dc2626",
									}}
								>
									{loginMutation.error instanceof Error &&
									loginMutation.error.message.includes("Network Error")
										? "Sin conexión con el servidor. Verificá que la API esté corriendo."
										: "Usuario o contraseña incorrectos"}
								</div>
							)}

							{/* Submit */}
							<Button
								type="submit"
								disabled={loginMutation.isPending}
								className="mt-1 h-11 w-full rounded-xl font-semibold text-white transition-all"
								style={{
									background: loginMutation.isPending
										? "#6b7280"
										: "linear-gradient(135deg, #059669, #10b981)",
									boxShadow: loginMutation.isPending
										? "none"
										: "0 4px 14px rgba(16,185,129,0.35)",
									border: "none",
								}}
							>
								{loginMutation.isPending ? "Ingresando…" : "Ingresar"}
							</Button>
						</form>
					</div>

					{/* Demo credentials */}
					<div
						className="mt-4 rounded-2xl px-5 py-4"
						style={{
							background: "#ffffff",
							border: "1px solid rgba(0,0,0,0.07)",
							boxShadow: "0 2px 12px rgba(0,0,0,0.04)",
						}}
					>
						<p
							className="mb-3 text-[10px] font-bold uppercase tracking-widest"
							style={{ color: "#9ca3af" }}
						>
							Cuentas de prueba
						</p>
						<div className="space-y-1">
							{demoCredentials.map(({ role, username, password }) => (
								<button
									key={username}
									type="button"
									onClick={() => {
										form.setFieldValue("username", username);
										form.setFieldValue("password", password);
									}}
									className="flex w-full items-center justify-between rounded-xl px-3 py-2.5 text-left transition-colors"
									style={{ color: "#374151" }}
									onMouseEnter={(e) => {
										(e.currentTarget as HTMLButtonElement).style.background =
											"rgba(16,185,129,0.06)";
									}}
									onMouseLeave={(e) => {
										(e.currentTarget as HTMLButtonElement).style.background = "";
									}}
								>
									<span className="text-xs font-semibold">{role}</span>
									<span
										className="rounded-lg px-2 py-0.5 font-mono text-[11px]"
										style={{ background: "#f3f4f6", color: "#6b7280" }}
									>
										{username}
									</span>
								</button>
							))}
						</div>
					</div>
				</div>
			</div>
		</div>
	);
}
