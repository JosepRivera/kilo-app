import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { CheckCircle } from "lucide-react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_auth/payments/")({
	beforeLoad: () => requireRole("OWNER", "CASHIER"),
	component: PaymentsPage,
});

type PaymentStatus = "PENDING" | "CONFIRMED" | "REJECTED";

interface PaymentNotification {
	id: string;
	amount: number;
	sender_name: string;
	reference: string;
	method: string;
	status: PaymentStatus;
	image_url?: string;
	sale_id?: string;
	created_at: string;
}

const STATUS_STYLES: Record<PaymentStatus, string> = {
	PENDING: "bg-[oklch(0.93_0.03_60)] text-[oklch(0.45_0.08_60)]",
	CONFIRMED: "bg-[oklch(0.93_0.02_145)] text-[oklch(0.4_0.1_145)]",
	REJECTED: "bg-[oklch(0.94_0_0)] text-muted-foreground",
};

const STATUS_LABELS: Record<PaymentStatus, string> = {
	PENDING: "Pendiente",
	CONFIRMED: "Confirmado",
	REJECTED: "Rechazado",
};

function PaymentsPage() {
	const qc = useQueryClient();

	const { data: payments = [], isLoading } = useQuery<PaymentNotification[]>({
		queryKey: ["payments"],
		queryFn: () => api.get("/payments").then((r) => r.data),
		refetchInterval: 15_000,
	});

	const confirmMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/payments/${id}`, { status: "CONFIRMED" }),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["payments"] }),
	});

	const rejectMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/payments/${id}`, { status: "REJECTED" }),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["payments"] }),
	});

	const pending = payments.filter((p) => p.status === "PENDING");
	const processed = payments.filter((p) => p.status !== "PENDING");

	return (
		<div>
			<PageHeader
				title="Notificaciones de pago"
				description={
					pending.length > 0
						? `${pending.length} pago${pending.length > 1 ? "s" : ""} por confirmar`
						: "Sin pagos pendientes"
				}
			/>

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : payments.length === 0 ? (
				<EmptyState
					title="Sin notificaciones de pago"
					description="Las notificaciones entrantes aparecerán aquí"
				/>
			) : (
				<div className="space-y-6">
					{pending.length > 0 && (
						<section>
							<p className="mb-3 text-xs font-medium uppercase tracking-wide text-muted-foreground">
								Pendientes
							</p>
							<div className="space-y-2">
								{pending.map((p) => (
									<PaymentCard
										key={p.id}
										payment={p}
										onConfirm={() => confirmMutation.mutate(p.id)}
										onReject={() => rejectMutation.mutate(p.id)}
										isPending={confirmMutation.isPending || rejectMutation.isPending}
									/>
								))}
							</div>
						</section>
					)}

					{processed.length > 0 && (
						<section>
							<p className="mb-3 text-xs font-medium uppercase tracking-wide text-muted-foreground">
								Procesados
							</p>
							<div className="rounded-xl border border-border bg-white overflow-hidden">
								<table className="w-full text-sm">
									<tbody className="divide-y divide-border">
										{processed.map((p) => (
											<tr key={p.id} className={cn(p.status === "REJECTED" && "opacity-50")}>
												<td className="px-4 py-3">
													<p className="font-medium text-foreground">{p.sender_name}</p>
													<p className="text-xs text-muted-foreground">{p.reference}</p>
												</td>
												<td className="px-4 py-3 text-muted-foreground text-sm">{p.method}</td>
												<td className="px-4 py-3 font-medium text-foreground">
													S/ {Number(p.amount).toFixed(2)}
												</td>
												<td className="px-4 py-3">
													<span
														className={cn(
															"inline-flex rounded-md px-2 py-0.5 text-xs font-medium",
															STATUS_STYLES[p.status],
														)}
													>
														{STATUS_LABELS[p.status]}
													</span>
												</td>
												<td className="px-4 py-3 text-right text-xs text-muted-foreground">
													{new Date(p.created_at).toLocaleString("es-PE", {
														day: "2-digit",
														month: "2-digit",
														hour: "2-digit",
														minute: "2-digit",
													})}
												</td>
											</tr>
										))}
									</tbody>
								</table>
							</div>
						</section>
					)}
				</div>
			)}
		</div>
	);
}

function PaymentCard({
	payment,
	onConfirm,
	onReject,
	isPending,
}: {
	payment: PaymentNotification;
	onConfirm: () => void;
	onReject: () => void;
	isPending: boolean;
}) {
	return (
		<div className="rounded-xl border border-border bg-white p-4">
			<div className="flex items-start justify-between gap-4">
				<div className="flex-1 min-w-0">
					<div className="flex items-center gap-2">
						<p className="text-sm font-medium text-foreground">{payment.sender_name}</p>
						<span className="text-xs text-muted-foreground">{payment.method}</span>
					</div>
					<p className="mt-0.5 text-xs text-muted-foreground">{payment.reference}</p>
					<p className="mt-2 text-lg font-semibold text-foreground">
						S/ {Number(payment.amount).toFixed(2)}
					</p>
				</div>

				{payment.image_url && (
					<img
						src={payment.image_url}
						alt="Comprobante"
						className="h-16 w-16 rounded-lg border border-border object-cover shrink-0"
					/>
				)}
			</div>

			<div className="mt-3 flex gap-2">
				<button
					type="button"
					onClick={onConfirm}
					disabled={isPending}
					className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-[oklch(0.18_0_0)] px-3 py-2 text-xs font-medium text-[oklch(0.95_0_0)] transition-colors hover:bg-[oklch(0.25_0_0)] disabled:opacity-50"
				>
					<CheckCircle size={12} />
					Confirmar
				</button>
				<button
					type="button"
					onClick={onReject}
					disabled={isPending}
					className="flex flex-1 items-center justify-center rounded-lg border border-border px-3 py-2 text-xs font-medium text-muted-foreground transition-colors hover:bg-[oklch(0.97_0_0)] hover:text-foreground disabled:opacity-50"
				>
					Rechazar
				</button>
			</div>
		</div>
	);
}
