import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { Minus, Plus, ShoppingCart, Trash2 } from "lucide-react";
import { useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";
import { cn } from "@/lib/utils";
import type { Product } from "@/types/api";

export const Route = createFileRoute("/_auth/sales/new")({
	beforeLoad: () => requireRole("OWNER", "CASHIER", "WAITER"),
	component: NewSalePage,
});

interface CartItem {
	product: Product;
	quantity: number;
}

function NewSalePage() {
	const qc = useQueryClient();
	const navigate = useNavigate();
	const [cart, setCart] = useState<CartItem[]>([]);
	const [search, setSearch] = useState("");
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

	const activeProducts = products.filter(
		(p) =>
			p.isActive &&
			(search === "" ||
				p.name.toLowerCase().includes(search.toLowerCase()) ||
				p.category.toLowerCase().includes(search.toLowerCase())),
	);

	const addToCart = (product: Product) => {
		setCart((prev) => {
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
			setCart((prev) => prev.filter((item) => item.product.id !== productId));
		} else {
			setCart((prev) =>
				prev.map((item) => (item.product.id === productId ? { ...item, quantity: qty } : item)),
			);
		}
	};

	const total = cart.reduce((acc, item) => acc + item.product.price * item.quantity, 0);

	const handleSubmit = () => {
		if (cart.length === 0) return;
		createMutation.mutate({
			items: cart.map((item) => ({
				product_id: item.product.id,
				quantity: item.quantity,
				unit_price: item.product.price,
			})),
			notes: notes || undefined,
		});
	};

	// Group by category
	const categories = [...new Set(activeProducts.map((p) => p.category))];

	return (
		<div className="flex gap-6 h-full">
			{/* Product catalog */}
			<div className="flex-1 min-w-0">
				<PageHeader title="Nueva venta" description="Selecciona los productos del pedido" />

				<div className="mb-4">
					<Input
						placeholder="Buscar producto o categoría…"
						value={search}
						onChange={(e) => setSearch(e.target.value)}
						className="max-w-sm"
					/>
				</div>

				{isLoading ? (
					<div className="py-12 text-center text-sm text-muted-foreground">Cargando…</div>
				) : activeProducts.length === 0 ? (
					<div className="py-12 text-center text-sm text-muted-foreground">
						{search ? "Sin resultados" : "Sin productos disponibles"}
					</div>
				) : (
					<div className="space-y-6">
						{categories.map((cat) => (
							<div key={cat}>
								<p className="mb-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">
									{cat}
								</p>
								<div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
									{activeProducts
										.filter((p) => p.category === cat)
										.map((p) => {
											const inCart = cart.find((c) => c.product.id === p.id);
											return (
												<button
													key={p.id}
													type="button"
													onClick={() => addToCart(p)}
													className={cn(
														"flex flex-col items-start rounded-xl border p-3 text-left transition-colors hover:bg-[oklch(0.97_0_0)]",
														inCart
															? "border-[oklch(0.6_0_0)] bg-[oklch(0.975_0_0)]"
															: "border-border bg-white",
													)}
												>
													<p className="text-sm font-medium text-foreground leading-tight">
														{p.name}
													</p>
													{p.description && (
														<p className="mt-0.5 text-xs text-muted-foreground line-clamp-1">
															{p.description}
														</p>
													)}
													<p className="mt-2 text-sm font-semibold text-foreground">
														S/ {Number(p.price).toFixed(2)}
													</p>
													{inCart && (
														<span className="mt-1 text-xs text-muted-foreground">
															× {inCart.quantity} en carrito
														</span>
													)}
												</button>
											);
										})}
								</div>
							</div>
						))}
					</div>
				)}
			</div>

			{/* Cart panel */}
			<div className="w-72 shrink-0">
				<div className="sticky top-0 rounded-xl border border-border bg-white p-4">
					<div className="mb-3 flex items-center gap-2">
						<ShoppingCart size={16} className="text-muted-foreground" />
						<span className="text-sm font-medium text-foreground">Carrito</span>
						{cart.length > 0 && (
							<span className="ml-auto text-xs text-muted-foreground">
								{cart.length} producto{cart.length > 1 ? "s" : ""}
							</span>
						)}
					</div>

					{cart.length === 0 ? (
						<p className="py-6 text-center text-xs text-muted-foreground">Sin productos</p>
					) : (
						<div className="space-y-2">
							{cart.map((item) => (
								<div key={item.product.id} className="flex items-center gap-2 text-sm">
									<div className="flex-1 min-w-0">
										<p className="truncate text-xs font-medium text-foreground">
											{item.product.name}
										</p>
										<p className="text-xs text-muted-foreground">
											S/ {Number(item.product.price).toFixed(2)}
										</p>
									</div>
									<div className="flex items-center gap-1">
										<button
											type="button"
											onClick={() => updateQty(item.product.id, item.quantity - 1)}
											className="rounded p-0.5 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
										>
											{item.quantity === 1 ? <Trash2 size={12} /> : <Minus size={12} />}
										</button>
										<span className="w-6 text-center text-xs text-foreground">{item.quantity}</span>
										<button
											type="button"
											onClick={() => updateQty(item.product.id, item.quantity + 1)}
											className="rounded p-0.5 text-muted-foreground hover:bg-[oklch(0.94_0_0)] hover:text-foreground"
										>
											<Plus size={12} />
										</button>
									</div>
								</div>
							))}
						</div>
					)}

					{cart.length > 0 && (
						<>
							<div className="mt-3 border-t border-border pt-3">
								<div className="mb-2 flex items-center justify-between text-sm">
									<span className="text-muted-foreground">Total</span>
									<span className="font-semibold text-foreground">S/ {total.toFixed(2)}</span>
								</div>
								<div className="mb-3">
									<Input
										placeholder="Notas del pedido…"
										value={notes}
										onChange={(e) => setNotes(e.target.value)}
										className="h-8 text-xs"
									/>
								</div>
							</div>
							<Button
								className="w-full"
								size="sm"
								onClick={handleSubmit}
								disabled={createMutation.isPending}
							>
								{createMutation.isPending ? "Registrando…" : "Registrar pedido"}
							</Button>
							{createMutation.isError && (
								<p className="mt-2 text-center text-xs text-destructive">Error al registrar</p>
							)}
						</>
					)}
				</div>
			</div>
		</div>
	);
}
