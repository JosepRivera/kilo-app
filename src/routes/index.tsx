import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/")({
	component: HomePage,
});

function HomePage() {
	return (
		<div className="flex min-h-screen items-center justify-center">
			<div className="text-center">
				<h1 className="text-4xl font-bold text-foreground">SmartBite</h1>
				<p className="mt-2 text-muted-foreground">Sistema de gestión para restaurantes</p>
			</div>
		</div>
	);
}
