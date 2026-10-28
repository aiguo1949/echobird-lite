import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import pkg from './package.json';

export default defineConfig({
  base: './',
  plugins: [react()],
  define: {
    __APP_VERSION__: JSON.stringify(pkg.version),
    __APP_EDITION__: JSON.stringify(process.env.EDITION || 'full'),
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // index.html is the only app entry. Without this, vite's dependency
  // pre-bundling scan crawls every .html in the repo — including the vendored
  // `references/**` folders (gitignored but present on disk) — and fails on
  // their broken imports whenever it re-optimizes (e.g. after a lockfile
  // change). Limiting the scan to the real entry keeps `vite dev` green.
  optimizeDeps: {
    entries: ['index.html'],
  },
  server: {
    port: 5173,
    open: false,
    watch: {
      ignored: ['**/src-tauri/target/**', '**/dist/**', '**/build/**'],
    },
  },
  // Tauri expects a fixed port and no browser auto-open
  clearScreen: false,
  // ── lite build tuning ─────────────────────────────────────────────────────
  // WebView2 (Windows 10+) / WKWebView (macOS 12+) both understand modern JS,
  // so transpiling down to ES2020 syntax is wasted bytes. Targeting the
  // WebView baseline removes the downlevelling helpers and shrinks the entry
  // chunk. Vendor code is split out so the React runtime is parsed once and
  // the markdown/lucide chunks only load when a page actually needs them.
  build: {
    target: 'chrome105',
    cssTarget: 'chrome105',
    reportCompressedSize: false,
    chunkSizeWarningLimit: 1024,
    rollupOptions: {
      output: {
        manualChunks(id: string) {
          if (!id.includes('node_modules')) return undefined;
          if (/react-markdown|remark-|rehype-|unified|mdast|hast|micromark/.test(id))
            return 'vendor-markdown';
          if (id.includes('lucide-react')) return 'vendor-icons';
          if (id.includes('@tauri-apps')) return 'vendor-tauri';
          if (/node_modules\/(react|react-dom|scheduler)\//.test(id)) return 'vendor-react';
          return 'vendor';
        },
      },
    },
  },
});
