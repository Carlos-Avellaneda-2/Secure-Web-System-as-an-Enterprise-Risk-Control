# Enterprise Risk Lab — frontend

Vite + React + `@auth0/auth0-react`. Ver el [README principal](../README.md).

```bash
npm install
npm run dev     # http://localhost:5173, usa .env.local (no versionado)
npm run build   # dist/, usa .env.production
```

`.env.local` de ejemplo:

```
VITE_AUTH0_DOMAIN=dev-onzcado3s7e0rlv3.us.auth0.com
VITE_AUTH0_CLIENT_ID=K0bPRHL92w3m4uUcNea79LTbFOpzI6bD
VITE_AUTH0_AUDIENCE=https://enterprise-risk-api
VITE_API_URL=http://localhost:8080
```
