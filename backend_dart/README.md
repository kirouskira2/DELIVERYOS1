# Delivery OS - Backend & Database

Este repositório contém o backend (Dart Frog) e a configuração do banco de dados (Supabase) para o sistema Delivery OS. O frontend (Flutter) é um projeto separado e não está incluído aqui.

## Stack Tecnológica

*   **Backend:** Dart Frog (Framework Dart para APIs e microsserviços)
*   **Banco de Dados:** Supabase (PostgreSQL, Auth, RLS, Edge Functions)
*   **Linguagem:** Dart

## Como Iniciar o Projeto

Siga os passos abaixo para configurar e rodar o backend e o banco de dados.

### 1. Configuração do Backend (Dart Frog)

1.  Navegue até a pasta `backend_dart/` no seu terminal:
    ```bash
    cd backend_dart
    ```
2.  Crie um arquivo `.env` dentro da pasta `backend_dart/` e adicione suas chaves do Supabase (as mesmas acima, ou suas próprias se estiver usando uma instância diferente):
    ```
    SUPABASE_URL=https://xnoivcxperibtuovusuo.supabase.co
    SUPABASE_PUBLISHABLE_KEY=sb_publishable_MEY2Tu7dhx9LfkNjyiC5Gw_6jLXwprF
    ```
3.  Instale as dependências do Dart:
    ```bash
    dart pub get
    ```
4.  Inicie o servidor Dart Frog:
    ```bash
    dart_frog dev
    ```
    O backend estará rodando em `http://localhost:8080`.

### 3. Frontend (Flutter)

O frontend Flutter é um projeto separado. Se você tiver o repositório do frontend, siga as instruções dele para configurá-lo e conectá-lo a este backend.