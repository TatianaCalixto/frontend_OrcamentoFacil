# OrçaFácil — Frontend (Mobile)

[![CI](https://github.com/TatianaCalixto/frontend_OrcamentoFacil/actions/workflows/ci.yml/badge.svg)](https://github.com/TatianaCalixto/frontend_OrcamentoFacil/actions/workflows/ci.yml)

App de controle financeiro pessoal. Este repositório concentra o **app mobile (Flutter)** do projeto.

> O backend (FastAPI), painel web (Streamlit), scripts e documentação técnica vivem em [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil).

🧭 Projeto desenvolvido com um fluxo de **documentação viva guiando a execução por sprints rastreáveis**.


## Como este projeto foi construído

Este projeto seguiu um fluxo de **documentação viva guiando a execução por
sprints**: a documentação define o *quê* e os critérios de pronto, e a
implementação avança sprint a sprint, com **testes obrigatórios** e
**rastreabilidade** de cada módulo até a sprint que o originou.

O detalhamento da metodologia e o plano operacional completo ficam fora deste
repositório.

## Estrutura

```
frontend_OrcamentoFacil/
└── mobile/   # App Flutter (Riverpod + go_router + Dio + fl_chart)
```

## Stack

- **Flutter** (canal stable)
- **Riverpod** para gerenciamento de estado
- **go_router** para navegação
- **Dio** com interceptor JWT para HTTP
- **fl_chart** para gráficos
- **flutter_secure_storage** para token
- **mocktail** + `flutter test` para testes

## Requisitos

- Flutter SDK (canal stable)
- Android Studio ou Xcode (para emuladores)
- Backend rodando localmente (veja [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil))

## Setup

> O projeto Flutter será inicializado dentro de `mobile/` na **Sprint 11**.

```bash
git clone https://github.com/TatianaCalixto/frontend_OrcamentoFacil.git
cd frontend_OrcamentoFacil/mobile
flutter pub get
flutter run
```

## Status

Em desenvolvimento — aguardando Sprint 11 (Flutter Setup e Autenticação). Sprints 0–10 focam no backend.

O plano de execução completo (17 sprints, 67 tarefas) é mantido fora do repositório, em planilha operacional privada.
