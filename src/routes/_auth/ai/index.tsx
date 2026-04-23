import { useMutation } from "@tanstack/react-query";
import { createFileRoute } from "@tanstack/react-router";
import { Send } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { PageHeader } from "@/components/shared/PageHeader";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { requireRole } from "@/lib/guards";

export const Route = createFileRoute("/_auth/ai/")({
	beforeLoad: () => requireRole("OWNER"),
	component: AIPage,
});

interface Message {
	id: number;
	role: "user" | "assistant";
	content: string;
}

let msgId = 0;
const nextId = () => ++msgId;

function AIPage() {
	const [messages, setMessages] = useState<Message[]>([
		{
			id: nextId(),
			role: "assistant",
			content:
				"Hola, soy tu asistente de SmartBite. Puedo ayudarte a analizar ventas, sugerir estrategias y responder preguntas sobre tu negocio. ¿En qué te puedo ayudar?",
		},
	]);
	const [input, setInput] = useState("");
	const bottomRef = useRef<HTMLDivElement>(null);

	const chatMutation = useMutation({
		mutationFn: (prompt: string) =>
			api.post("/ai/chat", { prompt, history: messages }).then((r) => r.data),
		onSuccess: (data: { response: string }) => {
			setMessages((prev) => [...prev, { id: nextId(), role: "assistant", content: data.response }]);
		},
		onError: () => {
			setMessages((prev) => [
				...prev,
				{
					id: nextId(),
					role: "assistant",
					content: "Lo siento, ocurrió un error. Intenta de nuevo.",
				},
			]);
		},
	});

	const handleSend = () => {
		const text = input.trim();
		if (!text || chatMutation.isPending) return;
		setInput("");
		setMessages((prev) => [...prev, { id: nextId(), role: "user", content: text }]);
		chatMutation.mutate(text);
	};

	const msgCount = messages.length;
	// biome-ignore lint/correctness/useExhaustiveDependencies: scroll on message count change only
	useEffect(() => {
		bottomRef.current?.scrollIntoView({ behavior: "smooth" });
	}, [msgCount]);

	return (
		<div className="flex flex-col" style={{ height: "calc(100vh - 96px)" }}>
			<PageHeader title="Asistente IA" description="Consulta inteligente sobre tu negocio" />

			{/* Messages */}
			<div className="flex-1 overflow-y-auto space-y-4 pb-4">
				{messages.map((msg) => (
					<div
						key={msg.id}
						className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
					>
						<div
							className={`max-w-lg rounded-2xl px-4 py-3 text-sm leading-relaxed ${
								msg.role === "user"
									? "bg-[oklch(0.18_0_0)] text-[oklch(0.95_0_0)]"
									: "bg-white border border-border text-foreground"
							}`}
						>
							{msg.content}
						</div>
					</div>
				))}

				{chatMutation.isPending && (
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

				<div ref={bottomRef} />
			</div>

			{/* Input */}
			<div className="flex gap-2 border-t border-border pt-4">
				<input
					type="text"
					value={input}
					onChange={(e) => setInput(e.target.value)}
					onKeyDown={(e) => {
						if (e.key === "Enter" && !e.shiftKey) {
							e.preventDefault();
							handleSend();
						}
					}}
					placeholder="Escribe tu consulta…"
					className="flex-1 rounded-lg border border-input bg-white px-4 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
					disabled={chatMutation.isPending}
				/>
				<Button
					onClick={handleSend}
					disabled={!input.trim() || chatMutation.isPending}
					size="sm"
					className="h-10 px-4"
				>
					<Send size={14} />
				</Button>
			</div>
		</div>
	);
}
