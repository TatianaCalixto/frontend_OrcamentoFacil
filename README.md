# OrçaFácil — App Mobile (Flutter)

[![CI](https://github.com/TatianaCalixto/frontend_OrcamentoFacil/actions/workflows/ci.yml/badge.svg)](https://github.com/TatianaCalixto/frontend_OrcamentoFacil/actions/workflows/ci.yml)

App de **controle financeiro pessoal** para Android e iOS, feito em **Flutter**. Aqui mora o app mobile; o **backend (FastAPI)** e o **painel web (Streamlit)** ficam no repositório irmão [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil).

Controle de contas, lançamento de receitas/despesas, orçamentos mensais por categoria com alertas, metas financeiras, dashboard com gráficos e importação de extratos CSV — autenticado por JWT contra a API do projeto.

---

## O que o app faz

| Área | Telas / recursos |
|---|---|
| **Autenticação** | Splash, Login e Cadastro — JWT, tratamento de 401 e token em `flutter_secure_storage` |
| **Dashboard** | Resumo do mês (receitas, despesas, saldo) + **gráfico de pizza** por categoria (`fl_chart`) |
| **Transações** | Lista com **filtros** (período, tipo, conta, categoria, busca textual) e **scroll infinito**; criar, editar e excluir com validação |
| **Contas** | CRUD de contas e seus saldos |
| **Categorias** | CRUD com **cores e ícones** |
| **Orçamentos** | Limite mensal por categoria com **alertas visuais** por status (ok / atenção / estourado) |
| **Metas** | Metas financeiras com **barra de progresso** e conclusão automática |
| **Importação** | Upload de **extrato CSV** (multipart) com resumo de criados / ignorados / erros por linha |
| **Perfil & Ajustes** | Dados do usuário, logout e **tema claro/escuro persistente** |

São **17 telas** em **11 áreas funcionais**, navegação declarativa com `go_router` e estado com Riverpod.

---

## Stack

- **Flutter** (canal stable) — Android e iOS, Dart `^3.10`
- **Riverpod 3** — gerenciamento de estado (Notifiers)
- **go_router 17** — navegação declarativa
- **Dio 5** — HTTP, com **interceptor JWT** (autenticação + 401) e **cache** (`dio_cache_interceptor`, respeitando `Cache-Control`)
- **freezed 3** + **json_serializable** — models e estados imutáveis com serialização gerada
- **fl_chart** — gráficos
- **flutter_secure_storage** — armazenamento seguro do token
- **mocktail** + `flutter test` — testes

## Arquitetura

Organização **feature-first**: cada domínio em `lib/features/<nome>/`, dividido em três camadas:

```
lib/
├── core/                  # rede (Dio), tema, env, conversores JSON
├── shared/                # widgets reutilizáveis (ex.: AsyncView: loading/empty/error)
└── features/<feature>/
    ├── data/              # models (freezed) + clients da API
    ├── application/       # controllers/estados (Riverpod Notifier)
    └── presentation/      # telas e widgets
```

Decisões de design recentes: models e estados migrados para **freezed** (igualdade estrutural e `copyWith` gerados), componente **`AsyncView`** padronizando os três estados de tela, e **cache HTTP** no Dio alinhado ao `Cache-Control` do backend.

## Qualidade

- **29 arquivos de teste** — unitários, de widget e de _round-trip_ de serialização (`flutter test`)
- Cobertura **≥ 70%** garantida no CI (atualmente ~75%, excluindo código gerado)
- **CI (GitHub Actions)** a cada push: `flutter analyze` → `flutter test --coverage` → gate de cobertura → **build do APK** (veja o badge acima)
- **Ícone e splash próprios** (`flutter_launcher_icons` + `flutter_native_splash`)

> Os arquivos gerados pelo code-gen (`*.freezed.dart`, `*.g.dart`) **não são versionados** por escolha de projeto — o CI os regenera com `build_runner` a cada checkout.

---

## Rodando localmente

Pré-requisitos: **Flutter SDK** (stable), Android Studio ou Xcode, e o **backend rodando** (veja [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil)).

```bash
git clone https://github.com/TatianaCalixto/frontend_OrcamentoFacil.git
cd frontend_OrcamentoFacil/mobile

flutter pub get                                       # 1. dependências
dart run build_runner build --delete-conflicting-outputs   # 2. gera models/estados (freezed)
cp .env.example .env                                  # 3. configura API_BASE_URL
flutter run                                           # 4. roda no emulador/dispositivo
```

**Dispositivo físico via USB?** O `localhost` do celular não é o da máquina. Com o backend em `:8000`, encaminhe a porta pelo cabo:

```bash
adb reverse tcp:8000 tcp:8000
```

Assim o app continua usando `http://localhost:8000` e alcança o backend da sua máquina.

---

## Como este projeto foi construído

Seguiu um fluxo de **documentação viva guiando a execução por sprints**: a documentação define o *quê* e os critérios de pronto, e a implementação avança sprint a sprint, com **testes obrigatórios** e **rastreabilidade** de cada módulo até a sprint que o originou (os commits seguem `feat(sXX-tYY): …`).

Desenvolvido em **parceria com IA**: a arquitetura, os critérios e a documentação são definidos por mim; a IA executa sob essa direção, sprint a sprint. O método importa mais que a ferramenta. O detalhamento da metodologia e o plano operacional completo ficam fora deste repositório (em [metodologia_OrcamentoFacil](https://github.com/TatianaCalixto/metodologia_OrcamentoFacil)).

## Repositórios do projeto

- **App mobile (este repo)** — Flutter
- **Backend + painel web** — [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil) (FastAPI + Streamlit + PostgreSQL)
- **Metodologia** — [metodologia_OrcamentoFacil](https://github.com/TatianaCalixto/metodologia_OrcamentoFacil) (documentação viva + agente executor)
</content>
</invoke>
