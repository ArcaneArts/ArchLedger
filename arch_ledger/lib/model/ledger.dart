import 'package:arch_ledger/util.dart';
import 'package:equatable/equatable.dart';

part 'participant.g.dart';

@JsonSerializable()
class Ledger with EquatableMixin {
  String? lender;
  String? user;

  @override
  List<Object?> get props => [value, date, due];

  Ledger();

  factory Ledger.fromJson(Map<String, dynamic> json) => _$LedgerFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerToJson(this);
}
