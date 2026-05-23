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

interface PaymentNotification {
	id: string;
	notification_id: string;
	amount: number;
	sender_name: string;
	source: string;
	raw_text: string;
	is_reviewed: boolean;
	reviewed_by?: string;
	reviewed_at?: string;
	created_at: string;
}

function PaymentsPage() {
	const qc = useQueryClient();

	const { data: payments = [], isLoading } = useQuery<PaymentNotification[]>({
		queryKey: ["payments"],
		queryFn: () => api.get("/payments/notifications").then((r) => r.data),
		refetchInterval: 15_000,
	});

	const reviewMutation = useMutation({
		mutationFn: (id: string) =>
			api.patch(`/payments/notifications/${id}`, { status: "REVIEWED" }),
		onSuccess: () => void qc.invalidateQueries({ queryKey: ["payments"] }),
	});

	const pending = payments.filter((p) => !p.is_reviewed);
	const reviewed = payments.filter((p) => p.is_reviewed);

	return (
		<div>
			<PageHeader
				title="Notificaciones de pago"
				description={
					pending.length > 0
						? `${pending.length} pago${pending.length > 1 ? "s" : ""} sin revisar`
						: "Sin pagos pendientes de revisión"
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
								Sin revisar
							</p>
							<div className="space-y-2">
								{pending.map((p) => (
									<PaymentCard
										key={p.id}
										payment={p}
										onReview={() => reviewMutation.mutate(p.id)}
										isPending={reviewMutation.isPending}
									/>
								))}
							</div>
						</section>
					)}

					{reviewed.length > 0 && (
						<section>
							<p className="mb-3 text-xs font-medium uppercase tracking-wide text-muted-foreground">
								Revisados
							</p>
							<div className="rounded-xl border border-border bg-white overflow-hidden">
								<table className="w-full text-sm">
									<tbody className="divide-y divide-border">
										{reviewed.map((p) => (
											<tr key={p.id} className="opacity-60">
												<td className="px-4 py-3">
													<p className="font-medium text-foreground">{p.sender_name}</p>
													<p className="text-xs text-muted-foreground">{p.source}</p>
												</td>
												<td className="px-4 py-3 font-medium text-foreground">
													S/ {Number(p.amount).toFixed(2)}
												</td>
												<td className="px-4 py-3 text-xs text-muted-foreground line-clamp-1 max-w-xs">
													{p.raw_text}
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
	onReview,
	isPending,
}: {
	payment: PaymentNotification;
	onReview: () => void;
	isPending: boolean;
}) {
	return (
		<div className="rounded-xl border border-border bg-white p-4">
			<div className="flex items-start justify-between gap-4">
				<div className="flex-1 min-w-0">
					<div className="flex items-center gap-2">
						<p className="text-sm font-medium text-foreground">{payment.sender_name}</p>
						<span className="rounded-md bg-[oklch(0.94_0_0)] px-1.5 py-0.5 text-xs text-muted-foreground">
							{payment.source}
						</span>
					</div>
					<p className="mt-0.5 text-xs text-muted-foreground line-clamp-2">{payment.raw_text}</p>
					<p className="mt-2 text-lg font-semibold text-foreground">
						S/ {Number(payment.amount).toFixed(2)}
					</p>
				</div>
			</div>

			<div className="mt-3">
				<button
					type="button"
					onClick={onReview}
					disabled={isPending}
					className={cn(
						"flex w-full items-center justify-center gap-1.5 rounded-lg bg-[oklch(0.18_0_0)] px-3 py-2 text-xs font-medium text-[oklch(0.95_0_0)] transition-colors hover:bg-[oklch(0.25_0_0)] disabled:opacity-50",
					)}
				>
					<CheckCircle size={12} />
					Marcar como revisado
				</button>
			</div>
		</div>
	);
}
