import {
	Beef,
	Beer,
	Coffee,
	Cookie,
	Croissant,
	Fish,
	Flame,
	IceCreamCone,
	LayoutGrid,
	Package,
	Pizza,
	Salad,
	Sandwich,
	Soup,
	Tag,
	UtensilsCrossed,
	Wine,
	type LucideIcon,
} from "lucide-react";

// Keys MUST be NFD-normalized lowercase on lookup.
export const CATEGORY_ICONS: Record<string, LucideIcon> = {
	todos: LayoutGrid,
	acompañamientos: UtensilsCrossed,
	bebidas: Coffee,
	"bebidas calientes": Coffee,
	cafe: Coffee,
	cafes: Coffee,
	combos: Package,
	comida: UtensilsCrossed,
	comidas: UtensilsCrossed,
	platos: UtensilsCrossed,
	hamburguesas: Beef,
	pizza: Pizza,
	pizzas: Pizza,
	pollo: Flame,
	sandwich: Sandwich,
	sandwiches: Sandwich,
	shawarma: Flame,
	postres: IceCreamCone,
	helados: IceCreamCone,
	tortas: IceCreamCone,
	pasteleria: Croissant,
	panaderia: Croissant,
	galletas: Cookie,
	snacks: Cookie,
	ensaladas: Salad,
	carnes: Beef,
	pescados: Fish,
	sopas: Soup,
	vinos: Wine,
	cervezas: Beer,
};

function normalize(s: string): string {
	return s
		.toLowerCase()
		.normalize("NFD")
		.replace(/[̀-ͯ]/g, "")
		.trim();
}

export function getCategoryIcon(category: string): LucideIcon {
	return CATEGORY_ICONS[normalize(category)] ?? Tag;
}
