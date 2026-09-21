#!/usr/bin/env bash
# create_feature.sh
#
# 为 Ark Tech Platform Flutter 应用创建标准 feature 目录骨架。
# 严格遵循 very_good_cli + Flutter 官方架构推荐：
#   - feature-first 组织（按业务功能划分，不按技术类型）
#   - 三层架构（data / domain / application / presentation）
#   - 每个 feature 自带测试（unit + widget）
#   - barrel file 作为对外统一入口
#
# 用法：
#   ./tool/create_feature.sh <feature_name> [features_dir]
#
# 参数：
#   feature_name   feature 名称（snake_case，如 vocab / text_enhancement）
#   features_dir   features 目录路径（默认 lib/features）
#
# 示例：
#   ./tool/create_feature.sh vocab
#   ./tool/create_feature.sh text_enhancement lib/src/features
#
# 前置条件：
#   1. 当前目录是 very_good_cli 生成的 Flutter 项目根
#   2. 已安装 Dart / Flutter
#
# 退出码：
#   0 成功
#   1 参数错误
#   2 feature 已存在
#   3 features 目录不存在

set -euo pipefail

# 参数解析
if [ $# -lt 1 ]; then
  echo "Usage: $0 <feature_name> [features_dir] [--state-management bloc|riverpod]" >&2
  echo "" >&2
  echo "  feature_name            snake_case 名称（必填）" >&2
  echo "  features_dir            features 目录（默认 lib/features）" >&2
  echo "  --state-management      bloc（默认，兼容 very_good_cli 默认）| riverpod（需手动加依赖）" >&2
  exit 1
fi

FEATURE_NAME=""
FEATURES_DIR="lib/features"
STATE_MGMT="bloc"

# 参数解析
while [ $# -gt 0 ]; do
  case "$1" in
    --state-management)
      STATE_MGMT=$2
      shift 2
      ;;
    --help|-h)
      head -20 "$0" | tail -18
      exit 0
      ;;
    -*)
      echo "Error: unknown option '$1'" >&2
      echo "Run '$0 --help' for usage" >&2
      exit 1
      ;;
    *)
      if [ -z "$FEATURE_NAME" ]; then
        FEATURE_NAME=$1
      else
        FEATURES_DIR=$1
      fi
      shift
      ;;
  esac
done

if [ -z "$FEATURE_NAME" ]; then
  echo "Error: feature_name is required" >&2
  exit 1
fi

# 校验 state-management
case "$STATE_MGMT" in
  bloc|riverpod) ;;
  *)
    echo "Error: --state-management must be 'bloc' or 'riverpod'" >&2
    echo "       got: $STATE_MGMT" >&2
    exit 1
    ;;
esac

