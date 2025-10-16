import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/remote_config.dart';

class ViewGateState {
  const ViewGateState(
      {required this.views, required this.depth, required this.blocked});

  final int views;
  final int depth;
  final bool blocked;

  ViewGateState copyWith({int? views, int? depth, bool? blocked}) {
    return ViewGateState(
      views: views ?? this.views,
      depth: depth ?? this.depth,
      blocked: blocked ?? this.blocked,
    );
  }
}

class ViewGateNotifier extends StateNotifier<ViewGateState> {
  ViewGateNotifier(this._config)
      : super(const ViewGateState(views: 0, depth: 0, blocked: false));

  final RemoteConfigValues _config;

  bool recordView({bool deep = false}) {
    final nextViews = state.views + 1;
    final nextDepth = deep ? state.depth + 1 : state.depth;
    final blocked =
        nextViews >= _config.maxFreeViews || nextDepth >= _config.maxFreeDepth;
    state =
        state.copyWith(views: nextViews, depth: nextDepth, blocked: blocked);
    return !blocked;
  }

  void reset() {
    state = const ViewGateState(views: 0, depth: 0, blocked: false);
  }
}

final viewGateProvider =
    StateNotifierProvider<ViewGateNotifier, ViewGateState>((ref) {
  final config = ref.watch(remoteConfigValuesProvider);
  return ViewGateNotifier(config);
});
