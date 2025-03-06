const colors = require("tailwindcss/colors");
module.exports = {
  mode: "jit",
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/javascript/**/*.js",
    "./node_modules/flowbite/**/*.js",
  ],
  theme: {
    extend: {
      animation: {
        "slide-down": "slide-down 0.5s ease forwards",
        "slide-up": "slide-up 0.5s ease forwards",
      },
      keyframes: {
        "slide-down": {
          from: { transform: "translateY(0px)" },
          to: { transform: "translateY(50px)" },
        },
        "slide-up": {
          from: { transform: "translateY(50px)" },
          to: { transform: "translateY(0px)" },
        },
      },
      colors: {
        primary: {
          50: "#e0f7fb",
          100: "#b3eaf5",
          200: "#80dced",
          300: "#4dcee5",
          400: "#2dd0f0", // on dark
          500: "#0fb1d2",
          600: "#0a8fb0",
          700: "#076f8e",
          800: "#054f6c",
          900: "#03364f", // on light
          950: "#012233",
        },
        secondary: {
          50: "#eae8f7",
          100: "#c8c3ed",
          200: "#a39ce3", // on dark
          300: "#7e75d9",
          400: "#5f4eca",
          500: "#4535b1", // on light
          600: "#372a8e",
          700: "#291f6b",
          800: "#1b1448",
          900: "#0d0925",
          950: "#060412",
        },
        tertiary: {
          50: "#fafafa",
          100: "#f5f5f5",
          200: "#e5e5e5",
          300: "#d4d4d4",
          400: "#a3a3a3",
          500: "#8b8b8b",
          600: "#717171",
          700: "#575757",
          800: "#3f3f3f",
          900: "#282828",
          950: "#121212",
        },
        accent: {
          50: "#ebfde5",
          100: "#d0fab3",
          200: "#b3f680",
          300: "#93f24d",
          400: "#6ef02d", // base
          500: "#52d216",
          600: "#3faa11",
          700: "#2d830c",
          800: "#1c5c07",
          900: "#0b3503",
          950: "#051a01",
        },
        notice: {
          50: "#ffe5e7",
          100: "#ffb3b5",
          200: "#ff8083",
          300: "#ff4d51",
          400: "#ff262b",
          500: "#DF2935",
          600: "#b0222b",
          700: "#801921",
          800: "#501017",
          900: "#20080d",
          950: "#100406",
        },
      },
      fontFamily: {
        body: [
          "Inter",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "system-ui",
          "Segoe UI",
          "Roboto",
          "Helvetica Neue",
          "Arial",
          "Noto Sans",
          "sans-serif",
          "Apple Color Emoji",
          "Segoe UI Emoji",
          "Segoe UI Symbol",
          "Noto Color Emoji",
        ],
        sans: [
          "Inter",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "system-ui",
          "Segoe UI",
          "Roboto",
          "Helvetica Neue",
          "Arial",
          "Noto Sans",
          "sans-serif",
          "Apple Color Emoji",
          "Segoe UI Emoji",
          "Segoe UI Symbol",
          "Noto Color Emoji",
        ],
      },
      screens: {
        xs: "475px",
        xxl: "1650px",
      },
    },
  },
  plugins: [require("flowbite/plugin"), require("@tailwindcss/typography")],
  darkMode: "media",
};
