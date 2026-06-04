import 'package:flutter/material.dart';

/// Trio de estados assíncronos reutilizável (S25-T04): [LoadingView],
/// [EmptyView] e [ErrorView]. Substitui os componentes locais duplicados
/// (_LoadingList/_EmptyList/_ErrorList, _LoadingView/_ErrorView).
///
/// Use `scrollable: true` em telas de lista com pull-to-refresh: o conteúdo
/// é centralizado na viewport e o gesto de arrastar continua funcionando
/// mesmo nos estados vazio/erro/carregando.

/// Indicador de carregamento centralizado.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.scrollable = false});

  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    const content = Center(child: CircularProgressIndicator());
    return scrollable ? const _ScrollableCenter(child: content) : content;
  }
}

/// Estado vazio: ícone + mensagem amigável.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.scrollable = false,
  });

  /// Ícone do estado vazio; passe `null` para exibir só a mensagem.
  final IconData? icon;
  final String message;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
        ],
        Text(message, textAlign: TextAlign.center),
      ],
    );
    return scrollable
        ? _ScrollableCenter(child: content)
        : Center(child: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}

/// Estado de erro: ícone + mensagem + ação opcional de "tentar novamente".
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Tentar novamente',
    this.scrollable = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ],
    );
    return scrollable
        ? _ScrollableCenter(child: content)
        : Center(child: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}

/// Centraliza o filho ocupando a altura da viewport e mantém o scroll
/// (necessário para o pull-to-refresh funcionar nos estados sem conteúdo).
class _ScrollableCenter extends StatelessWidget {
  const _ScrollableCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
