import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_app_bar.dart';
import 'package:ziggle/app/modules/core/data/models/analytics_event.dart';
import 'package:ziggle/app/modules/core/domain/enums/page_source.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_entity.dart';
import 'package:ziggle/app/modules/notices/presentation/bloc/notice_write_bloc.dart';
import 'package:ziggle/app/modules/notices/presentation/widgets/notice_renderer.dart';
import 'package:ziggle/app/modules/user/presentation/bloc/user_bloc.dart';
import 'package:ziggle/gen/strings.g.dart';

@RoutePage()
class NoticeWritePreviewPage extends StatefulWidget {
  const NoticeWritePreviewPage({super.key});

  @override
  State<NoticeWritePreviewPage> createState() => _NoticeWritePreviewPageState();
}

class _NoticeWritePreviewPageState extends State<NoticeWritePreviewPage>
    with AutoRouteAwareStateMixin<NoticeWritePreviewPage> {
  @override
  void didPush() =>
      AnalyticsRepository.pageView(const AnalyticsEvent.writeConfigPreview());
  @override
  void didPopNext() =>
      AnalyticsRepository.pageView(const AnalyticsEvent.writeConfigPreview());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZiggleAppBar.compact(
        backLabel: context.t.notice.write.configTitle,
        from: PageSource.writeConfigPreview,
        title: Text(context.t.notice.write.preview),
      ),
      body: BlocBuilder<NoticeWriteBloc, NoticeWriteState>(
        builder: (context, state) {
          if (!state.draft.isValid) {
            return const SizedBox();
          }
          return NoticeRenderer(
            notice: NoticeEntity.fromDraft(
              draft: state.draft,
              user: UserBloc.userOrNull(context)!,
            ),
            hideAuthorSetting: true,
          );
        },
      ),
    );
  }
}
