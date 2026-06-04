// Round-trip fromJson/toJson dos models freezed (S25-T02).
//
// Valida que: (1) o mapeamento camelCase<->snake_case esta correto, (2) o
// converter de Decimal (String "12.34" -> double) funciona, (3) os enums
// (de)serializam pelos @JsonValue, e (4) fromJson(toJson(x)) == x (igualdade
// estrutural gerada pelo freezed).

import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/features/accounts/data/account_models.dart';
import 'package:orcafacil_mobile/features/budgets/data/budget_models.dart';
import 'package:orcafacil_mobile/features/categories/data/category_models.dart';
import 'package:orcafacil_mobile/features/goals/data/goal_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';

void main() {
  group('Round-trip fromJson/toJson (freezed)', () {
    test('Transaction: campos, converter de amount, enums e round-trip', () {
      final json = {
        'id': 7,
        'user_id': 9,
        'account_id': 2,
        'category_id': 3,
        'type': 'expense',
        'amount': '12.34', // backend manda Decimal como String
        'date': '2026-05-23',
        'description': 'Mercado',
        'payment_method': 'pix',
        'is_recurring': false,
        'created_at': '2026-06-03T18:07:23.000Z',
      };
      final t = Transaction.fromJson(json);

      // paridade de campos / mapeamento snake_case + converter + enum
      expect(t.id, 7);
      expect(t.userId, 9);
      expect(t.accountId, 2);
      expect(t.categoryId, 3);
      expect(t.type, TransactionType.expense);
      expect(t.amount, 12.34);
      expect(t.description, 'Mercado');
      expect(t.paymentMethod, PaymentMethod.pix);
      expect(t.isRecurring, false);

      expect(Transaction.fromJson(t.toJson()), t);
    });

    test('Transaction: payment_method nulo e amount numerico', () {
      final t = Transaction.fromJson({
        'id': 1,
        'user_id': 1,
        'account_id': 1,
        'category_id': 1,
        'type': 'income',
        'amount': 50, // tambem aceita num
        'date': '2026-05-01',
        'description': null,
        'payment_method': null,
        'is_recurring': true,
        'created_at': '2026-05-01T00:00:00.000Z',
      });
      expect(t.amount, 50.0);
      expect(t.paymentMethod, isNull);
      expect(t.type, TransactionType.income);
      expect(Transaction.fromJson(t.toJson()), t);
    });

    test('TransactionPage: itens aninhados e round-trip', () {
      final page = TransactionPage.fromJson({
        'items': [
          {
            'id': 1,
            'user_id': 1,
            'account_id': 1,
            'category_id': 1,
            'type': 'income',
            'amount': '10.00',
            'date': '2026-05-01',
            'is_recurring': false,
            'created_at': '2026-05-01T00:00:00.000Z',
          },
        ],
        'total': 1,
        'page': 1,
        'page_size': 20,
      });
      expect(page.items, hasLength(1));
      expect(page.pageSize, 20);
      expect(TransactionPage.fromJson(page.toJson()), page);
    });

    test('Account (minimo) e Category (minimo)', () {
      final acc = Account.fromJson({'id': 1, 'name': 'Nubank', 'user_id': 9});
      expect(acc.id, 1);
      expect(acc.name, 'Nubank');
      expect(Account.fromJson(acc.toJson()), acc);

      final cat = Category.fromJson({
        'id': 2,
        'name': 'Salário',
        'type': 'income',
        'color': '#2ecc71',
      });
      expect(cat.type, TransactionType.income);
      expect(cat.color, '#2ecc71');
      expect(Category.fromJson(cat.toJson()), cat);
    });

    test('AccountFull: enum credit_card e defaults', () {
      final a = AccountFull.fromJson({
        'id': 1,
        'user_id': 9,
        'name': 'Cartão',
        'type': 'credit_card',
        'initial_balance': '100.00',
        'current_balance': '150.50',
        'is_active': true,
      });
      expect(a.type, AccountType.creditCard);
      expect(a.initialBalance, 100.0);
      expect(a.currentBalance, 150.5);
      expect(a.isActive, true);
      expect(AccountFull.fromJson(a.toJson()), a);
    });

    test('CategoryFull: nullables e is_default', () {
      final c = CategoryFull.fromJson({
        'id': 1,
        'user_id': 9,
        'name': 'Alimentação',
        'type': 'expense',
        'color': '#e74c3c',
        'icon': 'utensils',
        'is_default': true,
      });
      expect(c.type, TransactionType.expense);
      expect(c.isDefault, true);
      expect(c.icon, 'utensils');
      expect(CategoryFull.fromJson(c.toJson()), c);
    });

    test('BudgetWithUsage e BudgetRead', () {
      final b = BudgetWithUsage.fromJson({
        'id': 1,
        'user_id': 9,
        'category_id': 3,
        'month': 5,
        'year': 2026,
        'limit_amount': '500.00',
        'used_amount': '200.00',
        'percent_used': '40.00',
        'status': 'warning',
      });
      expect(b.status, BudgetStatus.warning);
      expect(b.limitAmount, 500.0);
      expect(b.percentUsed, 40.0);
      expect(BudgetWithUsage.fromJson(b.toJson()), b);

      final br = BudgetRead.fromJson({
        'id': 1,
        'user_id': 9,
        'category_id': 3,
        'month': 5,
        'year': 2026,
        'limit_amount': '500.00',
      });
      expect(br.limitAmount, 500.0);
      expect(BudgetRead.fromJson(br.toJson()), br);
    });

    test('Goal: deadline opcional, enum in_progress e getter progress', () {
      final g = Goal.fromJson({
        'id': 1,
        'user_id': 9,
        'name': 'Reserva',
        'target_amount': '1000.00',
        'current_amount': '250.00',
        'deadline': '2026-12-31',
        'status': 'in_progress',
      });
      expect(g.status, GoalStatus.inProgress);
      expect(g.targetAmount, 1000.0);
      expect(g.progress, 0.25);
      expect(Goal.fromJson(g.toJson()), g);

      final semDeadline = Goal.fromJson({
        'id': 2,
        'user_id': 9,
        'name': 'X',
        'target_amount': '100.00',
        'current_amount': '0.00',
        'deadline': null,
        'status': 'completed',
      });
      expect(semDeadline.deadline, isNull);
      expect(semDeadline.status, GoalStatus.completed);
      expect(Goal.fromJson(semDeadline.toJson()), semDeadline);
    });
  });
}
