/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './app/views/**/*.{html,html.erb,erb}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{rb,html,html.erb,erb}',
    './config/initializers/simple_form.rb'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'Consolas', 'Monaco', 'monospace']
      },
      colors: {
        'brand-green': '#57D9A3'
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      "nord", "lofi", "dark", "light", "cupcake", "bumblebee", "emerald",
      "corporate", "synthwave", "retro", "cyberpunk", "valentine", "halloween",
      "garden", "forest", "aqua", "pastel", "fantasy", "wireframe", "black",
      "luxury", "dracula", "cmyk", "autumn", "business", "acid", "lemonade",
      "night", "coffee", "winter", "dim", "sunset"
    ],
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: false,
    themeRoot: ":root"
  }
}
