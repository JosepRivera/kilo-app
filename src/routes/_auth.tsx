import { createFileRoute, Outlet } from "@tanstack/react-router";
import { Sidebar } from "@/components/layout/Sidebar";
import { requireAuth } from "@/lib/guards";

export const Route = createFileRoute("/_auth")({
	beforeLoad: requireAuth,
	component: AuthLayout,
});

function AuthLayout() {
	return (
		<div className="flex h-screen overflow-hidden bg-[oklch(0.975_0_0)]">
			<Sidebar />
			<main className="flex-1 overflow-y-auto">
				<div className="min-h-full p-6">
					<Outlet />
				</div>
			</main>
		</div>
	);
}
