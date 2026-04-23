import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { CheckCircle, XCircle } from "lucide-react";
import { useState } from "react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Sale } from "@/types/api";

export const Route = createFileRoute("/_auth/sales/checkout")({
	beforeLoad: () => requireRole("OWNER", "CASHIER"),
	component: CheckoutPage,
});

function CheckoutPage() {
	const qc = useQueryClient();
	const [selected, setSelected] = useState<string | null>(null);

	const { data: sales = [], isLoading } = useQuery<Sale[]>({
		queryKey: ["sales", "pending"],
		queryFn: () => api.get("/sales?status=PENDING").then((r) => r.data),
	});

	const completeMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/sales/${id}/status`, { status: "COMPLETED" }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["sales"] });
			setSelected(null);
		},
	});

	const cancelMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/sales/${id}/status`, { status: "CANCELLED" }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["sales"] });
			setSelected(null);
		},
	});

	const selectedSale = sales.find((s) => s.id === selected);

	return (
		<div className="flex gap-6">
			{/* Pending sales list */}
			<div className="flex-1 min-w-0">
				<PageHeader title="Cobrar" description="Ventas pendientes de pago" />

				{isLoading ? (
					<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
				) : sales.length === 0 ? (
					<EmptyState
						title="Sin ventas pendientes"
						description="Todas las ventas han sido procesadas"
					/>
				) : (
					<div className="space-y-2">
						{sales.map((sale) => (
							<button
								key={sale.id}
								type="button"
								onClick={() => setSelected(sale.id === selected ? null : sale.id)}
								className={cn(
									"w-full rounded-xl border p-4 text-left transition-colors",
									selected === sale.id
										? "border-[oklch(0.6_0_0)] bg-[oklch(0.975_0_0)]"
										: "border-border bg-white hover:bg-[oklch(0.975_0_0)]",
								)}
							>
								<div className="flex items-center justify-between">
									<div>
										<p className="text-sm font-medium text-foreground">
											Venta #{sale.id.slice(-6).toUpperCase()}
										</p>
										<p className="mt-0.5 text-xs text-muted-foreground">
											{sale.items?.length ?? 0} producto{(sale.items?.length ?? 0) !== 1 ? "s" : ""}
											{sale.notes && ` · ${sale.notes}`}
										</p>
									</div>
									<p className="text-base font-semibold text-foreground">
										S/ {Number(sale.total).toFixed(2)}
									</p>
								</div>
							</button>
						))}
					</div>
				)}
			</div>

			{/* Detail panel */}
			<div className="w-72 shrink-0">
				<div className="sticky top-0 rounded-xl border border-border bg-white p-4">
					<p className="mb-3 text-sm font-medium text-foreground">Detalle del pedido</p>

					{!selectedSale ? (
						<p className="py-6 text-center text-xs text-muted-foreground">
							Selecciona una venta para ver el detalle
						</p>
					) : (
						<>
							<div className="space-y-2">
								{selectedSale.items?.map((item) => (
									<div key={item.id} className="flex items-center justify-between text-xs">
										<span className="text-foreground">
											{item.product?.name} × {item.quantity}
										</span>
										<span className="text-muted-foreground">
											S/ {Number(item.subtotal).toFixed(2)}
										</span>
									</div>
								))}
							</div>

							{selectedSale.notes && (
								<p className="mt-3 rounded-md bg-[oklch(0.97_0_0)] px-3 py-2 text-xs text-muted-foreground">
									{selectedSale.notes}
								</p>
							)}

							<div className="mt-3 border-t border-border pt-3">
								<div className="mb-4 flex items-center justify-between">
									<span className="text-sm text-muted-foreground">Total a cobrar</span>
									<span className="text-lg font-bold text-foreground">
										S/ {Number(selectedSale.total).toFixed(2)}
									</span>
								</div>

								<div className="flex flex-col gap-2">
									<Button
										className="w-full"
										size="sm"
										onClick={() => completeMutation.mutate(selectedSale.id)}
										disabled={completeMutation.isPending || cancelMutation.isPending}
									>
										<CheckCircle size={14} className="mr-1.5" />
										{completeMutation.isPending ? "Procesando…" : "Cobrar"}
									</Button>
									<Button
										className="w-full"
										size="sm"
										variant="outline"
										onClick={() => cancelMutation.mutate(selectedSale.id)}
										disabled={completeMutation.isPending || cancelMutation.isPending}
									>
										<XCircle size={14} className="mr-1.5" />
										{cancelMutation.isPending ? "Cancelando…" : "Cancelar venta"}
									</Button>
								</div>

								{(completeMutation.isError || cancelMutation.isError) && (
									<p className="mt-2 text-center text-xs text-destructive">Error al procesar</p>
								)}
							</div>
						</>
					)}
				</div>
			</div>
		</div>
	);
}
