import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { createRootRoute, Outlet } from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/react-router-devtools";

const queryClient = new QueryClient({
	defaultOptions: {
		queries: {
			staleTime: 1000 * 60, // 1 minuto
			retry: 1,
		},
	},
});

function RootLayout() {
	return (
		<QueryClientProvider client={queryClient}>
			<Outlet />
			{import.meta.env.DEV && (
				<>
					<ReactQueryDevtools initialIsOpen={false} />
					<TanStackRouterDevtools />
				</>
			)}
		</QueryClientProvider>
	);
}

export const Route = createRootRoute({
	component: RootLayout,
});
