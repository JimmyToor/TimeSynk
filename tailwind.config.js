const colors = require('tailwindcss/colors')
module.exports = {
  mode: 'jit',
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './node_modules/flowbite/**/*.js',
  ],
  theme: {
    extend: {
      animation:  {
        'slide-down': 'slide-down 0.5s ease forwards',
        'slide-up': 'slide-up 0.5s ease forwards',
      },
      keyframes: {
        'slide-down': {
          'from': { transform: 'translateY(0px)'},
          'to': { transform: 'translateY(50px)'},
        },
        'slide-up': {
          'from': { transform: 'translateY(50px)'},
          'to': { transform: 'translateY(0px)'},
        }
      },
      colors: {
        primary: {
          50: "#eff6ff",
          100: "#dbeafe",
          200: "#bfdbfe",
          300: "#93c5fd",
          400: "#60a5fa",
          500: "#3b82f6",
          600: "#2563eb",
          700: "#1d4ed8",
          800: "#1e40af",
          900: "#1e3a8a",
          950: "#172554",
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
        "xxl": '1650px'
      }
    },
  },
  plugins: [
      require('flowbite/plugin'),
      require('@tailwindcss/typography'),
  ],
  darkMode: "media",

}
