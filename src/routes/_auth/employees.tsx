import { useForm } from "@tanstack/react-form";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Plus, RotateCcw, UserX } from "lucide-react";
import { useState } from "react";
import { z } from "zod";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Role, User } from "@/types/api";
import { ROLE_LABELS } from "@/types/api";

export const Route = createFileRoute("/_auth/employees")({
	beforeLoad: () => requireRole("OWNER"),
	component: EmployeesPage,
});

const ROLES: Role[] = ["CASHIER", "WAITER", "COOK"];

const createEmployeeSchema = z.object({
	name: z.string().min(2, "Mínimo 2 caracteres"),
	username: z.string().min(3, "Mínimo 3 caracteres").regex(/^\w+$/, "Solo letras, números y _"),
	password: z.string().min(6, "Mínimo 6 caracteres"),
	role: z.enum(["CASHIER", "WAITER", "COOK"]),
});

const resetPasswordSchema = z.object({
	password: z.string().min(8, "Mínimo 8 caracteres"),
});

function EmployeesPage() {
	const qc = useQueryClient();
	const [showCreate, setShowCreate] = useState(false);
	const [resetId, setResetId] = useState<string | null>(null);

	const { data: employees = [], isLoading } = useQuery<User[]>({
		queryKey: ["employees"],
		queryFn: () => api.get("/users").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: z.infer<typeof createEmployeeSchema>) => api.post("/users", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["employees"] });
			setShowCreate(false);
		},
	});

	const deactivateMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/users/${id}`, { is_active: false }),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["employees"] }),
	});

	const resetMutation = useMutation({
		mutationFn: ({ id, password }: { id: string; password: string }) =>
			api.patch(`/users/${id}/password`, { password }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["employees"] });
			setResetId(null);
		},
	});

	return (
		<div>
			<PageHeader
				title="Empleados"
				description="Gestión de cuentas y accesos del equipo"
				action={
					<Button size="sm" onClick={() => setShowCreate(true)}>
						<Plus size={14} className="mr-1" />
						Nuevo empleado
					</Button>
				}
			/>

			{/* Create form */}
			{showCreate && (
				<CreateEmployeeForm
					onSubmit={(v) => createMutation.mutate(v)}
					onCancel={() => setShowCreate(false)}
					isPending={createMutation.isPending}
					error={createMutation.isError ? "Error al crear el empleado" : undefined}
				/>
			)}

			{/* Table */}
			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : employees.length === 0 ? (
				<EmptyState
					title="Sin empleados registrados"
					description="Crea el primer empleado para empezar"
				/>
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Nombre
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Usuario
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Rol
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Estado
								</th>
								<th className="px-4 py-3" />
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{employees.map((emp) => (
								<tr key={emp.id} className={cn(!emp.isActive && "opacity-50")}>
									<td className="px-4 py-3 font-medium text-foreground">{emp.name}</td>
									<td className="px-4 py-3 text-muted-foreground">{emp.username}</td>
									<td className="px-4 py-3">
										<span className="inline-flex rounded-md bg-[oklch(0.94_0_0)] px-2 py-0.5 text-xs font-medium text-foreground">
											{ROLE_LABELS[emp.role]}
										</span>
									</td>
									<td className="px-4 py-3">
										<span
											className={cn(
												"text-xs",
												emp.isActive ? "text-foreground" : "text-muted-foreground",
											)}
										>
											{emp.isActive ? "Activo" : "Inactivo"}
										</span>
									</td>
									<td className="px-4 py-3">
										<div className="flex items-center justify-end gap-2">
											{resetId === emp.id ? (
												<ResetPasswordForm
													onSubmit={(pw) => resetMutation.mutate({ id: emp.id, password: pw })}
													onCancel={() => setResetId(null)}
													isPending={resetMutation.isPending}
												/>
											) : (
												<>
													<button
														type="button"
														title="Resetear contraseña"
														onClick={() => setResetId(emp.id)}
														className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
													>
														<RotateCcw size={14} />
													</button>
													{emp.isActive && (
														<button
															type="button"
															title="Desactivar empleado"
															onClick={() => deactivateMutation.mutate(emp.id)}
															className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-destructive"
														>
															<UserX size={14} />
														</button>
													)}
												</>
											)}
										</div>
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

function CreateEmployeeForm({
	onSubmit,
	onCancel,
	isPending,
	error,
}: {
	onSubmit: (v: z.infer<typeof createEmployeeSchema>) => void;
	onCancel: () => void;
	isPending: boolean;
	error?: string;
}) {
	const form = useForm({
		defaultValues: { name: "", username: "", password: "", role: "CASHIER" as Role },
		onSubmit: async ({ value }) => {
			const parsed = createEmployeeSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data);
		},
	});

	return (
		<div className="mb-4 rounded-xl border border-border bg-white p-5">
			<h3 className="mb-4 text-sm font-medium text-foreground">Nuevo empleado</h3>
			<form
				onSubmit={(e) => {
					e.preventDefault();
					void form.handleSubmit();
				}}
				className="grid grid-cols-2 gap-4"
			>
				<form.Field name="name">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Nombre completo</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="Ana García"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="username">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Usuario</Label>
							<Input
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="ana.garcia"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="password">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Contraseña</Label>
							<Input
								id={field.name}
								type="password"
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								placeholder="••••••"
							/>
						</div>
					)}
				</form.Field>

				<form.Field name="role">
					{(field) => (
						<div className="space-y-1.5">
							<Label htmlFor={field.name}>Rol</Label>
							<select
								id={field.name}
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value as Role)}
								className="w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
							>
								{ROLES.map((r) => (
									<option key={r} value={r}>
										{ROLE_LABELS[r]}
									</option>
								))}
							</select>
						</div>
					)}
				</form.Field>

				{error && <p className="col-span-2 text-xs text-destructive">{error}</p>}

				<div className="col-span-2 flex justify-end gap-2">
					<Button type="button" variant="outline" size="sm" onClick={onCancel}>
						Cancelar
					</Button>
					<Button type="submit" size="sm" disabled={isPending}>
						{isPending ? "Creando…" : "Crear empleado"}
					</Button>
				</div>
			</form>
		</div>
	);
}

function ResetPasswordForm({
	onSubmit,
	onCancel,
	isPending,
}: {
	onSubmit: (password: string) => void;
	onCancel: () => void;
	isPending: boolean;
}) {
	const form = useForm({
		defaultValues: { password: "" },
		onSubmit: async ({ value }) => {
			const parsed = resetPasswordSchema.safeParse(value);
			if (parsed.success) onSubmit(parsed.data.password);
		},
	});

	return (
		<form
			onSubmit={(e) => {
				e.preventDefault();
				void form.handleSubmit();
			}}
			className="flex items-center gap-2"
		>
			<form.Field name="password">
				{(field) => (
					<Input
						type="password"
						placeholder="Nueva contraseña"
						value={field.state.value}
						onChange={(e) => field.handleChange(e.target.value)}
						className="h-7 w-36 text-xs"
					/>
				)}
			</form.Field>
			<Button type="submit" size="sm" className="h-7 text-xs" disabled={isPending}>
				{isPending ? "…" : "Guardar"}
			</Button>
			<button
				type="button"
				onClick={onCancel}
				className="text-xs text-muted-foreground hover:text-foreground"
			>
				✕
			</button>
		</form>
	);
}
