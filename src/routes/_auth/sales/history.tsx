import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { ChevronDown, ChevronUp } from "lucide-react";
import { useState } from "react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Sale, SaleStatus } from "@/types/api";
import { SALE_STATUS_LABELS } from "@/types/api";

export const Route = createFileRoute("/_auth/sales/history")({
	beforeLoad: () => requireRole("OWNER", "CASHIER", "WAITER"),
	component: SalesHistoryPage,
});

const STATUS_STYLES: Record<SaleStatus, string> = {
	PENDING: "bg-[oklch(0.93_0.03_60)] text-[oklch(0.45_0.08_60)]",
	COMPLETED: "bg-[oklch(0.93_0.02_145)] text-[oklch(0.4_0.1_145)]",
	CANCELLED: "bg-[oklch(0.94_0_0)] text-muted-foreground",
};

function SalesHistoryPage() {
	const [expanded, setExpanded] = useState<string | null>(null);
	const [statusFilter, setStatusFilter] = useState<SaleStatus | "ALL">("ALL");

	const { data: sales = [], isLoading } = useQuery<Sale[]>({
		queryKey: ["sales"],
		queryFn: () => api.get("/sales").then((r) => r.data),
	});

	const filtered = statusFilter === "ALL" ? sales : sales.filter((s) => s.status === statusFilter);

	const totalCompleted = sales
		.filter((s) => s.status === "COMPLETED")
		.reduce((acc, s) => acc + Number(s.total), 0);

	return (
		<div>
			<PageHeader
				title="Historial de ventas"
				description={`Total cobrado: S/ ${totalCompleted.toFixed(2)}`}
			/>

			{/* Filters */}
			<div className="mb-4 flex gap-1">
				{(["ALL", "PENDING", "COMPLETED", "CANCELLED"] as const).map((s) => (
					<button
						key={s}
						type="button"
						onClick={() => setStatusFilter(s)}
						className={cn(
							"rounded-md px-3 py-1.5 text-xs font-medium transition-colors",
							statusFilter === s
								? "bg-foreground text-background"
								: "text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground",
						)}
					>
						{s === "ALL" ? "Todas" : SALE_STATUS_LABELS[s]}
					</button>
				))}
			</div>

			{isLoading ? (
				<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
			) : filtered.length === 0 ? (
				<EmptyState title="Sin ventas registradas" description="Las ventas aparecerán aquí" />
			) : (
				<div className="rounded-xl border border-border bg-white overflow-hidden">
					<table className="w-full text-sm">
						<thead>
							<tr className="border-b border-border bg-[oklch(0.975_0_0)]">
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									ID
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Productos
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Total
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Estado
								</th>
								<th className="px-4 py-3 text-left text-xs font-medium text-muted-foreground">
									Fecha
								</th>
								<th className="px-4 py-3" />
							</tr>
						</thead>
						<tbody className="divide-y divide-border">
							{filtered.map((sale) => (
								<>
									<tr key={sale.id} className={cn(sale.status === "CANCELLED" && "opacity-50")}>
										<td className="px-4 py-3 font-mono text-xs text-muted-foreground">
											#{sale.id.slice(-6).toUpperCase()}
										</td>
										<td className="px-4 py-3 text-muted-foreground">
											{sale.items?.length ?? 0} ítem{(sale.items?.length ?? 0) !== 1 ? "s" : ""}
										</td>
										<td className="px-4 py-3 font-medium text-foreground">
											S/ {Number(sale.total).toFixed(2)}
										</td>
										<td className="px-4 py-3">
											<span
												className={cn(
													"inline-flex rounded-md px-2 py-0.5 text-xs font-medium",
													STATUS_STYLES[sale.status],
												)}
											>
												{SALE_STATUS_LABELS[sale.status]}
											</span>
										</td>
										<td className="px-4 py-3 text-xs text-muted-foreground">
											{new Date(sale.created_at).toLocaleString("es-PE", {
												day: "2-digit",
												month: "2-digit",
												hour: "2-digit",
												minute: "2-digit",
											})}
										</td>
										<td className="px-4 py-3">
											<button
												type="button"
												onClick={() => setExpanded(expanded === sale.id ? null : sale.id)}
												className="rounded p-1 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
											>
												{expanded === sale.id ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
											</button>
										</td>
									</tr>

									{expanded === sale.id && (
										<tr key={`${sale.id}-detail`}>
											<td colSpan={6} className="bg-[oklch(0.975_0_0)] px-4 py-3">
												<div className="space-y-1">
													{sale.items?.map((item) => (
														<div
															key={item.id}
															className="flex items-center justify-between text-xs"
														>
															<span className="text-foreground">
																{item.product?.name} × {item.quantity}
															</span>
															<span className="text-muted-foreground">
																S/ {Number(item.subtotal).toFixed(2)}
															</span>
														</div>
													))}
													{sale.notes && (
														<p className="mt-1 text-xs text-muted-foreground italic">
															{sale.notes}
														</p>
													)}
												</div>
											</td>
										</tr>
									)}
								</>
							))}
						</tbody>
					</table>
				</div>
			)}
		</div>
	);
}
