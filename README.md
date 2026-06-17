# Delivery OS

Este é o projeto completo do Delivery OS, que contém o backend em Dart (Dart Frog) e o frontend em Flutter.

## Estrutura do Projeto

- `backend_dart/`: API e microsserviços desenvolvidos com Dart Frog.
- `frontend_flutter/`: Aplicativo frontend (web/mobile) utilizando Flutter.
- `supabase/`: Scripts de migrations para configurar o banco de dados Supabase.

## Pré-requisitos

Certifique-se de ter as seguintes ferramentas instaladas no seu ambiente:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (que já inclui o Dart SDK)
- Conta e projeto criado no [Supabase](https://supabase.com/)

---

## Passo 1: Configuração do Supabase

1. Crie um projeto no painel do Supabase.
2. Copie e execute o conteúdo dos arquivos SQL localizados na pasta `supabase/migrations/` no **SQL Editor** do seu projeto Supabase, para criar todas as tabelas e políticas de segurança necessárias.
3. Obtenha as chaves de conexão do seu projeto (`Project URL` e a `anon`/`publishable` key).
   > **Atenção:** Mantenha essas chaves em segredo e não faça commit delas no repositório.

---

## Passo 2: Inicializando o Backend (Dart Frog)

O backend necessita das credenciais do Supabase para se comunicar com o banco de dados.

1. Abra o terminal e acesse a pasta do backend:
   ```bash
   cd backend_dart
   ```

2. Crie um arquivo chamado `.env` na raiz de `backend_dart/` e insira suas credenciais (substitua pelos valores do seu projeto):
   ```env
   SUPABASE_URL=sua_url_do_supabase_aqui
   SUPABASE_PUBLISHABLE_KEY=sua_chave_anon_ou_public_aqui
   ```

3. Baixe e instale as dependências do Dart:
   ```bash
   dart pub get
   ```

4. Ative o CLI do Dart Frog globalmente (necessário apenas na primeira vez):
   ```bash
   dart pub global activate dart_frog_cli
   ```
   > **Nota importante para Windows:** Se após este comando o terminal exibir que `dart_frog` não é reconhecido, o diretório de executáveis do Dart não está no seu `PATH`.
   > Para resolver isso temporariamente no PowerShell atual, rode:
   > `$env:PATH += ";$env:LOCALAPPDATA\Pub\Cache\bin"`
   > Para resolver permanentemente, adicione `%LOCALAPPDATA%\Pub\Cache\bin` às Variáveis de Ambiente do Windows.

5. Inicie o servidor de desenvolvimento do backend:
   ```bash
   dart_frog dev
   ```

   Se tudo estiver correto, o backend estará rodando em `http://localhost:8080`.

---

## Passo 3: Inicializando o Frontend (Flutter)

O frontend também consome as credenciais do Supabase para gerenciar a autenticação de usuários.

1. Abra uma **nova aba** ou janela no terminal e acesse a pasta do frontend:
   ```bash
   cd frontend_flutter
   ```

2. Crie um arquivo chamado `.env` na raiz de `frontend_flutter/` e insira as mesmas credenciais utilizadas no backend:
   ```env
   SUPABASE_URL=sua_url_do_supabase_aqui
   SUPABASE_ANON_KEY=sua_chave_anon_ou_public_aqui
   ```

3. Baixe e instale as dependências do Flutter:
   ```bash
   flutter pub get
   ```

4. Execute a aplicação (por exemplo, no navegador Google Chrome):
   ```bash
   flutter run -d chrome
   ```
   *(Para rodar em um emulador Android ou iOS, garanta que ele esteja aberto e omita a flag `-d chrome`)*

---

## Passo 4: Produção e Hospedagem (AWS EC2)

O projeto também está configurado para **Deploy em Produção** em uma instância da AWS (Amazon Web Services).

- **🌐 Acesso ao Sistema Ao Vivo:** [https://54.221.132.160.sslip.io](https://54.221.132.160.sslip.io)

### Arquitetura de Containerização
O ambiente de produção foi completamente orquestrado utilizando **Docker e Docker Compose**, seguindo a seguinte estrutura na AWS EC2 (t3.micro):

1. **Backend em Dart (Container 1):** Compilado para binário executável AOT (*Ahead-of-Time*) gerando uma imagem Docker `slim` extremamente rápida e com baixo uso de memória.
2. **Nginx Reverse Proxy (Container 2):** Configurado para servir os arquivos estáticos do **Flutter Web**, aplicar criptografia SSL/TLS (HTTPS Let's Encrypt), implementar compressão Gzip e redirecionar internamente rotas da API (`/api/`) para o container do backend.

Isso garante alta performance, segurança e que o projeto seja independente de plataforma, pronto para ser executado em qualquer ambiente que suporte containers Docker. Consulte o relatório oficial de infraestrutura na pasta `docs/` para mais detalhes técnicos.
