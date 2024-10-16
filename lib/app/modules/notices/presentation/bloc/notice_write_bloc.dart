import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:ziggle/app/modules/core/domain/enums/language.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_entity.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_write_draft_entity.dart';
import 'package:ziggle/app/modules/notices/domain/enums/notice_type.dart';
import 'package:ziggle/app/modules/notices/domain/repositories/notice_repository.dart';

part 'notice_write_bloc.freezed.dart';

@injectable
class NoticeWriteBloc extends Bloc<NoticeWriteEvent, NoticeWriteState> {
  final NoticeRepository _repository;

  NoticeWriteBloc(this._repository) : super(const _Draft()) {
    on<_SetTitle>(
      (event, emit) => emit(_Draft(state.draft.copyWith(
        titles: {...state.draft.titles, event.lang: event.title},
      ))),
    );
    on<_SetBody>(
      (event, emit) => emit(_Draft(state.draft.copyWith(
        bodies: {...state.draft.bodies, event.lang: event.body},
      ))),
    );
    on<_SetImages>((event, emit) =>
        emit(_Draft(state.draft.copyWith(images: event.images))));
    on<_SetConfig>((event, emit) => emit(_Draft(state.draft.copyWith(
          type: event.type,
          tags: event.tags,
          deadline: event.deadline,
        ))));
    on<_AddAdditional>((event, emit) => emit(_Draft(state.draft.copyWith(
          deadline: event.deadline,
          additionalContent: event.contents,
        ))));
    on<_Publish>((event, emit) async {
      try {
        emit(_Loading(state.draft));
        if (event.prevNotice != null) {
          final notice = event.prevNotice!;
          if (!notice.isPublished &&
              state.draft.bodies.containsKey(Language.ko)) {
            await _repository.modify(
              id: notice.id,
              content: state.draft.bodies[Language.ko]!,
            );
          }
          if (!notice.contents.containsKey(Language.en) &&
              state.draft.bodies.containsKey(Language.en)) {
            await _repository.writeForeign(
              id: notice.id,
              deadline: notice.deadline,
              title: state.draft.titles[Language.en]!,
              content: state.draft.bodies[Language.en]!,
              contentId: 1,
              lang: Language.en,
            );
          }
          if (state.draft.additionalContent.isNotEmpty) {
            final added = await _repository.addAdditionalContent(
              id: notice.id,
              content: state.draft.additionalContent[Language.ko]!,
              deadline: state.draft.deadline ?? notice.currentDeadline,
            );
            if (state.draft.additionalContent.containsKey(Language.en)) {
              await _repository.writeForeign(
                id: notice.id,
                contentId: added.lastContentId,
                content: state.draft.additionalContent[Language.en]!,
                deadline: state.draft.deadline ?? notice.currentDeadline,
                lang: Language.en,
              );
            }
          }
          emit(_Done(state.draft, await _repository.getNotice(notice.id)));
        } else {
          final notice = await _repository.write(
            title: state.draft.titles[Language.ko]!,
            content: state.draft.bodies[Language.ko]!,
            type: state.draft.type!,
            tags: state.draft.tags,
            images: state.draft.images,
            deadline: state.draft.deadline,
          );
          if (state.draft.bodies.containsKey(Language.en)) {
            await _repository.writeForeign(
              id: notice.id,
              title: state.draft.titles[Language.en],
              content: state.draft.bodies[Language.en]!,
              contentId: 1,
              lang: Language.en,
              deadline: state.draft.deadline,
            );
          }
          emit(_Done(state.draft, notice));
        }
      } catch (e) {
        emit(_Error(state.draft, e.toString()));
      }
    });
  }
}

@freezed
class NoticeWriteEvent {
  const factory NoticeWriteEvent.setTitle(String title,
      [@Default(Language.ko) Language lang]) = _SetTitle;
  const factory NoticeWriteEvent.setBody(String body,
      [@Default(Language.ko) Language lang]) = _SetBody;
  const factory NoticeWriteEvent.setImages(List<File> images) = _SetImages;
  const factory NoticeWriteEvent.setConfig({
    required NoticeType type,
    required List<String> tags,
    DateTime? deadline,
  }) = _SetConfig;
  const factory NoticeWriteEvent.addAdditional({
    DateTime? deadline,
    required Map<Language, String> contents,
  }) = _AddAdditional;
  const factory NoticeWriteEvent.publish([NoticeEntity? prevNotice]) = _Publish;
}

@freezed
class NoticeWriteState with _$NoticeWriteState {
  const NoticeWriteState._();
  const factory NoticeWriteState.draft(
          [@Default(NoticeWriteDraftEntity()) NoticeWriteDraftEntity draft]) =
      _Draft;
  const factory NoticeWriteState.loading(NoticeWriteDraftEntity draft) =
      _Loading;
  const factory NoticeWriteState.done(
    NoticeWriteDraftEntity draft,
    NoticeEntity notice,
  ) = _Done;
  const factory NoticeWriteState.error(
    NoticeWriteDraftEntity draft,
    String error,
  ) = _Error;

  bool get hasResult => this is _Done || this is _Error;
  bool get isLoading => this is _Loading;
  bool get hasChanging =>
      draft.bodies.isNotEmpty || draft.additionalContent.isNotEmpty;
}
