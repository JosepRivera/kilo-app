import { createFileRoute, Outlet } from "@tanstack/react-router";
import { Menu } from "lucide-react";
import { useState } from "react";
import { Sidebar } from "@/components/layout/Sidebar";
import { requireAuth } from "@/lib/guards";

export const Route = createFileRoute("/_auth")({
	beforeLoad: requireAuth,
	component: AuthLayout,
});

function AuthLayout() {
	const [sidebarOpen, setSidebarOpen] = useState(false);

	return (
		<div className="flex h-screen overflow-hidden bg-gradient-to-br from-[#EAECF5] via-[#E6E9F4] to-[#DCE0EE]">
			<Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />

			<main className="flex-1 overflow-y-auto">
				{/* mobile top bar */}
				<div className="sticky top-0 z-30 flex items-center gap-3 border-b border-gray-200 bg-white px-4 py-3 lg:hidden">
					<button
						type="button"
						onClick={() => setSidebarOpen(true)}
						className="rounded-md p-1.5 text-gray-500 hover:bg-gray-100"
					>
						<Menu size={20} />
					</button>
					<span
						className="text-lg tracking-[2px] text-gray-900 leading-none"
						style={{ fontFamily: "'Bebas Neue', sans-serif" }}
					>
						SMARTBITE
					</span>
				</div>

				<div className="min-h-full p-4 lg:p-6">
					<Outlet />
				</div>
			</main>
		</div>
	);
}
