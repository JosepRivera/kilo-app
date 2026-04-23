import { createFileRoute, redirect } from "@tanstack/react-router";
import { getHomeForRole } from "@/lib/guards";
import { useAuthStore } from "@/stores/auth.store";

export const Route = createFileRoute("/")({
	beforeLoad: () => {
		const user = useAuthStore.getState().user;
		if (user) throw redirect({ to: getHomeForRole(user.role) });
		throw redirect({ to: "/login" });
	},
	component: () => null,
});
