import "package:bloc/bloc.dart";
import "package:meta/meta.dart";
import "../data/transaction_repository.dart";
part "transaction_state.dart";

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _transactionRepository;

  TransactionCubit(this._transactionRepository) : super(TransactionInitial());

  Future<void> writeTransaction(laverie, machine, load, email) async {
    print("before try");
    try {
      print("in try");
      emit(TransactionLoading());
      await _transactionRepository.writeTransaction(
          laverie, machine, load, email);
      print("DONE");
      emit((TransactionLoaded()));
    } on Exception catch (error) {
      print("exception");
      print(error);
      emit(TransactionError(
          "Erreur lors de la transaction. Veuillez prendre note des machines "
          "lancées sur papier et contactez Samuel Gérard pour notifier de "
          "l'erreur"));
    }
  }
}
