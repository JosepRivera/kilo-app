import { useQuery } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { ChevronDown, ChevronUp } from "lucide-react";
import { Fragment, useState } from "react";
import { EmptyState } from "@/components/shared/EmptyState";
import { PageHeader } from "@/components/shared/PageHeader";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import {
	getSaleStatusGroup,
	SALE_STATUS_LABELS,
	type Sale,
	type SaleStatus,
	type SaleStatusGroup,
} from "@/types/api";

export const Route = createFileRoute("/_auth/sales/history")({
	beforeLoad: () => requireRole("OWNER", "CASHIER", "WAITER"),
	component: SalesHistoryPage,
});

const STATUS_STYLES: Record<SaleStatusGroup, string> = {
	pending: "bg-[oklch(0.93_0.03_60)] text-[oklch(0.45_0.08_60)]",
	completed: "bg-[oklch(0.93_0.02_145)] text-[oklch(0.4_0.1_145)]",
	cancelled: "bg-[oklch(0.94_0_0)] text-muted-foreground",
};

function getStatusStyle(status: SaleStatus): string {
	return STATUS_STYLES[getSaleStatusGroup(status)];
}

function getStatusLabel(status: SaleStatus): string {
	return SALE_STATUS_LABELS[status];
}

type FilterValue = "ALL" | SaleStatusGroup;

const FILTER_TABS: ReadonlyArray<{ value: FilterValue; label: string }> = [
	{ value: "ALL", label: "Todas" },
	{ value: "pending", label: "Pendiente" },
	{ value: "completed", label: "Completada" },
	{ value: "cancelled", label: "Cancelada" },
];

function SalesHistoryPage() {
	const [expanded, setExpanded] = useState<string | null>(null);
	const [statusFilter, setStatusFilter] = useState<FilterValue>("ALL");

	const { data: sales = [], isLoading } = useQuery<Sale[]>({
		queryKey: ["sales"],
		queryFn: () => api.get("/sales").then((r) => r.data),
	});

	const filtered =
		statusFilter === "ALL"
			? sales
			: sales.filter((s) => getSaleStatusGroup(s.status) === statusFilter);

	const totalCompleted = sales
		.filter((s) => getSaleStatusGroup(s.status) === "completed")
		.reduce((acc, s) => acc + Number(s.total), 0);

	return (
		<div>
			<PageHeader
				title="Historial de ventas"
				description={`Total cobrado: S/ ${totalCompleted.toFixed(2)}`}
			/>

			{/* Filters */}
			<div className="mb-4 flex gap-1">
				{FILTER_TABS.map((tab) => (
					<button
						key={tab.value}
						type="button"
						onClick={() => setStatusFilter(tab.value)}
						className={cn(
							"rounded-md px-3 py-1.5 text-xs font-medium transition-colors",
							statusFilter === tab.value
								? "bg-foreground text-background"
								: "text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground",
						)}
					>
						{tab.label}
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
								<Fragment key={sale.id}>
									<tr
										key={sale.id}
										className={cn(sale.status === "CANCELLED" && "opacity-50")}
									>
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
													getStatusStyle(sale.status),
												)}
											>
												{getStatusLabel(sale.status)}
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
								</Fragment>
							))}
						</tbody>
					</table>
				</div>
			)}
		</div>
	);
}
