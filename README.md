# OrçaFácil — Frontend (Mobile)

App de controle financeiro pessoal. Este repositório concentra o **app mobile (Flutter)** do projeto.

> O backend (FastAPI), painel web (Streamlit), scripts e documentação técnica vivem em [backend_OrcamentoFacil](https://github.com/TatianaCalixto/backend_OrcamentoFacil).
>
> 📋 **Este código é o substrato de um caso de uso de metodologia.** Para entender o método "documentação viva + agente executor" usado para planejar, executar e revisar este projeto com Claude Code, veja → [metodologia_OrcamentoFacil](https://github.com/TatianaCalixto/metodologia_OrcamentoFacil).

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
