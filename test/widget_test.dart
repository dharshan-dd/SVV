import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:microfinance_app/widgets/amount_summary_card.dart';

void main() {
  testWidgets('AmountSummaryCard renders title and amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmountSummaryCard(
            title: 'Total Credit',
            amount: 1234.5,
            icon: Icons.account_balance_wallet_rounded,
            backgroundColor: Colors.white,
            textColor: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('Total Credit'), findsOneWidget);
    expect(find.text('₹1,234.50'), findsOneWidget);
  });
}