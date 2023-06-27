import 'package:arch_ledger/util.dart';
import 'package:equatable/equatable.dart';

part 'participant.g.dart';

@JsonSerializable()
class TXN with EquatableMixin {
  int? value;
  int? date;
  int? due;

  @override
  List<Object?> get props => [value, date, due];

  TXN();

  factory TXN.fromJson(Map<String, dynamic> json) => _$TXNFromJson(json);

  Map<String, dynamic> toJson() => _$TXNToJson(this);
}
