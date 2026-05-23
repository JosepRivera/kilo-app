import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Banknote, CheckCircle, ClipboardList, Smartphone, XCircle } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Sale } from "@/types/api";

export const Route = createFileRoute("/_auth/sales/checkout")({
	beforeLoad: () => requireRole("OWNER", "CASHIER"),
	component: CheckoutPage,
});

type PaymentMethod = "CASH" | "YAPE" | "PLIN" | "AGORA";

const PAYMENT_OPTIONS: { value: PaymentMethod; label: string; icon: React.ReactNode; color: string }[] = [
	{ value: "CASH", label: "Efectivo", icon: <Banknote size={14} />, color: "border-green-300 bg-green-50 text-green-700 data-[active=true]:border-green-500 data-[active=true]:bg-green-100" },
	{ value: "YAPE", label: "Yape", icon: <Smartphone size={14} />, color: "border-purple-300 bg-purple-50 text-purple-700 data-[active=true]:border-purple-500 data-[active=true]:bg-purple-100" },
	{ value: "PLIN", label: "Plin", icon: <Smartphone size={14} />, color: "border-teal-300 bg-teal-50 text-teal-700 data-[active=true]:border-teal-500 data-[active=true]:bg-teal-100" },
	{ value: "AGORA", label: "Ágora", icon: <Smartphone size={14} />, color: "border-blue-300 bg-blue-50 text-blue-700 data-[active=true]:border-blue-500 data-[active=true]:bg-blue-100" },
];

