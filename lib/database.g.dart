// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedsTable extends Feeds with TableInfo<$FeedsTable, Feed> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteUrlMeta = const VerificationMeta(
    'siteUrl',
  );
  @override
  late final GeneratedColumn<String> siteUrl = GeneratedColumn<String>(
    'site_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<String> lastUpdated = GeneratedColumn<String>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0'),
  );
  static const VerificationMeta _displayModeMeta = const VerificationMeta(
    'displayMode',
  );
  @override
  late final GeneratedColumn<String> displayMode = GeneratedColumn<String>(
    'display_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    feedUrl,
    siteUrl,
    title,
    category,
    iconUrl,
    lastUpdated,
    displayMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feeds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Feed> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('site_url')) {
      context.handle(
        _siteUrlMeta,
        siteUrl.isAcceptableOrUnknown(data['site_url']!, _siteUrlMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('display_mode')) {
      context.handle(
        _displayModeMeta,
        displayMode.isAcceptableOrUnknown(
          data['display_mode']!,
          _displayModeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {feedUrl};
  @override
  Feed map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Feed(
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      )!,
      siteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated'],
      )!,
      displayMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_mode'],
      )!,
    );
  }

  @override
  $FeedsTable createAlias(String alias) {
    return $FeedsTable(attachedDatabase, alias);
  }
}

