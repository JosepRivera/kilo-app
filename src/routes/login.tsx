import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import {
	BarChart3,
	ChefHat,
	Eye,
	EyeOff,
	Loader2,
	Package,
	TrendingUp,
	UtensilsCrossed,
} from "lucide-react";
import { useState } from "react";
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
		title: "Transacciones rápidas",
		desc: "Registra órdenes y cobra sin demoras",
	},
	{
		icon: ChefHat,
		title: "Comunicación instantánea",
		desc: "Los mensajes llegan al instante",
	},
	{
		icon: Package,
		title: "Gestión de inventario",
		desc: "Alertas automáticas de stock",
	},
	{
		icon: BarChart3,
		title: "Análisis de datos",
		desc: "Métricas claras de tu negocio",
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
			const username = value.username.replace(/@smartbite\.local$/i, "").trim();
			const parsed = loginSchema.safeParse({ username, password: value.password });
			if (!parsed.success) return;
			await loginMutation.mutateAsync(parsed.data);
		},
	});

	return (
		<div className="flex min-h-screen bg-white">
			{/* HERO PANEL - Desktop Only (58% width, Blue) */}
			<div
				className="hidden lg:flex lg:flex-col flex-none relative"
				style={{
					width: "58%",
					backgroundColor: "var(--color-login-blue-700)",
					backgroundImage:
						"linear-gradient(135deg, var(--color-login-blue-700) 0%, var(--color-login-blue-600) 100%)",
					clipPath: "polygon(0 0, 100% 0, 85% 100%, 0 100%)",
				}}
			>
				{/* Glow effects */}
				<div
					className="absolute inset-0 pointer-events-none"
					style={{
						background:
							"radial-gradient(ellipse 60% 50% at 20% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 70%)",
					}}
				/>
				<div
					className="absolute inset-0 pointer-events-none"
					style={{
						background:
							"radial-gradient(ellipse 50% 40% at 80% 80%, rgba(255, 255, 255, 0.05) 0%, transparent 70%)",
					}}
				/>

				{/* Content */}
				<div className="relative flex flex-1 flex-col justify-between px-14 py-12 animate-in fade-in-left duration-500">
					{/* Brand */}
					<div className="flex items-center gap-3">
						<div
							className="flex h-10 w-10 items-center justify-center rounded-xl"
							style={{ backgroundColor: "rgba(255, 255, 255, 0.15)" }}
						>
							<UtensilsCrossed className="h-5 w-5 text-white" />
						</div>
						<span className="text-xl font-bold text-white">SmartBite</span>
					</div>

					{/* Hero Section */}
					<div className="space-y-6">
						<h2 className="text-4xl font-bold leading-tight text-white">
							Tu negocio, <span className="inline-block">bajo control</span>
						</h2>
						<p className="max-w-sm text-sm leading-relaxed text-white/70">
							Todo lo que necesitas en un solo lugar — desde la primera orden hasta el análisis de
							datos.
						</p>

						{/* Features */}
						<div className="space-y-4 pt-4">
							{features.map(({ icon: Icon, title, desc }, idx) => (
								<div
									key={title}
									className="flex gap-3 animate-in fade-in-up"
									style={{
										animationDuration: "500ms",
										animationDelay: `${250 + idx * 50}ms`,
										animationFillMode: "both",
									}}
								>
									<div className="flex-shrink-0">
										<Icon className="h-5 w-5 text-white" />
									</div>
									<div>
										<p className="text-sm font-semibold text-white">{title}</p>
										<p className="text-xs leading-snug text-white/60">{desc}</p>
									</div>
								</div>
							))}
						</div>

						{/* Social Proof */}
						<div
							className="flex items-center gap-2 rounded-lg px-3 py-2 mt-6"
							style={{ backgroundColor: "rgba(255, 255, 255, 0.1)" }}
						>
							<TrendingUp className="h-4 w-4 text-white" />
							<p className="text-xs text-white/70">
								Menos errores, más tiempo para lo que importa.
							</p>
						</div>
					</div>

					{/* Footer */}
					<p className="text-xs text-white/40">
						© 2026 SmartBite — Sistema inteligente para negocios
					</p>
				</div>
			</div>

			{/* FORM PANEL - Desktop Right / Mobile Full (42% desktop, 100% mobile) */}
			<div className="flex flex-1 flex-col items-center justify-center px-6 py-12 lg:px-10">
				{/* Mobile Brand */}
				<div className="mb-8 flex items-center gap-2 lg:hidden">
					<UtensilsCrossed className="h-5 w-5" style={{ color: "var(--color-login-blue-700)" }} />
					<span className="text-lg font-bold" style={{ color: "var(--color-login-gray-dark)" }}>
						SmartBite
					</span>
				</div>

				<div
					className="w-full max-w-sm animate-in fade-in-up duration-500"
					style={{ animationDelay: "200ms", animationFillMode: "both" }}
				>
					{/* Heading */}
					<div className="mb-8">
						<h1 className="text-2xl font-bold" style={{ color: "var(--color-login-gray-dark)" }}>
							Bienvenido de vuelta
						</h1>
						<p className="mt-2 text-sm" style={{ color: "var(--color-login-gray-muted)" }}>
							Ingresa para continuar
						</p>
					</div>

					{/* Form Card */}
					<div
						className="rounded-lg border px-8 py-8"
						style={{
							backgroundColor: "white",
							borderColor: "var(--color-login-gray-light)",
							boxShadow: "0 10px 40px rgba(0, 0, 0, 0.08)",
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
									onChange: ({ value }) => (value.length === 0 ? "Ingresa tu usuario" : undefined),
								}}
							>
								{(field) => (
									<div className="space-y-1.5">
										<Label htmlFor={field.name} style={{ color: "var(--color-login-gray-dark)" }}>
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
											style={{
												borderColor:
													field.state.meta.errors.length > 0
														? "var(--color-login-red)"
														: "var(--color-login-gray-light)",
												backgroundColor: "white",
												color: "var(--color-login-gray-dark)",
											}}
											className="h-10 w-full rounded-lg border px-3 py-2 text-base placeholder:text-[var(--color-login-gray-medium)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-login-blue-500)] focus-visible:ring-offset-0 disabled:cursor-not-allowed disabled:bg-[var(--color-login-gray-light)] disabled:opacity-50"
										/>
										{field.state.meta.errors.length > 0 && (
											<p className="text-xs" style={{ color: "var(--color-login-red)" }}>
												{field.state.meta.errors[0]}
											</p>
										)}
									</div>
								)}
							</form.Field>

							{/* Password */}
							<form.Field
								name="password"
								validators={{
									onChange: ({ value }) =>
										value.length === 0 ? "Ingresa tu contraseña" : undefined,
								}}
							>
								{(field) => (
									<div className="space-y-1.5">
										<Label htmlFor={field.name} style={{ color: "var(--color-login-gray-dark)" }}>
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
												style={{
													borderColor:
														field.state.meta.errors.length > 0
															? "var(--color-login-red)"
															: "var(--color-login-gray-light)",
													backgroundColor: "white",
													color: "var(--color-login-gray-dark)",
												}}
												className="h-10 w-full rounded-lg border px-3 py-2 text-base placeholder:text-[var(--color-login-gray-medium)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-login-blue-500)] focus-visible:ring-offset-0 disabled:cursor-not-allowed disabled:bg-[var(--color-login-gray-light)] disabled:opacity-50"
											/>
											<button
												type="button"
												onClick={() => setShowPassword((v) => !v)}
												className="absolute inset-y-0 right-0 flex items-center px-3 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-login-blue-500)]"
												style={{ color: "var(--color-login-gray-medium)" }}
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
											<p className="text-xs" style={{ color: "var(--color-login-red)" }}>
												{field.state.meta.errors[0]}
											</p>
										)}
									</div>
								)}
							</form.Field>

							{/* Error Message */}
							{loginMutation.error && (
								<div
									className="rounded-lg px-4 py-3 text-sm flex gap-2"
									style={{
										backgroundColor: "rgba(239, 68, 68, 0.06)",
										border: "1px solid rgba(239, 68, 68, 0.15)",
										color: "var(--color-login-red)",
									}}
								>
									<span>
										{loginMutation.error instanceof Error &&
										loginMutation.error.message.includes("Network Error")
											? "Sin conexión con el servidor. Verificá que la API esté corriendo."
											: "Usuario o contraseña incorrectos"}
									</span>
								</div>
							)}

							{/* Submit Button */}
							<Button
								type="submit"
								disabled={loginMutation.isPending}
								variant="blue"
								className="mt-2 h-12 w-full font-semibold transition-all"
								style={{
									backgroundColor: loginMutation.isPending
										? "var(--color-login-gray-medium)"
										: "var(--color-login-blue-700)",
									color: "white",
								}}
								onMouseEnter={(e) => {
									if (!loginMutation.isPending) {
										(e.currentTarget as HTMLButtonElement).style.backgroundColor =
											"var(--color-login-blue-600)";
									}
								}}
								onMouseLeave={(e) => {
									if (!loginMutation.isPending) {
										(e.currentTarget as HTMLButtonElement).style.backgroundColor =
											"var(--color-login-blue-700)";
									}
								}}
							>
								{loginMutation.isPending ? (
									<>
										<Loader2 className="mr-2 h-4 w-4 animate-spin" />
										Ingresando...
									</>
								) : (
									"Ingresar"
								)}
							</Button>
						</form>
					</div>

					{/* Demo Credentials */}
					<div
						className="mt-4 rounded-lg border px-6 py-5"
						style={{
							backgroundColor: "white",
							borderColor: "var(--color-login-gray-light)",
							boxShadow: "0 4px 12px rgba(0, 0, 0, 0.04)",
						}}
					>
						<p
							className="mb-4 text-xs font-bold uppercase tracking-wider"
							style={{ color: "var(--color-login-gray-muted)" }}
						>
							Cuentas de prueba
						</p>
						<div className="space-y-2">
							{demoCredentials.map(({ role, username, password }) => (
								<button
									key={username}
									type="button"
									onClick={() => {
										form.setFieldValue("username", username);
										form.setFieldValue("password", password);
									}}
									className="flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-left transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-login-blue-500)]"
									style={{
										color: "var(--color-login-gray-dark)",
										backgroundColor: "transparent",
									}}
									onMouseEnter={(e) => {
										(e.currentTarget as HTMLButtonElement).style.backgroundColor =
											"rgba(0, 150, 136, 0.08)";
									}}
									onMouseLeave={(e) => {
										(e.currentTarget as HTMLButtonElement).style.backgroundColor = "transparent";
									}}
								>
									<span className="text-xs font-semibold">{role}</span>
									<span
										className="rounded-lg px-2.5 py-1 font-mono text-xs"
										style={{
											backgroundColor: "var(--color-login-gray-light)",
											color: "var(--color-login-gray-muted)",
										}}
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
