import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { ClipboardList, Minus, Plus, Search, ShoppingBag, Trash2 } from "lucide-react";
import { useState } from "react";
import { VoiceFab } from "@/components/ui/VoiceFab";
import { getCategoryIcon } from "@/lib/categoryIcons";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Product } from "@/types/api";

export const Route = createFileRoute("/_auth/sales/new")({
	beforeLoad: () => requireRole("OWNER", "CASHIER", "WAITER"),
	component: NewSalePage,
});

interface OrderItem {
	product: Product;
	quantity: number;
}

function NewSalePage() {
	const qc = useQueryClient();
	const navigate = useNavigate();
	const [order, setOrder] = useState<OrderItem[]>([]);
	const [search, setSearch] = useState("");
	const [activeCategory, setActiveCategory] = useState<string>("Todos");
	const [notes, setNotes] = useState("");

	const { data: products = [], isLoading } = useQuery<Product[]>({
		queryKey: ["products"],
		queryFn: () => api.get("/products").then((r) => r.data),
	});

	const createMutation = useMutation({
		mutationFn: (body: object) => api.post("/sales", body),
		onSuccess: () => {
			void qc.invalidateQueries({ queryKey: ["sales"] });
			void navigate({ to: "/sales/history" });
		},
	});

	const addToOrder = (product: Product) => {
		setOrder((prev) => {
			const existing = prev.find((item) => item.product.id === product.id);
			if (existing)
				return prev.map((item) =>
					item.product.id === product.id ? { ...item, quantity: item.quantity + 1 } : item,
				);
			return [...prev, { product, quantity: 1 }];
		});
	};

	const updateQty = (productId: string, qty: number) => {
		if (qty <= 0) {
			setOrder((prev) => prev.filter((item) => item.product.id !== productId));
		} else {
			setOrder((prev) =>
				prev.map((item) => (item.product.id === productId ? { ...item, quantity: qty } : item)),
			);
		}
	};

	const total = order.reduce((acc, item) => acc + item.product.price * item.quantity, 0);
	const totalItems = order.reduce((acc, item) => acc + item.quantity, 0);

	const handleSubmit = () => {
		if (order.length === 0) return;
		createMutation.mutate({
			items: order.map((item) => ({
				product_id: item.product.id,
				quantity: item.quantity,
				unit_price: item.product.price,
			})),
			notes: notes || undefined,
		});
	};

	const allCategories = [...new Set(products.filter((p) => p.isActive).map((p) => p.category))];

	const filtered = products.filter(
		(p) =>
			p.isActive &&
			(search === "" ||
				p.name.toLowerCase().includes(search.toLowerCase()) ||
				p.category.toLowerCase().includes(search.toLowerCase())) &&
			(activeCategory === "Todos" || p.category === activeCategory),
	);

	const categories = activeCategory === "Todos"
		? [...new Set(filtered.map((p) => p.category))]
		: [activeCategory];

	return (
		<>
		<div className="flex h-full flex-col gap-0 md:flex-row md:gap-5">

			{/* ── Catalog ── */}
			<div className="flex min-w-0 flex-1 flex-col">

				{/* Header */}
				<div className="mb-4 flex items-start justify-between">
					<div>
						<h1 className="text-xl font-semibold text-gray-900">Nuevo pedido</h1>
						<p className="text-sm text-gray-400">Seleccioná los productos del pedido</p>
					</div>
					{totalItems > 0 && (
						<span className="flex items-center gap-1.5 rounded-full bg-orange-100 px-3 py-1 text-xs font-semibold text-orange-600 md:hidden">
							<ClipboardList size={12} />
							{totalItems} ítem{totalItems > 1 ? "s" : ""} · S/ {total.toFixed(2)}
						</span>
					)}
				</div>

				{/* Search */}
				<div className="relative mb-3">
					<Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
					<input
						type="text"
						placeholder="Buscar producto o categoría…"
						value={search}
						onChange={(e) => setSearch(e.target.value)}
						className="w-full rounded-lg border border-gray-200 bg-white py-2 pl-9 pr-3 text-sm text-gray-800 outline-none placeholder:text-gray-400 focus:border-orange-400 focus:ring-2 focus:ring-orange-100 transition-all"
					/>
				</div>

				{/* Category pills */}
				<div className="mb-4 flex gap-2 overflow-x-auto pb-1 [scrollbar-width:none]">
					{["Todos", ...allCategories].map((cat) => {
						const CatIcon = getCategoryIcon(cat);
						return (
							<button
								key={cat}
								type="button"
								onClick={() => setActiveCategory(cat)}
								className={cn(
									"shrink-0 flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium transition-all",
									activeCategory === cat
										? "bg-orange-500 text-white shadow-sm"
										: "bg-white text-gray-500 border border-gray-200 hover:border-orange-300 hover:text-orange-500",
								)}
							>
								<CatIcon size={12} />
								{cat}
							</button>
						);
					})}
				</div>

				{/* Products */}
				<div className="flex-1 overflow-y-auto pb-4 pr-1">
					{isLoading ? (
						<div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
							{Array.from({ length: 6 }).map((_, i) => (
								<div key={i} className="h-24 animate-pulse rounded-xl bg-gray-100" />
							))}
						</div>
					) : filtered.length === 0 ? (
						<div className="flex flex-col items-center justify-center py-16 text-center">
							<div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100">
								<Search size={20} className="text-gray-400" />
							</div>
							<p className="text-sm font-medium text-gray-500">Sin resultados</p>
							<p className="text-xs text-gray-400">Probá con otro término</p>
						</div>
					) : (
						<div className="space-y-5">
							{categories.map((cat) => {
								const catProducts = filtered.filter((p) => p.category === cat);
								if (catProducts.length === 0) return null;
								return (
									<div key={cat}>
										<p className="mb-2 text-[11px] font-semibold uppercase tracking-widest text-gray-400">
											{cat}
										</p>
										<div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
											{catProducts.map((p) => {
												const inOrder = order.find((c) => c.product.id === p.id);
												return (
													<button
														key={p.id}
														type="button"
														onClick={() => addToOrder(p)}
														className={cn(
															"group relative flex flex-col items-start rounded-xl border p-3 text-left transition-all duration-150",
															inOrder
																? "border-orange-400 bg-orange-50 shadow-sm"
																: "border-gray-200 bg-white hover:border-orange-300 hover:shadow-sm",
														)}
													>
														{inOrder && (
															<span className="absolute right-2 top-2 flex h-5 w-5 items-center justify-center rounded-full bg-orange-500 text-[10px] font-bold text-white">
																{inOrder.quantity}
															</span>
														)}
														<p className="pr-5 text-sm font-semibold leading-tight text-gray-800">
															{p.name}
														</p>
														{p.description && (
															<p className="mt-0.5 line-clamp-1 text-[11px] text-gray-400">
																{p.description}
															</p>
														)}
														<p className="mt-2 text-sm font-bold text-orange-500">
															S/ {Number(p.price).toFixed(2)}
														</p>
													</button>
												);
											})}
										</div>
									</div>
								);
							})}
						</div>
					)}
				</div>
			</div>

			{/* ── Order panel ── */}
			<div className="w-full shrink-0 md:w-72">
				<div className="sticky top-0 flex flex-col rounded-xl border border-gray-200 bg-white shadow-sm">
					{/* Panel header */}
					<div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
						<div className="flex items-center gap-2">
							<div className="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-50">
								<ShoppingBag size={16} className="text-orange-600" />
							</div>
							<span className="text-sm font-semibold text-gray-800">Pedido Actual</span>
						</div>
						<span className="rounded-full bg-orange-50 px-2 py-0.5 text-[10px] font-semibold text-orange-600">
							{totalItems} {totalItems === 1 ? "item" : "items"}
						</span>
					</div>

					{/* Items */}
					<div className="max-h-[340px] overflow-y-auto px-4 py-3">
						{order.length === 0 ? (
							<div className="flex flex-col items-center justify-center py-8 text-center">
								<div className="mb-2 flex h-10 w-10 items-center justify-center rounded-full bg-gray-50">
									<ShoppingBag size={18} className="text-gray-300" />
								</div>
								<p className="text-xs text-gray-400">Sin productos</p>
							</div>
						) : (
							<ul className="space-y-2">
								{order.map((item) => (
									<li key={item.product.id} className="flex items-start gap-2 rounded-lg border border-gray-100 p-2">
										<div className="min-w-0 flex-1">
											<p className="truncate text-xs font-medium text-gray-800">
												{item.product.name}
											</p>
											<p className="text-[11px] text-gray-400">
												S/ {Number(item.product.price).toFixed(2)}
											</p>
										</div>
										<div className="flex shrink-0 items-center gap-1">
											<button
												type="button"
												onClick={() => updateQty(item.product.id, item.quantity - 1)}
												className="flex h-6 w-6 items-center justify-center rounded-md border border-gray-200 text-gray-400 transition-colors hover:border-red-200 hover:bg-red-50 hover:text-red-500"
											>
												{item.quantity === 1 ? <Trash2 size={10} /> : <Minus size={10} />}
											</button>
											<span className="w-5 text-center text-xs font-semibold text-gray-700">
												{item.quantity}
											</span>
											<button
												type="button"
												onClick={() => updateQty(item.product.id, item.quantity + 1)}
												className="flex h-6 w-6 items-center justify-center rounded-md border border-gray-200 text-gray-400 transition-colors hover:border-orange-300 hover:bg-orange-50 hover:text-orange-500"
											>
												<Plus size={10} />
											</button>
										</div>
										<span className="w-14 shrink-0 text-right text-xs font-semibold tabular-nums text-gray-700">
											S/ {(item.product.price * item.quantity).toFixed(2)}
										</span>
									</li>
								))}
							</ul>
						)}
					</div>

					{/* Footer: total + notes + button */}
					<div className="border-t border-gray-100 px-4 pb-4 pt-3">
						<div className="mb-3 flex items-center justify-between">
							<span className="text-xs text-gray-500">Total</span>
							<span className="text-base font-bold text-gray-900">S/ {total.toFixed(2)}</span>
						</div>
						<textarea
							placeholder="Notas del pedido..."
							value={notes}
							onChange={(e) => setNotes(e.target.value)}
							rows={2}
							className="mb-3 w-full resize-none rounded-lg border border-gray-200 px-3 py-2 text-xs text-gray-700 outline-none placeholder:text-gray-400 focus:border-orange-400 focus:ring-2 focus:ring-orange-100 transition-all"
						/>
						<Button
							className="w-full bg-orange-500 text-white hover:bg-orange-600 active:scale-[0.98] disabled:bg-slate-200 disabled:text-slate-400"
							onClick={handleSubmit}
							disabled={order.length === 0 || createMutation.isPending}
						>
							{createMutation.isPending ? "Registrando…" : "Confirmar pedido"}
						</Button>
						{createMutation.isError && (
							<p className="mt-2 text-center text-xs text-red-500">Error al registrar</p>
						)}
					</div>
				</div>
			</div>
		</div>
		<VoiceFab formType="sale" />
		</>
	);
}
