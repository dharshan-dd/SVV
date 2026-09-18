import 'package:flutter_test/flutter_test.dart';
import 'package:microfinance_app/services/collection_calculation_service.dart';

void main() {
  group('CollectionCalculationService.calculateDayRecordTrail', () {
    test('computes totalAmount and finalAmount correctly', () {
      final trail = CollectionCalculationService().calculateDayRecordTrail(
        previousFinalAmount: 1000.0,
        netAmountInHand: 500.0,
        collectedAmount: 300.0,
        remainingAmount: 100.0,
        documentFees: 50.0,
        adapAmount: 40.0,
        rrGpayAmount: 30.0,
        expense: 20.0,
      );

      // total = net + collected + remaining + document fees
      expect(trail['totalAmount'], 950.0);
      // amountAfterAdap = total - adap
      expect(trail['amountAfterAdap'], 910.0);
      // amountAfterGpay = amountAfterAdap - gpay
      expect(trail['amountAfterGpay'], 880.0);
      // finalAmount = amountAfterGpay - expense
      expect(trail['finalAmount'], 860.0);
      // previousFinalAmount is passed through unchanged
      expect(trail['previousFinalAmount'], 1000.0);
    });

    test('handles zero inputs without error', () {
      final trail = CollectionCalculationService().calculateDayRecordTrail(
        previousFinalAmount: 0.0,
        netAmountInHand: 0.0,
        collectedAmount: 0.0,
        remainingAmount: 0.0,
        documentFees: 0.0,
        adapAmount: 0.0,
        rrGpayAmount: 0.0,
        expense: 0.0,
      );

      expect(trail['totalAmount'], 0.0);
      expect(trail['finalAmount'], 0.0);
    });

    test('deductions can drive finalAmount negative', () {
      final trail = CollectionCalculationService().calculateDayRecordTrail(
        previousFinalAmount: 0.0,
        netAmountInHand: 100.0,
        collectedAmount: 0.0,
        remainingAmount: 0.0,
        documentFees: 0.0,
        adapAmount: 0.0,
        rrGpayAmount: 0.0,
        expense: 200.0,
      );

      expect(trail['totalAmount'], 100.0);
      expect(trail['finalAmount'], -100.0);
    });
  });
}