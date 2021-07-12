part of "transaction_cubit.dart";

@immutable
abstract class TransactionState {
  const TransactionState();
}

class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

class TransactionLoaded extends TransactionState {
  const TransactionLoaded();
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is TransactionError && o.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
