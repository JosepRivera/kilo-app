interface EmptyStateProps {
	title: string;
	description?: string;
	action?: React.ReactNode;
}

export function EmptyState({ title, description, action }: EmptyStateProps) {
	return (
		<div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-border bg-white py-16 text-center">
			<p className="text-sm font-medium text-foreground">{title}</p>
			{description && <p className="mt-1 text-xs text-muted-foreground">{description}</p>}
			{action && <div className="mt-4">{action}</div>}
		</div>
	);
}
