import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link, useNavigate, useRouterState } from "@tanstack/react-router";
import {
	BookOpen,
	BotMessageSquare,
	Building2,
	ChefHat,
	CreditCard,
	DollarSign,
	Home,
	LogOut,
	Package,
	ShoppingCart,
	Users,
	Utensils,
	X,
} from "lucide-react";
import logoSrc from "@/assets/logo-smartbite.png";
import { api } from "@/lib/api";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth.store";
import type { Ingredient, Role } from "@/types/api";
import { ROLE_LABELS } from "@/types/api";
import {
	Dialog,
	DialogContent,
	DialogDescription,
	DialogFooter,
	DialogHeader,
	DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

interface NavItem {
	label: string;
	to: string;
	icon: React.ReactNode;
	roles: Role[];
}

const ROLE_ICONS: Record<Role, React.ReactNode> = {
	OWNER: <Building2 size={16} />,
	CASHIER: <CreditCard size={16} />,
	WAITER: <Utensils size={16} />,
	COOK: <ChefHat size={16} />,
};

const OPERACION: NavItem[] = [
	{ label: "Inicio", to: "/dashboard", icon: <Home size={15} />, roles: ["OWNER"] },
	{
		label: "Tomar Pedido",
		to: "/sales/new",
		icon: <ShoppingCart size={15} />,
		roles: ["OWNER", "CASHIER", "WAITER"],
	},
	{
		label: "Cobrar",
		to: "/sales/checkout",
		icon: <CreditCard size={15} />,
		roles: ["OWNER", "CASHIER"],
	},
	{
		label: "Cocina",
		to: "/production-plan",
		icon: <ChefHat size={15} />,
		roles: ["OWNER", "CASHIER", "WAITER", "COOK"],
	},
	{
		label: "IA & Predicción",
		to: "/ai",
		icon: <BotMessageSquare size={15} />,
		roles: ["OWNER"],
	},
];

const GESTION: NavItem[] = [
	{ label: "Inventario", to: "/ingredients", icon: <Package size={15} />, roles: ["OWNER"] },
	{ label: "Recetas", to: "/recipes", icon: <BookOpen size={15} />, roles: ["OWNER"] },
	{ label: "Finanzas", to: "/expenses", icon: <DollarSign size={15} />, roles: ["OWNER"] },
	{ label: "Equipo", to: "/employees", icon: <Users size={15} />, roles: ["OWNER"] },
];

function NavSection({
	label,
	items,
	currentPath,
	badgeMap,
	userRole,
	onNavigate,
}: {
	label: string;
	items: NavItem[];
	currentPath: string;
	badgeMap: Record<string, boolean>;
	userRole: Role;
	onNavigate?: () => void;
}) {
	const visible = items.filter((i) => i.roles.includes(userRole));
	if (!visible.length) return null;
	return (
		<div className="mb-1">
			<p className="mb-1 px-3 text-[10px] font-semibold uppercase tracking-wider text-gray-400">
				{label}
			</p>
			<ul className="space-y-0.5">
				{visible.map((item) => {
					const isActive =
						currentPath === item.to || currentPath.startsWith(`${item.to}/`);
					const hasBadge = badgeMap[item.to];
					return (
						<li key={item.to}>
							<Link
								to={item.to}
								onClick={onNavigate}
								className={cn(
									"flex items-center gap-2.5 rounded-xl px-3 py-2 text-sm font-medium transition-all",
									isActive
										? "bg-gray-200 shadow-sm text-gray-800"
										: "text-gray-500 hover:text-gray-800",
								)}
							>
								<span className={cn("shrink-0", isActive ? "text-orange-500" : "text-gray-400")}>
									{item.icon}
								</span>
								<span className="flex-1">{item.label}</span>
								{hasBadge && (
									<span className="h-2 w-2 rounded-full bg-orange-500 shrink-0" />
								)}
							</Link>
						</li>
					);
				})}
			</ul>
		</div>
	);
}

function getInitials(name: string) {
	return name
		.split(" ")
		.slice(0, 2)
		.map((w) => w[0])
		.join("")
		.toUpperCase();
}

interface SidebarProps {
	open?: boolean;
	onClose?: () => void;
}

export function Sidebar({ open = true, onClose }: SidebarProps) {
	const { user, clearAuth } = useAuthStore();
	const navigate = useNavigate();
	const router = useRouterState();
	const currentPath = router.location.pathname;
	const [showLogoutDialog, setShowLogoutDialog] = useState(false);

	const { data: ingredients = [] } = useQuery<Ingredient[]>({
		queryKey: ["ingredients"],
		queryFn: () => api.get("/ingredients").then((r) => r.data),
		enabled: user?.role === "OWNER",
		refetchInterval: 60_000,
		staleTime: 30_000,
	});

	const lowStockCount = ingredients.filter((i) => i.stock <= i.minStock).length;
	const badgeMap: Record<string, boolean> = { "/ingredients": lowStockCount > 0 };

	if (!user) return null;

	function handleLogout() {
		clearAuth();
		navigate({ to: "/login" });
	}

	function handleNavigate() {
		onClose?.();
	}

	return (
		<>
			{/* mobile backdrop */}
			{open && onClose && (
				<div
					className="fixed inset-0 z-40 bg-black/40 lg:hidden"
					onClick={onClose}
				/>
			)}

			<aside
				className={cn(
					"flex h-screen w-64 shrink-0 flex-col transition-transform duration-200",
					// desktop: transparent + right border for separation
					"lg:relative lg:translate-x-0 lg:z-auto lg:bg-white",
					"lg:border-r lg:border-gray-200 lg:shadow-[1px_0_12px_rgba(0,0,0,0.06)]",
					// mobile: fixed overlay with solid bg
					"fixed inset-y-0 left-0 z-50 bg-[#EAECF5]",
					open ? "translate-x-0" : "-translate-x-full lg:translate-x-0",
				)}
			>
				{/* Brand */}
				<div className="relative flex items-center justify-center px-4 py-4">
					<div className="flex items-center gap-2.5">
						<img src={logoSrc} alt="SmartBite" className="h-9 w-auto" />
						<span
							className="text-xl tracking-[2px] text-gray-900 leading-none"
							style={{ fontFamily: "'Bebas Neue', sans-serif" }}
						>
							SMARTBITE
						</span>
					</div>
					{onClose && (
						<button
							type="button"
							onClick={onClose}
							className="absolute right-4 rounded-md p-1 text-gray-400 hover:bg-gray-100 lg:hidden"
						>
							<X size={16} />
						</button>
					)}
				</div>

				{/* Nav */}
				<nav className="flex-1 overflow-y-auto px-2 py-3">
					<NavSection
						label="Operación"
						items={OPERACION}
						currentPath={currentPath}
						badgeMap={badgeMap}
						userRole={user.role}
						onNavigate={handleNavigate}
					/>
					<div className="my-2" />
					<NavSection
						label="Gestión"
						items={GESTION}
						currentPath={currentPath}
						badgeMap={badgeMap}
						userRole={user.role}
						onNavigate={handleNavigate}
					/>
				</nav>

				{/* Footer */}
				<div className="border-t border-white/60 px-3 py-3">
					<div className="flex items-center gap-2.5 px-2 py-2">
						<div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-orange-100 text-orange-600">
							{ROLE_ICONS[user.role]}
						</div>
						<div className="min-w-0 flex-1">
							<p className="truncate text-xs font-semibold text-gray-800">{user.name}</p>
							<p className="text-[10px] text-gray-400">{ROLE_LABELS[user.role]}</p>
						</div>
						<button
							type="button"
							onClick={() => setShowLogoutDialog(true)}
							title="Cerrar sesión"
							className="shrink-0 rounded-md p-1.5 text-gray-400 transition-colors hover:bg-red-50 hover:text-red-500"
						>
							<LogOut size={14} />
						</button>
					</div>
				</div>
			</aside>

			<Dialog open={showLogoutDialog} onOpenChange={setShowLogoutDialog}>
				<DialogContent showCloseButton={false}>
					<DialogHeader>
						<DialogTitle>¿Cerrar sesión?</DialogTitle>
						<DialogDescription>
							Vas a salir de tu cuenta. Vas a necesitar ingresar tus credenciales de nuevo para volver.
						</DialogDescription>
					</DialogHeader>
					<DialogFooter>
						<Button variant="outline" onClick={() => setShowLogoutDialog(false)}>
							Cancelar
						</Button>
						<Button
							variant="destructive"
							onClick={() => {
								setShowLogoutDialog(false);
								handleLogout();
							}}
						>
							Cerrar sesión
						</Button>
					</DialogFooter>
				</DialogContent>
			</Dialog>
		</>
	);
}
