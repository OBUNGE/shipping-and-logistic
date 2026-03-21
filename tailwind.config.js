/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/components/**/*.{erb,html}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        purple: {
          600: '#9333ea',
        },
      },
    },
  },
  plugins: [],
  // Prevent Tailwind from conflicting with Bootstrap
  important: true,
  corePlugins: {
    preflight: false, // Disable Tailwind's base styles to avoid conflicts with Bootstrap
  },
}