class Feed extends DataClass implements Insertable<Feed> {
  final String feedUrl;
  final String siteUrl;
  final String title;
  final String category;
  final String iconUrl;
  final String lastUpdated;
  final String displayMode;
  const Feed({
    required this.feedUrl,
    required this.siteUrl,
    required this.title,
    required this.category,
    required this.iconUrl,
    required this.lastUpdated,
    required this.displayMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feed_url'] = Variable<String>(feedUrl);
    map['site_url'] = Variable<String>(siteUrl);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['icon_url'] = Variable<String>(iconUrl);
    map['last_updated'] = Variable<String>(lastUpdated);
    map['display_mode'] = Variable<String>(displayMode);
    return map;
  }

  FeedsCompanion toCompanion(bool nullToAbsent) {
    return FeedsCompanion(
      feedUrl: Value(feedUrl),
      siteUrl: Value(siteUrl),
      title: Value(title),
      category: Value(category),
      iconUrl: Value(iconUrl),
      lastUpdated: Value(lastUpdated),
      displayMode: Value(displayMode),
    );
  }

  factory Feed.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Feed(
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      siteUrl: serializer.fromJson<String>(json['siteUrl']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      iconUrl: serializer.fromJson<String>(json['iconUrl']),
      lastUpdated: serializer.fromJson<String>(json['lastUpdated']),
      displayMode: serializer.fromJson<String>(json['displayMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'feedUrl': serializer.toJson<String>(feedUrl),
      'siteUrl': serializer.toJson<String>(siteUrl),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'iconUrl': serializer.toJson<String>(iconUrl),
      'lastUpdated': serializer.toJson<String>(lastUpdated),
      'displayMode': serializer.toJson<String>(displayMode),
    };
  }

  Feed copyWith({
    String? feedUrl,
    String? siteUrl,
    String? title,
    String? category,
    String? iconUrl,
    String? lastUpdated,
    String? displayMode,
  }) => Feed(
    feedUrl: feedUrl ?? this.feedUrl,
    siteUrl: siteUrl ?? this.siteUrl,
    title: title ?? this.title,
    category: category ?? this.category,
    iconUrl: iconUrl ?? this.iconUrl,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    displayMode: displayMode ?? this.displayMode,
  );
  Feed copyWithCompanion(FeedsCompanion data) {
    return Feed(
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      siteUrl: data.siteUrl.present ? data.siteUrl.value : this.siteUrl,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      displayMode: data.displayMode.present
          ? data.displayMode.value
          : this.displayMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Feed(')
          ..write('feedUrl: $feedUrl, ')
          ..write('siteUrl: $siteUrl, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('displayMode: $displayMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    feedUrl,
    siteUrl,
    title,
    category,
    iconUrl,
    lastUpdated,
    displayMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Feed &&
          other.feedUrl == this.feedUrl &&
          other.siteUrl == this.siteUrl &&
          other.title == this.title &&
          other.category == this.category &&
          other.iconUrl == this.iconUrl &&
          other.lastUpdated == this.lastUpdated &&
          other.displayMode == this.displayMode);
}

class FeedsCompanion extends UpdateCompanion<Feed> {
  final Value<String> feedUrl;
  final Value<String> siteUrl;
  final Value<String> title;
  final Value<String> category;
  final Value<String> iconUrl;
  final Value<String> lastUpdated;
  final Value<String> displayMode;
  final Value<int> rowid;
  const FeedsCompanion({
    this.feedUrl = const Value.absent(),
    this.siteUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.displayMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedsCompanion.insert({
    required String feedUrl,
    this.siteUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.displayMode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : feedUrl = Value(feedUrl);
  static Insertable<Feed> custom({
    Expression<String>? feedUrl,
    Expression<String>? siteUrl,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? iconUrl,
    Expression<String>? lastUpdated,
    Expression<String>? displayMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (feedUrl != null) 'feed_url': feedUrl,
      if (siteUrl != null) 'site_url': siteUrl,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (displayMode != null) 'display_mode': displayMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedsCompanion copyWith({
    Value<String>? feedUrl,
    Value<String>? siteUrl,
    Value<String>? title,
    Value<String>? category,
    Value<String>? iconUrl,
    Value<String>? lastUpdated,
    Value<String>? displayMode,
    Value<int>? rowid,
  }) {
    return FeedsCompanion(
      feedUrl: feedUrl ?? this.feedUrl,
      siteUrl: siteUrl ?? this.siteUrl,
      title: title ?? this.title,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      displayMode: displayMode ?? this.displayMode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (siteUrl.present) {
      map['site_url'] = Variable<String>(siteUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<String>(lastUpdated.value);
    }
    if (displayMode.present) {
      map['display_mode'] = Variable<String>(displayMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedsCompanion(')
          ..write('feedUrl: $feedUrl, ')
          ..write('siteUrl: $siteUrl, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('displayMode: $displayMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArticlesTable extends Articles with TableInfo<$ArticlesTable, Article> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enclosureMeta = const VerificationMeta(
    'enclosure',
  );
  @override
  late final GeneratedColumn<String> enclosure = GeneratedColumn<String>(
    'enclosure',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    title,
    feedUrl,
    link,
    description,
    content,
    enclosure,
    author,
    date,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Article> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('enclosure')) {
      context.handle(
        _enclosureMeta,
        enclosure.isAcceptableOrUnknown(data['enclosure']!, _enclosureMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  Article map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Article(
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      feedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_url'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      enclosure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}enclosure'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ArticlesTable createAlias(String alias) {
    return $ArticlesTable(attachedDatabase, alias);
  }
}

class Article extends DataClass implements Insertable<Article> {
  final String guid;
  final String title;
  final String feedUrl;
  final String link;
  final String description;
  final String content;
  final String enclosure;
  final String author;
  final String date;
  final String status;
  const Article({
    required this.guid,
    required this.title,
    required this.feedUrl,
    required this.link,
    required this.description,
    required this.content,
    required this.enclosure,
    required this.author,
    required this.date,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    map['title'] = Variable<String>(title);
    map['feed_url'] = Variable<String>(feedUrl);
    map['link'] = Variable<String>(link);
    map['description'] = Variable<String>(description);
    map['content'] = Variable<String>(content);
    map['enclosure'] = Variable<String>(enclosure);
    map['author'] = Variable<String>(author);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    return map;
  }

  ArticlesCompanion toCompanion(bool nullToAbsent) {
    return ArticlesCompanion(
      guid: Value(guid),
      title: Value(title),
      feedUrl: Value(feedUrl),
      link: Value(link),
      description: Value(description),
      content: Value(content),
      enclosure: Value(enclosure),
      author: Value(author),
      date: Value(date),
      status: Value(status),
    );
  }

  factory Article.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Article(
      guid: serializer.fromJson<String>(json['guid']),
      title: serializer.fromJson<String>(json['title']),
      feedUrl: serializer.fromJson<String>(json['feedUrl']),
      link: serializer.fromJson<String>(json['link']),
      description: serializer.fromJson<String>(json['description']),
      content: serializer.fromJson<String>(json['content']),
      enclosure: serializer.fromJson<String>(json['enclosure']),
      author: serializer.fromJson<String>(json['author']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'title': serializer.toJson<String>(title),
      'feedUrl': serializer.toJson<String>(feedUrl),
      'link': serializer.toJson<String>(link),
      'description': serializer.toJson<String>(description),
      'content': serializer.toJson<String>(content),
      'enclosure': serializer.toJson<String>(enclosure),
      'author': serializer.toJson<String>(author),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
    };
  }

  Article copyWith({
    String? guid,
    String? title,
    String? feedUrl,
    String? link,
    String? description,
    String? content,
    String? enclosure,
    String? author,
    String? date,
    String? status,
  }) => Article(
    guid: guid ?? this.guid,
    title: title ?? this.title,
    feedUrl: feedUrl ?? this.feedUrl,
    link: link ?? this.link,
    description: description ?? this.description,
    content: content ?? this.content,
    enclosure: enclosure ?? this.enclosure,
    author: author ?? this.author,
    date: date ?? this.date,
    status: status ?? this.status,
  );
  Article copyWithCompanion(ArticlesCompanion data) {
    return Article(
      guid: data.guid.present ? data.guid.value : this.guid,
      title: data.title.present ? data.title.value : this.title,
      feedUrl: data.feedUrl.present ? data.feedUrl.value : this.feedUrl,
      link: data.link.present ? data.link.value : this.link,
      description: data.description.present
          ? data.description.value
          : this.description,
      content: data.content.present ? data.content.value : this.content,
      enclosure: data.enclosure.present ? data.enclosure.value : this.enclosure,
      author: data.author.present ? data.author.value : this.author,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Article(')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('link: $link, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('enclosure: $enclosure, ')
          ..write('author: $author, ')
          ..write('date: $date, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    guid,
    title,
    feedUrl,
    link,
    description,
    content,
    enclosure,
    author,
    date,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Article &&
          other.guid == this.guid &&
          other.title == this.title &&
          other.feedUrl == this.feedUrl &&
          other.link == this.link &&
          other.description == this.description &&
          other.content == this.content &&
          other.enclosure == this.enclosure &&
          other.author == this.author &&
          other.date == this.date &&
          other.status == this.status);
}

class ArticlesCompanion extends UpdateCompanion<Article> {
  final Value<String> guid;
  final Value<String> title;
  final Value<String> feedUrl;
  final Value<String> link;
  final Value<String> description;
  final Value<String> content;
  final Value<String> enclosure;
  final Value<String> author;
  final Value<String> date;
  final Value<String> status;
  final Value<int> rowid;
  const ArticlesCompanion({
    this.guid = const Value.absent(),
    this.title = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.link = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.enclosure = const Value.absent(),
    this.author = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArticlesCompanion.insert({
    required String guid,
    this.title = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.link = const Value.absent(),
    this.description = const Value.absent(),
    this.content = const Value.absent(),
    this.enclosure = const Value.absent(),
    this.author = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : guid = Value(guid);
  static Insertable<Article> custom({
    Expression<String>? guid,
    Expression<String>? title,
    Expression<String>? feedUrl,
    Expression<String>? link,
    Expression<String>? description,
    Expression<String>? content,
    Expression<String>? enclosure,
    Expression<String>? author,
    Expression<String>? date,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (title != null) 'title': title,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (link != null) 'link': link,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (enclosure != null) 'enclosure': enclosure,
      if (author != null) 'author': author,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArticlesCompanion copyWith({
    Value<String>? guid,
    Value<String>? title,
    Value<String>? feedUrl,
    Value<String>? link,
    Value<String>? description,
    Value<String>? content,
    Value<String>? enclosure,
    Value<String>? author,
    Value<String>? date,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ArticlesCompanion(
      guid: guid ?? this.guid,
      title: title ?? this.title,
      feedUrl: feedUrl ?? this.feedUrl,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      enclosure: enclosure ?? this.enclosure,
      author: author ?? this.author,
      date: date ?? this.date,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (enclosure.present) {
      map['enclosure'] = Variable<String>(enclosure.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticlesCompanion(')
          ..write('guid: $guid, ')
          ..write('title: $title, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('link: $link, ')
          ..write('description: $description, ')
          ..write('content: $content, ')
          ..write('enclosure: $enclosure, ')
          ..write('author: $author, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $FeedsTable feeds = $FeedsTable(this);
  late final $ArticlesTable articles = $ArticlesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    feeds,
    articles,
  ];
}

typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      Value<String> value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$FeedsTableCreateCompanionBuilder =
    FeedsCompanion Function({
      required String feedUrl,
      Value<String> siteUrl,
      Value<String> title,
      Value<String> category,
      Value<String> iconUrl,
      Value<String> lastUpdated,
      Value<String> displayMode,
      Value<int> rowid,
    });
typedef $$FeedsTableUpdateCompanionBuilder =
    FeedsCompanion Function({
      Value<String> feedUrl,
      Value<String> siteUrl,
      Value<String> title,
      Value<String> category,
      Value<String> iconUrl,
      Value<String> lastUpdated,
      Value<String> displayMode,
      Value<int> rowid,
    });

class $$FeedsTableFilterComposer extends Composer<_$AppDatabase, $FeedsTable> {
  $$FeedsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteUrl => $composableBuilder(
    column: $table.siteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayMode => $composableBuilder(
    column: $table.displayMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedsTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedsTable> {
  $$FeedsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteUrl => $composableBuilder(
    column: $table.siteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayMode => $composableBuilder(
    column: $table.displayMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedsTable> {
  $$FeedsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get siteUrl =>
      $composableBuilder(column: $table.siteUrl, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayMode => $composableBuilder(
    column: $table.displayMode,
    builder: (column) => column,
  );
}

class $$FeedsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedsTable,
          Feed,
          $$FeedsTableFilterComposer,
          $$FeedsTableOrderingComposer,
          $$FeedsTableAnnotationComposer,
          $$FeedsTableCreateCompanionBuilder,
          $$FeedsTableUpdateCompanionBuilder,
          (Feed, BaseReferences<_$AppDatabase, $FeedsTable, Feed>),
          Feed,
          PrefetchHooks Function()
        > {
  $$FeedsTableTableManager(_$AppDatabase db, $FeedsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> feedUrl = const Value.absent(),
                Value<String> siteUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> lastUpdated = const Value.absent(),
                Value<String> displayMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedsCompanion(
                feedUrl: feedUrl,
                siteUrl: siteUrl,
                title: title,
                category: category,
                iconUrl: iconUrl,
                lastUpdated: lastUpdated,
                displayMode: displayMode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String feedUrl,
                Value<String> siteUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> iconUrl = const Value.absent(),
                Value<String> lastUpdated = const Value.absent(),
                Value<String> displayMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedsCompanion.insert(
                feedUrl: feedUrl,
                siteUrl: siteUrl,
                title: title,
                category: category,
                iconUrl: iconUrl,
                lastUpdated: lastUpdated,
                displayMode: displayMode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedsTable,
      Feed,
      $$FeedsTableFilterComposer,
      $$FeedsTableOrderingComposer,
      $$FeedsTableAnnotationComposer,
      $$FeedsTableCreateCompanionBuilder,
      $$FeedsTableUpdateCompanionBuilder,
      (Feed, BaseReferences<_$AppDatabase, $FeedsTable, Feed>),
      Feed,
      PrefetchHooks Function()
    >;
typedef $$ArticlesTableCreateCompanionBuilder =
    ArticlesCompanion Function({
      required String guid,
      Value<String> title,
      Value<String> feedUrl,
      Value<String> link,
      Value<String> description,
      Value<String> content,
      Value<String> enclosure,
      Value<String> author,
      Value<String> date,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$ArticlesTableUpdateCompanionBuilder =
    ArticlesCompanion Function({
      Value<String> guid,
      Value<String> title,
      Value<String> feedUrl,
      Value<String> link,
      Value<String> description,
      Value<String> content,
      Value<String> enclosure,
      Value<String> author,
      Value<String> date,
      Value<String> status,
      Value<int> rowid,
    });

class $$ArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enclosure => $composableBuilder(
    column: $table.enclosure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enclosure => $composableBuilder(
    column: $table.enclosure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticlesTable> {
  $$ArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get enclosure =>
      $composableBuilder(column: $table.enclosure, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticlesTable,
          Article,
          $$ArticlesTableFilterComposer,
          $$ArticlesTableOrderingComposer,
          $$ArticlesTableAnnotationComposer,
          $$ArticlesTableCreateCompanionBuilder,
          $$ArticlesTableUpdateCompanionBuilder,
          (Article, BaseReferences<_$AppDatabase, $ArticlesTable, Article>),
          Article,
          PrefetchHooks Function()
        > {
  $$ArticlesTableTableManager(_$AppDatabase db, $ArticlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> feedUrl = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> enclosure = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion(
                guid: guid,
                title: title,
                feedUrl: feedUrl,
                link: link,
                description: description,
                content: content,
                enclosure: enclosure,
                author: author,
                date: date,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                Value<String> title = const Value.absent(),
                Value<String> feedUrl = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> enclosure = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArticlesCompanion.insert(
                guid: guid,
                title: title,
                feedUrl: feedUrl,
                link: link,
                description: description,
                content: content,
                enclosure: enclosure,
                author: author,
                date: date,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticlesTable,
      Article,
      $$ArticlesTableFilterComposer,
      $$ArticlesTableOrderingComposer,
      $$ArticlesTableAnnotationComposer,
      $$ArticlesTableCreateCompanionBuilder,
      $$ArticlesTableUpdateCompanionBuilder,
      (Article, BaseReferences<_$AppDatabase, $ArticlesTable, Article>),
      Article,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$FeedsTableTableManager get feeds =>
      $$FeedsTableTableManager(_db, _db.feeds);
  $$ArticlesTableTableManager get articles =>
      $$ArticlesTableTableManager(_db, _db.articles);
}
