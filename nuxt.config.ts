// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: [
    '@pinia/nuxt',
    'nitro-cloudflare-dev',
  ],

  css: [
    'tdesign-vue-next/es/style/index.css',
    'tdesign-mobile-vue/es/navbar/style/index.css',
    'tdesign-mobile-vue/es/tab-bar/style/index.css',
    '~/assets/css/main.css',
  ],

  build: {
    transpile: ['tdesign-vue-next', 'tdesign-icons-vue-next', 'tdesign-mobile-vue']
  },

  vite: {
    optimizeDeps: {
      include: ['tdesign-icons-vue-next', 'tdesign-mobile-vue']
    }
  },

  runtimeConfig: {
    public: {
      appName: 'Asset Master',
    },
  },

  app: {
    head: {
      title: 'Asset Master — Portfolio Wealth Manager',
      meta: [
        { name: 'description', content: 'Premium wealth and asset portfolio management system with live market data' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { charset: 'utf-8' },
      ],
      link: [
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap' },
      ],
    },
  },
})
