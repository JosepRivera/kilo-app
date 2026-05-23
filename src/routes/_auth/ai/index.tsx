import { useMutation } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Send } from "lucide-react";
import { useRef, useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/ai/")({
	beforeLoad: () => requireRole("OWNER"),
	component: AIPage,
});

let historySeq = 0;

interface QueryResult {
	id: number;
	question: string;
	sql: string;
	result: Record<string, unknown>[];
}

function AIPage() {
	const [question, setQuestion] = useState("");
	const [history, setHistory] = useState<QueryResult[]>([]);
	const bottomRef = useRef<HTMLDivElement>(null);

	const queryMutation = useMutation({
		mutationFn: (q: string) =>
			api
				.post<{ sql: string; result: Record<string, unknown>[] }>("/ai/queries", { question: q })
				.then((r) => r.data),
		onSuccess: (data, q) => {
			setHistory((prev) => [
				...prev,
				{ id: ++historySeq, question: q, sql: data.sql, result: data.result ?? [] },
			]);
			setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: "smooth" }), 50);
		},
	});

	const handleSend = () => {
		const q = question.trim();
		if (!q || queryMutation.isPending) return;
		setQuestion("");
		queryMutation.mutate(q);
	};

	return (
		<div className="flex flex-col" style={{ height: "calc(100vh - 96px)" }}>
			<PageHeader
				title="Asistente IA"
				description="Consulta datos del negocio en lenguaje natural"
			/>

			{/* Results area */}
			<div className="flex-1 overflow-y-auto space-y-4 pb-4">
				{history.length === 0 && !queryMutation.isPending && (
					<div className="py-10 text-center">
						<p className="text-sm font-medium text-foreground">Consulta tus datos en español</p>
						<p className="mt-1 text-xs text-muted-foreground">
							Ejemplos: "¿Cuántas ventas hay este mes?" · "Productos con más ventas" · "Total de
							gastos"
						</p>
					</div>
				)}

				{history.map((entry) => (
					<QueryCard key={entry.id} entry={entry} />
				))}

				{queryMutation.isPending && (
					<div className="flex justify-start">
						<div className="rounded-2xl border border-border bg-white px-4 py-3">
							<div className="flex gap-1">
								<span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:0ms]" />
								<span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:150ms]" />
								<span className="h-1.5 w-1.5 animate-bounce rounded-full bg-muted-foreground [animation-delay:300ms]" />
							</div>
						</div>
					</div>
				)}

				{queryMutation.isError && (
					<div className="rounded-lg border border-[oklch(0.85_0.04_30)] bg-[oklch(0.97_0.02_30)] px-4 py-3 text-sm text-[oklch(0.45_0.08_30)]">
						No se pudo procesar la consulta. Intenta reformularla o verifica que sea válida.
					</div>
				)}

				<div ref={bottomRef} />
			</div>

			{/* Input */}
			<div className="flex gap-2 border-t border-border pt-4">
				<input
					type="text"
					value={question}
					onChange={(e) => setQuestion(e.target.value)}
					onKeyDown={(e) => {
						if (e.key === "Enter" && !e.shiftKey) {
							e.preventDefault();
							handleSend();
						}
					}}
					placeholder="¿Cuántas ventas hubo esta semana?"
					className="flex-1 rounded-lg border border-input bg-white px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
					disabled={queryMutation.isPending}
				/>
				<Button
					onClick={handleSend}
					disabled={!question.trim() || queryMutation.isPending}
					size="sm"
					className="h-10 px-4"
				>
					<Send size={14} />
				</Button>
			</div>
		</div>
	);
}

function QueryCard({ entry }: { entry: QueryResult }) {
	const [showSql, setShowSql] = useState(false);
	const cols = entry.result.length > 0 ? Object.keys(entry.result[0]) : [];

	return (
		<div className="space-y-2">
			{/* Question */}
			<div className="flex justify-end">
				<div className="max-w-lg rounded-2xl bg-[oklch(0.18_0_0)] px-4 py-2.5 text-sm text-[oklch(0.95_0_0)]">
					{entry.question}
				</div>
			</div>

			{/* Result */}
			<div className="rounded-2xl border border-border bg-white px-4 py-3">
				{entry.result.length === 0 ? (
					<p className="text-sm text-muted-foreground">Sin resultados</p>
				) : (
					<div className="overflow-x-auto">
						<table className="w-full text-xs">
							<thead>
								<tr className="border-b border-border">
									{cols.map((col) => (
										<th
											key={col}
											className="pb-2 text-left font-medium text-muted-foreground pr-4 whitespace-nowrap"
										>
											{col}
										</th>
									))}
								</tr>
							</thead>
							<tbody className="divide-y divide-border">
								{entry.result.slice(0, 20).map((row, i) => (
									// biome-ignore lint/suspicious/noArrayIndexKey: stable result rows
									<tr key={i}>
										{cols.map((col) => (
											<td key={col} className="py-1.5 pr-4 text-foreground whitespace-nowrap">
												{String(row[col] ?? "—")}
											</td>
										))}
									</tr>
								))}
							</tbody>
						</table>
						{entry.result.length > 20 && (
							<p className="mt-2 text-xs text-muted-foreground">
								Mostrando 20 de {entry.result.length} filas
							</p>
						)}
					</div>
				)}

				<button
					type="button"
					onClick={() => setShowSql((v) => !v)}
					className="mt-2 text-xs text-muted-foreground hover:text-foreground"
				>
					{showSql ? "Ocultar SQL" : "Ver SQL generado"}
				</button>

				{showSql && (
					<pre className="mt-2 rounded-md bg-[oklch(0.96_0_0)] p-2 text-xs text-foreground overflow-x-auto">
						{entry.sql}
					</pre>
				)}
			</div>
		</div>
	);
}
