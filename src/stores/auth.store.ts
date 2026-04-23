import { create } from "zustand";
import { persist } from "zustand/middleware";

interface User {
	id: string;
	name: string;
	username: string;
	role: "OWNER" | "CASHIER" | "WAITER" | "COOK";
}

interface AuthState {
	accessToken: string | null;
	refreshToken: string | null;
	user: User | null;
	setAuth: (tokens: { accessToken: string; refreshToken: string }, user: User) => void;
	clearAuth: () => void;
	setAccessToken: (token: string) => void;
}

export const useAuthStore = create<AuthState>()(
	persist(
		(set) => ({
			accessToken: null,
			refreshToken: null,
			user: null,
			setAuth: (tokens, user) =>
				set({ accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user }),
			clearAuth: () => set({ accessToken: null, refreshToken: null, user: null }),
			setAccessToken: (token) => set({ accessToken: token }),
		}),
		{
			name: "smartbite-auth",
			// Solo persiste el refresh token y el user — el access token se renueva al cargar
			partialize: (state) => ({
				refreshToken: state.refreshToken,
				user: state.user,
			}),
		},
	),
);
