export type Role = "OWNER" | "CASHIER" | "WAITER" | "COOK";

export interface User {
	id: string;
	name: string;
	username: string;
	role: Role;
	isActive: boolean;
	createdAt: string;
	updatedAt: string;
}

export interface AuthTokens {
	access_token: string;
	refresh_token: string;
}

export interface LoginResponse {
	access_token: string;
	refresh_token: string;
	user: User;
}

export const ROLE_LABELS: Record<Role, string> = {
	OWNER: "Dueño",
	CASHIER: "Cajero",
	WAITER: "Mozo",
	COOK: "Cocinero",
};

export const ROLE_HOME: Record<Role, string> = {
	OWNER: "/dashboard",
	CASHIER: "/sales/checkout",
	WAITER: "/sales/new",
	COOK: "/production-plan",
};

// Products
export interface Product {
	id: string;
	name: string;
	description?: string;
	price: number;
	category: string;
	isActive: boolean;
	createdAt: string;
	updatedAt: string;
}

// Ingredients
export interface Ingredient {
	id: string;
	name: string;
	unit: string;
	stock: number;
	minStock: number;
	costPerUnit: number;
	is_low_stock: boolean;
	createdAt: string;
	updatedAt: string;
}

// Recipes — per product: GET /recipes/:productId, PUT /recipes/:productId
export interface RecipeItem {
	id: string;
	ingredient_id: string;
	ingredient_name: string;
	unit: string;
	quantity: number;
}

export interface Recipe {
	product_id: string;
	items: RecipeItem[];
}

// Sales
export type SaleStatus = "PENDING" | "COMPLETED" | "CANCELLED";

export interface SaleItem {
	id: string;
	product_id: string;
	product: Product;
	quantity: number;
	unit_price: number;
	subtotal: number;
}

export interface Sale {
	id: string;
	items: SaleItem[];
	total: number;
	status: SaleStatus;
	notes?: string;
	created_by: string;
	created_at: string;
	updated_at: string;
}

// Expenses
export interface Expense {
	id: string;
	description: string;
	amount: number;
	category: string;
	created_at: string;
	user_id: string;
}

export const SALE_STATUS_LABELS: Record<SaleStatus, string> = {
	PENDING: "Pendiente",
	COMPLETED: "Completada",
	CANCELLED: "Cancelada",
};

export const EXPENSE_CATEGORIES = [
	"Insumos",
	"Servicios",
	"Personal",
	"Mantenimiento",
	"Marketing",
	"Otros",
] as const;

export type ExpenseCategory = (typeof EXPENSE_CATEGORIES)[number];
