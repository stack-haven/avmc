---
description: |
  为 Ark Tech Platform 生成基于 very_good_cli + Flutter 官方架构推荐的跨端应用脚手架。
  支持移动端 + 桌面端同源码双产物（Flutter 同源码打 iOS/Android/macOS/Windows/Linux）。

  触发场景：
  - "用 very_good_cli 创建 Flutter 应用" / "新建 Evie Flutter 客户端"
  - "Flutter 官方推荐的 app architecture 怎么落地"
  - "feature-first 目录结构 + 四层架构（data/domain/application/presentation）"
  - "Flutter 应用代码生成（freezed、riverpod_generator、go_router）"
  - "新增业务功能模块（feature）" → 调用 scripts/create_feature.sh
  - "校验 Flutter 项目架构合规" → 调用 scripts/check_architecture.sh

  需要用户提供的输入：产品名、目标端、技术栈版本、状态管理选型（默认 bloc，兼容 very_good_cli）。
name: avmc-flutter-app
---

# Ark Tech Platform Flutter 应用生成

基于 **very_good_cli** 工程哲学和 **Flutter 官方 App Architecture 指南**，为 Ark Tech Platform 多端应用生成标准 Flutter 项目脚手架。

---

## 〇、基础原则（不可妥协）

### very_good_cli 开发哲学

