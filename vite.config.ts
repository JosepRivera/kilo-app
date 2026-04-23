import path from "path";
import { tanstackRouter } from "@tanstack/router-plugin/vite";
import react, { reactCompilerPreset } from "@vitejs/plugin-react";
import babel from "@rolldown/plugin-babel";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
	plugins: [
		// tanstackRouter MUST come before react()
		tanstackRouter({
			target: "react",
			autoCodeSplitting: true,
		}),
		react(),
		babel({ presets: [reactCompilerPreset()] }),
		tailwindcss(),
	],
	resolve: {
		alias: {
			"@": path.resolve(__dirname, "./src"),
		},
	},
});
