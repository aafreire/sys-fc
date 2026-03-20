# Etapa 1: build
FROM elixir:1.17.3-alpine AS build

# Instala dependências do sistema necessárias para compilação
# libsodium-dev é necessária para argon2_elixir (NIF)
RUN apk add --no-cache build-base git libsodium-dev

WORKDIR /app

# Instala hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# Copia arquivos de dependências e busca deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copia o restante do código
COPY config config
COPY lib lib
COPY priv priv

# Compila o projeto
RUN mix compile

# Gera o release
RUN mix release

# Etapa 2: imagem final (menor)
FROM elixir:1.17.3-alpine AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs libsodium

WORKDIR /app

COPY --from=build /app/_build/prod/rel/sys_fc ./

ENV HOME=/app
ENV PORT=4000
ENV PHX_SERVER=true

EXPOSE 4000

CMD ["bin/sys_fc", "start"]
