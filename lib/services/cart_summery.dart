

class CartSummary {
  final int itemCount;
  final double totalAmount;
  final double amountToPay;
  static const double deliveryCharge = 10.0;

  CartSummary({required this.itemCount, required this.totalAmount})
      : amountToPay = totalAmount + deliveryCharge;
}

