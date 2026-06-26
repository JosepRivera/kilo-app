import { Mic } from "lucide-react";
import { cn } from "@/lib/utils";

export type VoiceFormType = "sale" | "expense" | "ingredient_update";

export interface VoiceFabProps {
	formType: VoiceFormType;
	onClick?: () => void;
	disabled?: boolean;
	className?: string;
}

export function VoiceFab({ formType, onClick, disabled, className }: VoiceFabProps) {
	return (
		<button
			type="button"
			aria-label="Registro por voz"
			data-form-type={formType}
			disabled={disabled}
			onClick={onClick}
			className={cn(
				"fixed bottom-6 right-6 z-40 flex h-14 w-14 items-center justify-center rounded-full bg-gray-900 text-white shadow-xl transition-all duration-200 hover:scale-105 hover:bg-gray-800 disabled:bg-slate-300 disabled:shadow-none",
				className,
			)}
		>
			<span className="absolute inset-0 rounded-full bg-orange-400/25 animate-ping opacity-75" />
			<Mic size={22} className="relative text-orange-400" />
		</button>
	);
}
