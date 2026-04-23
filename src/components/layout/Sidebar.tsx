import { useQuery } from "@tanstack/react-query";
import { Link, useRouterState } from "@tanstack/react-router";
import {
	BarChart2,
	BookOpen,
	BotMessageSquare,
	ChefHat,
	ClipboardList,
	CreditCard,
	DollarSign,
	FileText,
	LogOut,
	Package,
	ShoppingCart,
	TrendingUp,
	Users,
	Utensils,
	Wallet,
} from "lucide-react";
import { api } from "@/lib/api";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth.store";
import type { Ingredient, Role } from "@/types/api";
import { ROLE_LABELS } from "@/types/api";

interface NavItem {
	label: string;
	to: string;
	icon: React.ReactNode;
	roles: Role[];
}

const NAV_ITEMS: NavItem[] = [
	// Dashboard
	{
		label: "Dashboard",
		to: "/dashboard",
		icon: <BarChart2 size={16} />,
		roles: ["OWNER"],
	},
	// Operaciones
	{
		label: "Nueva venta",
		to: "/sales/new",
		icon: <ShoppingCart size={16} />,
		roles: ["OWNER", "CASHIER", "WAITER"],
	},
	{
		label: "Cobrar",
		to: "/sales/checkout",
		icon: <CreditCard size={16} />,
		roles: ["OWNER", "CASHIER"],
	},
	{
		label: "Historial de ventas",
		to: "/sales/history",
		icon: <ClipboardList size={16} />,
		roles: ["OWNER", "CASHIER", "WAITER"],
	},
	{
		label: "Productos",
		to: "/products",
		icon: <Package size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Insumos",
		to: "/ingredients",
		icon: <Utensils size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Recetas",
		to: "/recipes",
		icon: <BookOpen size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Gastos",
		to: "/expenses",
		icon: <DollarSign size={16} />,
		roles: ["OWNER"],
	},
	// Reportes
	{
		label: "Reportes",
		to: "/reports/period",
		icon: <FileText size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Rentabilidad",
		to: "/reports/profitability",
		icon: <TrendingUp size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Cierre de caja",
		to: "/cash-closes",
		icon: <Wallet size={16} />,
		roles: ["OWNER"],
	},
	// IA
	{
		label: "Asistente IA",
		to: "/ai",
		icon: <BotMessageSquare size={16} />,
		roles: ["OWNER"],
	},
	{
		label: "Plan de producción",
		to: "/production-plan",
		icon: <ChefHat size={16} />,
		roles: ["OWNER", "CASHIER", "WAITER", "COOK"],
	},
	// Pagos y equipo
	{
		label: "Notif. de pagos",
		to: "/payments",
		icon: <CreditCard size={16} />,
		roles: ["OWNER", "CASHIER"],
	},
	{
		label: "Empleados",
		to: "/employees",
		icon: <Users size={16} />,
		roles: ["OWNER"],
	},
];

export function Sidebar() {
	const { user, clearAuth } = useAuthStore();
	const router = useRouterState();
	const currentPath = router.location.pathname;

	const { data: ingredients = [] } = useQuery<Ingredient[]>({
		queryKey: ["ingredients"],
		queryFn: () => api.get("/ingredients").then((r) => r.data),
		enabled: user?.role === "OWNER",
		refetchInterval: 60_000,
		staleTime: 30_000,
	});

	const lowStockCount = ingredients.filter((i) => i.stock <= i.min_stock).length;

	if (!user) return null;

	const visibleItems = NAV_ITEMS.filter((item) => item.roles.includes(user.role));

	return (
		<aside className="flex h-screen w-56 flex-shrink-0 flex-col border-r border-[oklch(0.25_0_0)] bg-[oklch(0.13_0_0)]">
			{/* Brand */}
			<div className="border-b border-[oklch(0.22_0_0)] px-5 py-4">
				<span className="text-sm font-semibold tracking-wide text-[oklch(0.95_0_0)]">
					SmartBite
				</span>
			</div>

			{/* Nav */}
			<nav className="flex-1 overflow-y-auto px-2 py-3">
				<ul className="space-y-0.5">
					{visibleItems.map((item) => {
						const isActive = currentPath === item.to || currentPath.startsWith(`${item.to}/`);
						return (
							<li key={item.to}>
								<Link
									to={item.to}
									className={cn(
										"flex items-center gap-2.5 rounded-md px-3 py-2 text-sm transition-colors",
										isActive
											? "bg-[oklch(0.22_0_0)] text-[oklch(0.95_0_0)]"
											: "text-[oklch(0.6_0_0)] hover:bg-[oklch(0.18_0_0)] hover:text-[oklch(0.85_0_0)]",
									)}
								>
									<span
										className={cn(isActive ? "text-[oklch(0.85_0_0)]" : "text-[oklch(0.5_0_0)]")}
									>
										{item.icon}
									</span>
									<span className="flex-1">{item.label}</span>
									{item.to === "/ingredients" && lowStockCount > 0 && (
										<span className="flex h-4 min-w-4 items-center justify-center rounded-full bg-[oklch(0.55_0.08_30)] px-1 text-[10px] font-medium text-white">
											{lowStockCount}
										</span>
									)}
								</Link>
							</li>
						);
					})}
				</ul>
			</nav>

			{/* Footer */}
			<div className="border-t border-[oklch(0.22_0_0)] px-4 py-3">
				<div className="mb-2">
					<p className="text-xs font-medium text-[oklch(0.75_0_0)]">{user.name}</p>
					<p className="text-xs text-[oklch(0.45_0_0)]">{ROLE_LABELS[user.role]}</p>
				</div>
				<button
					type="button"
					onClick={clearAuth}
					className="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-xs text-[oklch(0.45_0_0)] transition-colors hover:bg-[oklch(0.18_0_0)] hover:text-[oklch(0.65_0_0)]"
				>
					<LogOut size={13} />
					Cerrar sesión
				</button>
			</div>
		</aside>
	);
}