function CheckoutPage() {
	const qc = useQueryClient();
	const [selected, setSelected] = useState<string | null>(null);
	const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("CASH");

	const { data: sales = [], isLoading } = useQuery<Sale[]>({
		queryKey: ["sales", "open"],
		queryFn: () => api.get("/sales?status=OPEN").then((r) => r.data),
	});

	const payMutation = useMutation({
		mutationFn: ({ id, method }: { id: string; method: PaymentMethod }) =>
			api.post(`/sales/${id}/payments`, { payment_method: method }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["sales"] });
			setSelected(null);
		},
	});

	const cancelMutation = useMutation({
		mutationFn: (id: string) => api.patch(`/sales/${id}`, { status: "CANCELLED" }),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["sales"] });
			setSelected(null);
		},
	});

	const selectedSale = sales.find((s) => s.id === selected);

	return (
		<div className="flex h-full flex-col gap-0 md:flex-row md:gap-5">

			{/* ── Open orders list ── */}
			<div className="flex min-w-0 flex-1 flex-col">
				<div className="mb-4">
					<h1 className="text-xl font-semibold text-gray-900">Cobrar</h1>
					<p className="text-sm text-gray-400">Pedidos abiertos pendientes de pago</p>
				</div>

				{isLoading ? (
					<div className="space-y-2">
						{Array.from({ length: 4 }).map((_, i) => (
							<div key={i} className="h-16 animate-pulse rounded-xl bg-gray-100" />
						))}
					</div>
				) : sales.length === 0 ? (
					<div className="flex flex-col items-center justify-center py-16 text-center">
						<div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
							<CheckCircle size={22} className="text-green-500" />
						</div>
						<p className="text-sm font-medium text-gray-600">Sin pedidos pendientes</p>
						<p className="text-xs text-gray-400">Todos los pedidos han sido cobrados</p>
					</div>
				) : (
					<div className="space-y-2 overflow-y-auto">
						{sales.map((sale) => (
							<button
								key={sale.id}
								type="button"
								onClick={() => setSelected(sale.id === selected ? null : sale.id)}
								className={cn(
									"w-full rounded-xl border p-4 text-left transition-all",
									selected === sale.id
										? "border-orange-400 bg-orange-50 shadow-sm"
										: "border-gray-200 bg-white hover:border-orange-300 hover:shadow-sm",
								)}
							>
								<div className="flex items-center justify-between">
									<div>
										<p className="text-sm font-semibold text-gray-800">
											Pedido #{sale.id.slice(-6).toUpperCase()}
										</p>
										<p className="mt-0.5 text-xs text-gray-400">
											{sale.items?.length ?? 0} producto{(sale.items?.length ?? 0) !== 1 ? "s" : ""}
											{sale.notes && ` · ${sale.notes}`}
										</p>
									</div>
									<p className="text-base font-bold text-orange-500">
										S/ {Number(sale.total).toFixed(2)}
									</p>
								</div>
							</button>
						))}
					</div>
				)}
			</div>

			{/* ── Payment panel ── */}
			<div className="w-full shrink-0 md:w-72">
				<div className="sticky top-0 rounded-xl border border-gray-200 bg-white shadow-sm">
					<div className="flex items-center gap-2 border-b border-gray-100 px-4 py-3">
						<div className="flex h-7 w-7 items-center justify-center rounded-lg bg-orange-100">
							<ClipboardList size={14} className="text-orange-500" />
						</div>
						<span className="text-sm font-semibold text-gray-800">Detalle del pedido</span>
					</div>

					{!selectedSale ? (
						<div className="flex flex-col items-center justify-center py-10 text-center">
							<div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-gray-50">
								<ClipboardList size={18} className="text-gray-300" />
							</div>
							<p className="text-xs text-gray-400">Seleccioná un pedido</p>
						</div>
					) : (
						<div className="px-4 pb-4 pt-3">
							{/* Items */}
							<div className="mb-3 space-y-2">
								{selectedSale.items?.map((item) => (
									<div key={item.id} className="flex items-center justify-between text-xs">
										<span className="text-gray-700">
											{item.product?.name} × {item.quantity}
										</span>
										<span className="font-medium text-gray-700">
											S/ {Number(item.subtotal).toFixed(2)}
										</span>
									</div>
								))}
							</div>

							{selectedSale.notes && (
								<p className="mb-3 rounded-lg bg-gray-50 px-3 py-2 text-xs text-gray-500">
									{selectedSale.notes}
								</p>
							)}

							<div className="mb-4 flex items-center justify-between border-t border-gray-100 pt-3">
								<span className="text-xs text-gray-500">Total</span>
								<span className="text-lg font-bold text-gray-900">
									S/ {Number(selectedSale.total).toFixed(2)}
								</span>
							</div>

							{/* Payment method */}
							<p className="mb-2 text-xs font-medium text-gray-500">Método de pago</p>
							<div className="mb-4 grid grid-cols-2 gap-1.5">
								{PAYMENT_OPTIONS.map((opt) => (
									<button
										key={opt.value}
										type="button"
										data-active={paymentMethod === opt.value}
										onClick={() => setPaymentMethod(opt.value)}
										className={cn(
											"flex items-center gap-1.5 rounded-lg border px-2.5 py-2 text-xs font-medium transition-all",
											opt.color,
										)}
									>
										{opt.icon}
										{opt.label}
									</button>
								))}
							</div>

							<Button
								className="w-full bg-orange-500 text-white hover:bg-orange-600 active:scale-[0.98]"
								onClick={() => payMutation.mutate({ id: selectedSale.id, method: paymentMethod })}
								disabled={payMutation.isPending || cancelMutation.isPending}
							>
								<CheckCircle size={14} className="mr-1.5" />
								{payMutation.isPending ? "Procesando…" : "Registrar pago"}
							</Button>

							<button
								type="button"
								onClick={() => cancelMutation.mutate(selectedSale.id)}
								disabled={payMutation.isPending || cancelMutation.isPending}
								className="mt-2 flex w-full items-center justify-center gap-1.5 rounded-lg border border-gray-200 py-2 text-xs text-gray-500 transition-colors hover:border-red-200 hover:bg-red-50 hover:text-red-500"
							>
								<XCircle size={12} />
								Cancelar pedido
							</button>

							{(payMutation.isError || cancelMutation.isError) && (
								<p className="mt-2 text-center text-xs text-red-500">Error al procesar</p>
							)}
						</div>
					)}
				</div>
			</div>
		</div>
	);
}
