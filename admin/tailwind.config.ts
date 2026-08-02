import type { Config } from "tailwindcss";

// Placeholder brand palette pending TogPlay's official brand guide.
// coral/orange = primary action color, navy = deep accent/dark surfaces.
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        coral: {
          50: "#fff3ed",
          100: "#ffe3d4",
          200: "#ffc4a8",
          300: "#ff9d71",
          400: "#ff7038",
          500: "#ff4d14",
          600: "#f0330a",
          700: "#c7240a",
          800: "#9e1f10",
          900: "#801d11",
        },
        navy: {
          50: "#eef1f7",
          100: "#d4dbea",
          200: "#a9b7d5",
          300: "#7d92bf",
          400: "#5a71a3",
          500: "#3d5285",
          600: "#2c3d67",
          700: "#212e4d",
          800: "#161f37",
          900: "#0d1322",
          950: "#080c17",
        },
      },
      fontFamily: {
        sans: [
          "Inter",
          "-apple-system",
          "BlinkMacSystemFont",
          "Segoe UI",
          "sans-serif",
        ],
      },
    },
  },
  plugins: [],
} satisfies Config;
