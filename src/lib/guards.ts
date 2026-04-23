import { redirect } from "@tanstack/react-router";
import { useAuthStore } from "@/stores/auth.store";
import type { Role } from "@/types/api";

export function requireAuth() {
	const { accessToken, refreshToken } = useAuthStore.getState();
	if (!accessToken && !refreshToken) {
		throw redirect({ to: "/login" });
	}
}

export function requireRole(...roles: Role[]) {
	const { user, refreshToken, accessToken } = useAuthStore.getState();
	if (!accessToken && !refreshToken) {
		throw redirect({ to: "/login" });
	}
	if (user && !roles.includes(user.role)) {
		throw redirect({ to: "/unauthorized" });
	}
}

export function redirectIfAuth() {
	const { user } = useAuthStore.getState();
	if (user) {
		const home = getHomeForRole(user.role);
		throw redirect({ to: home });
	}
}

export function getHomeForRole(role: Role): string {
	const homes: Record<Role, string> = {
		OWNER: "/dashboard",
		CASHIER: "/sales/checkout",
		WAITER: "/sales/new",
		COOK: "/production-plan",
	};
	return homes[role];
}
