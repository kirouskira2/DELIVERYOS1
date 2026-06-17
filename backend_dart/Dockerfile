# ============================================================
# DeliveryOS — Backend Dart Frog (Produção)
# Multi-stage build: compila binário AOT para máxima performance
# ============================================================

# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Adiciona o pub-cache/bin ao PATH (onde o dart_frog CLI é instalado)
ENV PATH="$PATH:/root/.pub-cache/bin"

# Copia apenas pubspec primeiro para cache de dependências
COPY pubspec.* ./
RUN dart pub get

# Copia o código fonte
COPY . .

# Instala o CLI do Dart Frog e gera o build de produção
RUN dart pub global activate dart_frog_cli
RUN dart_frog build

# Compila para binário nativo (AOT) — execução ~10x mais rápida
RUN dart compile exe build/bin/server.dart -o /app/server

# Stage 2: Runtime (imagem mínima)
FROM debian:bookworm-slim

# Instala certificados SSL (necessário para HTTPS ao Supabase)
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia apenas o binário compilado e o .env
COPY --from=build /app/server ./server
COPY .env .env

EXPOSE 8080

# Health check: verifica se o servidor responde
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

CMD ["./server"]