[Very Good Ventures](https://verygood.ventures/) 团队（Flutter 社区顶级工程团队）开发的项目脚手架工具和 lints 规则集，沉淀的核心工程原则：

| 原则 | 含义 | 落地 |
|------|------|------|
| **约定优于配置** | 不发明新的目录约定；统一的项目结构让任何团队成员能快速上手 | `very_good create flutter_app` 生成的目录结构是事实标准，不做修改 |
| **测试是头等公民** | 不是可选，每个 feature 自带 unit + widget test 模板 | `test/features/<name>/` 跟 `lib/features/<name>/` 镜像 |
| **严格 lints** | 比 `flutter_lints` 严格 5-10 倍 | 强制使用 `very_good_analysis`（200+ 规则） |
| **依赖倒置** | 业务侧定义接口（domain/repository），实现侧（data/repository_impl）注入 | abstract interface class |
| **不可变状态** | 所有 model、state 必须不可变（freezed） | `@freezed` 注解 + sealed unions |
| **CI 友好** | 模板内置 GitHub Actions CI，所有脚本可 headless 执行 | `tool/` 目录存放脚本 |
| **一致性** | 跨项目一致的目录、命名、测试结构 | monorepo 内所有 Flutter 应用结构一致 |
| **小步快跑** | 提供 brick（mason 模板）按需引入能力 | `tool/create_feature.sh` 是 brick 模式 |

**关键决策：**

- ✅ **必须使用 very_good_cli 生成项目骨架**（不自己造轮子）
- ✅ **必须使用 very_good_analysis**（禁用 `flutter_lints`）
- ✅ **测试覆盖率门禁 45%**（与 backend-service 对齐）
- ❌ **不修改 very_good_cli 生成的目录结构**（如 `lib/app/`、`tool/`、`integration_test/`）

### Flutter 官方 App Architecture 推荐

来源：[docs.flutter.dev/app-architecture](https://docs.flutter.dev/app-architecture)（Flutter 团队 2024+ 正式推荐）

| 原则 | 含义 | 落地 |
|------|------|------|
| **三层分离** | UI（presentation） / 状态管理（application） / 数据（data） | `presentation/` `application/` `data/` 三目录 |
| **Feature-first** | 按业务功能组织代码，不按技术类型（不要 `lib/models/` `lib/screens/` `lib/services/`） | `lib/features/<feature_name>/` |
| **Repository 模式** | 业务通过接口访问数据，不知道数据来源（remote/local/cache） | `domain/repository/` + `data/repository/` |
| **单向数据流** | UI 触发事件 → state 变化 → UI 自动 rebuild | Riverpod / Provider |
| **不可变数据** | 所有 model、state 不可变，修改时创建新实例 | freezed |
| **错误是数据** | 用 sealed class 表达错误，不是 throw | `@freezed sealed class XxxState` |

**状态管理选型（Ark Tech Platform 决策）：**

| 候选 | 推荐度 | 理由 |
|------|:---:|------|
| **Bloc / Cubit** | ✅ **默认（兼容 very_good_cli）** | very_good_cli 生成项目默认使用；脚本 `create_feature.sh --state-management bloc` |
| **Riverpod 2.x**（含 riverpod_generator） | ✅ **可选高级** | 脚本 `--state-management riverpod`；需手动加 `flutter_riverpod`、`riverpod_annotation`、`freezed_annotation` 等依赖 |
| Provider | ❌ 不推荐 | 已被 Riverpod 取代 |
| GetX | ❌ 禁用 | 反模式，违反 Flutter 官方架构原则 |

**选择建议：**

- **首次项目**：用 bloc（脚本默认，开箱即用，跟 very_good_cli 默认一致）
- **新项目，需要强类型、编译期安全**：切到 riverpod（脚本 `--state-management riverpod`，需先手动加依赖）

---

## 一、项目初始化

### 1.1 安装 very_good_cli

```bash
# 标准安装
dart pub global activate very_good_cli

# 验证（应输出 very_good_cli X.Y.Z）
very_good --version
```

如果遇到 "Kernel binary format version" 错误，说明 Dart SDK 与 very_good_cli 版本不匹配：
- 重新 `dart pub global activate very_good_cli` 重装
- 或使用 FVM（Flutter Version Management）固定 Flutter 版本

### 1.2 生成应用骨架

```bash
# 进入 mobile-desktop-service 子仓库
cd mobile-desktop-service/apps

# 生成 Flutter 应用（注意：org 与 backend-service 对齐）
very_good create flutter_app evie_mobile \
  --description "Evie Mobile - Ark Tech Platform (Ark Product Service)" \
  --org com.stackhaven.avmc
```

**参数说明：**

| 参数 | 必填 | 说明 | 默认值 |
|------|:---:|------|--------|
| 应用名 | ✅ | snake_case，跟 `<product>-<platform>` 命名一致 | — |
| `--description` | ✅ | 应用描述，出现在 pubspec.yaml 和 About 对话框 | — |
| `--org` | ✅ | 组织域，反向生成包名（如 `com.stackhaven.avmc.evie_mobile`） | — |
| `--platforms` | ❌ | 目标平台（逗号分隔） | `android,ios` |
| `--template` | ❌ | 脚手架模板（默认 `flutter_app`） | `flutter_app` |

**生成的项目结构（不要修改）：**

```
evie_mobile/
├── android/                    # Android 工程（very_good_cli 生成）
├── ios/                        # iOS 工程
├── lib/                        # 源代码（重点维护）
│   ├── app/                    # 应用核心（不修改）
│   │   ├── app.dart            # MyApp widget
│   │   └── view/
│   ├── bootstrap.dart          # 启动入口（错误处理、observability）
│   ├── counter/                # 默认 feature（删除）
│   ├── l10n/                   # 国际化（默认）
│   └── main.dart               # 程序入口
├── test/                       # 镜像 lib/ 结构
│   ├── app/
│   ├── counter/                # 默认 feature 的测试（删除）
│   ├── helpers/                # 测试辅助
│   └── ...
├── tool/                       # ✅ 自定义脚本放这里（git tracked）
│   ├── create_feature.sh       # [本 skill 内置] 创建 feature 骨架
│   ├── check_architecture.sh   # [本 skill 内置] 架构合规检查
│   ├── gen_proto.sh            # [本 skill 内置] proto → Dart 生成
│   └── pre_commit.sh           # [本 skill 内置] 提交前检查
├── integration_test/           # 集成测试（very_good_cli 生成）
├── analysis_options.yaml       # ✅ 必须包含 very_good_analysis
├── pubspec.yaml                # 依赖配置
├── README.md
└── .gitignore
```

### 1.3 替换默认依赖（适配 Ark Tech Platform 决策）

```yaml
# pubspec.yaml

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

  # ===== Ark Tech Platform 强制依赖 =====
  # 状态管理（Flutter 官方推荐）
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 路由
  go_router: ^14.0.0          # 单 app 路由
  auto_route: ^9.2.0          # 多 page 路由（带注解）

  # 数据建模（不可变 + sealed unions）
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # API 客户端（与 backend-service gRPC 对接）
  grpc: ^3.2.4
  protobuf: ^3.1.0
  # REST 备用
  dio: ^5.4.0

  # 安全存储
  flutter_secure_storage: ^9.2.2

  # 日志
  logger: ^2.0.2+1

  # 多端条件编译
  universal_platform: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # ===== Ark Tech Platform 强制 lints（替代 flutter_lints） =====
  very_good_analysis: ^6.0.0   # ← 关键：替代 flutter_lints

  # 代码生成器
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10

  # 测试
  mocktail: ^1.0.3             # 替代 mockito（无代码生成）
  bloc_test: ^9.1.7            # 保留以备 Bloc 场景
  very_good_test_runner: ^0.3.0  # very_good_cli 测试增强
```

```yaml
# analysis_options.yaml

# ✅ 强制：使用 very_good_analysis（替代 flutter_lints）
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - lib/generated/**          # proto 生成代码免检
    - "**/*.g.dart"             # 代码生成器产物
    - "**/*.freezed.dart"
    - "**/*.pb.dart"
    - "**/*.pbgrpc.dart"
  errors:
    invalid_annotation_target: ignore  # riverpod_generator 注解需要

linter:
  rules:
    # Ark Tech Platform 额外规则（与 very_good_analysis 配合）
    public_member_api_docs: true       # public API 必须有文档注释
    prefer_single_quotes: true
    sort_constructors_first: true
    sort_pub_dependencies: false       # very_good_analysis 已处理
```

### 1.4 注入本 skill 内置脚本

```bash
# 复制本 skill 的脚本到项目 tool/ 目录
cp -r <skill_dir>/scripts/* tool/
chmod +x tool/*.sh
```

---

## 二、Feature-first + 四层架构

### 2.1 目录结构标准

每个业务功能（feature）必须严格按以下结构组织：

```
lib/features/<feature_name>/
├── <feature_name>.dart              # ✅ barrel file（对外唯一入口）
├── data/                            # 数据层
│   ├── datasources/                 # 数据源接口（remote/local）
│   │   ├── <name>_remote_datasource.dart
│   │   └── <name>_local_datasource.dart
│   ├── models/                      # DTO（可序列化）
│   │   └── <name>_model.dart
│   └── repositories/                # 仓储实现
│       └── <name>_repository_impl.dart
├── domain/                          # 领域层（业务核心）
│   ├── entities/                    # 业务实体（不可变）
│   │   └── <name>.dart
│   ├── repositories/                # 仓储接口（abstract）
│   │   └── <name>_repository.dart
│   └── usecases/                    # 用例（单一职责）
│       └── get_<name>.dart
├── application/                     # 应用层（状态管理）
│   ├── providers/                   # Riverpod providers
│   │   └── <name>_provider.dart
│   └── states/                      # sealed state unions
│       └── <name>_state.dart
└── presentation/                    # UI 层
    ├── pages/                       # 页面（auto_route 注解）
    │   └── <name>_page.dart
    └── widgets/                     # 复用 widget
        └── <name>_card.dart
```

**镜像测试结构（与 lib/features/ 一一对应）：**

```
test/features/<feature_name>/
├── data/
│   ├── datasources/                 # 远端数据源测试
│   └── repository/                  # 仓储测试
├── domain/
│   └── usecases/                    # 用例测试
├── application/                     # 状态管理测试
└── presentation/
    ├── pages/                       # 页面 widget 测试
    └── widgets/                     # widget 单元测试
```

### 2.2 依赖方向（强制单向）

```
presentation  →  application  →  domain  ←  data
       ↓              ↓             ↑         ↑
     （页面）      （providers）   （接口）  （实现）
```

| 层 | 允许依赖 | 禁止依赖 |
|----|---------|---------|
| **presentation** | application, domain, core | data, package:flutter/material 之外的具体 UI 库 |
| **application** | domain, core | presentation, data（不知道数据来源） |
| **domain** | core（仅 entity + 第三方基础库如 freezed） | application, presentation, data |
| **data** | domain（实现接口）, core | application, presentation |

**自动化校验：** `./tool/check_architecture.sh` 检测跨层非法依赖。

### 2.3 创建新 feature（一行命令）

```bash
./tool/create_feature.sh vocab
# 输出完整四层骨架 + barrel file + 测试模板
```

**脚本行为：**

1. 创建目录树（10 个子目录 + 镜像 test 目录）
2. 生成 boilerplate 代码：
   - `<feature>.dart`（barrel file）
   - `domain/entities/<feature>.dart`（freezed 实体）
   - `domain/repositories/<feature>_repository.dart`（abstract interface）
   - `domain/usecases/get_<feature>.dart`（用例）
   - `data/models/<feature>_model.dart`（DTO + JSON）
   - `data/datasources/<feature>_{remote,local}_datasource.dart`（接口）
   - `data/repositories/<feature>_repository_impl.dart`（默认实现：远程优先 + 本地缓存降级）
   - `application/providers/<feature>_provider.dart`（Riverpod 注解）
   - `application/states/<feature>_state.dart`（sealed union）
   - `presentation/pages/<feature>_page.dart`（auto_route 注解）
3. 生成测试模板：
   - `test/features/<feature>/domain/usecases/get_<feature>_test.dart`（mocktail）
   - `test/features/<feature>/presentation/pages/<feature>_page_test.dart`

**macOS BSD sed 兼容性已处理：** PascalCase 转换使用 awk（macOS + Linux 通用）。

### 2.4 校验架构合规

```bash
./tool/check_architecture.sh
```

**校验项：**

| Check | 内容 |
|-------|------|
| 1 | 每个 feature 必须有完整的 10 个子目录 + barrel file |
| 2 | 跨层非法依赖（domain → data、application → presentation 等） |
| 3 | 每个 feature 必须有 `test/features/<name>/` 镜像 |
| 4 | `analysis_options.yaml` 必须包含 `very_good_analysis` |

CI 必跑该脚本，发现违规立即失败。

---

## 三、状态管理（Riverpod 模式）

### 3.1 层级职责

| 层 | 组件 | 职责 |
|----|------|------|
| 应用层 | `@Riverpod` providers | 暴露数据给 UI |
| 应用层 | `@riverpod class XxxNotifier extends _$XxxNotifier` | 状态变更 |
| 应用层 | `@freezed sealed class XxxState` | 状态定义（sealed union） |
| UI 层 | `ConsumerWidget` | 订阅状态、派发事件 |

### 3.2 Provider 命名规范

| 角色 | 命名 | 示例 |
|------|------|------|
| 数据源 | `<feature>RemoteDataSource` | `vocabRemoteDataSource` |
| 仓储 | `<feature>Repository` | `vocabRepository` |
| 用例 | `get<Feature>` / `list<Feature>s` | `getVocab` / `listVocabs` |
| Notifier | `<Feature>List` / `<Feature>Detail` | `VocabList` |
| State | `<Feature>ListState` | `VocabListState` |

**ref 类型后缀由 riverpod_generator 自动推导：**

```dart
@riverpod
VocabRepository vocabRepository(VocabRepositoryRef ref) => ...;
//                                       ^^^^^^^^^^^^^^^^^^ 自动推导
```

### 3.3 Sealed State（freezed union）

```dart
// application/states/vocab_list_state.dart
@freezed
sealed class VocabListState with _$VocabListState {
  const factory VocabListState.initial() = VocabListInitial;
  const factory VocabListState.loading() = VocabListStateLoading;
  const factory VocabListState.loaded(List<Vocab> items) = VocabListLoaded;
  const factory VocabListState.error(Object error, StackTrace stackTrace) =
      VocabListError;
}
```

### 3.4 Notifier + UI 切换（switch expression）

```dart
// presentation/pages/vocab_page.dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(vocabListProvider);
  return switch (state) {
    VocabListInitial() => const SizedBox.shrink(),
    VocabListLoading() => const Center(child: CircularProgressIndicator()),
    VocabListLoaded(:final items) => ListView.builder(...),
    VocabListError(:final error) => Center(child: Text('Error: $error')),
  };
}
```

---

## 四、数据层集成

### 4.1 与 backend-service gRPC 对接

```bash
# 1. 确保 backend-service proto 与 buf 配置就绪
ls ../../../backend-service/proto
ls tooling/codegen/buf-gen-dart.yaml

# 2. 生成 Dart 客户端
./tool/gen_proto.sh
# 输出到 lib/generated/<service>/<version>/*.pbgrpc.dart
```

**buf-gen-dart.yaml 模板（放在 `tooling/codegen/`）：**

```yaml
version: v1
plugins:
  - plugin: buf.build/protocolbuffers/dart
    out: lib/generated
  - plugin: buf.build/grpc/dart:v1
    out: lib/generated
```

### 4.2 gRPC 客户端封装

```dart
// lib/core/network/grpc_client.dart
class GrpcClient {
  late final ClientChannel _channel;
  String? _accessToken;

  GrpcClient({required String host, required int port}) {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.secure()),
    );
  }

  void setAccessToken(String? token) => _accessToken = token;

  CallOptions authOptions() => CallOptions(
    metadata: _accessToken != null
        ? {'authorization': 'Bearer $_accessToken'}
        : const {},
  );

  Future<void> shutdown() => _channel.shutdown();
}
```

```dart
// lib/features/vocab/data/datasources/vocab_remote_datasource.dart（实现）
class VocabRemoteDataSourceImpl implements VocabRemoteDataSource {
  VocabRemoteDataSourceImpl(this._client, this._channel);

  final GrpcClient _client;
  // 由 gen_proto 生成
  final DictionaryServiceClient get _stub =>
      DictionaryServiceClient(_channel);

  @override
  Future<VocabModel> getById(String id) async {
    final response = await _stub.getWord(
      GetWordRequest()..id = id,
      options: _client.authOptions(),
    );
    return VocabModel.fromProto(response);
  }
}
```

### 4.3 仓储实现：远程优先 + 本地缓存降级

```dart
// data/repositories/vocab_repository_impl.dart
class VocabRepositoryImpl implements VocabRepository {
  const VocabRepositoryImpl({
    required VocabRemoteDataSource remote,
    required VocabLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final VocabRemoteDataSource _remote;
  final VocabLocalDataSource _local;

  @override
  Future<List<Vocab>> list({int pageSize = 20, String? pageToken}) async {
    try {
      final models = await _remote.list(pageSize: pageSize, pageToken: pageToken);
      unawaited(_local.cacheList(models));  // 异步缓存
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      // 网络失败降级到本地缓存
      final cached = await _local.getCachedList();
      return cached.map((m) => m.toEntity()).toList();
    }
  }
}
```

---

## 五、路由（auto_route + go_router 混合）

### 5.1 全局路由（go_router）

用于简单的 shell route、auth 守卫、deep link：

```dart
// lib/app/routing/app_router.dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: VocabListRoute.page),
    AutoRoute(page: VocabDetailRoute.page),
  ];
}
```

### 5.2 Feature 内部（auto_route 注解）

```dart
// presentation/pages/vocab_page.dart
@RoutePage()
class VocabPage extends ConsumerWidget { ... }
```

### 5.3 路由生成

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 六、认证与多租户

### 6.1 Token 存储

```dart
// lib/core/auth/token_storage.dart
class TokenStorage {
  const TokenStorage(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  Future<String?> getAccessToken() => _secureStorage.read(key: _keyAccess);
  Future<String?> getRefreshToken() => _secureStorage.read(key: _keyRefresh);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _secureStorage.write(key: _keyAccess, value: access);
    await _secureStorage.write(key: _keyRefresh, value: refresh);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _keyAccess);
    await _secureStorage.delete(key: _keyRefresh);
  }
}
```

### 6.2 401 自动刷新

```dart
// lib/core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, this._refresh);

  final TokenStorage _tokenStorage;
  final Future<bool> Function() _refresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _refresh();
      if (refreshed) {
        // 重试原请求
        final retryResponse = await Dio().fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      }
    }
    handler.next(err);
  }
}
```

### 6.3 多租户原则

- ✅ `tenant_id` 从 JWT claims 提取
- ❌ 不接受客户端传入 `tenant_id`
- ❌ 不在本地维护租户表

---

## 七、测试策略

### 7.1 三层测试金字塔

| 层级 | 工具 | 目标覆盖率 | 范围 |
|------|------|:---:|------|
| Unit | `flutter test` + `mocktail` | 70% | domain, application, data |
| Widget | `flutter test` | 20% | presentation widgets + pages |
| Integration | `integration_test` | 10% | 关键流程（登录 → 列表 → 详情） |

### 7.2 Mock 规范

- ✅ **使用 mocktail**（无代码生成，类型安全）
- ❌ 不使用 mockito（需要 build_runner）
- ❌ 不使用真实网络调用（测试用 InMemoryDataSource）

```dart
// test/features/vocab/domain/usecases/get_vocab_test.dart
class _MockVocabRepository extends Mock implements VocabRepository {}

void main() {
  group('GetVocab', () {
    late VocabRepository repository;
    late GetVocab useCase;

    setUp(() {
      repository = _MockVocabRepository();
      useCase = GetVocab(repository);
    });

    test('returns entity when repository succeeds', () async {
      final entity = Vocab(
        id: 'test-id',
        name: 'test',
        createdAt: DateTime(2026, 1, 1),
      );
      when(() => repository.getById('test-id')).thenAnswer((_) async => entity);

      final result = await useCase('test-id');

      expect(result, equals(entity));
      verify(() => repository.getById('test-id')).called(1);
    });
  });
}
```

### 7.3 CI 测试与覆盖率门禁

```bash
./tool/pre_commit.sh    # 跑全部检查：format + analyze + test + coverage + architecture
```

门禁：覆盖率 ≥ 45%（与 backend-service 对齐）。

---

## 八、桌面端扩展

### 8.1 同源码双产物原则

移动端 (`apps/evie-mobile/`) 和桌面端 (`apps/evie-desktop/`) 共享同一份 Dart 业务代码，但：

- 不同的 `main.dart` 入口
- 不同的 `bootstrap.dart`（桌面端不需要错误上报 SDK）
- 不同的窗口配置（桌面端用 `bitsdojo_window` 或 `window_manager`）

### 8.2 桌面端特有配置

```yaml
# apps/evie-desktop/pubspec.yaml（与 evie-mobile 几乎相同）
dependencies:
  window_manager: ^0.3.5     # 桌面窗口管理
  bitsdojo_window: ^0.1.6    # 自定义窗口装饰
  system_tray: ^2.0.3        # 系统托盘
  file_picker: ^8.0.0        # 文件选择器
  universal_platform: ^1.0.0 # 平台判断
```

### 8.3 平台条件编译

```dart
import 'package:universal_platform/universal_platform.dart';

class FileOperations {
  Future<void> openFile(String path) async {
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) {
      await _openInApp(path);  // 移动端：应用内预览
    } else if (UniversalPlatform.isMacOS || UniversalPlatform.isWindows) {
      await _openInDesktopApp(path);  // 桌面端：系统应用打开
    }
  }
}
```

### 8.4 桌面端不能用的 API

- ❌ `flutter_secure_storage`（macOS Keychain 部分场景失效）
- ❌ 传感器、加速度计、陀螺仪
- ❌ 相机（需要 macOS 权限配置）
- ❌ 推送通知（用系统通知替代）
- ❌ 应用内购买（用 Stripe 替代）

---

## 九、CI/CD

### 9.1 GitHub Actions 配置（very_good_cli 内置）

very_good_cli 生成的项目自带 `.github/workflows/main.yaml`，需修改为 Ark Tech Platform 标准：

```yaml
# .github/workflows/main.yaml
name: Evie Mobile CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: ./tool/pre_commit.sh  # 全部检查

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/checkout@v4
        with:
          repository: stack-haven/avmc-mobile-desktop-service
          path: monorepo
      - run: |
          cd monorepo/apps/evie-mobile
          flutter build apk --release
          flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: monorepo/apps/evie-mobile/build/app/outputs/

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          cd monorepo/apps/evie-mobile
          flutter build ios --release --no-codesign

  build-desktop:
    needs: test
    strategy:
      matrix: { os: [macos-latest, windows-latest, ubuntu-latest] }
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - run: |
          cd monorepo/apps/evie-desktop
          flutter build macos --release   # 或 windows / linux
```

### 9.2 发布前检查清单

- [ ] `./tool/pre_commit.sh` 全绿
- [ ] 版本号在 `pubspec.yaml` 中递增
- [ ] `CHANGELOG.md` 更新
- [ ] iOS Info.plist 权限说明补全
- [ ] Android AndroidManifest 权限最小化
- [ ] macOS entitlements 最小化
- [ ] 密钥不在代码中

---

## 十、持续演进

### 10.1 添加新 feature

```bash
# 1. 生成骨架
./tool/create_feature.sh text_enhancement

# 2. 编写代码
#    - domain/entities/text_enhancement.dart（freezed）
#    - domain/repositories/text_enhancement_repository.dart（接口）
#    - data/datasources/text_enhancement_remote_datasource.dart（实现）
#    - data/repositories/text_enhancement_repository_impl.dart
#    - application/providers/text_enhancement_provider.dart
#    - presentation/pages/text_enhancement_page.dart

# 3. 生成代码（freezed + riverpod_generator + auto_route）
dart run build_runner build --delete-conflicting-outputs

# 4. 校验架构
./tool/check_architecture.sh

# 5. 写测试
#    - test/features/text_enhancement/domain/usecases/
#    - test/features/text_enhancement/presentation/

# 6. 跑全部检查
./tool/pre_commit.sh
```

### 10.2 修改现有 feature

1. 先读 `<feature>.dart`（barrel file）了解对外接口
2. 修改对应层的文件（严格按依赖方向）
3. 更新测试
4. 跑 `./tool/pre_commit.sh`

### 10.3 升级依赖

```bash
# 查看可升级
flutter pub outdated

# 升级 non-breaking
flutter pub upgrade --major-versions

# 必须同步修改
# - analysis_options.yaml（如升级 very_good_analysis）
# - scripts/*.sh（如 API 变更）
```

### 10.4 故障排查

| 现象 | 排查 |
|------|------|
| `flutter analyze` 大量 very_good_analysis 错误 | 检查 `analysis_options.yaml` 是否 include very_good_analysis |
| `dart run build_runner` 冲突 | 加 `--delete-conflicting-outputs` |
| Riverpod provider 类型错误 | 检查 `riverpod_lint` 是否安装、`custom_lint` 是否配置 |
| gRPC 连接失败 | 检查 TLS 配置（生产必须 secure） |
| macOS 桌面端 `flutter_secure_storage` 失败 | 改用 `flutter_keychain` 或回退到 `shared_preferences`（加密后存储） |

---

## 十一、内置脚本速查

| 脚本 | 用途 | 调用时机 |
|------|------|----------|
| `tool/create_feature.sh` | 生成 feature 完整骨架（10 个目录 + 8 个 dart 文件 + 2 个 test） | 新增 feature |
| `tool/check_architecture.sh` | 校验四层架构 + 跨层依赖 + very_good_analysis 启用 | pre-commit / CI |
| `tool/gen_proto.sh` | backend-service/proto → Dart 客户端生成 | proto 变更后 |
| `tool/pre_commit.sh` | format + analyze + test + coverage + architecture（一体化） | pre-commit / CI |

**详细用法见各脚本头部注释。**

---

## 十二、与其他端的关系

| 端 | skill | 共享代码 |
|----|-------|----------|
| React Native | `avmc-react-native-app` | `mobile-desktop-service/packages/api-client/`（TS） |
| uni-app | `avmc-uniapp-app` | 同上 |
| Web | `avmc-frontend-page`（frontend-service） | 无（Vue 生态独立） |

**API 客户端生成原则：**

- Flutter 应用使用 Dart gRPC 客户端（生成到 `lib/generated/`）
- TypeScript 应用（RN / uni-app）使用 TS 客户端（生成到 `packages/api-client/`）
- 两者都从同一个 `backend-service/proto/` 源生成，契约一致

---

## 十三、相关文档

- 整体规范：`avmc-mobile-desktop-monorepo`
- React Native 项目：`avmc-react-native-app`
- uni-app 项目：`avmc-uniapp-app`
- very_good_cli：https://cli.vgv.dev.co/
- Flutter 官方架构：https://docs.flutter.dev/app-architecture
- Riverpod：https://riverpod.dev/
- Freezed：https://pub.dev/packages/freezed
- Ark Tech Platform API 契约：`docs/architecture/3-0-跨领域-API边界与通信契约.md`
