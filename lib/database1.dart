import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// 声明生成的文件名（运行 build_runner 后自动生成）
part 'database.g.dart';

// 1. 设置表
class Settings extends Table {
  TextColumn get key => text()();        // 键名
  TextColumn get value => text()();      // 键值

  @override
  Set<Column> get primaryKey => {key};   // 指定键名为主键
}

// 2. 订阅表
class Feeds extends Table {
  TextColumn get feedUrl => text()();     // 订阅链接
  TextColumn get siteUrl => text()();     // 网站链接
  TextColumn get title => text()();       // 显示名
  TextColumn get category => text()();    // 分组名
  TextColumn get iconUrl => text()();     // 图标链接
  TextColumn get lastUpdated => text()(); // 上次更新时间戳
  TextColumn get displayMode => text()(); // 显示模式

  @override
  Set<Column> get primaryKey => {feedUrl}; // 指定订阅链接为主键
}

// 3. 内容表
class Articles extends Table {
  TextColumn get guid => text()();        // guid
  TextColumn get title => text()();       // 标题
  TextColumn get feedUrl => text()();     // 所属订阅
  TextColumn get link => text()();        // 网页链接
  TextColumn get description => text()(); // 描述
  TextColumn get content => text()();     // 内容
  TextColumn get enclosure => text()();       // 媒体
  TextColumn get author => text()();      // 作者
  TextColumn get date => text()();        // 日期
  TextColumn get isRead => text()();      // 是否已读

  @override
  Set<Column> get primaryKey => {guid};   // 指定guid为主键
}

// 4. 数据库实例类
@DriftDatabase(tables: [Settings, Feeds, Articles])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// 5. 物理存储连接配置（Android 端）
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rss_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}