# 校验 feature 命名（snake_case）
if ! [[ "$FEATURE_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Error: feature name must be snake_case (lowercase, digits, underscores)" >&2
  echo "       got: $FEATURE_NAME" >&2
  exit 1
fi

# 校验 features 目录存在
if [ ! -d "$FEATURES_DIR" ]; then
  echo "Error: features directory '$FEATURES_DIR' does not exist" >&2
  echo "Hint: mkdir -p $FEATURES_DIR" >&2
  exit 3
fi

# 从 pubspec.yaml 读取实际包名（避免硬编码）
PACKAGE_NAME=""
if [ -f "pubspec.yaml" ]; then
  PACKAGE_NAME=$(awk '/^name:/{print $2; exit}' pubspec.yaml)
fi
if [ -z "$PACKAGE_NAME" ]; then
  echo "Error: cannot detect package name from pubspec.yaml" >&2
  exit 3
fi

BASE_DIR="$FEATURES_DIR/$FEATURE_NAME"

# 校验 feature 不存在
if [ -d "$BASE_DIR" ]; then
  echo "Error: feature '$FEATURE_NAME' already exists at $BASE_DIR" >&2
  exit 2
fi

# PascalCase 形式（用于类名）
# 注意：macOS BSD sed 不支持 \U，所以用 awk 做首字母大写转换（macOS + Linux 通用）
PASCAL_NAME=$(echo "$FEATURE_NAME" | awk '
  BEGIN { FS="_"; OFS="" }
  {
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }
')

# 目录创建（按 very_good_cli + Flutter 官方架构）
mkdir -p \
  "$BASE_DIR/data/datasources" \
  "$BASE_DIR/data/models" \
  "$BASE_DIR/data/repositories" \
  "$BASE_DIR/domain/entities" \
  "$BASE_DIR/domain/repositories" \
  "$BASE_DIR/domain/usecases" \
  "$BASE_DIR/application/providers" \
  "$BASE_DIR/application/states" \
  "$BASE_DIR/presentation/pages" \
  "$BASE_DIR/presentation/widgets" \
  "test/features/$FEATURE_NAME/data/datasources" \
  "test/features/$FEATURE_NAME/data/repositories" \
  "test/features/$FEATURE_NAME/domain/usecases" \
  "test/features/$FEATURE_NAME/application" \
  "test/features/$FEATURE_NAME/presentation/pages" \
  "test/features/$FEATURE_NAME/presentation/widgets"

# barrel file（feature 对外唯一入口）
cat > "$BASE_DIR/${FEATURE_NAME}.dart" << EOF
/// ${PASCAL_NAME} feature barrel file.
///
/// 对外只导出 ${PASCAL_NAME} 的：
///   - Domain entities（业务实体）
///   - Domain repository interfaces（仓储接口）
///   - Application providers（Riverpod 状态管理入口）
///   - Presentation pages（页面）
///
/// 不导出：
///   - data/* 的具体实现（仅通过 domain 接口暴露）
///   - usecases 的内部细节
library;
export 'domain/entities/${FEATURE_NAME}.dart';
export 'domain/repositories/${FEATURE_NAME}_repository.dart';
EOF

# 根据 STATE_MGMT 追加 application 导出
if [ "$STATE_MGMT" = "bloc" ]; then
  cat >> "$BASE_DIR/${FEATURE_NAME}.dart" << EOF
export 'application/bloc/${FEATURE_NAME}_cubit.dart';
EOF
elif [ "$STATE_MGMT" = "riverpod" ]; then
  cat >> "$BASE_DIR/${FEATURE_NAME}.dart" << EOF
export 'application/providers/${FEATURE_NAME}_provider.dart';
export 'application/states/${FEATURE_NAME}_state.dart';
EOF
fi

cat >> "$BASE_DIR/${FEATURE_NAME}.dart" << EOF
export 'presentation/pages/${FEATURE_NAME}_page.dart';
EOF

# Domain Entity（领域实体 — 业务核心，不可变，不依赖 freezed）
cat > "$BASE_DIR/domain/entities/${FEATURE_NAME}.dart" << EOF
/// ${PASCAL_NAME} 领域实体。
///
/// 业务核心模型，不依赖任何外部（无 JSON 序列化、无 RPC 类型引用）。
/// 使用 const + final 不可变，不依赖 Equatable/freezed。
class ${PASCAL_NAME} {
  const ${PASCAL_NAME}({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
}
EOF

# Domain Repository Interface（仓储接口 — 业务侧定义）
cat > "$BASE_DIR/domain/repositories/${FEATURE_NAME}_repository.dart" << EOF
import '../entities/${FEATURE_NAME}.dart';

/// ${PASCAL_NAME} 仓储接口。
///
/// 由 data 层实现，application 层通过 Riverpod 注入。
abstract interface class ${PASCAL_NAME}Repository {
  Future<${PASCAL_NAME}> getById(String id);

  Future<List<${PASCAL_NAME}>> list({int pageSize = 20, String? pageToken});

  Future<${PASCAL_NAME}> create({required String name});
}
EOF

# Use Case（用例 — 单一职责的业务编排）
cat > "$BASE_DIR/domain/usecases/get_${FEATURE_NAME}.dart" << EOF
import '../entities/${FEATURE_NAME}.dart';
import '../repositories/${FEATURE_NAME}_repository.dart';

/// 获取 ${PASCAL_NAME} 用例。
///
/// 单一职责：通过仓储获取单个 ${PASCAL_NAME}。
class Get${PASCAL_NAME} {
  const Get${PASCAL_NAME}(this._repository);

  final ${PASCAL_NAME}Repository _repository;

  Future<${PASCAL_NAME}> call(String id) => _repository.getById(id);
}
EOF

# Data Model（DTO — 包含 JSON 序列化、proto 转换等，不依赖 freezed/json_serializable）
cat > "$BASE_DIR/data/models/${FEATURE_NAME}_model.dart" << EOF
import '../../domain/entities/${FEATURE_NAME}.dart';

/// ${PASCAL_NAME} 数据传输对象（DTO）。
/// data 层专用：包含 JSON 序列化、与 proto/RPC 类型转换。
/// 不暴露到 application / presentation 层。
///
/// 不使用 freezed / json_serializable / equatable 以兼容 very_good_cli 默认依赖；
/// 如已添加 freezed 依赖，可改回 freezed 风格。
class ${PASCAL_NAME}Model {
  const ${PASCAL_NAME}Model({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  factory ${PASCAL_NAME}Model.fromJson(Map<String, dynamic> json) =>
      ${PASCAL_NAME}Model(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  /// DTO → Domain Entity。
  ${PASCAL_NAME} toEntity() => ${PASCAL_NAME}(
        id: id,
        name: name,
        createdAt: createdAt,
      );
}

/// Domain Entity → DTO。
${PASCAL_NAME}Model ${FEATURE_NAME}ModelFromEntity(${PASCAL_NAME} entity) =>
    ${PASCAL_NAME}Model(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
    );
EOF

# Data Source（数据源接口 — remote/local）
cat > "$BASE_DIR/data/datasources/${FEATURE_NAME}_remote_datasource.dart" << EOF
import '../models/${FEATURE_NAME}_model.dart';

/// ${PASCAL_NAME} 远程数据源接口。
///
/// 具体实现：gRPC client / Dio HTTP client。
abstract interface class ${PASCAL_NAME}RemoteDataSource {
  Future<${PASCAL_NAME}Model> getById(String id);

  Future<List<${PASCAL_NAME}Model>> list({int pageSize = 20, String? pageToken});

  Future<${PASCAL_NAME}Model> create({required String name});
}
EOF

cat > "$BASE_DIR/data/datasources/${FEATURE_NAME}_local_datasource.dart" << EOF
import '../models/${FEATURE_NAME}_model.dart';

/// ${PASCAL_NAME} 本地数据源接口。
///
/// 具体实现：Drift / Hive / SharedPreferences / secure_storage。
abstract interface class ${PASCAL_NAME}LocalDataSource {
  Future<List<${PASCAL_NAME}Model>> getCachedList();

  Future<void> cacheList(List<${PASCAL_NAME}Model> models);
}
EOF

# Repository Implementation（仓储实现 — 组合 remote + local）
cat > "$BASE_DIR/data/repositories/${FEATURE_NAME}_repository_impl.dart" << EOF
import '../../domain/entities/${FEATURE_NAME}.dart';
import '../../domain/repositories/${FEATURE_NAME}_repository.dart';
import '../datasources/${FEATURE_NAME}_local_datasource.dart';
import '../datasources/${FEATURE_NAME}_remote_datasource.dart';

/// ${PASCAL_NAME} 仓储默认实现：远程优先，本地缓存。
class ${PASCAL_NAME}RepositoryImpl implements ${PASCAL_NAME}Repository {
  const ${PASCAL_NAME}RepositoryImpl({
    required ${PASCAL_NAME}RemoteDataSource remote,
    required ${PASCAL_NAME}LocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final ${PASCAL_NAME}RemoteDataSource _remote;
  final ${PASCAL_NAME}LocalDataSource _local;

  @override
  Future<${PASCAL_NAME}> getById(String id) async {
    final model = await _remote.getById(id);
    return model.toEntity();
  }

  @override
  Future<List<${PASCAL_NAME}>> list({int pageSize = 20, String? pageToken}) async {
    try {
      final models = await _remote.list(
        pageSize: pageSize,
        pageToken: pageToken,
      );
      // 异步缓存，不阻塞返回
      unawaited(_local.cacheList(models));
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      // 降级到本地缓存
      final cached = await _local.getCachedList();
      return cached.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Future<${PASCAL_NAME}> create({required String name}) async {
    final model = await _remote.create(name: name);
    return model.toEntity();
  }
}

/// 抑制 unawaited 警告的 import（Dart 3.0+ 需要）
void unawaited(Future<void> future) {}
EOF

# Application + Presentation + Tests（按 STATE_MGMT 选择模板）
if [ "$STATE_MGMT" = "bloc" ]; then
# Application Cubit（bloc 状态管理）
mkdir -p "$BASE_DIR/application/bloc"
cat > "$BASE_DIR/application/bloc/${FEATURE_NAME}_cubit.dart" << EOF
import 'package:bloc/bloc.dart';

import '../../domain/entities/${FEATURE_NAME}.dart';
import '../../domain/repositories/${FEATURE_NAME}_repository.dart';
import '../../domain/usecases/get_${FEATURE_NAME}.dart';

part '${FEATURE_NAME}_cubit_state.dart';

/// ${PASCAL_NAME} Cubit（bloc 状态管理，兼容 very_good_cli 默认）。
class ${PASCAL_NAME}Cubit extends Cubit<${PASCAL_NAME}State> {
  ${PASCAL_NAME}Cubit({required Get${PASCAL_NAME} get${PASCAL_NAME}})
      : _get${PASCAL_NAME} = get${PASCAL_NAME},
        super(const ${PASCAL_NAME}Initial());

  final Get${PASCAL_NAME} _get${PASCAL_NAME};

  /// 加载 ${PASCAL_NAME}。首次进入页面或下拉刷新时调用。
  Future<void> load() async {
    emit(const ${PASCAL_NAME}Loading());
    try {
      final item = await _get${PASCAL_NAME}.call('');
      emit(${PASCAL_NAME}Loaded(item));
    } catch (e, st) {
      emit(${PASCAL_NAME}Error(e, st));
    }
  }
}
EOF

# Application Cubit State（part of cubit file）
cat > "$BASE_DIR/application/bloc/${FEATURE_NAME}_cubit_state.dart" << EOF
part of '${FEATURE_NAME}_cubit.dart';

/// ${PASCAL_NAME} 状态（sealed class，bloc 风格，不依赖 Equatable/freezed）。
sealed class ${PASCAL_NAME}State {
  const ${PASCAL_NAME}State();
}

final class ${PASCAL_NAME}Initial extends ${PASCAL_NAME}State {
  const ${PASCAL_NAME}Initial();
}

final class ${PASCAL_NAME}Loading extends ${PASCAL_NAME}State {
  const ${PASCAL_NAME}Loading();
}

final class ${PASCAL_NAME}Loaded extends ${PASCAL_NAME}State {
  const ${PASCAL_NAME}Loaded(this.item);
  final ${PASCAL_NAME} item;
}

final class ${PASCAL_NAME}Error extends ${PASCAL_NAME}State {
  const ${PASCAL_NAME}Error(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
EOF

# Presentation Page（bloc 风格：Page + View 分离）
cat > "$BASE_DIR/presentation/pages/${FEATURE_NAME}_page.dart" << EOF
// 如启用 auto_route 路由，取消下一行 import 和类上的 @RoutePage() 注解。
// import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../${FEATURE_NAME}.dart';
import '../../domain/usecases/get_${FEATURE_NAME}.dart';

/// ${PASCAL_NAME} 页面（bloc 风格）。
///
/// 使用前提：在 main.dart 的 MultiRepositoryProvider 中注册 ${PASCAL_NAME}Repository。
// @RoutePage()
class ${PASCAL_NAME}Page extends StatelessWidget {
  const ${PASCAL_NAME}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ${PASCAL_NAME}Cubit(
        get${PASCAL_NAME}: Get${PASCAL_NAME}(context.read<${PASCAL_NAME}Repository>()),
      )..load(),
      child: const ${PASCAL_NAME}View(),
    );
  }
}

/// ${PASCAL_NAME} View（纯 UI，订阅 cubit 状态）。
class ${PASCAL_NAME}View extends StatelessWidget {
  const ${PASCAL_NAME}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${PASCAL_NAME}')),
      body: BlocBuilder<${PASCAL_NAME}Cubit, ${PASCAL_NAME}State>(
        builder: (context, state) => switch (state) {
          ${PASCAL_NAME}Initial() => const Center(
              child: ElevatedButton(
                onPressed: null,
                child: Text('Tap to load'),
              ),
            ),
          ${PASCAL_NAME}Loading() => const Center(
              child: CircularProgressIndicator(),
            ),
          ${PASCAL_NAME}Loaded(:final item) => ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.label),
                  title: Text(item.name),
                  subtitle: Text(item.id),
                ),
              ],
            ),
          ${PASCAL_NAME}Error(:final error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: \$error', textAlign: TextAlign.center),
              ),
            ),
        },
      ),
    );
  }
}
EOF

# Bloc Cubit Test（用 bloc_test）
mkdir -p "test/features/$FEATURE_NAME/application/bloc"
cat > "test/features/$FEATURE_NAME/application/bloc/${FEATURE_NAME}_cubit_test.dart" << EOF
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/application/bloc/${FEATURE_NAME}_cubit.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/entities/${FEATURE_NAME}.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/repositories/${FEATURE_NAME}_repository.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/usecases/get_${FEATURE_NAME}.dart';

class _Mock${PASCAL_NAME}Repository extends Mock implements ${PASCAL_NAME}Repository {}

class _Fake${PASCAL_NAME} extends Fake implements ${PASCAL_NAME} {}

void main() {
  setUpAll(() {
    registerFallbackValue(_Fake${PASCAL_NAME}());
  });

  group('${PASCAL_NAME}Cubit', () {
    late ${PASCAL_NAME}Repository repository;

    setUp(() {
      repository = _Mock${PASCAL_NAME}Repository();
    });

    blocTest<${PASCAL_NAME}Cubit, ${PASCAL_NAME}State>(
      'emits [loading, loaded] when load succeeds',
      build: () => ${PASCAL_NAME}Cubit(get${PASCAL_NAME}: Get${PASCAL_NAME}(repository)),
      setUp: () {
        when(() => repository.getById(any())).thenAnswer(
          (_) async => ${PASCAL_NAME}(
            id: 'test-id',
            name: 'Test',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<${PASCAL_NAME}Loading>(),
        isA<${PASCAL_NAME}Loaded>(),
      ],
    );

    blocTest<${PASCAL_NAME}Cubit, ${PASCAL_NAME}State>(
      'emits [loading, error] when load fails',
      build: () => ${PASCAL_NAME}Cubit(get${PASCAL_NAME}: Get${PASCAL_NAME}(repository)),
      setUp: () {
        when(() => repository.getById(any())).thenThrow(Exception('boom'));
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<${PASCAL_NAME}Loading>(),
        isA<${PASCAL_NAME}Error>(),
      ],
    );
  });
}
EOF

# Bloc Page Widget Test
cat > "test/features/$FEATURE_NAME/presentation/pages/${FEATURE_NAME}_page_test.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/application/bloc/${FEATURE_NAME}_cubit.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/entities/${FEATURE_NAME}.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/repositories/${FEATURE_NAME}_repository.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/usecases/get_${FEATURE_NAME}.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/presentation/pages/${FEATURE_NAME}_page.dart';

class _Mock${PASCAL_NAME}Repository extends Mock implements ${PASCAL_NAME}Repository {}

class _Fake${PASCAL_NAME} extends Fake implements ${PASCAL_NAME} {}

void main() {
  setUpAll(() {
    registerFallbackValue(_Fake${PASCAL_NAME}());
  });

  group('${PASCAL_NAME}Page', () {
    late ${PASCAL_NAME}Repository repository;

    setUp(() {
      repository = _Mock${PASCAL_NAME}Repository();
    });

    Widget buildSubject() {
      return MaterialApp(
        home: RepositoryProvider<${PASCAL_NAME}Repository>.value(
          value: repository,
          child: const ${PASCAL_NAME}Page(),
        ),
      );
    }

    testWidgets('renders loaded view on success', (tester) async {
      when(() => repository.getById(any())).thenAnswer(
        (_) async => ${PASCAL_NAME}(
          id: 'test-id',
          name: 'Test',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders error message on failure', (tester) async {
      when(() => repository.getById(any())).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });
}
EOF

elif [ "$STATE_MGMT" = "riverpod" ]; then
# Application Provider（Riverpod 状态管理）
mkdir -p "$BASE_DIR/application/providers"
cat > "$BASE_DIR/application/providers/${FEATURE_NAME}_provider.dart" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/${FEATURE_NAME}_local_datasource.dart';
import '../../data/datasources/${FEATURE_NAME}_remote_datasource.dart';
import '../../data/repositories/${FEATURE_NAME}_repository_impl.dart';
import '../../domain/entities/${FEATURE_NAME}.dart';
import '../../domain/repositories/${FEATURE_NAME}_repository.dart';
import '../../domain/usecases/get_${FEATURE_NAME}.dart';
import '../states/${FEATURE_NAME}_state.dart';

part '${FEATURE_NAME}_provider.g.dart';

/// 远程数据源 Provider（由 main.dart 在 ProviderScope 启动前 override）。
@Riverpod(keepAlive: true)
${PASCAL_NAME}RemoteDataSource ${FEATURE_NAME}RemoteDataSource(
  ${FEATURE_NAME}RemoteDataSourceRef ref,
) =>
    throw UnimplementedError('Override in main.dart ProviderScope');

/// 本地数据源 Provider。
@Riverpod(keepAlive: true)
${PASCAL_NAME}LocalDataSource ${FEATURE_NAME}LocalDataSource(
  ${PASCAL_NAME}LocalDataSourceRef ref,
) =>
    throw UnimplementedError('Override in main.dart ProviderScope');

/// 仓储 Provider。
@Riverpod(keepAlive: true)
${PASCAL_NAME}Repository ${FEATURE_NAME}Repository(
  ${PASCAL_NAME}RepositoryRef ref,
) =>
    ${PASCAL_NAME}RepositoryImpl(
      remote: ref.watch(${FEATURE_NAME}RemoteDataSourceProvider),
      local: ref.watch(${FEATURE_NAME}LocalDataSourceProvider),
    );

/// Use Case Provider。
@Riverpod(keepAlive: true)
Get${PASCAL_NAME} get${PASCAL_NAME}(Get${PASCAL_NAME}Ref ref) =>
    Get${PASCAL_NAME}(ref.watch(${FEATURE_NAME}RepositoryProvider));

/// ${PASCAL_NAME} 状态 Notifier。
@riverpod
class ${PASCAL_NAME}Notifier extends _\$\$${PASCAL_NAME}Notifier {
  @override
  ${PASCAL_NAME}ListState build() => const ${PASCAL_NAME}ListState.initial();

  Future<void> load() async {
    state = const ${PASCAL_NAME}ListState.loading();
    try {
      final item = await ref.read(get${PASCAL_NAME}Provider).call('');
      state = ${PASCAL_NAME}ListState.loaded(item);
    } catch (e, st) {
      state = ${PASCAL_NAME}ListState.error(e, st);
    }
  }
}
EOF

# Application State（sealed class — freezed union）
cat > "$BASE_DIR/application/states/${FEATURE_NAME}_state.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/${FEATURE_NAME}.dart';

part '${FEATURE_NAME}_state.freezed.dart';

/// ${PASCAL_NAME} 状态（sealed union，Riverpod 风格）。
@freezed
sealed class ${PASCAL_NAME}ListState with _\$\$${PASCAL_NAME}ListState {
  const factory ${PASCAL_NAME}ListState.initial() = ${PASCAL_NAME}ListInitial;

  const factory ${PASCAL_NAME}ListState.loading() = ${PASCAL_NAME}ListLoading;

  const factory ${PASCAL_NAME}ListState.loaded(${PASCAL_NAME} item) =
      ${PASCAL_NAME}ListLoaded;

  const factory ${PASCAL_NAME}ListState.error(Object error, StackTrace stackTrace) =
      ${PASCAL_NAME}ListError;
}
EOF

# Presentation Page（Riverpod 风格）
cat > "$BASE_DIR/presentation/pages/${FEATURE_NAME}_page.dart" << EOF
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../${FEATURE_NAME}.dart';

/// ${PASCAL_NAME} 页面（Riverpod 风格）。
@RoutePage()
class ${PASCAL_NAME}Page extends ConsumerWidget {
  const ${PASCAL_NAME}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${FEATURE_NAME}NotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('${PASCAL_NAME}')),
      body: switch (state) {
        ${PASCAL_NAME}ListInitial() => const Center(
            child: ElevatedButton(
              onPressed: null,
              child: Text('Tap to load'),
            ),
          ),
        ${PASCAL_NAME}ListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        ${PASCAL_NAME}ListLoaded(:final item) => ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.label),
                title: Text(item.name),
                subtitle: Text(item.id),
              ),
            ],
          ),
        ${PASCAL_NAME}ListError(:final error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $error', textAlign: TextAlign.center),
            ),
          ),
      },
    );
  }
}
EOF

# Riverpod Page Widget Test
cat > "test/features/$FEATURE_NAME/presentation/pages/${FEATURE_NAME}_page_test.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/application/providers/${FEATURE_NAME}_provider.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/entities/${FEATURE_NAME}.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/domain/repositories/${FEATURE_NAME}_repository.dart';
import 'package:${PACKAGE_NAME}/features/${FEATURE_NAME}/presentation/pages/${FEATURE_NAME}_page.dart';

class _Mock${PASCAL_NAME}Repository extends Mock implements ${PASCAL_NAME}Repository {}

void main() {
  group('${PASCAL_NAME}Page', () {
    late _Mock${PASCAL_NAME}Repository repository;

    setUp(() {
      repository = _Mock${PASCAL_NAME}Repository();
    });

    Widget buildSubject() {
      return ProviderScope(
        overrides: [
          ${FEATURE_NAME}RepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ${PASCAL_NAME}Page()),
      );
    }

    testWidgets('renders loaded view on success', (tester) async {
      when(() => repository.getById(any())).thenAnswer(
        (_) async => ${PASCAL_NAME}(
          id: 'test-id',
          name: 'Test',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders error message on failure', (tester) async {
      when(() => repository.getById(any())).thenThrow(Exception('boom'));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
    });
  });
}
EOF

else
  echo "Error: unknown STATE_MGMT=$STATE_MGMT" >&2
  exit 1
fi

echo "✓ Created feature '$FEATURE_NAME' at $BASE_DIR"
echo "  ✓ State management: $STATE_MGMT"
echo "  ✓ Domain layer:     entities + repository interface + use cases"
echo "  ✓ Data layer:       models + datasources + repository impl"
if [ "$STATE_MGMT" = "bloc" ]; then
  echo "  ✓ Application:      cubit + sealed states (bloc 风格)"
  echo "  ✓ Tests:            cubit + usecase + widget tests"
else
  echo "  ✓ Application:      providers + sealed unions (riverpod 风格)"
  echo "  ✓ Tests:            page widget test + usecase test"
fi
echo "  ✓ Presentation:     pages (auto_route 注解)"
echo ""
echo "Next steps ($STATE_MGMT 模式):"
echo "  1. 在 main.dart 中注册 ${PASCAL_NAME}Repository"
echo "  2. 实现 ${PASCAL_NAME}RemoteDataSource（gRPC 或 Dio）"
echo "  3. 实现 ${PASCAL_NAME}LocalDataSource（Drift / Hive）"
echo "  4. 注册 ${PASCAL_NAME}Page 到路由表"
if [ "$STATE_MGMT" = "riverpod" ]; then
  echo "  5. 运行 dart run build_runner build 生成 freezed + riverpod 代码"
  echo "  6. 运行 ./tool/check_architecture.sh 校验目录合规"
else
  echo "  5. 运行 ./tool/check_architecture.sh 校验目录合规"
fi
