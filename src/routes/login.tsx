import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
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
	username: z.string().min(1, "El usuario es requerido"),
	password: z.string().min(1, "La contraseña es requerida"),
});

function LoginPage() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);

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
			const parsed = loginSchema.safeParse(value);
			if (!parsed.success) return;
			await loginMutation.mutateAsync(parsed.data);
		},
	});

	return (
		<div className="flex min-h-screen items-center justify-center bg-[oklch(0.98_0_0)]">
			<div className="w-full max-w-sm">
				{/* Brand */}
				<div className="mb-8 text-center">
					<h1 className="text-2xl font-semibold tracking-tight text-foreground">SmartBite</h1>
					<p className="mt-1 text-sm text-muted-foreground">Sistema de gestión para restaurantes</p>
				</div>

				{/* Card */}
				<div className="rounded-xl border border-border bg-white px-8 py-8 shadow-sm">
					<h2 className="mb-6 text-base font-medium text-foreground">Iniciar sesión</h2>

					<form
						onSubmit={(e) => {
							e.preventDefault();
							void form.handleSubmit();
						}}
						className="space-y-4"
					>
						<form.Field
							name="username"
							validators={{
								onChange: ({ value }) =>
									value.length === 0 ? "El usuario es requerido" : undefined,
							}}
						>
							{(field) => (
								<div className="space-y-1.5">
									<Label htmlFor={field.name}>Usuario</Label>
									<Input
										id={field.name}
										type="text"
										placeholder="tu.usuario"
										autoComplete="username"
										value={field.state.value}
										onChange={(e) => field.handleChange(e.target.value)}
										onBlur={field.handleBlur}
										aria-invalid={field.state.meta.errors.length > 0}
									/>
									{field.state.meta.errors.length > 0 && (
										<p className="text-xs text-destructive">{field.state.meta.errors[0]}</p>
									)}
								</div>
							)}
						</form.Field>

						<form.Field
							name="password"
							validators={{
								onChange: ({ value }) =>
									value.length === 0 ? "La contraseña es requerida" : undefined,
							}}
						>
							{(field) => (
								<div className="space-y-1.5">
									<Label htmlFor={field.name}>Contraseña</Label>
									<Input
										id={field.name}
										type="password"
										placeholder="••••••••"
										autoComplete="current-password"
										value={field.state.value}
										onChange={(e) => field.handleChange(e.target.value)}
										onBlur={field.handleBlur}
										aria-invalid={field.state.meta.errors.length > 0}
									/>
									{field.state.meta.errors.length > 0 && (
										<p className="text-xs text-destructive">{field.state.meta.errors[0]}</p>
									)}
								</div>
							)}
						</form.Field>

						{loginMutation.error && (
							<p className="rounded-lg bg-destructive/8 px-3 py-2 text-sm text-destructive">
								{loginMutation.error instanceof Error &&
								loginMutation.error.message.includes("Network Error")
									? "No se pudo conectar con el servidor. Verifica que la API esté corriendo."
									: "Usuario o contraseña incorrectos"}
							</p>
						)}

						<Button type="submit" className="mt-2 w-full" disabled={loginMutation.isPending}>
							{loginMutation.isPending ? "Ingresando…" : "Ingresar"}
						</Button>
					</form>
				</div>
			</div>
		</div>
	);
}
