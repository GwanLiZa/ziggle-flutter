import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/user/domain/entities/user_entity.dart';
import 'package:ziggle/app/modules/user/domain/repositories/user_repository.dart';

part 'user_bloc.freezed.dart';

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _repository;
  final AnalyticsRepository _analyticsRepository;

  UserBloc(
    this._repository,
    this._analyticsRepository,
  ) : super(const _Initial()) {
    on<_Init>((event, emit) async {
      return emit.forEach(
        _repository.me,
        onData: (data) {
          _analyticsRepository.logChangeUser(data);
          return _Done(data);
        },
        onError: (_, __) => const _Initial(),
      );
    });
    on<_Fetch>((event, emit) async {
      _repository.refetchMe();
    });
  }

  static UserEntity? userOrNull(BuildContext context) =>
      context.read<UserBloc>().state.user;
}

@freezed
sealed class UserEvent with _$UserEvent {
  const factory UserEvent.init() = _Init;
  const factory UserEvent.fetch() = _Fetch;
}

@freezed
sealed class UserState with _$UserState {
  const UserState._();

  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.done(UserEntity? user) = _Done;

  bool get isLoading => whenOrNull(loading: () => true) ?? false;
  UserEntity? get user => mapOrNull(done: (e) => e.user);
}
