import axios from "axios";
import { useAuthStore } from "@/stores/auth.store";

export const api = axios.create({
	baseURL: import.meta.env.VITE_API_URL ?? "http://localhost:3000",
	headers: {
		"Content-Type": "application/json",
	},
});

// Adjunta el access token en cada request
api.interceptors.request.use((config) => {
	const token = useAuthStore.getState().accessToken;
	if (token) {
		config.headers.Authorization = `Bearer ${token}`;
	}
	return config;
});

// Auto-refresh: si recibe 401, intenta renovar el token y reintenta el request
let isRefreshing = false;
let refreshQueue: Array<(token: string) => void> = [];

api.interceptors.response.use(
	(response) => response,
	async (error) => {
		const original = error.config;

		if (error.response?.status !== 401 || original._retry) {
			return Promise.reject(error);
		}

		original._retry = true;
		const { refreshToken, setAccessToken, clearAuth } = useAuthStore.getState();

		if (!refreshToken) {
			clearAuth();
			return Promise.reject(error);
		}

		if (isRefreshing) {
			return new Promise((resolve) => {
				refreshQueue.push((token) => {
					original.headers.Authorization = `Bearer ${token}`;
					resolve(api(original));
				});
			});
		}

		isRefreshing = true;

		try {
			const { data } = await axios.post(
				`${import.meta.env.VITE_API_URL ?? "http://localhost:3000"}/auth/refresh`,
				{ refresh_token: refreshToken },
			);

			const newToken: string = data.access_token;
			setAccessToken(newToken);

			for (const cb of refreshQueue) cb(newToken);
			refreshQueue = [];

			original.headers.Authorization = `Bearer ${newToken}`;
			return api(original);
		} catch {
			clearAuth();
			return Promise.reject(error);
		} finally {
			isRefreshing = false;
		}
	},
);
