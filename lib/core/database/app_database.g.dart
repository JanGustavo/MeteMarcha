// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$ExerciseDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutSplitsTable get workoutSplits => attachedDatabase.workoutSplits;
  $WorkoutDaysTable get workoutDays => attachedDatabase.workoutDays;
  $WorkoutDayExercisesTable get workoutDayExercises =>
      attachedDatabase.workoutDayExercises;
  ExerciseDaoManager get managers => ExerciseDaoManager(this);
}

class ExerciseDaoManager {
  final _$ExerciseDaoMixin _db;
  ExerciseDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutSplitsTableTableManager get workoutSplits =>
      $$WorkoutSplitsTableTableManager(_db.attachedDatabase, _db.workoutSplits);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db.attachedDatabase, _db.workoutDays);
  $$WorkoutDayExercisesTableTableManager get workoutDayExercises =>
      $$WorkoutDayExercisesTableTableManager(
          _db.attachedDatabase, _db.workoutDayExercises);
}

mixin _$WorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutSplitsTable get workoutSplits => attachedDatabase.workoutSplits;
  $WorkoutDaysTable get workoutDays => attachedDatabase.workoutDays;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutDayExercisesTable get workoutDayExercises =>
      attachedDatabase.workoutDayExercises;
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  $ExerciseLogsTable get exerciseLogs => attachedDatabase.exerciseLogs;
  $WeeklySchedulesTable get weeklySchedules => attachedDatabase.weeklySchedules;
  WorkoutDaoManager get managers => WorkoutDaoManager(this);
}

class WorkoutDaoManager {
  final _$WorkoutDaoMixin _db;
  WorkoutDaoManager(this._db);
  $$WorkoutSplitsTableTableManager get workoutSplits =>
      $$WorkoutSplitsTableTableManager(_db.attachedDatabase, _db.workoutSplits);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db.attachedDatabase, _db.workoutDays);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutDayExercisesTableTableManager get workoutDayExercises =>
      $$WorkoutDayExercisesTableTableManager(
          _db.attachedDatabase, _db.workoutDayExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
          _db.attachedDatabase, _db.workoutSessions);
  $$ExerciseLogsTableTableManager get exerciseLogs =>
      $$ExerciseLogsTableTableManager(_db.attachedDatabase, _db.exerciseLogs);
  $$WeeklySchedulesTableTableManager get weeklySchedules =>
      $$WeeklySchedulesTableTableManager(
          _db.attachedDatabase, _db.weeklySchedules);
}

mixin _$LogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutSplitsTable get workoutSplits => attachedDatabase.workoutSplits;
  $WorkoutDaysTable get workoutDays => attachedDatabase.workoutDays;
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  $ExerciseLogsTable get exerciseLogs => attachedDatabase.exerciseLogs;
  LogDaoManager get managers => LogDaoManager(this);
}

class LogDaoManager {
  final _$LogDaoMixin _db;
  LogDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutSplitsTableTableManager get workoutSplits =>
      $$WorkoutSplitsTableTableManager(_db.attachedDatabase, _db.workoutSplits);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db.attachedDatabase, _db.workoutDays);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
          _db.attachedDatabase, _db.workoutSessions);
  $$ExerciseLogsTableTableManager get exerciseLogs =>
      $$ExerciseLogsTableTableManager(_db.attachedDatabase, _db.exerciseLogs);
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grupoMuscularMeta =
      const VerificationMeta('grupoMuscular');
  @override
  late final GeneratedColumn<String> grupoMuscular = GeneratedColumn<String>(
      'grupo_muscular', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
      'link', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isUnilateralMeta =
      const VerificationMeta('isUnilateral');
  @override
  late final GeneratedColumn<bool> isUnilateral = GeneratedColumn<bool>(
      'is_unilateral', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_unilateral" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _equipamentoMeta =
      const VerificationMeta('equipamento');
  @override
  late final GeneratedColumn<String> equipamento = GeneratedColumn<String>(
      'equipamento', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Livre'));
  static const VerificationMeta _tempoDescansoSegundosMeta =
      const VerificationMeta('tempoDescansoSegundos');
  @override
  late final GeneratedColumn<int> tempoDescansoSegundos = GeneratedColumn<int>(
      'tempo_descanso_segundos', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(90));
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<String> volume = GeneratedColumn<String>(
      'volume', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vezesFeitoMeta =
      const VerificationMeta('vezesFeito');
  @override
  late final GeneratedColumn<int> vezesFeito = GeneratedColumn<int>(
      'vezes_feito', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nome,
        grupoMuscular,
        link,
        isUnilateral,
        equipamento,
        tempoDescansoSegundos,
        volume,
        vezesFeito,
        observacoes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('grupo_muscular')) {
      context.handle(
          _grupoMuscularMeta,
          grupoMuscular.isAcceptableOrUnknown(
              data['grupo_muscular']!, _grupoMuscularMeta));
    } else if (isInserting) {
      context.missing(_grupoMuscularMeta);
    }
    if (data.containsKey('link')) {
      context.handle(
          _linkMeta, link.isAcceptableOrUnknown(data['link']!, _linkMeta));
    }
    if (data.containsKey('is_unilateral')) {
      context.handle(
          _isUnilateralMeta,
          isUnilateral.isAcceptableOrUnknown(
              data['is_unilateral']!, _isUnilateralMeta));
    }
    if (data.containsKey('equipamento')) {
      context.handle(
          _equipamentoMeta,
          equipamento.isAcceptableOrUnknown(
              data['equipamento']!, _equipamentoMeta));
    }
    if (data.containsKey('tempo_descanso_segundos')) {
      context.handle(
          _tempoDescansoSegundosMeta,
          tempoDescansoSegundos.isAcceptableOrUnknown(
              data['tempo_descanso_segundos']!, _tempoDescansoSegundosMeta));
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta,
          volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    if (data.containsKey('vezes_feito')) {
      context.handle(
          _vezesFeitoMeta,
          vezesFeito.isAcceptableOrUnknown(
              data['vezes_feito']!, _vezesFeitoMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      grupoMuscular: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grupo_muscular'])!,
      link: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link']),
      isUnilateral: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_unilateral'])!,
      equipamento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipamento'])!,
      tempoDescansoSegundos: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}tempo_descanso_segundos'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}volume']),
      vezesFeito: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vezes_feito'])!,
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final int id;
  final String nome;

  /// Peito | Costas | Ombro | Tríceps | Bíceps | Perna | Core | Glúteo
  final String grupoMuscular;

  /// Link YouTube/referência para ver a execução
  final String? link;

  /// Se true: cada lado é trabalhado separadamente.
  /// Impacta o cálculo de volume: peso × reps × 2 quando lado = 'ambos'.
  final bool isUnilateral;

  /// Livre | Barra | Haltere | Cabo | Máquina | Peso Corporal | Smith
  final String equipamento;

  /// Tempo de descanso padrão em segundos (padrão 90s)
  final int tempoDescansoSegundos;

  /// Volume recomendado (ex: "3x12")
  final String? volume;

  /// Incrementado a cada sessão concluída (não a cada série).
  final int vezesFeito;

  /// Observações / Dicas de biomecânica para o exercício
  final String? observacoes;
  const Exercise(
      {required this.id,
      required this.nome,
      required this.grupoMuscular,
      this.link,
      required this.isUnilateral,
      required this.equipamento,
      required this.tempoDescansoSegundos,
      this.volume,
      required this.vezesFeito,
      this.observacoes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['grupo_muscular'] = Variable<String>(grupoMuscular);
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    map['is_unilateral'] = Variable<bool>(isUnilateral);
    map['equipamento'] = Variable<String>(equipamento);
    map['tempo_descanso_segundos'] = Variable<int>(tempoDescansoSegundos);
    if (!nullToAbsent || volume != null) {
      map['volume'] = Variable<String>(volume);
    }
    map['vezes_feito'] = Variable<int>(vezesFeito);
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      nome: Value(nome),
      grupoMuscular: Value(grupoMuscular),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      isUnilateral: Value(isUnilateral),
      equipamento: Value(equipamento),
      tempoDescansoSegundos: Value(tempoDescansoSegundos),
      volume:
          volume == null && nullToAbsent ? const Value.absent() : Value(volume),
      vezesFeito: Value(vezesFeito),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      grupoMuscular: serializer.fromJson<String>(json['grupoMuscular']),
      link: serializer.fromJson<String?>(json['link']),
      isUnilateral: serializer.fromJson<bool>(json['isUnilateral']),
      equipamento: serializer.fromJson<String>(json['equipamento']),
      tempoDescansoSegundos:
          serializer.fromJson<int>(json['tempoDescansoSegundos']),
      volume: serializer.fromJson<String?>(json['volume']),
      vezesFeito: serializer.fromJson<int>(json['vezesFeito']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'grupoMuscular': serializer.toJson<String>(grupoMuscular),
      'link': serializer.toJson<String?>(link),
      'isUnilateral': serializer.toJson<bool>(isUnilateral),
      'equipamento': serializer.toJson<String>(equipamento),
      'tempoDescansoSegundos': serializer.toJson<int>(tempoDescansoSegundos),
      'volume': serializer.toJson<String?>(volume),
      'vezesFeito': serializer.toJson<int>(vezesFeito),
      'observacoes': serializer.toJson<String?>(observacoes),
    };
  }

  Exercise copyWith(
          {int? id,
          String? nome,
          String? grupoMuscular,
          Value<String?> link = const Value.absent(),
          bool? isUnilateral,
          String? equipamento,
          int? tempoDescansoSegundos,
          Value<String?> volume = const Value.absent(),
          int? vezesFeito,
          Value<String?> observacoes = const Value.absent()}) =>
      Exercise(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        grupoMuscular: grupoMuscular ?? this.grupoMuscular,
        link: link.present ? link.value : this.link,
        isUnilateral: isUnilateral ?? this.isUnilateral,
        equipamento: equipamento ?? this.equipamento,
        tempoDescansoSegundos:
            tempoDescansoSegundos ?? this.tempoDescansoSegundos,
        volume: volume.present ? volume.value : this.volume,
        vezesFeito: vezesFeito ?? this.vezesFeito,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      grupoMuscular: data.grupoMuscular.present
          ? data.grupoMuscular.value
          : this.grupoMuscular,
      link: data.link.present ? data.link.value : this.link,
      isUnilateral: data.isUnilateral.present
          ? data.isUnilateral.value
          : this.isUnilateral,
      equipamento:
          data.equipamento.present ? data.equipamento.value : this.equipamento,
      tempoDescansoSegundos: data.tempoDescansoSegundos.present
          ? data.tempoDescansoSegundos.value
          : this.tempoDescansoSegundos,
      volume: data.volume.present ? data.volume.value : this.volume,
      vezesFeito:
          data.vezesFeito.present ? data.vezesFeito.value : this.vezesFeito,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('grupoMuscular: $grupoMuscular, ')
          ..write('link: $link, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('equipamento: $equipamento, ')
          ..write('tempoDescansoSegundos: $tempoDescansoSegundos, ')
          ..write('volume: $volume, ')
          ..write('vezesFeito: $vezesFeito, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, grupoMuscular, link, isUnilateral,
      equipamento, tempoDescansoSegundos, volume, vezesFeito, observacoes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.grupoMuscular == this.grupoMuscular &&
          other.link == this.link &&
          other.isUnilateral == this.isUnilateral &&
          other.equipamento == this.equipamento &&
          other.tempoDescansoSegundos == this.tempoDescansoSegundos &&
          other.volume == this.volume &&
          other.vezesFeito == this.vezesFeito &&
          other.observacoes == this.observacoes);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String> grupoMuscular;
  final Value<String?> link;
  final Value<bool> isUnilateral;
  final Value<String> equipamento;
  final Value<int> tempoDescansoSegundos;
  final Value<String?> volume;
  final Value<int> vezesFeito;
  final Value<String?> observacoes;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.grupoMuscular = const Value.absent(),
    this.link = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    this.equipamento = const Value.absent(),
    this.tempoDescansoSegundos = const Value.absent(),
    this.volume = const Value.absent(),
    this.vezesFeito = const Value.absent(),
    this.observacoes = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required String grupoMuscular,
    this.link = const Value.absent(),
    this.isUnilateral = const Value.absent(),
    this.equipamento = const Value.absent(),
    this.tempoDescansoSegundos = const Value.absent(),
    this.volume = const Value.absent(),
    this.vezesFeito = const Value.absent(),
    this.observacoes = const Value.absent(),
  })  : nome = Value(nome),
        grupoMuscular = Value(grupoMuscular);
  static Insertable<Exercise> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? grupoMuscular,
    Expression<String>? link,
    Expression<bool>? isUnilateral,
    Expression<String>? equipamento,
    Expression<int>? tempoDescansoSegundos,
    Expression<String>? volume,
    Expression<int>? vezesFeito,
    Expression<String>? observacoes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (grupoMuscular != null) 'grupo_muscular': grupoMuscular,
      if (link != null) 'link': link,
      if (isUnilateral != null) 'is_unilateral': isUnilateral,
      if (equipamento != null) 'equipamento': equipamento,
      if (tempoDescansoSegundos != null)
        'tempo_descanso_segundos': tempoDescansoSegundos,
      if (volume != null) 'volume': volume,
      if (vezesFeito != null) 'vezes_feito': vezesFeito,
      if (observacoes != null) 'observacoes': observacoes,
    });
  }

  ExercisesCompanion copyWith(
      {Value<int>? id,
      Value<String>? nome,
      Value<String>? grupoMuscular,
      Value<String?>? link,
      Value<bool>? isUnilateral,
      Value<String>? equipamento,
      Value<int>? tempoDescansoSegundos,
      Value<String?>? volume,
      Value<int>? vezesFeito,
      Value<String?>? observacoes}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      link: link ?? this.link,
      isUnilateral: isUnilateral ?? this.isUnilateral,
      equipamento: equipamento ?? this.equipamento,
      tempoDescansoSegundos:
          tempoDescansoSegundos ?? this.tempoDescansoSegundos,
      volume: volume ?? this.volume,
      vezesFeito: vezesFeito ?? this.vezesFeito,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (grupoMuscular.present) {
      map['grupo_muscular'] = Variable<String>(grupoMuscular.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (isUnilateral.present) {
      map['is_unilateral'] = Variable<bool>(isUnilateral.value);
    }
    if (equipamento.present) {
      map['equipamento'] = Variable<String>(equipamento.value);
    }
    if (tempoDescansoSegundos.present) {
      map['tempo_descanso_segundos'] =
          Variable<int>(tempoDescansoSegundos.value);
    }
    if (volume.present) {
      map['volume'] = Variable<String>(volume.value);
    }
    if (vezesFeito.present) {
      map['vezes_feito'] = Variable<int>(vezesFeito.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('grupoMuscular: $grupoMuscular, ')
          ..write('link: $link, ')
          ..write('isUnilateral: $isUnilateral, ')
          ..write('equipamento: $equipamento, ')
          ..write('tempoDescansoSegundos: $tempoDescansoSegundos, ')
          ..write('volume: $volume, ')
          ..write('vezesFeito: $vezesFeito, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSplitsTable extends WorkoutSplits
    with TableInfo<$WorkoutSplitsTable, WorkoutSplit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ativoMeta = const VerificationMeta('ativo');
  @override
  late final GeneratedColumn<bool> ativo = GeneratedColumn<bool>(
      'ativo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ativo" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, tipo, nome, ativo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_splits';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSplit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('ativo')) {
      context.handle(
          _ativoMeta, ativo.isAcceptableOrUnknown(data['ativo']!, _ativoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSplit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSplit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      ativo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ativo'])!,
    );
  }

  @override
  $WorkoutSplitsTable createAlias(String alias) {
    return $WorkoutSplitsTable(attachedDatabase, alias);
  }
}

class WorkoutSplit extends DataClass implements Insertable<WorkoutSplit> {
  final int id;

  /// ABC | ABCD | ABCDE | CUSTOM
  final String tipo;

  /// Nome exibido ao usuário
  final String nome;

  /// Apenas uma divisão pode estar ativa por vez
  final bool ativo;
  const WorkoutSplit(
      {required this.id,
      required this.tipo,
      required this.nome,
      required this.ativo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tipo'] = Variable<String>(tipo);
    map['nome'] = Variable<String>(nome);
    map['ativo'] = Variable<bool>(ativo);
    return map;
  }

  WorkoutSplitsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSplitsCompanion(
      id: Value(id),
      tipo: Value(tipo),
      nome: Value(nome),
      ativo: Value(ativo),
    );
  }

  factory WorkoutSplit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSplit(
      id: serializer.fromJson<int>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      nome: serializer.fromJson<String>(json['nome']),
      ativo: serializer.fromJson<bool>(json['ativo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tipo': serializer.toJson<String>(tipo),
      'nome': serializer.toJson<String>(nome),
      'ativo': serializer.toJson<bool>(ativo),
    };
  }

  WorkoutSplit copyWith({int? id, String? tipo, String? nome, bool? ativo}) =>
      WorkoutSplit(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        nome: nome ?? this.nome,
        ativo: ativo ?? this.ativo,
      );
  WorkoutSplit copyWithCompanion(WorkoutSplitsCompanion data) {
    return WorkoutSplit(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      nome: data.nome.present ? data.nome.value : this.nome,
      ativo: data.ativo.present ? data.ativo.value : this.ativo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSplit(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipo, nome, ativo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSplit &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.nome == this.nome &&
          other.ativo == this.ativo);
}

class WorkoutSplitsCompanion extends UpdateCompanion<WorkoutSplit> {
  final Value<int> id;
  final Value<String> tipo;
  final Value<String> nome;
  final Value<bool> ativo;
  const WorkoutSplitsCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.nome = const Value.absent(),
    this.ativo = const Value.absent(),
  });
  WorkoutSplitsCompanion.insert({
    this.id = const Value.absent(),
    required String tipo,
    required String nome,
    this.ativo = const Value.absent(),
  })  : tipo = Value(tipo),
        nome = Value(nome);
  static Insertable<WorkoutSplit> custom({
    Expression<int>? id,
    Expression<String>? tipo,
    Expression<String>? nome,
    Expression<bool>? ativo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (nome != null) 'nome': nome,
      if (ativo != null) 'ativo': ativo,
    });
  }

  WorkoutSplitsCompanion copyWith(
      {Value<int>? id,
      Value<String>? tipo,
      Value<String>? nome,
      Value<bool>? ativo}) {
    return WorkoutSplitsCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (ativo.present) {
      map['ativo'] = Variable<bool>(ativo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSplitsCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('nome: $nome, ')
          ..write('ativo: $ativo')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDaysTable extends WorkoutDays
    with TableInfo<$WorkoutDaysTable, WorkoutDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _splitIdMeta =
      const VerificationMeta('splitId');
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
      'split_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_splits (id)'));
  static const VerificationMeta _letraMeta = const VerificationMeta('letra');
  @override
  late final GeneratedColumn<String> letra = GeneratedColumn<String>(
      'letra', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, splitId, letra, nome];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_days';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(_splitIdMeta,
          splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta));
    } else if (isInserting) {
      context.missing(_splitIdMeta);
    }
    if (data.containsKey('letra')) {
      context.handle(
          _letraMeta, letra.isAcceptableOrUnknown(data['letra']!, _letraMeta));
    } else if (isInserting) {
      context.missing(_letraMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      splitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_id'])!,
      letra: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}letra'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
    );
  }

  @override
  $WorkoutDaysTable createAlias(String alias) {
    return $WorkoutDaysTable(attachedDatabase, alias);
  }
}

class WorkoutDay extends DataClass implements Insertable<WorkoutDay> {
  final int id;
  final int splitId;

  /// A, B, C, D, E
  final String letra;

  /// "Peito e Tríceps", "Costas e Bíceps", etc.
  final String nome;
  const WorkoutDay(
      {required this.id,
      required this.splitId,
      required this.letra,
      required this.nome});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_id'] = Variable<int>(splitId);
    map['letra'] = Variable<String>(letra);
    map['nome'] = Variable<String>(nome);
    return map;
  }

  WorkoutDaysCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDaysCompanion(
      id: Value(id),
      splitId: Value(splitId),
      letra: Value(letra),
      nome: Value(nome),
    );
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDay(
      id: serializer.fromJson<int>(json['id']),
      splitId: serializer.fromJson<int>(json['splitId']),
      letra: serializer.fromJson<String>(json['letra']),
      nome: serializer.fromJson<String>(json['nome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitId': serializer.toJson<int>(splitId),
      'letra': serializer.toJson<String>(letra),
      'nome': serializer.toJson<String>(nome),
    };
  }

  WorkoutDay copyWith({int? id, int? splitId, String? letra, String? nome}) =>
      WorkoutDay(
        id: id ?? this.id,
        splitId: splitId ?? this.splitId,
        letra: letra ?? this.letra,
        nome: nome ?? this.nome,
      );
  WorkoutDay copyWithCompanion(WorkoutDaysCompanion data) {
    return WorkoutDay(
      id: data.id.present ? data.id.value : this.id,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      letra: data.letra.present ? data.letra.value : this.letra,
      nome: data.nome.present ? data.nome.value : this.nome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDay(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('letra: $letra, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, splitId, letra, nome);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDay &&
          other.id == this.id &&
          other.splitId == this.splitId &&
          other.letra == this.letra &&
          other.nome == this.nome);
}

class WorkoutDaysCompanion extends UpdateCompanion<WorkoutDay> {
  final Value<int> id;
  final Value<int> splitId;
  final Value<String> letra;
  final Value<String> nome;
  const WorkoutDaysCompanion({
    this.id = const Value.absent(),
    this.splitId = const Value.absent(),
    this.letra = const Value.absent(),
    this.nome = const Value.absent(),
  });
  WorkoutDaysCompanion.insert({
    this.id = const Value.absent(),
    required int splitId,
    required String letra,
    required String nome,
  })  : splitId = Value(splitId),
        letra = Value(letra),
        nome = Value(nome);
  static Insertable<WorkoutDay> custom({
    Expression<int>? id,
    Expression<int>? splitId,
    Expression<String>? letra,
    Expression<String>? nome,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitId != null) 'split_id': splitId,
      if (letra != null) 'letra': letra,
      if (nome != null) 'nome': nome,
    });
  }

  WorkoutDaysCompanion copyWith(
      {Value<int>? id,
      Value<int>? splitId,
      Value<String>? letra,
      Value<String>? nome}) {
    return WorkoutDaysCompanion(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      letra: letra ?? this.letra,
      nome: nome ?? this.nome,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (letra.present) {
      map['letra'] = Variable<String>(letra.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDaysCompanion(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('letra: $letra, ')
          ..write('nome: $nome')
          ..write(')'))
        .toString();
  }
}

class $WorkoutDayExercisesTable extends WorkoutDayExercises
    with TableInfo<$WorkoutDayExercisesTable, WorkoutDayExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutDayExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
      'day_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_days (id)'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
      'ordem', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, dayId, exerciseId, ordem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_day_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutDayExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
          _dayIdMeta, dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta));
    } else if (isInserting) {
      context.missing(_dayIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('ordem')) {
      context.handle(
          _ordemMeta, ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta));
    } else if (isInserting) {
      context.missing(_ordemMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutDayExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutDayExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_id'])!,
      ordem: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordem'])!,
    );
  }

  @override
  $WorkoutDayExercisesTable createAlias(String alias) {
    return $WorkoutDayExercisesTable(attachedDatabase, alias);
  }
}

class WorkoutDayExercise extends DataClass
    implements Insertable<WorkoutDayExercise> {
  final int id;
  final int dayId;
  final int exerciseId;

  /// 0-based; controla a ordem de exibição no treino
  final int ordem;
  const WorkoutDayExercise(
      {required this.id,
      required this.dayId,
      required this.exerciseId,
      required this.ordem});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_id'] = Variable<int>(dayId);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['ordem'] = Variable<int>(ordem);
    return map;
  }

  WorkoutDayExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutDayExercisesCompanion(
      id: Value(id),
      dayId: Value(dayId),
      exerciseId: Value(exerciseId),
      ordem: Value(ordem),
    );
  }

  factory WorkoutDayExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutDayExercise(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int>(json['dayId']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      ordem: serializer.fromJson<int>(json['ordem']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int>(dayId),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'ordem': serializer.toJson<int>(ordem),
    };
  }

  WorkoutDayExercise copyWith(
          {int? id, int? dayId, int? exerciseId, int? ordem}) =>
      WorkoutDayExercise(
        id: id ?? this.id,
        dayId: dayId ?? this.dayId,
        exerciseId: exerciseId ?? this.exerciseId,
        ordem: ordem ?? this.ordem,
      );
  WorkoutDayExercise copyWithCompanion(WorkoutDayExercisesCompanion data) {
    return WorkoutDayExercise(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDayExercise(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, exerciseId, ordem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutDayExercise &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.exerciseId == this.exerciseId &&
          other.ordem == this.ordem);
}

class WorkoutDayExercisesCompanion extends UpdateCompanion<WorkoutDayExercise> {
  final Value<int> id;
  final Value<int> dayId;
  final Value<int> exerciseId;
  final Value<int> ordem;
  const WorkoutDayExercisesCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.ordem = const Value.absent(),
  });
  WorkoutDayExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int dayId,
    required int exerciseId,
    required int ordem,
  })  : dayId = Value(dayId),
        exerciseId = Value(exerciseId),
        ordem = Value(ordem);
  static Insertable<WorkoutDayExercise> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<int>? exerciseId,
    Expression<int>? ordem,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (ordem != null) 'ordem': ordem,
    });
  }

  WorkoutDayExercisesCompanion copyWith(
      {Value<int>? id,
      Value<int>? dayId,
      Value<int>? exerciseId,
      Value<int>? ordem}) {
    return WorkoutDayExercisesCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      exerciseId: exerciseId ?? this.exerciseId,
      ordem: ordem ?? this.ordem,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutDayExercisesCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('ordem: $ordem')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
      'day_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_days (id)'));
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('em_andamento'));
  static const VerificationMeta _duracaoSegundosMeta =
      const VerificationMeta('duracaoSegundos');
  @override
  late final GeneratedColumn<int> duracaoSegundos = GeneratedColumn<int>(
      'duracao_segundos', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, dayId, data, status, duracaoSegundos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_id')) {
      context.handle(
          _dayIdMeta, dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('duracao_segundos')) {
      context.handle(
          _duracaoSegundosMeta,
          duracaoSegundos.isAcceptableOrUnknown(
              data['duracao_segundos']!, _duracaoSegundosMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_id']),
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      duracaoSegundos: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duracao_segundos']),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final int? dayId;

  /// ISO 8601 — "2025-06-07T08:30:00.000"
  final String data;

  /// em_andamento | concluido | cancelado
  final String status;

  /// Duração total em segundos; preenchido ao concluir
  final int? duracaoSegundos;
  const WorkoutSession(
      {required this.id,
      this.dayId,
      required this.data,
      required this.status,
      this.duracaoSegundos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    map['data'] = Variable<String>(data);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || duracaoSegundos != null) {
      map['duracao_segundos'] = Variable<int>(duracaoSegundos);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      dayId:
          dayId == null && nullToAbsent ? const Value.absent() : Value(dayId),
      data: Value(data),
      status: Value(status),
      duracaoSegundos: duracaoSegundos == null && nullToAbsent
          ? const Value.absent()
          : Value(duracaoSegundos),
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      dayId: serializer.fromJson<int?>(json['dayId']),
      data: serializer.fromJson<String>(json['data']),
      status: serializer.fromJson<String>(json['status']),
      duracaoSegundos: serializer.fromJson<int?>(json['duracaoSegundos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayId': serializer.toJson<int?>(dayId),
      'data': serializer.toJson<String>(data),
      'status': serializer.toJson<String>(status),
      'duracaoSegundos': serializer.toJson<int?>(duracaoSegundos),
    };
  }

  WorkoutSession copyWith(
          {int? id,
          Value<int?> dayId = const Value.absent(),
          String? data,
          String? status,
          Value<int?> duracaoSegundos = const Value.absent()}) =>
      WorkoutSession(
        id: id ?? this.id,
        dayId: dayId.present ? dayId.value : this.dayId,
        data: data ?? this.data,
        status: status ?? this.status,
        duracaoSegundos: duracaoSegundos.present
            ? duracaoSegundos.value
            : this.duracaoSegundos,
      );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
      data: data.data.present ? data.data.value : this.data,
      status: data.status.present ? data.status.value : this.status,
      duracaoSegundos: data.duracaoSegundos.present
          ? data.duracaoSegundos.value
          : this.duracaoSegundos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('data: $data, ')
          ..write('status: $status, ')
          ..write('duracaoSegundos: $duracaoSegundos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayId, data, status, duracaoSegundos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.dayId == this.dayId &&
          other.data == this.data &&
          other.status == this.status &&
          other.duracaoSegundos == this.duracaoSegundos);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<int?> dayId;
  final Value<String> data;
  final Value<String> status;
  final Value<int?> duracaoSegundos;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    this.data = const Value.absent(),
    this.status = const Value.absent(),
    this.duracaoSegundos = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.dayId = const Value.absent(),
    required String data,
    this.status = const Value.absent(),
    this.duracaoSegundos = const Value.absent(),
  }) : data = Value(data);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<int>? dayId,
    Expression<String>? data,
    Expression<String>? status,
    Expression<int>? duracaoSegundos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayId != null) 'day_id': dayId,
      if (data != null) 'data': data,
      if (status != null) 'status': status,
      if (duracaoSegundos != null) 'duracao_segundos': duracaoSegundos,
    });
  }

  WorkoutSessionsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? dayId,
      Value<String>? data,
      Value<String>? status,
      Value<int?>? duracaoSegundos}) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      dayId: dayId ?? this.dayId,
      data: data ?? this.data,
      status: status ?? this.status,
      duracaoSegundos: duracaoSegundos ?? this.duracaoSegundos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (duracaoSegundos.present) {
      map['duracao_segundos'] = Variable<int>(duracaoSegundos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('dayId: $dayId, ')
          ..write('data: $data, ')
          ..write('status: $status, ')
          ..write('duracaoSegundos: $duracaoSegundos')
          ..write(')'))
        .toString();
  }
}

class $ExerciseLogsTable extends ExerciseLogs
    with TableInfo<$ExerciseLogsTable, ExerciseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
      'session_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES workout_sessions (id)'));
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pesoMeta = const VerificationMeta('peso');
  @override
  late final GeneratedColumn<double> peso = GeneratedColumn<double>(
      'peso', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _repeticoesMeta =
      const VerificationMeta('repeticoes');
  @override
  late final GeneratedColumn<int> repeticoes = GeneratedColumn<int>(
      'repeticoes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _serieMeta = const VerificationMeta('serie');
  @override
  late final GeneratedColumn<int> serie = GeneratedColumn<int>(
      'serie', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _ladoMeta = const VerificationMeta('lado');
  @override
  late final GeneratedColumn<String> lado = GeneratedColumn<String>(
      'lado', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ambos'));
  static const VerificationMeta _concluidoMeta =
      const VerificationMeta('concluido');
  @override
  late final GeneratedColumn<bool> concluido = GeneratedColumn<bool>(
      'concluido', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("concluido" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _equipamentoMeta =
      const VerificationMeta('equipamento');
  @override
  late final GeneratedColumn<String> equipamento = GeneratedColumn<String>(
      'equipamento', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exerciseId,
        sessionId,
        data,
        peso,
        repeticoes,
        serie,
        lado,
        concluido,
        equipamento,
        observacoes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('peso')) {
      context.handle(
          _pesoMeta, peso.isAcceptableOrUnknown(data['peso']!, _pesoMeta));
    } else if (isInserting) {
      context.missing(_pesoMeta);
    }
    if (data.containsKey('repeticoes')) {
      context.handle(
          _repeticoesMeta,
          repeticoes.isAcceptableOrUnknown(
              data['repeticoes']!, _repeticoesMeta));
    } else if (isInserting) {
      context.missing(_repeticoesMeta);
    }
    if (data.containsKey('serie')) {
      context.handle(
          _serieMeta, serie.isAcceptableOrUnknown(data['serie']!, _serieMeta));
    }
    if (data.containsKey('lado')) {
      context.handle(
          _ladoMeta, lado.isAcceptableOrUnknown(data['lado']!, _ladoMeta));
    }
    if (data.containsKey('concluido')) {
      context.handle(_concluidoMeta,
          concluido.isAcceptableOrUnknown(data['concluido']!, _concluidoMeta));
    }
    if (data.containsKey('equipamento')) {
      context.handle(
          _equipamentoMeta,
          equipamento.isAcceptableOrUnknown(
              data['equipamento']!, _equipamentoMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      peso: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peso'])!,
      repeticoes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repeticoes'])!,
      serie: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}serie'])!,
      lado: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lado'])!,
      concluido: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}concluido'])!,
      equipamento: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipamento']),
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
    );
  }

  @override
  $ExerciseLogsTable createAlias(String alias) {
    return $ExerciseLogsTable(attachedDatabase, alias);
  }
}

class ExerciseLog extends DataClass implements Insertable<ExerciseLog> {
  final int id;
  final int exerciseId;
  final int sessionId;
  final String data;

  /// kg — pode ser 0 para exercícios de peso corporal
  final double peso;
  final int repeticoes;

  /// O número da série (1, 2, 3...)
  final int serie;

  /// ambos | esquerdo | direito
  /// Para bilaterais, sempre 'ambos'.
  final String lado;

  /// false = série pulada/não realizada (mantém no histórico como ausência)
  final bool concluido;

  /// O equipamento utilizado na execução (pode sobrescrever a recomendação do exercício)
  final String? equipamento;

  /// Observações adicionais sobre a série (ex: banco 80°, rest-pause, drop set)
  final String? observacoes;
  const ExerciseLog(
      {required this.id,
      required this.exerciseId,
      required this.sessionId,
      required this.data,
      required this.peso,
      required this.repeticoes,
      required this.serie,
      required this.lado,
      required this.concluido,
      this.equipamento,
      this.observacoes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['session_id'] = Variable<int>(sessionId);
    map['data'] = Variable<String>(data);
    map['peso'] = Variable<double>(peso);
    map['repeticoes'] = Variable<int>(repeticoes);
    map['serie'] = Variable<int>(serie);
    map['lado'] = Variable<String>(lado);
    map['concluido'] = Variable<bool>(concluido);
    if (!nullToAbsent || equipamento != null) {
      map['equipamento'] = Variable<String>(equipamento);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    return map;
  }

  ExerciseLogsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseLogsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      sessionId: Value(sessionId),
      data: Value(data),
      peso: Value(peso),
      repeticoes: Value(repeticoes),
      serie: Value(serie),
      lado: Value(lado),
      concluido: Value(concluido),
      equipamento: equipamento == null && nullToAbsent
          ? const Value.absent()
          : Value(equipamento),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
    );
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseLog(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      data: serializer.fromJson<String>(json['data']),
      peso: serializer.fromJson<double>(json['peso']),
      repeticoes: serializer.fromJson<int>(json['repeticoes']),
      serie: serializer.fromJson<int>(json['serie']),
      lado: serializer.fromJson<String>(json['lado']),
      concluido: serializer.fromJson<bool>(json['concluido']),
      equipamento: serializer.fromJson<String?>(json['equipamento']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'sessionId': serializer.toJson<int>(sessionId),
      'data': serializer.toJson<String>(data),
      'peso': serializer.toJson<double>(peso),
      'repeticoes': serializer.toJson<int>(repeticoes),
      'serie': serializer.toJson<int>(serie),
      'lado': serializer.toJson<String>(lado),
      'concluido': serializer.toJson<bool>(concluido),
      'equipamento': serializer.toJson<String?>(equipamento),
      'observacoes': serializer.toJson<String?>(observacoes),
    };
  }

  ExerciseLog copyWith(
          {int? id,
          int? exerciseId,
          int? sessionId,
          String? data,
          double? peso,
          int? repeticoes,
          int? serie,
          String? lado,
          bool? concluido,
          Value<String?> equipamento = const Value.absent(),
          Value<String?> observacoes = const Value.absent()}) =>
      ExerciseLog(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        sessionId: sessionId ?? this.sessionId,
        data: data ?? this.data,
        peso: peso ?? this.peso,
        repeticoes: repeticoes ?? this.repeticoes,
        serie: serie ?? this.serie,
        lado: lado ?? this.lado,
        concluido: concluido ?? this.concluido,
        equipamento: equipamento.present ? equipamento.value : this.equipamento,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
      );
  ExerciseLog copyWithCompanion(ExerciseLogsCompanion data) {
    return ExerciseLog(
      id: data.id.present ? data.id.value : this.id,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      data: data.data.present ? data.data.value : this.data,
      peso: data.peso.present ? data.peso.value : this.peso,
      repeticoes:
          data.repeticoes.present ? data.repeticoes.value : this.repeticoes,
      serie: data.serie.present ? data.serie.value : this.serie,
      lado: data.lado.present ? data.lado.value : this.lado,
      concluido: data.concluido.present ? data.concluido.value : this.concluido,
      equipamento:
          data.equipamento.present ? data.equipamento.value : this.equipamento,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLog(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sessionId: $sessionId, ')
          ..write('data: $data, ')
          ..write('peso: $peso, ')
          ..write('repeticoes: $repeticoes, ')
          ..write('serie: $serie, ')
          ..write('lado: $lado, ')
          ..write('concluido: $concluido, ')
          ..write('equipamento: $equipamento, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, sessionId, data, peso,
      repeticoes, serie, lado, concluido, equipamento, observacoes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseLog &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.sessionId == this.sessionId &&
          other.data == this.data &&
          other.peso == this.peso &&
          other.repeticoes == this.repeticoes &&
          other.serie == this.serie &&
          other.lado == this.lado &&
          other.concluido == this.concluido &&
          other.equipamento == this.equipamento &&
          other.observacoes == this.observacoes);
}

class ExerciseLogsCompanion extends UpdateCompanion<ExerciseLog> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<int> sessionId;
  final Value<String> data;
  final Value<double> peso;
  final Value<int> repeticoes;
  final Value<int> serie;
  final Value<String> lado;
  final Value<bool> concluido;
  final Value<String?> equipamento;
  final Value<String?> observacoes;
  const ExerciseLogsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.data = const Value.absent(),
    this.peso = const Value.absent(),
    this.repeticoes = const Value.absent(),
    this.serie = const Value.absent(),
    this.lado = const Value.absent(),
    this.concluido = const Value.absent(),
    this.equipamento = const Value.absent(),
    this.observacoes = const Value.absent(),
  });
  ExerciseLogsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required int sessionId,
    required String data,
    required double peso,
    required int repeticoes,
    this.serie = const Value.absent(),
    this.lado = const Value.absent(),
    this.concluido = const Value.absent(),
    this.equipamento = const Value.absent(),
    this.observacoes = const Value.absent(),
  })  : exerciseId = Value(exerciseId),
        sessionId = Value(sessionId),
        data = Value(data),
        peso = Value(peso),
        repeticoes = Value(repeticoes);
  static Insertable<ExerciseLog> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<int>? sessionId,
    Expression<String>? data,
    Expression<double>? peso,
    Expression<int>? repeticoes,
    Expression<int>? serie,
    Expression<String>? lado,
    Expression<bool>? concluido,
    Expression<String>? equipamento,
    Expression<String>? observacoes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (sessionId != null) 'session_id': sessionId,
      if (data != null) 'data': data,
      if (peso != null) 'peso': peso,
      if (repeticoes != null) 'repeticoes': repeticoes,
      if (serie != null) 'serie': serie,
      if (lado != null) 'lado': lado,
      if (concluido != null) 'concluido': concluido,
      if (equipamento != null) 'equipamento': equipamento,
      if (observacoes != null) 'observacoes': observacoes,
    });
  }

  ExerciseLogsCompanion copyWith(
      {Value<int>? id,
      Value<int>? exerciseId,
      Value<int>? sessionId,
      Value<String>? data,
      Value<double>? peso,
      Value<int>? repeticoes,
      Value<int>? serie,
      Value<String>? lado,
      Value<bool>? concluido,
      Value<String?>? equipamento,
      Value<String?>? observacoes}) {
    return ExerciseLogsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      sessionId: sessionId ?? this.sessionId,
      data: data ?? this.data,
      peso: peso ?? this.peso,
      repeticoes: repeticoes ?? this.repeticoes,
      serie: serie ?? this.serie,
      lado: lado ?? this.lado,
      concluido: concluido ?? this.concluido,
      equipamento: equipamento ?? this.equipamento,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (peso.present) {
      map['peso'] = Variable<double>(peso.value);
    }
    if (repeticoes.present) {
      map['repeticoes'] = Variable<int>(repeticoes.value);
    }
    if (serie.present) {
      map['serie'] = Variable<int>(serie.value);
    }
    if (lado.present) {
      map['lado'] = Variable<String>(lado.value);
    }
    if (concluido.present) {
      map['concluido'] = Variable<bool>(concluido.value);
    }
    if (equipamento.present) {
      map['equipamento'] = Variable<String>(equipamento.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLogsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('sessionId: $sessionId, ')
          ..write('data: $data, ')
          ..write('peso: $peso, ')
          ..write('repeticoes: $repeticoes, ')
          ..write('serie: $serie, ')
          ..write('lado: $lado, ')
          ..write('concluido: $concluido, ')
          ..write('equipamento: $equipamento, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pesoAtualMeta =
      const VerificationMeta('pesoAtual');
  @override
  late final GeneratedColumn<double> pesoAtual = GeneratedColumn<double>(
      'peso_atual', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _alturaMeta = const VerificationMeta('altura');
  @override
  late final GeneratedColumn<double> altura = GeneratedColumn<double>(
      'altura', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, nome, pesoAtual, altura];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<UserProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    }
    if (data.containsKey('peso_atual')) {
      context.handle(_pesoAtualMeta,
          pesoAtual.isAcceptableOrUnknown(data['peso_atual']!, _pesoAtualMeta));
    }
    if (data.containsKey('altura')) {
      context.handle(_alturaMeta,
          altura.isAcceptableOrUnknown(data['altura']!, _alturaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome']),
      pesoAtual: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peso_atual']),
      altura: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}altura']),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String? nome;
  final double? pesoAtual;
  final double? altura;
  const UserProfile({required this.id, this.nome, this.pesoAtual, this.altura});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || nome != null) {
      map['nome'] = Variable<String>(nome);
    }
    if (!nullToAbsent || pesoAtual != null) {
      map['peso_atual'] = Variable<double>(pesoAtual);
    }
    if (!nullToAbsent || altura != null) {
      map['altura'] = Variable<double>(altura);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      nome: nome == null && nullToAbsent ? const Value.absent() : Value(nome),
      pesoAtual: pesoAtual == null && nullToAbsent
          ? const Value.absent()
          : Value(pesoAtual),
      altura:
          altura == null && nullToAbsent ? const Value.absent() : Value(altura),
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String?>(json['nome']),
      pesoAtual: serializer.fromJson<double?>(json['pesoAtual']),
      altura: serializer.fromJson<double?>(json['altura']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String?>(nome),
      'pesoAtual': serializer.toJson<double?>(pesoAtual),
      'altura': serializer.toJson<double?>(altura),
    };
  }

  UserProfile copyWith(
          {int? id,
          Value<String?> nome = const Value.absent(),
          Value<double?> pesoAtual = const Value.absent(),
          Value<double?> altura = const Value.absent()}) =>
      UserProfile(
        id: id ?? this.id,
        nome: nome.present ? nome.value : this.nome,
        pesoAtual: pesoAtual.present ? pesoAtual.value : this.pesoAtual,
        altura: altura.present ? altura.value : this.altura,
      );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      pesoAtual: data.pesoAtual.present ? data.pesoAtual.value : this.pesoAtual,
      altura: data.altura.present ? data.altura.value : this.altura,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('pesoAtual: $pesoAtual, ')
          ..write('altura: $altura')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, pesoAtual, altura);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.pesoAtual == this.pesoAtual &&
          other.altura == this.altura);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String?> nome;
  final Value<double?> pesoAtual;
  final Value<double?> altura;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.pesoAtual = const Value.absent(),
    this.altura = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.pesoAtual = const Value.absent(),
    this.altura = const Value.absent(),
  });
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<double>? pesoAtual,
    Expression<double>? altura,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (pesoAtual != null) 'peso_atual': pesoAtual,
      if (altura != null) 'altura': altura,
    });
  }

  UserProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? nome,
      Value<double?>? pesoAtual,
      Value<double?>? altura}) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      pesoAtual: pesoAtual ?? this.pesoAtual,
      altura: altura ?? this.altura,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (pesoAtual.present) {
      map['peso_atual'] = Variable<double>(pesoAtual.value);
    }
    if (altura.present) {
      map['altura'] = Variable<double>(altura.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('pesoAtual: $pesoAtual, ')
          ..write('altura: $altura')
          ..write(')'))
        .toString();
  }
}

class $WeeklyWeightsTable extends WeeklyWeights
    with TableInfo<$WeeklyWeightsTable, WeeklyWeight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyWeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _semanaMeta = const VerificationMeta('semana');
  @override
  late final GeneratedColumn<String> semana = GeneratedColumn<String>(
      'semana', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pesoMeta = const VerificationMeta('peso');
  @override
  late final GeneratedColumn<double> peso = GeneratedColumn<double>(
      'peso', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, semana, peso, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_weights';
  @override
  VerificationContext validateIntegrity(Insertable<WeeklyWeight> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('semana')) {
      context.handle(_semanaMeta,
          semana.isAcceptableOrUnknown(data['semana']!, _semanaMeta));
    } else if (isInserting) {
      context.missing(_semanaMeta);
    }
    if (data.containsKey('peso')) {
      context.handle(
          _pesoMeta, peso.isAcceptableOrUnknown(data['peso']!, _pesoMeta));
    } else if (isInserting) {
      context.missing(_pesoMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyWeight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyWeight(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      semana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semana'])!,
      peso: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peso'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $WeeklyWeightsTable createAlias(String alias) {
    return $WeeklyWeightsTable(attachedDatabase, alias);
  }
}

class WeeklyWeight extends DataClass implements Insertable<WeeklyWeight> {
  final int id;

  /// "2025-W23" — chave de semana
  final String semana;
  final double peso;

  /// Data exata do registro
  final String data;
  const WeeklyWeight(
      {required this.id,
      required this.semana,
      required this.peso,
      required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['semana'] = Variable<String>(semana);
    map['peso'] = Variable<double>(peso);
    map['data'] = Variable<String>(data);
    return map;
  }

  WeeklyWeightsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyWeightsCompanion(
      id: Value(id),
      semana: Value(semana),
      peso: Value(peso),
      data: Value(data),
    );
  }

  factory WeeklyWeight.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyWeight(
      id: serializer.fromJson<int>(json['id']),
      semana: serializer.fromJson<String>(json['semana']),
      peso: serializer.fromJson<double>(json['peso']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'semana': serializer.toJson<String>(semana),
      'peso': serializer.toJson<double>(peso),
      'data': serializer.toJson<String>(data),
    };
  }

  WeeklyWeight copyWith(
          {int? id, String? semana, double? peso, String? data}) =>
      WeeklyWeight(
        id: id ?? this.id,
        semana: semana ?? this.semana,
        peso: peso ?? this.peso,
        data: data ?? this.data,
      );
  WeeklyWeight copyWithCompanion(WeeklyWeightsCompanion data) {
    return WeeklyWeight(
      id: data.id.present ? data.id.value : this.id,
      semana: data.semana.present ? data.semana.value : this.semana,
      peso: data.peso.present ? data.peso.value : this.peso,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyWeight(')
          ..write('id: $id, ')
          ..write('semana: $semana, ')
          ..write('peso: $peso, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, semana, peso, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyWeight &&
          other.id == this.id &&
          other.semana == this.semana &&
          other.peso == this.peso &&
          other.data == this.data);
}

class WeeklyWeightsCompanion extends UpdateCompanion<WeeklyWeight> {
  final Value<int> id;
  final Value<String> semana;
  final Value<double> peso;
  final Value<String> data;
  const WeeklyWeightsCompanion({
    this.id = const Value.absent(),
    this.semana = const Value.absent(),
    this.peso = const Value.absent(),
    this.data = const Value.absent(),
  });
  WeeklyWeightsCompanion.insert({
    this.id = const Value.absent(),
    required String semana,
    required double peso,
    required String data,
  })  : semana = Value(semana),
        peso = Value(peso),
        data = Value(data);
  static Insertable<WeeklyWeight> custom({
    Expression<int>? id,
    Expression<String>? semana,
    Expression<double>? peso,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (semana != null) 'semana': semana,
      if (peso != null) 'peso': peso,
      if (data != null) 'data': data,
    });
  }

  WeeklyWeightsCompanion copyWith(
      {Value<int>? id,
      Value<String>? semana,
      Value<double>? peso,
      Value<String>? data}) {
    return WeeklyWeightsCompanion(
      id: id ?? this.id,
      semana: semana ?? this.semana,
      peso: peso ?? this.peso,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (semana.present) {
      map['semana'] = Variable<String>(semana.value);
    }
    if (peso.present) {
      map['peso'] = Variable<double>(peso.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyWeightsCompanion(')
          ..write('id: $id, ')
          ..write('semana: $semana, ')
          ..write('peso: $peso, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $WeeklySchedulesTable extends WeeklySchedules
    with TableInfo<$WeeklySchedulesTable, WeeklySchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklySchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _diaSemanaMeta =
      const VerificationMeta('diaSemana');
  @override
  late final GeneratedColumn<String> diaSemana = GeneratedColumn<String>(
      'dia_semana', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dayIdMeta = const VerificationMeta('dayId');
  @override
  late final GeneratedColumn<int> dayId = GeneratedColumn<int>(
      'day_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES workout_days (id)'));
  @override
  List<GeneratedColumn> get $columns => [id, diaSemana, dayId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_schedules';
  @override
  VerificationContext validateIntegrity(Insertable<WeeklySchedule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dia_semana')) {
      context.handle(_diaSemanaMeta,
          diaSemana.isAcceptableOrUnknown(data['dia_semana']!, _diaSemanaMeta));
    } else if (isInserting) {
      context.missing(_diaSemanaMeta);
    }
    if (data.containsKey('day_id')) {
      context.handle(
          _dayIdMeta, dayId.isAcceptableOrUnknown(data['day_id']!, _dayIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklySchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklySchedule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      diaSemana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dia_semana'])!,
      dayId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_id']),
    );
  }

  @override
  $WeeklySchedulesTable createAlias(String alias) {
    return $WeeklySchedulesTable(attachedDatabase, alias);
  }
}

class WeeklySchedule extends DataClass implements Insertable<WeeklySchedule> {
  final int id;

  /// Segunda-feira, Terça-feira, etc.
  final String diaSemana;

  /// ID do dia de treino associado (null = descanso)
  final int? dayId;
  const WeeklySchedule({required this.id, required this.diaSemana, this.dayId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dia_semana'] = Variable<String>(diaSemana);
    if (!nullToAbsent || dayId != null) {
      map['day_id'] = Variable<int>(dayId);
    }
    return map;
  }

  WeeklySchedulesCompanion toCompanion(bool nullToAbsent) {
    return WeeklySchedulesCompanion(
      id: Value(id),
      diaSemana: Value(diaSemana),
      dayId:
          dayId == null && nullToAbsent ? const Value.absent() : Value(dayId),
    );
  }

  factory WeeklySchedule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklySchedule(
      id: serializer.fromJson<int>(json['id']),
      diaSemana: serializer.fromJson<String>(json['diaSemana']),
      dayId: serializer.fromJson<int?>(json['dayId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'diaSemana': serializer.toJson<String>(diaSemana),
      'dayId': serializer.toJson<int?>(dayId),
    };
  }

  WeeklySchedule copyWith(
          {int? id,
          String? diaSemana,
          Value<int?> dayId = const Value.absent()}) =>
      WeeklySchedule(
        id: id ?? this.id,
        diaSemana: diaSemana ?? this.diaSemana,
        dayId: dayId.present ? dayId.value : this.dayId,
      );
  WeeklySchedule copyWithCompanion(WeeklySchedulesCompanion data) {
    return WeeklySchedule(
      id: data.id.present ? data.id.value : this.id,
      diaSemana: data.diaSemana.present ? data.diaSemana.value : this.diaSemana,
      dayId: data.dayId.present ? data.dayId.value : this.dayId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklySchedule(')
          ..write('id: $id, ')
          ..write('diaSemana: $diaSemana, ')
          ..write('dayId: $dayId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, diaSemana, dayId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklySchedule &&
          other.id == this.id &&
          other.diaSemana == this.diaSemana &&
          other.dayId == this.dayId);
}

class WeeklySchedulesCompanion extends UpdateCompanion<WeeklySchedule> {
  final Value<int> id;
  final Value<String> diaSemana;
  final Value<int?> dayId;
  const WeeklySchedulesCompanion({
    this.id = const Value.absent(),
    this.diaSemana = const Value.absent(),
    this.dayId = const Value.absent(),
  });
  WeeklySchedulesCompanion.insert({
    this.id = const Value.absent(),
    required String diaSemana,
    this.dayId = const Value.absent(),
  }) : diaSemana = Value(diaSemana);
  static Insertable<WeeklySchedule> custom({
    Expression<int>? id,
    Expression<String>? diaSemana,
    Expression<int>? dayId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diaSemana != null) 'dia_semana': diaSemana,
      if (dayId != null) 'day_id': dayId,
    });
  }

  WeeklySchedulesCompanion copyWith(
      {Value<int>? id, Value<String>? diaSemana, Value<int?>? dayId}) {
    return WeeklySchedulesCompanion(
      id: id ?? this.id,
      diaSemana: diaSemana ?? this.diaSemana,
      dayId: dayId ?? this.dayId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (diaSemana.present) {
      map['dia_semana'] = Variable<String>(diaSemana.value);
    }
    if (dayId.present) {
      map['day_id'] = Variable<int>(dayId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklySchedulesCompanion(')
          ..write('id: $id, ')
          ..write('diaSemana: $diaSemana, ')
          ..write('dayId: $dayId')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exercicioNomeMeta =
      const VerificationMeta('exercicioNome');
  @override
  late final GeneratedColumn<String> exercicioNome = GeneratedColumn<String>(
      'exercicio_nome', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exercicioIdMeta =
      const VerificationMeta('exercicioId');
  @override
  late final GeneratedColumn<int> exercicioId = GeneratedColumn<int>(
      'exercicio_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'));
  static const VerificationMeta _valorAlvoMeta =
      const VerificationMeta('valorAlvo');
  @override
  late final GeneratedColumn<double> valorAlvo = GeneratedColumn<double>(
      'valor_alvo', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _valorInicialMeta =
      const VerificationMeta('valorInicial');
  @override
  late final GeneratedColumn<double> valorInicial = GeneratedColumn<double>(
      'valor_inicial', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dataCriacaoMeta =
      const VerificationMeta('dataCriacao');
  @override
  late final GeneratedColumn<String> dataCriacao = GeneratedColumn<String>(
      'data_criacao', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _concluidoMeta =
      const VerificationMeta('concluido');
  @override
  late final GeneratedColumn<bool> concluido = GeneratedColumn<bool>(
      'concluido', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("concluido" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tipo,
        exercicioNome,
        exercicioId,
        valorAlvo,
        valorInicial,
        dataCriacao,
        concluido
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('exercicio_nome')) {
      context.handle(
          _exercicioNomeMeta,
          exercicioNome.isAcceptableOrUnknown(
              data['exercicio_nome']!, _exercicioNomeMeta));
    }
    if (data.containsKey('exercicio_id')) {
      context.handle(
          _exercicioIdMeta,
          exercicioId.isAcceptableOrUnknown(
              data['exercicio_id']!, _exercicioIdMeta));
    }
    if (data.containsKey('valor_alvo')) {
      context.handle(_valorAlvoMeta,
          valorAlvo.isAcceptableOrUnknown(data['valor_alvo']!, _valorAlvoMeta));
    } else if (isInserting) {
      context.missing(_valorAlvoMeta);
    }
    if (data.containsKey('valor_inicial')) {
      context.handle(
          _valorInicialMeta,
          valorInicial.isAcceptableOrUnknown(
              data['valor_inicial']!, _valorInicialMeta));
    }
    if (data.containsKey('data_criacao')) {
      context.handle(
          _dataCriacaoMeta,
          dataCriacao.isAcceptableOrUnknown(
              data['data_criacao']!, _dataCriacaoMeta));
    } else if (isInserting) {
      context.missing(_dataCriacaoMeta);
    }
    if (data.containsKey('concluido')) {
      context.handle(_concluidoMeta,
          concluido.isAcceptableOrUnknown(data['concluido']!, _concluidoMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      exercicioNome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercicio_nome']),
      exercicioId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercicio_id']),
      valorAlvo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_alvo'])!,
      valorInicial: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}valor_inicial']),
      dataCriacao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_criacao'])!,
      concluido: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}concluido'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String tipo;
  final String? exercicioNome;
  final int? exercicioId;
  final double valorAlvo;
  final double? valorInicial;
  final String dataCriacao;
  final bool concluido;
  const Goal(
      {required this.id,
      required this.tipo,
      this.exercicioNome,
      this.exercicioId,
      required this.valorAlvo,
      this.valorInicial,
      required this.dataCriacao,
      required this.concluido});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    if (!nullToAbsent || exercicioNome != null) {
      map['exercicio_nome'] = Variable<String>(exercicioNome);
    }
    if (!nullToAbsent || exercicioId != null) {
      map['exercicio_id'] = Variable<int>(exercicioId);
    }
    map['valor_alvo'] = Variable<double>(valorAlvo);
    if (!nullToAbsent || valorInicial != null) {
      map['valor_inicial'] = Variable<double>(valorInicial);
    }
    map['data_criacao'] = Variable<String>(dataCriacao);
    map['concluido'] = Variable<bool>(concluido);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      tipo: Value(tipo),
      exercicioNome: exercicioNome == null && nullToAbsent
          ? const Value.absent()
          : Value(exercicioNome),
      exercicioId: exercicioId == null && nullToAbsent
          ? const Value.absent()
          : Value(exercicioId),
      valorAlvo: Value(valorAlvo),
      valorInicial: valorInicial == null && nullToAbsent
          ? const Value.absent()
          : Value(valorInicial),
      dataCriacao: Value(dataCriacao),
      concluido: Value(concluido),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      exercicioNome: serializer.fromJson<String?>(json['exercicioNome']),
      exercicioId: serializer.fromJson<int?>(json['exercicioId']),
      valorAlvo: serializer.fromJson<double>(json['valorAlvo']),
      valorInicial: serializer.fromJson<double?>(json['valorInicial']),
      dataCriacao: serializer.fromJson<String>(json['dataCriacao']),
      concluido: serializer.fromJson<bool>(json['concluido']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'exercicioNome': serializer.toJson<String?>(exercicioNome),
      'exercicioId': serializer.toJson<int?>(exercicioId),
      'valorAlvo': serializer.toJson<double>(valorAlvo),
      'valorInicial': serializer.toJson<double?>(valorInicial),
      'dataCriacao': serializer.toJson<String>(dataCriacao),
      'concluido': serializer.toJson<bool>(concluido),
    };
  }

  Goal copyWith(
          {String? id,
          String? tipo,
          Value<String?> exercicioNome = const Value.absent(),
          Value<int?> exercicioId = const Value.absent(),
          double? valorAlvo,
          Value<double?> valorInicial = const Value.absent(),
          String? dataCriacao,
          bool? concluido}) =>
      Goal(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        exercicioNome:
            exercicioNome.present ? exercicioNome.value : this.exercicioNome,
        exercicioId: exercicioId.present ? exercicioId.value : this.exercicioId,
        valorAlvo: valorAlvo ?? this.valorAlvo,
        valorInicial:
            valorInicial.present ? valorInicial.value : this.valorInicial,
        dataCriacao: dataCriacao ?? this.dataCriacao,
        concluido: concluido ?? this.concluido,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      exercicioNome: data.exercicioNome.present
          ? data.exercicioNome.value
          : this.exercicioNome,
      exercicioId:
          data.exercicioId.present ? data.exercicioId.value : this.exercicioId,
      valorAlvo: data.valorAlvo.present ? data.valorAlvo.value : this.valorAlvo,
      valorInicial: data.valorInicial.present
          ? data.valorInicial.value
          : this.valorInicial,
      dataCriacao:
          data.dataCriacao.present ? data.dataCriacao.value : this.dataCriacao,
      concluido: data.concluido.present ? data.concluido.value : this.concluido,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('exercicioNome: $exercicioNome, ')
          ..write('exercicioId: $exercicioId, ')
          ..write('valorAlvo: $valorAlvo, ')
          ..write('valorInicial: $valorInicial, ')
          ..write('dataCriacao: $dataCriacao, ')
          ..write('concluido: $concluido')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipo, exercicioNome, exercicioId,
      valorAlvo, valorInicial, dataCriacao, concluido);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.exercicioNome == this.exercicioNome &&
          other.exercicioId == this.exercicioId &&
          other.valorAlvo == this.valorAlvo &&
          other.valorInicial == this.valorInicial &&
          other.dataCriacao == this.dataCriacao &&
          other.concluido == this.concluido);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String?> exercicioNome;
  final Value<int?> exercicioId;
  final Value<double> valorAlvo;
  final Value<double?> valorInicial;
  final Value<String> dataCriacao;
  final Value<bool> concluido;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.exercicioNome = const Value.absent(),
    this.exercicioId = const Value.absent(),
    this.valorAlvo = const Value.absent(),
    this.valorInicial = const Value.absent(),
    this.dataCriacao = const Value.absent(),
    this.concluido = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String tipo,
    this.exercicioNome = const Value.absent(),
    this.exercicioId = const Value.absent(),
    required double valorAlvo,
    this.valorInicial = const Value.absent(),
    required String dataCriacao,
    this.concluido = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tipo = Value(tipo),
        valorAlvo = Value(valorAlvo),
        dataCriacao = Value(dataCriacao);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? exercicioNome,
    Expression<int>? exercicioId,
    Expression<double>? valorAlvo,
    Expression<double>? valorInicial,
    Expression<String>? dataCriacao,
    Expression<bool>? concluido,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (exercicioNome != null) 'exercicio_nome': exercicioNome,
      if (exercicioId != null) 'exercicio_id': exercicioId,
      if (valorAlvo != null) 'valor_alvo': valorAlvo,
      if (valorInicial != null) 'valor_inicial': valorInicial,
      if (dataCriacao != null) 'data_criacao': dataCriacao,
      if (concluido != null) 'concluido': concluido,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? tipo,
      Value<String?>? exercicioNome,
      Value<int?>? exercicioId,
      Value<double>? valorAlvo,
      Value<double?>? valorInicial,
      Value<String>? dataCriacao,
      Value<bool>? concluido,
      Value<int>? rowid}) {
    return GoalsCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      exercicioNome: exercicioNome ?? this.exercicioNome,
      exercicioId: exercicioId ?? this.exercicioId,
      valorAlvo: valorAlvo ?? this.valorAlvo,
      valorInicial: valorInicial ?? this.valorInicial,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      concluido: concluido ?? this.concluido,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (exercicioNome.present) {
      map['exercicio_nome'] = Variable<String>(exercicioNome.value);
    }
    if (exercicioId.present) {
      map['exercicio_id'] = Variable<int>(exercicioId.value);
    }
    if (valorAlvo.present) {
      map['valor_alvo'] = Variable<double>(valorAlvo.value);
    }
    if (valorInicial.present) {
      map['valor_inicial'] = Variable<double>(valorInicial.value);
    }
    if (dataCriacao.present) {
      map['data_criacao'] = Variable<String>(dataCriacao.value);
    }
    if (concluido.present) {
      map['concluido'] = Variable<bool>(concluido.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('exercicioNome: $exercicioNome, ')
          ..write('exercicioId: $exercicioId, ')
          ..write('valorAlvo: $valorAlvo, ')
          ..write('valorInicial: $valorInicial, ')
          ..write('dataCriacao: $dataCriacao, ')
          ..write('concluido: $concluido, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pesoMeta = const VerificationMeta('peso');
  @override
  late final GeneratedColumn<double> peso = GeneratedColumn<double>(
      'peso', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _gorduraPercentualMeta =
      const VerificationMeta('gorduraPercentual');
  @override
  late final GeneratedColumn<double> gorduraPercentual =
      GeneratedColumn<double>('gordura_percentual', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _massaMagraMeta =
      const VerificationMeta('massaMagra');
  @override
  late final GeneratedColumn<double> massaMagra = GeneratedColumn<double>(
      'massa_magra', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _imcMeta = const VerificationMeta('imc');
  @override
  late final GeneratedColumn<double> imc = GeneratedColumn<double>(
      'imc', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _peitoMeta = const VerificationMeta('peito');
  @override
  late final GeneratedColumn<double> peito = GeneratedColumn<double>(
      'peito', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cinturaMeta =
      const VerificationMeta('cintura');
  @override
  late final GeneratedColumn<double> cintura = GeneratedColumn<double>(
      'cintura', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bracoEsquerdoMeta =
      const VerificationMeta('bracoEsquerdo');
  @override
  late final GeneratedColumn<double> bracoEsquerdo = GeneratedColumn<double>(
      'braco_esquerdo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bracoDireitoMeta =
      const VerificationMeta('bracoDireito');
  @override
  late final GeneratedColumn<double> bracoDireito = GeneratedColumn<double>(
      'braco_direito', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _coxaEsquerdaMeta =
      const VerificationMeta('coxaEsquerda');
  @override
  late final GeneratedColumn<double> coxaEsquerda = GeneratedColumn<double>(
      'coxa_esquerda', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _coxaDireitaMeta =
      const VerificationMeta('coxaDireita');
  @override
  late final GeneratedColumn<double> coxaDireita = GeneratedColumn<double>(
      'coxa_direita', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _panturrilhaEsquerdaMeta =
      const VerificationMeta('panturrilhaEsquerda');
  @override
  late final GeneratedColumn<double> panturrilhaEsquerda =
      GeneratedColumn<double>('panturrilha_esquerda', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _panturrilhaDireitaMeta =
      const VerificationMeta('panturrilhaDireita');
  @override
  late final GeneratedColumn<double> panturrilhaDireita =
      GeneratedColumn<double>('panturrilha_direita', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _fotoPathMeta =
      const VerificationMeta('fotoPath');
  @override
  late final GeneratedColumn<String> fotoPath = GeneratedColumn<String>(
      'foto_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        data,
        peso,
        gorduraPercentual,
        massaMagra,
        imc,
        peito,
        cintura,
        bracoEsquerdo,
        bracoDireito,
        coxaEsquerda,
        coxaDireita,
        panturrilhaEsquerda,
        panturrilhaDireita,
        fotoPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(Insertable<BodyMeasurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('peso')) {
      context.handle(
          _pesoMeta, peso.isAcceptableOrUnknown(data['peso']!, _pesoMeta));
    }
    if (data.containsKey('gordura_percentual')) {
      context.handle(
          _gorduraPercentualMeta,
          gorduraPercentual.isAcceptableOrUnknown(
              data['gordura_percentual']!, _gorduraPercentualMeta));
    }
    if (data.containsKey('massa_magra')) {
      context.handle(
          _massaMagraMeta,
          massaMagra.isAcceptableOrUnknown(
              data['massa_magra']!, _massaMagraMeta));
    }
    if (data.containsKey('imc')) {
      context.handle(
          _imcMeta, imc.isAcceptableOrUnknown(data['imc']!, _imcMeta));
    }
    if (data.containsKey('peito')) {
      context.handle(
          _peitoMeta, peito.isAcceptableOrUnknown(data['peito']!, _peitoMeta));
    }
    if (data.containsKey('cintura')) {
      context.handle(_cinturaMeta,
          cintura.isAcceptableOrUnknown(data['cintura']!, _cinturaMeta));
    }
    if (data.containsKey('braco_esquerdo')) {
      context.handle(
          _bracoEsquerdoMeta,
          bracoEsquerdo.isAcceptableOrUnknown(
              data['braco_esquerdo']!, _bracoEsquerdoMeta));
    }
    if (data.containsKey('braco_direito')) {
      context.handle(
          _bracoDireitoMeta,
          bracoDireito.isAcceptableOrUnknown(
              data['braco_direito']!, _bracoDireitoMeta));
    }
    if (data.containsKey('coxa_esquerda')) {
      context.handle(
          _coxaEsquerdaMeta,
          coxaEsquerda.isAcceptableOrUnknown(
              data['coxa_esquerda']!, _coxaEsquerdaMeta));
    }
    if (data.containsKey('coxa_direita')) {
      context.handle(
          _coxaDireitaMeta,
          coxaDireita.isAcceptableOrUnknown(
              data['coxa_direita']!, _coxaDireitaMeta));
    }
    if (data.containsKey('panturrilha_esquerda')) {
      context.handle(
          _panturrilhaEsquerdaMeta,
          panturrilhaEsquerda.isAcceptableOrUnknown(
              data['panturrilha_esquerda']!, _panturrilhaEsquerdaMeta));
    }
    if (data.containsKey('panturrilha_direita')) {
      context.handle(
          _panturrilhaDireitaMeta,
          panturrilhaDireita.isAcceptableOrUnknown(
              data['panturrilha_direita']!, _panturrilhaDireitaMeta));
    }
    if (data.containsKey('foto_path')) {
      context.handle(_fotoPathMeta,
          fotoPath.isAcceptableOrUnknown(data['foto_path']!, _fotoPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      peso: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peso']),
      gorduraPercentual: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}gordura_percentual']),
      massaMagra: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}massa_magra']),
      imc: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}imc']),
      peito: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}peito']),
      cintura: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cintura']),
      bracoEsquerdo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}braco_esquerdo']),
      bracoDireito: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}braco_direito']),
      coxaEsquerda: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}coxa_esquerda']),
      coxaDireita: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}coxa_direita']),
      panturrilhaEsquerda: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}panturrilha_esquerda']),
      panturrilhaDireita: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}panturrilha_direita']),
      fotoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_path']),
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final int id;
  final String data;
  final double? peso;
  final double? gorduraPercentual;
  final double? massaMagra;
  final double? imc;
  final double? peito;
  final double? cintura;
  final double? bracoEsquerdo;
  final double? bracoDireito;
  final double? coxaEsquerda;
  final double? coxaDireita;
  final double? panturrilhaEsquerda;
  final double? panturrilhaDireita;
  final String? fotoPath;
  const BodyMeasurement(
      {required this.id,
      required this.data,
      this.peso,
      this.gorduraPercentual,
      this.massaMagra,
      this.imc,
      this.peito,
      this.cintura,
      this.bracoEsquerdo,
      this.bracoDireito,
      this.coxaEsquerda,
      this.coxaDireita,
      this.panturrilhaEsquerda,
      this.panturrilhaDireita,
      this.fotoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data'] = Variable<String>(data);
    if (!nullToAbsent || peso != null) {
      map['peso'] = Variable<double>(peso);
    }
    if (!nullToAbsent || gorduraPercentual != null) {
      map['gordura_percentual'] = Variable<double>(gorduraPercentual);
    }
    if (!nullToAbsent || massaMagra != null) {
      map['massa_magra'] = Variable<double>(massaMagra);
    }
    if (!nullToAbsent || imc != null) {
      map['imc'] = Variable<double>(imc);
    }
    if (!nullToAbsent || peito != null) {
      map['peito'] = Variable<double>(peito);
    }
    if (!nullToAbsent || cintura != null) {
      map['cintura'] = Variable<double>(cintura);
    }
    if (!nullToAbsent || bracoEsquerdo != null) {
      map['braco_esquerdo'] = Variable<double>(bracoEsquerdo);
    }
    if (!nullToAbsent || bracoDireito != null) {
      map['braco_direito'] = Variable<double>(bracoDireito);
    }
    if (!nullToAbsent || coxaEsquerda != null) {
      map['coxa_esquerda'] = Variable<double>(coxaEsquerda);
    }
    if (!nullToAbsent || coxaDireita != null) {
      map['coxa_direita'] = Variable<double>(coxaDireita);
    }
    if (!nullToAbsent || panturrilhaEsquerda != null) {
      map['panturrilha_esquerda'] = Variable<double>(panturrilhaEsquerda);
    }
    if (!nullToAbsent || panturrilhaDireita != null) {
      map['panturrilha_direita'] = Variable<double>(panturrilhaDireita);
    }
    if (!nullToAbsent || fotoPath != null) {
      map['foto_path'] = Variable<String>(fotoPath);
    }
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      data: Value(data),
      peso: peso == null && nullToAbsent ? const Value.absent() : Value(peso),
      gorduraPercentual: gorduraPercentual == null && nullToAbsent
          ? const Value.absent()
          : Value(gorduraPercentual),
      massaMagra: massaMagra == null && nullToAbsent
          ? const Value.absent()
          : Value(massaMagra),
      imc: imc == null && nullToAbsent ? const Value.absent() : Value(imc),
      peito:
          peito == null && nullToAbsent ? const Value.absent() : Value(peito),
      cintura: cintura == null && nullToAbsent
          ? const Value.absent()
          : Value(cintura),
      bracoEsquerdo: bracoEsquerdo == null && nullToAbsent
          ? const Value.absent()
          : Value(bracoEsquerdo),
      bracoDireito: bracoDireito == null && nullToAbsent
          ? const Value.absent()
          : Value(bracoDireito),
      coxaEsquerda: coxaEsquerda == null && nullToAbsent
          ? const Value.absent()
          : Value(coxaEsquerda),
      coxaDireita: coxaDireita == null && nullToAbsent
          ? const Value.absent()
          : Value(coxaDireita),
      panturrilhaEsquerda: panturrilhaEsquerda == null && nullToAbsent
          ? const Value.absent()
          : Value(panturrilhaEsquerda),
      panturrilhaDireita: panturrilhaDireita == null && nullToAbsent
          ? const Value.absent()
          : Value(panturrilhaDireita),
      fotoPath: fotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoPath),
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<int>(json['id']),
      data: serializer.fromJson<String>(json['data']),
      peso: serializer.fromJson<double?>(json['peso']),
      gorduraPercentual:
          serializer.fromJson<double?>(json['gorduraPercentual']),
      massaMagra: serializer.fromJson<double?>(json['massaMagra']),
      imc: serializer.fromJson<double?>(json['imc']),
      peito: serializer.fromJson<double?>(json['peito']),
      cintura: serializer.fromJson<double?>(json['cintura']),
      bracoEsquerdo: serializer.fromJson<double?>(json['bracoEsquerdo']),
      bracoDireito: serializer.fromJson<double?>(json['bracoDireito']),
      coxaEsquerda: serializer.fromJson<double?>(json['coxaEsquerda']),
      coxaDireita: serializer.fromJson<double?>(json['coxaDireita']),
      panturrilhaEsquerda:
          serializer.fromJson<double?>(json['panturrilhaEsquerda']),
      panturrilhaDireita:
          serializer.fromJson<double?>(json['panturrilhaDireita']),
      fotoPath: serializer.fromJson<String?>(json['fotoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'data': serializer.toJson<String>(data),
      'peso': serializer.toJson<double?>(peso),
      'gorduraPercentual': serializer.toJson<double?>(gorduraPercentual),
      'massaMagra': serializer.toJson<double?>(massaMagra),
      'imc': serializer.toJson<double?>(imc),
      'peito': serializer.toJson<double?>(peito),
      'cintura': serializer.toJson<double?>(cintura),
      'bracoEsquerdo': serializer.toJson<double?>(bracoEsquerdo),
      'bracoDireito': serializer.toJson<double?>(bracoDireito),
      'coxaEsquerda': serializer.toJson<double?>(coxaEsquerda),
      'coxaDireita': serializer.toJson<double?>(coxaDireita),
      'panturrilhaEsquerda': serializer.toJson<double?>(panturrilhaEsquerda),
      'panturrilhaDireita': serializer.toJson<double?>(panturrilhaDireita),
      'fotoPath': serializer.toJson<String?>(fotoPath),
    };
  }

  BodyMeasurement copyWith(
          {int? id,
          String? data,
          Value<double?> peso = const Value.absent(),
          Value<double?> gorduraPercentual = const Value.absent(),
          Value<double?> massaMagra = const Value.absent(),
          Value<double?> imc = const Value.absent(),
          Value<double?> peito = const Value.absent(),
          Value<double?> cintura = const Value.absent(),
          Value<double?> bracoEsquerdo = const Value.absent(),
          Value<double?> bracoDireito = const Value.absent(),
          Value<double?> coxaEsquerda = const Value.absent(),
          Value<double?> coxaDireita = const Value.absent(),
          Value<double?> panturrilhaEsquerda = const Value.absent(),
          Value<double?> panturrilhaDireita = const Value.absent(),
          Value<String?> fotoPath = const Value.absent()}) =>
      BodyMeasurement(
        id: id ?? this.id,
        data: data ?? this.data,
        peso: peso.present ? peso.value : this.peso,
        gorduraPercentual: gorduraPercentual.present
            ? gorduraPercentual.value
            : this.gorduraPercentual,
        massaMagra: massaMagra.present ? massaMagra.value : this.massaMagra,
        imc: imc.present ? imc.value : this.imc,
        peito: peito.present ? peito.value : this.peito,
        cintura: cintura.present ? cintura.value : this.cintura,
        bracoEsquerdo:
            bracoEsquerdo.present ? bracoEsquerdo.value : this.bracoEsquerdo,
        bracoDireito:
            bracoDireito.present ? bracoDireito.value : this.bracoDireito,
        coxaEsquerda:
            coxaEsquerda.present ? coxaEsquerda.value : this.coxaEsquerda,
        coxaDireita: coxaDireita.present ? coxaDireita.value : this.coxaDireita,
        panturrilhaEsquerda: panturrilhaEsquerda.present
            ? panturrilhaEsquerda.value
            : this.panturrilhaEsquerda,
        panturrilhaDireita: panturrilhaDireita.present
            ? panturrilhaDireita.value
            : this.panturrilhaDireita,
        fotoPath: fotoPath.present ? fotoPath.value : this.fotoPath,
      );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      data: data.data.present ? data.data.value : this.data,
      peso: data.peso.present ? data.peso.value : this.peso,
      gorduraPercentual: data.gorduraPercentual.present
          ? data.gorduraPercentual.value
          : this.gorduraPercentual,
      massaMagra:
          data.massaMagra.present ? data.massaMagra.value : this.massaMagra,
      imc: data.imc.present ? data.imc.value : this.imc,
      peito: data.peito.present ? data.peito.value : this.peito,
      cintura: data.cintura.present ? data.cintura.value : this.cintura,
      bracoEsquerdo: data.bracoEsquerdo.present
          ? data.bracoEsquerdo.value
          : this.bracoEsquerdo,
      bracoDireito: data.bracoDireito.present
          ? data.bracoDireito.value
          : this.bracoDireito,
      coxaEsquerda: data.coxaEsquerda.present
          ? data.coxaEsquerda.value
          : this.coxaEsquerda,
      coxaDireita:
          data.coxaDireita.present ? data.coxaDireita.value : this.coxaDireita,
      panturrilhaEsquerda: data.panturrilhaEsquerda.present
          ? data.panturrilhaEsquerda.value
          : this.panturrilhaEsquerda,
      panturrilhaDireita: data.panturrilhaDireita.present
          ? data.panturrilhaDireita.value
          : this.panturrilhaDireita,
      fotoPath: data.fotoPath.present ? data.fotoPath.value : this.fotoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('peso: $peso, ')
          ..write('gorduraPercentual: $gorduraPercentual, ')
          ..write('massaMagra: $massaMagra, ')
          ..write('imc: $imc, ')
          ..write('peito: $peito, ')
          ..write('cintura: $cintura, ')
          ..write('bracoEsquerdo: $bracoEsquerdo, ')
          ..write('bracoDireito: $bracoDireito, ')
          ..write('coxaEsquerda: $coxaEsquerda, ')
          ..write('coxaDireita: $coxaDireita, ')
          ..write('panturrilhaEsquerda: $panturrilhaEsquerda, ')
          ..write('panturrilhaDireita: $panturrilhaDireita, ')
          ..write('fotoPath: $fotoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      data,
      peso,
      gorduraPercentual,
      massaMagra,
      imc,
      peito,
      cintura,
      bracoEsquerdo,
      bracoDireito,
      coxaEsquerda,
      coxaDireita,
      panturrilhaEsquerda,
      panturrilhaDireita,
      fotoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.data == this.data &&
          other.peso == this.peso &&
          other.gorduraPercentual == this.gorduraPercentual &&
          other.massaMagra == this.massaMagra &&
          other.imc == this.imc &&
          other.peito == this.peito &&
          other.cintura == this.cintura &&
          other.bracoEsquerdo == this.bracoEsquerdo &&
          other.bracoDireito == this.bracoDireito &&
          other.coxaEsquerda == this.coxaEsquerda &&
          other.coxaDireita == this.coxaDireita &&
          other.panturrilhaEsquerda == this.panturrilhaEsquerda &&
          other.panturrilhaDireita == this.panturrilhaDireita &&
          other.fotoPath == this.fotoPath);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<int> id;
  final Value<String> data;
  final Value<double?> peso;
  final Value<double?> gorduraPercentual;
  final Value<double?> massaMagra;
  final Value<double?> imc;
  final Value<double?> peito;
  final Value<double?> cintura;
  final Value<double?> bracoEsquerdo;
  final Value<double?> bracoDireito;
  final Value<double?> coxaEsquerda;
  final Value<double?> coxaDireita;
  final Value<double?> panturrilhaEsquerda;
  final Value<double?> panturrilhaDireita;
  final Value<String?> fotoPath;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.data = const Value.absent(),
    this.peso = const Value.absent(),
    this.gorduraPercentual = const Value.absent(),
    this.massaMagra = const Value.absent(),
    this.imc = const Value.absent(),
    this.peito = const Value.absent(),
    this.cintura = const Value.absent(),
    this.bracoEsquerdo = const Value.absent(),
    this.bracoDireito = const Value.absent(),
    this.coxaEsquerda = const Value.absent(),
    this.coxaDireita = const Value.absent(),
    this.panturrilhaEsquerda = const Value.absent(),
    this.panturrilhaDireita = const Value.absent(),
    this.fotoPath = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required String data,
    this.peso = const Value.absent(),
    this.gorduraPercentual = const Value.absent(),
    this.massaMagra = const Value.absent(),
    this.imc = const Value.absent(),
    this.peito = const Value.absent(),
    this.cintura = const Value.absent(),
    this.bracoEsquerdo = const Value.absent(),
    this.bracoDireito = const Value.absent(),
    this.coxaEsquerda = const Value.absent(),
    this.coxaDireita = const Value.absent(),
    this.panturrilhaEsquerda = const Value.absent(),
    this.panturrilhaDireita = const Value.absent(),
    this.fotoPath = const Value.absent(),
  }) : data = Value(data);
  static Insertable<BodyMeasurement> custom({
    Expression<int>? id,
    Expression<String>? data,
    Expression<double>? peso,
    Expression<double>? gorduraPercentual,
    Expression<double>? massaMagra,
    Expression<double>? imc,
    Expression<double>? peito,
    Expression<double>? cintura,
    Expression<double>? bracoEsquerdo,
    Expression<double>? bracoDireito,
    Expression<double>? coxaEsquerda,
    Expression<double>? coxaDireita,
    Expression<double>? panturrilhaEsquerda,
    Expression<double>? panturrilhaDireita,
    Expression<String>? fotoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (data != null) 'data': data,
      if (peso != null) 'peso': peso,
      if (gorduraPercentual != null) 'gordura_percentual': gorduraPercentual,
      if (massaMagra != null) 'massa_magra': massaMagra,
      if (imc != null) 'imc': imc,
      if (peito != null) 'peito': peito,
      if (cintura != null) 'cintura': cintura,
      if (bracoEsquerdo != null) 'braco_esquerdo': bracoEsquerdo,
      if (bracoDireito != null) 'braco_direito': bracoDireito,
      if (coxaEsquerda != null) 'coxa_esquerda': coxaEsquerda,
      if (coxaDireita != null) 'coxa_direita': coxaDireita,
      if (panturrilhaEsquerda != null)
        'panturrilha_esquerda': panturrilhaEsquerda,
      if (panturrilhaDireita != null) 'panturrilha_direita': panturrilhaDireita,
      if (fotoPath != null) 'foto_path': fotoPath,
    });
  }

  BodyMeasurementsCompanion copyWith(
      {Value<int>? id,
      Value<String>? data,
      Value<double?>? peso,
      Value<double?>? gorduraPercentual,
      Value<double?>? massaMagra,
      Value<double?>? imc,
      Value<double?>? peito,
      Value<double?>? cintura,
      Value<double?>? bracoEsquerdo,
      Value<double?>? bracoDireito,
      Value<double?>? coxaEsquerda,
      Value<double?>? coxaDireita,
      Value<double?>? panturrilhaEsquerda,
      Value<double?>? panturrilhaDireita,
      Value<String?>? fotoPath}) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      data: data ?? this.data,
      peso: peso ?? this.peso,
      gorduraPercentual: gorduraPercentual ?? this.gorduraPercentual,
      massaMagra: massaMagra ?? this.massaMagra,
      imc: imc ?? this.imc,
      peito: peito ?? this.peito,
      cintura: cintura ?? this.cintura,
      bracoEsquerdo: bracoEsquerdo ?? this.bracoEsquerdo,
      bracoDireito: bracoDireito ?? this.bracoDireito,
      coxaEsquerda: coxaEsquerda ?? this.coxaEsquerda,
      coxaDireita: coxaDireita ?? this.coxaDireita,
      panturrilhaEsquerda: panturrilhaEsquerda ?? this.panturrilhaEsquerda,
      panturrilhaDireita: panturrilhaDireita ?? this.panturrilhaDireita,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (peso.present) {
      map['peso'] = Variable<double>(peso.value);
    }
    if (gorduraPercentual.present) {
      map['gordura_percentual'] = Variable<double>(gorduraPercentual.value);
    }
    if (massaMagra.present) {
      map['massa_magra'] = Variable<double>(massaMagra.value);
    }
    if (imc.present) {
      map['imc'] = Variable<double>(imc.value);
    }
    if (peito.present) {
      map['peito'] = Variable<double>(peito.value);
    }
    if (cintura.present) {
      map['cintura'] = Variable<double>(cintura.value);
    }
    if (bracoEsquerdo.present) {
      map['braco_esquerdo'] = Variable<double>(bracoEsquerdo.value);
    }
    if (bracoDireito.present) {
      map['braco_direito'] = Variable<double>(bracoDireito.value);
    }
    if (coxaEsquerda.present) {
      map['coxa_esquerda'] = Variable<double>(coxaEsquerda.value);
    }
    if (coxaDireita.present) {
      map['coxa_direita'] = Variable<double>(coxaDireita.value);
    }
    if (panturrilhaEsquerda.present) {
      map['panturrilha_esquerda'] = Variable<double>(panturrilhaEsquerda.value);
    }
    if (panturrilhaDireita.present) {
      map['panturrilha_direita'] = Variable<double>(panturrilhaDireita.value);
    }
    if (fotoPath.present) {
      map['foto_path'] = Variable<String>(fotoPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('data: $data, ')
          ..write('peso: $peso, ')
          ..write('gorduraPercentual: $gorduraPercentual, ')
          ..write('massaMagra: $massaMagra, ')
          ..write('imc: $imc, ')
          ..write('peito: $peito, ')
          ..write('cintura: $cintura, ')
          ..write('bracoEsquerdo: $bracoEsquerdo, ')
          ..write('bracoDireito: $bracoDireito, ')
          ..write('coxaEsquerda: $coxaEsquerda, ')
          ..write('coxaDireita: $coxaDireita, ')
          ..write('panturrilhaEsquerda: $panturrilhaEsquerda, ')
          ..write('panturrilhaDireita: $panturrilhaDireita, ')
          ..write('fotoPath: $fotoPath')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutSplitsTable workoutSplits = $WorkoutSplitsTable(this);
  late final $WorkoutDaysTable workoutDays = $WorkoutDaysTable(this);
  late final $WorkoutDayExercisesTable workoutDayExercises =
      $WorkoutDayExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions =
      $WorkoutSessionsTable(this);
  late final $ExerciseLogsTable exerciseLogs = $ExerciseLogsTable(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $WeeklyWeightsTable weeklyWeights = $WeeklyWeightsTable(this);
  late final $WeeklySchedulesTable weeklySchedules =
      $WeeklySchedulesTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements =
      $BodyMeasurementsTable(this);
  late final ExerciseDao exerciseDao = ExerciseDao(this as AppDatabase);
  late final WorkoutDao workoutDao = WorkoutDao(this as AppDatabase);
  late final LogDao logDao = LogDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        exercises,
        workoutSplits,
        workoutDays,
        workoutDayExercises,
        workoutSessions,
        exerciseLogs,
        userProfiles,
        weeklyWeights,
        weeklySchedules,
        goals,
        bodyMeasurements
      ];
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  required String nome,
  required String grupoMuscular,
  Value<String?> link,
  Value<bool> isUnilateral,
  Value<String> equipamento,
  Value<int> tempoDescansoSegundos,
  Value<String?> volume,
  Value<int> vezesFeito,
  Value<String?> observacoes,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String> grupoMuscular,
  Value<String?> link,
  Value<bool> isUnilateral,
  Value<String> equipamento,
  Value<int> tempoDescansoSegundos,
  Value<String?> volume,
  Value<int> vezesFeito,
  Value<String?> observacoes,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutDayExercisesTable,
      List<WorkoutDayExercise>> _workoutDayExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutDayExercises,
          aliasName: $_aliasNameGenerator(
              db.exercises.id, db.workoutDayExercises.exerciseId));

  $$WorkoutDayExercisesTableProcessedTableManager get workoutDayExercisesRefs {
    final manager =
        $$WorkoutDayExercisesTableTableManager($_db, $_db.workoutDayExercises)
            .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutDayExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ExerciseLogsTable, List<ExerciseLog>>
      _exerciseLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exerciseLogs,
              aliasName: $_aliasNameGenerator(
                  db.exercises.id, db.exerciseLogs.exerciseId));

  $$ExerciseLogsTableProcessedTableManager get exerciseLogsRefs {
    final manager = $$ExerciseLogsTableTableManager($_db, $_db.exerciseLogs)
        .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_exerciseLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals,
          aliasName:
              $_aliasNameGenerator(db.exercises.id, db.goals.exercicioId));

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.exercicioId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grupoMuscular => $composableBuilder(
      column: $table.grupoMuscular, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get link => $composableBuilder(
      column: $table.link, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tempoDescansoSegundos => $composableBuilder(
      column: $table.tempoDescansoSegundos,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vezesFeito => $composableBuilder(
      column: $table.vezesFeito, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutDayExercisesRefs(
      Expression<bool> Function($$WorkoutDayExercisesTableFilterComposer f) f) {
    final $$WorkoutDayExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDayExercises,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDayExercisesTableFilterComposer(
              $db: $db,
              $table: $db.workoutDayExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> exerciseLogsRefs(
      Expression<bool> Function($$ExerciseLogsTableFilterComposer f) f) {
    final $$ExerciseLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseLogsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> goalsRefs(
      Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.exercicioId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grupoMuscular => $composableBuilder(
      column: $table.grupoMuscular,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get link => $composableBuilder(
      column: $table.link, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tempoDescansoSegundos => $composableBuilder(
      column: $table.tempoDescansoSegundos,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vezesFeito => $composableBuilder(
      column: $table.vezesFeito, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get grupoMuscular => $composableBuilder(
      column: $table.grupoMuscular, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<bool> get isUnilateral => $composableBuilder(
      column: $table.isUnilateral, builder: (column) => column);

  GeneratedColumn<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => column);

  GeneratedColumn<int> get tempoDescansoSegundos => $composableBuilder(
      column: $table.tempoDescansoSegundos, builder: (column) => column);

  GeneratedColumn<String> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<int> get vezesFeito => $composableBuilder(
      column: $table.vezesFeito, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  Expression<T> workoutDayExercisesRefs<T extends Object>(
      Expression<T> Function($$WorkoutDayExercisesTableAnnotationComposer a)
          f) {
    final $$WorkoutDayExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.workoutDayExercises,
            getReferencedColumn: (t) => t.exerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkoutDayExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workoutDayExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> exerciseLogsRefs<T extends Object>(
      Expression<T> Function($$ExerciseLogsTableAnnotationComposer a) f) {
    final $$ExerciseLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseLogs,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
      Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.exercicioId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function(
        {bool workoutDayExercisesRefs,
        bool exerciseLogsRefs,
        bool goalsRefs})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String> grupoMuscular = const Value.absent(),
            Value<String?> link = const Value.absent(),
            Value<bool> isUnilateral = const Value.absent(),
            Value<String> equipamento = const Value.absent(),
            Value<int> tempoDescansoSegundos = const Value.absent(),
            Value<String?> volume = const Value.absent(),
            Value<int> vezesFeito = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            nome: nome,
            grupoMuscular: grupoMuscular,
            link: link,
            isUnilateral: isUnilateral,
            equipamento: equipamento,
            tempoDescansoSegundos: tempoDescansoSegundos,
            volume: volume,
            vezesFeito: vezesFeito,
            observacoes: observacoes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            required String grupoMuscular,
            Value<String?> link = const Value.absent(),
            Value<bool> isUnilateral = const Value.absent(),
            Value<String> equipamento = const Value.absent(),
            Value<int> tempoDescansoSegundos = const Value.absent(),
            Value<String?> volume = const Value.absent(),
            Value<int> vezesFeito = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            nome: nome,
            grupoMuscular: grupoMuscular,
            link: link,
            isUnilateral: isUnilateral,
            equipamento: equipamento,
            tempoDescansoSegundos: tempoDescansoSegundos,
            volume: volume,
            vezesFeito: vezesFeito,
            observacoes: observacoes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {workoutDayExercisesRefs = false,
              exerciseLogsRefs = false,
              goalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutDayExercisesRefs) db.workoutDayExercises,
                if (exerciseLogsRefs) db.exerciseLogs,
                if (goalsRefs) db.goals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutDayExercisesRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            WorkoutDayExercise>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._workoutDayExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .workoutDayExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (exerciseLogsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable,
                            ExerciseLog>(
                        currentTable: table,
                        referencedTable: $$ExercisesTableReferences
                            ._exerciseLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0)
                                .exerciseLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items),
                  if (goalsRefs)
                    await $_getPrefetchedData<Exercise, $ExercisesTable, Goal>(
                        currentTable: table,
                        referencedTable:
                            $$ExercisesTableReferences._goalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExercisesTableReferences(db, table, p0).goalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exercicioId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function(
        {bool workoutDayExercisesRefs, bool exerciseLogsRefs, bool goalsRefs})>;
typedef $$WorkoutSplitsTableCreateCompanionBuilder = WorkoutSplitsCompanion
    Function({
  Value<int> id,
  required String tipo,
  required String nome,
  Value<bool> ativo,
});
typedef $$WorkoutSplitsTableUpdateCompanionBuilder = WorkoutSplitsCompanion
    Function({
  Value<int> id,
  Value<String> tipo,
  Value<String> nome,
  Value<bool> ativo,
});

final class $$WorkoutSplitsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutSplitsTable, WorkoutSplit> {
  $$WorkoutSplitsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutDaysTable, List<WorkoutDay>>
      _workoutDaysRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutDays,
              aliasName: $_aliasNameGenerator(
                  db.workoutSplits.id, db.workoutDays.splitId));

  $$WorkoutDaysTableProcessedTableManager get workoutDaysRefs {
    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutDaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSplitsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSplitsTable> {
  $$WorkoutSplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutDaysRefs(
      Expression<bool> Function($$WorkoutDaysTableFilterComposer f) f) {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSplitsTable> {
  $$WorkoutSplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ativo => $composableBuilder(
      column: $table.ativo, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutSplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSplitsTable> {
  $$WorkoutSplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<bool> get ativo =>
      $composableBuilder(column: $table.ativo, builder: (column) => column);

  Expression<T> workoutDaysRefs<T extends Object>(
      Expression<T> Function($$WorkoutDaysTableAnnotationComposer a) f) {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSplitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSplitsTable,
    WorkoutSplit,
    $$WorkoutSplitsTableFilterComposer,
    $$WorkoutSplitsTableOrderingComposer,
    $$WorkoutSplitsTableAnnotationComposer,
    $$WorkoutSplitsTableCreateCompanionBuilder,
    $$WorkoutSplitsTableUpdateCompanionBuilder,
    (WorkoutSplit, $$WorkoutSplitsTableReferences),
    WorkoutSplit,
    PrefetchHooks Function({bool workoutDaysRefs})> {
  $$WorkoutSplitsTableTableManager(_$AppDatabase db, $WorkoutSplitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<bool> ativo = const Value.absent(),
          }) =>
              WorkoutSplitsCompanion(
            id: id,
            tipo: tipo,
            nome: nome,
            ativo: ativo,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tipo,
            required String nome,
            Value<bool> ativo = const Value.absent(),
          }) =>
              WorkoutSplitsCompanion.insert(
            id: id,
            tipo: tipo,
            nome: nome,
            ativo: ativo,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSplitsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({workoutDaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutDaysRefs) db.workoutDays],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutDaysRefs)
                    await $_getPrefetchedData<WorkoutSplit, $WorkoutSplitsTable,
                            WorkoutDay>(
                        currentTable: table,
                        referencedTable: $$WorkoutSplitsTableReferences
                            ._workoutDaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSplitsTableReferences(db, table, p0)
                                .workoutDaysRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.splitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutSplitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSplitsTable,
    WorkoutSplit,
    $$WorkoutSplitsTableFilterComposer,
    $$WorkoutSplitsTableOrderingComposer,
    $$WorkoutSplitsTableAnnotationComposer,
    $$WorkoutSplitsTableCreateCompanionBuilder,
    $$WorkoutSplitsTableUpdateCompanionBuilder,
    (WorkoutSplit, $$WorkoutSplitsTableReferences),
    WorkoutSplit,
    PrefetchHooks Function({bool workoutDaysRefs})>;
typedef $$WorkoutDaysTableCreateCompanionBuilder = WorkoutDaysCompanion
    Function({
  Value<int> id,
  required int splitId,
  required String letra,
  required String nome,
});
typedef $$WorkoutDaysTableUpdateCompanionBuilder = WorkoutDaysCompanion
    Function({
  Value<int> id,
  Value<int> splitId,
  Value<String> letra,
  Value<String> nome,
});

final class $$WorkoutDaysTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutDaysTable, WorkoutDay> {
  $$WorkoutDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSplitsTable _splitIdTable(_$AppDatabase db) =>
      db.workoutSplits.createAlias(
          $_aliasNameGenerator(db.workoutDays.splitId, db.workoutSplits.id));

  $$WorkoutSplitsTableProcessedTableManager get splitId {
    final $_column = $_itemColumn<int>('split_id')!;

    final manager = $$WorkoutSplitsTableTableManager($_db, $_db.workoutSplits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WorkoutDayExercisesTable,
      List<WorkoutDayExercise>> _workoutDayExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutDayExercises,
          aliasName: $_aliasNameGenerator(
              db.workoutDays.id, db.workoutDayExercises.dayId));

  $$WorkoutDayExercisesTableProcessedTableManager get workoutDayExercisesRefs {
    final manager =
        $$WorkoutDayExercisesTableTableManager($_db, $_db.workoutDayExercises)
            .filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutDayExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSession>>
      _workoutSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.workoutSessions,
              aliasName: $_aliasNameGenerator(
                  db.workoutDays.id, db.workoutSessions.dayId));

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager =
        $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions)
            .filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_workoutSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WeeklySchedulesTable, List<WeeklySchedule>>
      _weeklySchedulesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.weeklySchedules,
              aliasName: $_aliasNameGenerator(
                  db.workoutDays.id, db.weeklySchedules.dayId));

  $$WeeklySchedulesTableProcessedTableManager get weeklySchedulesRefs {
    final manager =
        $$WeeklySchedulesTableTableManager($_db, $_db.weeklySchedules)
            .filter((f) => f.dayId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_weeklySchedulesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutDaysTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get letra => $composableBuilder(
      column: $table.letra, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  $$WorkoutSplitsTableFilterComposer get splitId {
    final $$WorkoutSplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.workoutSplits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSplitsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSplits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> workoutDayExercisesRefs(
      Expression<bool> Function($$WorkoutDayExercisesTableFilterComposer f) f) {
    final $$WorkoutDayExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutDayExercises,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDayExercisesTableFilterComposer(
              $db: $db,
              $table: $db.workoutDayExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> workoutSessionsRefs(
      Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> weeklySchedulesRefs(
      Expression<bool> Function($$WeeklySchedulesTableFilterComposer f) f) {
    final $$WeeklySchedulesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weeklySchedules,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeeklySchedulesTableFilterComposer(
              $db: $db,
              $table: $db.weeklySchedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get letra => $composableBuilder(
      column: $table.letra, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  $$WorkoutSplitsTableOrderingComposer get splitId {
    final $$WorkoutSplitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.workoutSplits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSplitsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSplits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDaysTable> {
  $$WorkoutDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get letra =>
      $composableBuilder(column: $table.letra, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  $$WorkoutSplitsTableAnnotationComposer get splitId {
    final $$WorkoutSplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.workoutSplits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSplits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> workoutDayExercisesRefs<T extends Object>(
      Expression<T> Function($$WorkoutDayExercisesTableAnnotationComposer a)
          f) {
    final $$WorkoutDayExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.workoutDayExercises,
            getReferencedColumn: (t) => t.dayId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$WorkoutDayExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.workoutDayExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> workoutSessionsRefs<T extends Object>(
      Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> weeklySchedulesRefs<T extends Object>(
      Expression<T> Function($$WeeklySchedulesTableAnnotationComposer a) f) {
    final $$WeeklySchedulesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.weeklySchedules,
        getReferencedColumn: (t) => t.dayId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WeeklySchedulesTableAnnotationComposer(
              $db: $db,
              $table: $db.weeklySchedules,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutDaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, $$WorkoutDaysTableReferences),
    WorkoutDay,
    PrefetchHooks Function(
        {bool splitId,
        bool workoutDayExercisesRefs,
        bool workoutSessionsRefs,
        bool weeklySchedulesRefs})> {
  $$WorkoutDaysTableTableManager(_$AppDatabase db, $WorkoutDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> splitId = const Value.absent(),
            Value<String> letra = const Value.absent(),
            Value<String> nome = const Value.absent(),
          }) =>
              WorkoutDaysCompanion(
            id: id,
            splitId: splitId,
            letra: letra,
            nome: nome,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int splitId,
            required String letra,
            required String nome,
          }) =>
              WorkoutDaysCompanion.insert(
            id: id,
            splitId: splitId,
            letra: letra,
            nome: nome,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutDaysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {splitId = false,
              workoutDayExercisesRefs = false,
              workoutSessionsRefs = false,
              weeklySchedulesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutDayExercisesRefs) db.workoutDayExercises,
                if (workoutSessionsRefs) db.workoutSessions,
                if (weeklySchedulesRefs) db.weeklySchedules
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (splitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.splitId,
                    referencedTable:
                        $$WorkoutDaysTableReferences._splitIdTable(db),
                    referencedColumn:
                        $$WorkoutDaysTableReferences._splitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutDayExercisesRefs)
                    await $_getPrefetchedData<WorkoutDay, $WorkoutDaysTable, WorkoutDayExercise>(
                        currentTable: table,
                        referencedTable: $$WorkoutDaysTableReferences
                            ._workoutDayExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutDaysTableReferences(db, table, p0)
                                .workoutDayExercisesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.dayId == item.id),
                        typedResults: items),
                  if (workoutSessionsRefs)
                    await $_getPrefetchedData<WorkoutDay, $WorkoutDaysTable,
                            WorkoutSession>(
                        currentTable: table,
                        referencedTable: $$WorkoutDaysTableReferences
                            ._workoutSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutDaysTableReferences(db, table, p0)
                                .workoutSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.dayId == item.id),
                        typedResults: items),
                  if (weeklySchedulesRefs)
                    await $_getPrefetchedData<WorkoutDay, $WorkoutDaysTable,
                            WeeklySchedule>(
                        currentTable: table,
                        referencedTable: $$WorkoutDaysTableReferences
                            ._weeklySchedulesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutDaysTableReferences(db, table, p0)
                                .weeklySchedulesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.dayId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutDaysTable,
    WorkoutDay,
    $$WorkoutDaysTableFilterComposer,
    $$WorkoutDaysTableOrderingComposer,
    $$WorkoutDaysTableAnnotationComposer,
    $$WorkoutDaysTableCreateCompanionBuilder,
    $$WorkoutDaysTableUpdateCompanionBuilder,
    (WorkoutDay, $$WorkoutDaysTableReferences),
    WorkoutDay,
    PrefetchHooks Function(
        {bool splitId,
        bool workoutDayExercisesRefs,
        bool workoutSessionsRefs,
        bool weeklySchedulesRefs})>;
typedef $$WorkoutDayExercisesTableCreateCompanionBuilder
    = WorkoutDayExercisesCompanion Function({
  Value<int> id,
  required int dayId,
  required int exerciseId,
  required int ordem,
});
typedef $$WorkoutDayExercisesTableUpdateCompanionBuilder
    = WorkoutDayExercisesCompanion Function({
  Value<int> id,
  Value<int> dayId,
  Value<int> exerciseId,
  Value<int> ordem,
});

final class $$WorkoutDayExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutDayExercisesTable, WorkoutDayExercise> {
  $$WorkoutDayExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias($_aliasNameGenerator(
          db.workoutDayExercises.dayId, db.workoutDays.id));

  $$WorkoutDaysTableProcessedTableManager get dayId {
    final $_column = $_itemColumn<int>('day_id')!;

    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias($_aliasNameGenerator(
          db.workoutDayExercises.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutDayExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutDayExercisesTable> {
  $$WorkoutDayExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnFilters(column));

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutDayExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutDayExercisesTable> {
  $$WorkoutDayExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordem => $composableBuilder(
      column: $table.ordem, builder: (column) => ColumnOrderings(column));

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableOrderingComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutDayExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutDayExercisesTable> {
  $$WorkoutDayExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutDayExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutDayExercisesTable,
    WorkoutDayExercise,
    $$WorkoutDayExercisesTableFilterComposer,
    $$WorkoutDayExercisesTableOrderingComposer,
    $$WorkoutDayExercisesTableAnnotationComposer,
    $$WorkoutDayExercisesTableCreateCompanionBuilder,
    $$WorkoutDayExercisesTableUpdateCompanionBuilder,
    (WorkoutDayExercise, $$WorkoutDayExercisesTableReferences),
    WorkoutDayExercise,
    PrefetchHooks Function({bool dayId, bool exerciseId})> {
  $$WorkoutDayExercisesTableTableManager(
      _$AppDatabase db, $WorkoutDayExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutDayExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutDayExercisesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutDayExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> dayId = const Value.absent(),
            Value<int> exerciseId = const Value.absent(),
            Value<int> ordem = const Value.absent(),
          }) =>
              WorkoutDayExercisesCompanion(
            id: id,
            dayId: dayId,
            exerciseId: exerciseId,
            ordem: ordem,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int dayId,
            required int exerciseId,
            required int ordem,
          }) =>
              WorkoutDayExercisesCompanion.insert(
            id: id,
            dayId: dayId,
            exerciseId: exerciseId,
            ordem: ordem,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutDayExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayId,
                    referencedTable:
                        $$WorkoutDayExercisesTableReferences._dayIdTable(db),
                    referencedColumn:
                        $$WorkoutDayExercisesTableReferences._dayIdTable(db).id,
                  ) as T;
                }
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable: $$WorkoutDayExercisesTableReferences
                        ._exerciseIdTable(db),
                    referencedColumn: $$WorkoutDayExercisesTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WorkoutDayExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutDayExercisesTable,
    WorkoutDayExercise,
    $$WorkoutDayExercisesTableFilterComposer,
    $$WorkoutDayExercisesTableOrderingComposer,
    $$WorkoutDayExercisesTableAnnotationComposer,
    $$WorkoutDayExercisesTableCreateCompanionBuilder,
    $$WorkoutDayExercisesTableUpdateCompanionBuilder,
    (WorkoutDayExercise, $$WorkoutDayExercisesTableReferences),
    WorkoutDayExercise,
    PrefetchHooks Function({bool dayId, bool exerciseId})>;
typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<int> id,
  Value<int?> dayId,
  required String data,
  Value<String> status,
  Value<int?> duracaoSegundos,
});
typedef $$WorkoutSessionsTableUpdateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<int> id,
  Value<int?> dayId,
  Value<String> data,
  Value<String> status,
  Value<int?> duracaoSegundos,
});

final class $$WorkoutSessionsTableReferences extends BaseReferences<
    _$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias(
          $_aliasNameGenerator(db.workoutSessions.dayId, db.workoutDays.id));

  $$WorkoutDaysTableProcessedTableManager? get dayId {
    final $_column = $_itemColumn<int>('day_id');
    if ($_column == null) return null;
    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ExerciseLogsTable, List<ExerciseLog>>
      _exerciseLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exerciseLogs,
              aliasName: $_aliasNameGenerator(
                  db.workoutSessions.id, db.exerciseLogs.sessionId));

  $$ExerciseLogsTableProcessedTableManager get exerciseLogsRefs {
    final manager = $$ExerciseLogsTableTableManager($_db, $_db.exerciseLogs)
        .filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_exerciseLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duracaoSegundos => $composableBuilder(
      column: $table.duracaoSegundos,
      builder: (column) => ColumnFilters(column));

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> exerciseLogsRefs(
      Expression<bool> Function($$ExerciseLogsTableFilterComposer f) f) {
    final $$ExerciseLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseLogs,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseLogsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duracaoSegundos => $composableBuilder(
      column: $table.duracaoSegundos,
      builder: (column) => ColumnOrderings(column));

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableOrderingComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get duracaoSegundos => $composableBuilder(
      column: $table.duracaoSegundos, builder: (column) => column);

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> exerciseLogsRefs<T extends Object>(
      Expression<T> Function($$ExerciseLogsTableAnnotationComposer a) f) {
    final $$ExerciseLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exerciseLogs,
        getReferencedColumn: (t) => t.sessionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WorkoutSessionsTable,
    WorkoutSession,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (WorkoutSession, $$WorkoutSessionsTableReferences),
    WorkoutSession,
    PrefetchHooks Function({bool dayId, bool exerciseLogsRefs})> {
  $$WorkoutSessionsTableTableManager(
      _$AppDatabase db, $WorkoutSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> dayId = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> duracaoSegundos = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion(
            id: id,
            dayId: dayId,
            data: data,
            status: status,
            duracaoSegundos: duracaoSegundos,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> dayId = const Value.absent(),
            required String data,
            Value<String> status = const Value.absent(),
            Value<int?> duracaoSegundos = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion.insert(
            id: id,
            dayId: dayId,
            data: data,
            status: status,
            duracaoSegundos: duracaoSegundos,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WorkoutSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayId = false, exerciseLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (exerciseLogsRefs) db.exerciseLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayId,
                    referencedTable:
                        $$WorkoutSessionsTableReferences._dayIdTable(db),
                    referencedColumn:
                        $$WorkoutSessionsTableReferences._dayIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exerciseLogsRefs)
                    await $_getPrefetchedData<WorkoutSession,
                            $WorkoutSessionsTable, ExerciseLog>(
                        currentTable: table,
                        referencedTable: $$WorkoutSessionsTableReferences
                            ._exerciseLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WorkoutSessionsTableReferences(db, table, p0)
                                .exerciseLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sessionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WorkoutSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WorkoutSessionsTable,
    WorkoutSession,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (WorkoutSession, $$WorkoutSessionsTableReferences),
    WorkoutSession,
    PrefetchHooks Function({bool dayId, bool exerciseLogsRefs})>;
typedef $$ExerciseLogsTableCreateCompanionBuilder = ExerciseLogsCompanion
    Function({
  Value<int> id,
  required int exerciseId,
  required int sessionId,
  required String data,
  required double peso,
  required int repeticoes,
  Value<int> serie,
  Value<String> lado,
  Value<bool> concluido,
  Value<String?> equipamento,
  Value<String?> observacoes,
});
typedef $$ExerciseLogsTableUpdateCompanionBuilder = ExerciseLogsCompanion
    Function({
  Value<int> id,
  Value<int> exerciseId,
  Value<int> sessionId,
  Value<String> data,
  Value<double> peso,
  Value<int> repeticoes,
  Value<int> serie,
  Value<String> lado,
  Value<bool> concluido,
  Value<String?> equipamento,
  Value<String?> observacoes,
});

final class $$ExerciseLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ExerciseLogsTable, ExerciseLog> {
  $$ExerciseLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias(
          $_aliasNameGenerator(db.exerciseLogs.exerciseId, db.exercises.id));

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.workoutSessions.createAlias($_aliasNameGenerator(
          db.exerciseLogs.sessionId, db.workoutSessions.id));

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager =
        $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExerciseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repeticoes => $composableBuilder(
      column: $table.repeticoes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serie => $composableBuilder(
      column: $table.serie, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lado => $composableBuilder(
      column: $table.lado, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get concluido => $composableBuilder(
      column: $table.concluido, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableFilterComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repeticoes => $composableBuilder(
      column: $table.repeticoes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serie => $composableBuilder(
      column: $table.serie, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lado => $composableBuilder(
      column: $table.lado, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get concluido => $composableBuilder(
      column: $table.concluido, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableOrderingComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseLogsTable> {
  $$ExerciseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get peso =>
      $composableBuilder(column: $table.peso, builder: (column) => column);

  GeneratedColumn<int> get repeticoes => $composableBuilder(
      column: $table.repeticoes, builder: (column) => column);

  GeneratedColumn<int> get serie =>
      $composableBuilder(column: $table.serie, builder: (column) => column);

  GeneratedColumn<String> get lado =>
      $composableBuilder(column: $table.lado, builder: (column) => column);

  GeneratedColumn<bool> get concluido =>
      $composableBuilder(column: $table.concluido, builder: (column) => column);

  GeneratedColumn<String> get equipamento => $composableBuilder(
      column: $table.equipamento, builder: (column) => column);

  GeneratedColumn<String> get observacoes => $composableBuilder(
      column: $table.observacoes, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sessionId,
        referencedTable: $db.workoutSessions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExerciseLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseLogsTable,
    ExerciseLog,
    $$ExerciseLogsTableFilterComposer,
    $$ExerciseLogsTableOrderingComposer,
    $$ExerciseLogsTableAnnotationComposer,
    $$ExerciseLogsTableCreateCompanionBuilder,
    $$ExerciseLogsTableUpdateCompanionBuilder,
    (ExerciseLog, $$ExerciseLogsTableReferences),
    ExerciseLog,
    PrefetchHooks Function({bool exerciseId, bool sessionId})> {
  $$ExerciseLogsTableTableManager(_$AppDatabase db, $ExerciseLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> exerciseId = const Value.absent(),
            Value<int> sessionId = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<double> peso = const Value.absent(),
            Value<int> repeticoes = const Value.absent(),
            Value<int> serie = const Value.absent(),
            Value<String> lado = const Value.absent(),
            Value<bool> concluido = const Value.absent(),
            Value<String?> equipamento = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              ExerciseLogsCompanion(
            id: id,
            exerciseId: exerciseId,
            sessionId: sessionId,
            data: data,
            peso: peso,
            repeticoes: repeticoes,
            serie: serie,
            lado: lado,
            concluido: concluido,
            equipamento: equipamento,
            observacoes: observacoes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int exerciseId,
            required int sessionId,
            required String data,
            required double peso,
            required int repeticoes,
            Value<int> serie = const Value.absent(),
            Value<String> lado = const Value.absent(),
            Value<bool> concluido = const Value.absent(),
            Value<String?> equipamento = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              ExerciseLogsCompanion.insert(
            id: id,
            exerciseId: exerciseId,
            sessionId: sessionId,
            data: data,
            peso: peso,
            repeticoes: repeticoes,
            serie: serie,
            lado: lado,
            concluido: concluido,
            equipamento: equipamento,
            observacoes: observacoes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExerciseLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false, sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$ExerciseLogsTableReferences._exerciseIdTable(db),
                    referencedColumn:
                        $$ExerciseLogsTableReferences._exerciseIdTable(db).id,
                  ) as T;
                }
                if (sessionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sessionId,
                    referencedTable:
                        $$ExerciseLogsTableReferences._sessionIdTable(db),
                    referencedColumn:
                        $$ExerciseLogsTableReferences._sessionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExerciseLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExerciseLogsTable,
    ExerciseLog,
    $$ExerciseLogsTableFilterComposer,
    $$ExerciseLogsTableOrderingComposer,
    $$ExerciseLogsTableAnnotationComposer,
    $$ExerciseLogsTableCreateCompanionBuilder,
    $$ExerciseLogsTableUpdateCompanionBuilder,
    (ExerciseLog, $$ExerciseLogsTableReferences),
    ExerciseLog,
    PrefetchHooks Function({bool exerciseId, bool sessionId})>;
typedef $$UserProfilesTableCreateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<int> id,
  Value<String?> nome,
  Value<double?> pesoAtual,
  Value<double?> altura,
});
typedef $$UserProfilesTableUpdateCompanionBuilder = UserProfilesCompanion
    Function({
  Value<int> id,
  Value<String?> nome,
  Value<double?> pesoAtual,
  Value<double?> altura,
});

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pesoAtual => $composableBuilder(
      column: $table.pesoAtual, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get altura => $composableBuilder(
      column: $table.altura, builder: (column) => ColumnFilters(column));
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nome => $composableBuilder(
      column: $table.nome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pesoAtual => $composableBuilder(
      column: $table.pesoAtual, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get altura => $composableBuilder(
      column: $table.altura, builder: (column) => ColumnOrderings(column));
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<double> get pesoAtual =>
      $composableBuilder(column: $table.pesoAtual, builder: (column) => column);

  GeneratedColumn<double> get altura =>
      $composableBuilder(column: $table.altura, builder: (column) => column);
}

class $$UserProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()> {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> nome = const Value.absent(),
            Value<double?> pesoAtual = const Value.absent(),
            Value<double?> altura = const Value.absent(),
          }) =>
              UserProfilesCompanion(
            id: id,
            nome: nome,
            pesoAtual: pesoAtual,
            altura: altura,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> nome = const Value.absent(),
            Value<double?> pesoAtual = const Value.absent(),
            Value<double?> altura = const Value.absent(),
          }) =>
              UserProfilesCompanion.insert(
            id: id,
            nome: nome,
            pesoAtual: pesoAtual,
            altura: altura,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProfilesTable,
    UserProfile,
    $$UserProfilesTableFilterComposer,
    $$UserProfilesTableOrderingComposer,
    $$UserProfilesTableAnnotationComposer,
    $$UserProfilesTableCreateCompanionBuilder,
    $$UserProfilesTableUpdateCompanionBuilder,
    (
      UserProfile,
      BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>
    ),
    UserProfile,
    PrefetchHooks Function()>;
typedef $$WeeklyWeightsTableCreateCompanionBuilder = WeeklyWeightsCompanion
    Function({
  Value<int> id,
  required String semana,
  required double peso,
  required String data,
});
typedef $$WeeklyWeightsTableUpdateCompanionBuilder = WeeklyWeightsCompanion
    Function({
  Value<int> id,
  Value<String> semana,
  Value<double> peso,
  Value<String> data,
});

class $$WeeklyWeightsTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklyWeightsTable> {
  $$WeeklyWeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get semana => $composableBuilder(
      column: $table.semana, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$WeeklyWeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklyWeightsTable> {
  $$WeeklyWeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get semana => $composableBuilder(
      column: $table.semana, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$WeeklyWeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklyWeightsTable> {
  $$WeeklyWeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get semana =>
      $composableBuilder(column: $table.semana, builder: (column) => column);

  GeneratedColumn<double> get peso =>
      $composableBuilder(column: $table.peso, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$WeeklyWeightsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeeklyWeightsTable,
    WeeklyWeight,
    $$WeeklyWeightsTableFilterComposer,
    $$WeeklyWeightsTableOrderingComposer,
    $$WeeklyWeightsTableAnnotationComposer,
    $$WeeklyWeightsTableCreateCompanionBuilder,
    $$WeeklyWeightsTableUpdateCompanionBuilder,
    (
      WeeklyWeight,
      BaseReferences<_$AppDatabase, $WeeklyWeightsTable, WeeklyWeight>
    ),
    WeeklyWeight,
    PrefetchHooks Function()> {
  $$WeeklyWeightsTableTableManager(_$AppDatabase db, $WeeklyWeightsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyWeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyWeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyWeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> semana = const Value.absent(),
            Value<double> peso = const Value.absent(),
            Value<String> data = const Value.absent(),
          }) =>
              WeeklyWeightsCompanion(
            id: id,
            semana: semana,
            peso: peso,
            data: data,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String semana,
            required double peso,
            required String data,
          }) =>
              WeeklyWeightsCompanion.insert(
            id: id,
            semana: semana,
            peso: peso,
            data: data,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeeklyWeightsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeeklyWeightsTable,
    WeeklyWeight,
    $$WeeklyWeightsTableFilterComposer,
    $$WeeklyWeightsTableOrderingComposer,
    $$WeeklyWeightsTableAnnotationComposer,
    $$WeeklyWeightsTableCreateCompanionBuilder,
    $$WeeklyWeightsTableUpdateCompanionBuilder,
    (
      WeeklyWeight,
      BaseReferences<_$AppDatabase, $WeeklyWeightsTable, WeeklyWeight>
    ),
    WeeklyWeight,
    PrefetchHooks Function()>;
typedef $$WeeklySchedulesTableCreateCompanionBuilder = WeeklySchedulesCompanion
    Function({
  Value<int> id,
  required String diaSemana,
  Value<int?> dayId,
});
typedef $$WeeklySchedulesTableUpdateCompanionBuilder = WeeklySchedulesCompanion
    Function({
  Value<int> id,
  Value<String> diaSemana,
  Value<int?> dayId,
});

final class $$WeeklySchedulesTableReferences extends BaseReferences<
    _$AppDatabase, $WeeklySchedulesTable, WeeklySchedule> {
  $$WeeklySchedulesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutDaysTable _dayIdTable(_$AppDatabase db) =>
      db.workoutDays.createAlias(
          $_aliasNameGenerator(db.weeklySchedules.dayId, db.workoutDays.id));

  $$WorkoutDaysTableProcessedTableManager? get dayId {
    final $_column = $_itemColumn<int>('day_id');
    if ($_column == null) return null;
    final manager = $$WorkoutDaysTableTableManager($_db, $_db.workoutDays)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WeeklySchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $WeeklySchedulesTable> {
  $$WeeklySchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diaSemana => $composableBuilder(
      column: $table.diaSemana, builder: (column) => ColumnFilters(column));

  $$WorkoutDaysTableFilterComposer get dayId {
    final $$WorkoutDaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableFilterComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeeklySchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeeklySchedulesTable> {
  $$WeeklySchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diaSemana => $composableBuilder(
      column: $table.diaSemana, builder: (column) => ColumnOrderings(column));

  $$WorkoutDaysTableOrderingComposer get dayId {
    final $$WorkoutDaysTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableOrderingComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeeklySchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeeklySchedulesTable> {
  $$WeeklySchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get diaSemana =>
      $composableBuilder(column: $table.diaSemana, builder: (column) => column);

  $$WorkoutDaysTableAnnotationComposer get dayId {
    final $$WorkoutDaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.dayId,
        referencedTable: $db.workoutDays,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WorkoutDaysTableAnnotationComposer(
              $db: $db,
              $table: $db.workoutDays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$WeeklySchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeeklySchedulesTable,
    WeeklySchedule,
    $$WeeklySchedulesTableFilterComposer,
    $$WeeklySchedulesTableOrderingComposer,
    $$WeeklySchedulesTableAnnotationComposer,
    $$WeeklySchedulesTableCreateCompanionBuilder,
    $$WeeklySchedulesTableUpdateCompanionBuilder,
    (WeeklySchedule, $$WeeklySchedulesTableReferences),
    WeeklySchedule,
    PrefetchHooks Function({bool dayId})> {
  $$WeeklySchedulesTableTableManager(
      _$AppDatabase db, $WeeklySchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklySchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklySchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklySchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> diaSemana = const Value.absent(),
            Value<int?> dayId = const Value.absent(),
          }) =>
              WeeklySchedulesCompanion(
            id: id,
            diaSemana: diaSemana,
            dayId: dayId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String diaSemana,
            Value<int?> dayId = const Value.absent(),
          }) =>
              WeeklySchedulesCompanion.insert(
            id: id,
            diaSemana: diaSemana,
            dayId: dayId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$WeeklySchedulesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dayId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (dayId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.dayId,
                    referencedTable:
                        $$WeeklySchedulesTableReferences._dayIdTable(db),
                    referencedColumn:
                        $$WeeklySchedulesTableReferences._dayIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$WeeklySchedulesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeeklySchedulesTable,
    WeeklySchedule,
    $$WeeklySchedulesTableFilterComposer,
    $$WeeklySchedulesTableOrderingComposer,
    $$WeeklySchedulesTableAnnotationComposer,
    $$WeeklySchedulesTableCreateCompanionBuilder,
    $$WeeklySchedulesTableUpdateCompanionBuilder,
    (WeeklySchedule, $$WeeklySchedulesTableReferences),
    WeeklySchedule,
    PrefetchHooks Function({bool dayId})>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String tipo,
  Value<String?> exercicioNome,
  Value<int?> exercicioId,
  required double valorAlvo,
  Value<double?> valorInicial,
  required String dataCriacao,
  Value<bool> concluido,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> tipo,
  Value<String?> exercicioNome,
  Value<int?> exercicioId,
  Value<double> valorAlvo,
  Value<double?> valorInicial,
  Value<String> dataCriacao,
  Value<bool> concluido,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExercisesTable _exercicioIdTable(_$AppDatabase db) => db.exercises
      .createAlias($_aliasNameGenerator(db.goals.exercicioId, db.exercises.id));

  $$ExercisesTableProcessedTableManager? get exercicioId {
    final $_column = $_itemColumn<int>('exercicio_id');
    if ($_column == null) return null;
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exercicioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exercicioNome => $composableBuilder(
      column: $table.exercicioNome, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorAlvo => $composableBuilder(
      column: $table.valorAlvo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valorInicial => $composableBuilder(
      column: $table.valorInicial, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataCriacao => $composableBuilder(
      column: $table.dataCriacao, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get concluido => $composableBuilder(
      column: $table.concluido, builder: (column) => ColumnFilters(column));

  $$ExercisesTableFilterComposer get exercicioId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercicioId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exercicioNome => $composableBuilder(
      column: $table.exercicioNome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorAlvo => $composableBuilder(
      column: $table.valorAlvo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valorInicial => $composableBuilder(
      column: $table.valorInicial,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataCriacao => $composableBuilder(
      column: $table.dataCriacao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get concluido => $composableBuilder(
      column: $table.concluido, builder: (column) => ColumnOrderings(column));

  $$ExercisesTableOrderingComposer get exercicioId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercicioId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableOrderingComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get exercicioNome => $composableBuilder(
      column: $table.exercicioNome, builder: (column) => column);

  GeneratedColumn<double> get valorAlvo =>
      $composableBuilder(column: $table.valorAlvo, builder: (column) => column);

  GeneratedColumn<double> get valorInicial => $composableBuilder(
      column: $table.valorInicial, builder: (column) => column);

  GeneratedColumn<String> get dataCriacao => $composableBuilder(
      column: $table.dataCriacao, builder: (column) => column);

  GeneratedColumn<bool> get concluido =>
      $composableBuilder(column: $table.concluido, builder: (column) => column);

  $$ExercisesTableAnnotationComposer get exercicioId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exercicioId,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool exercicioId})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String?> exercicioNome = const Value.absent(),
            Value<int?> exercicioId = const Value.absent(),
            Value<double> valorAlvo = const Value.absent(),
            Value<double?> valorInicial = const Value.absent(),
            Value<String> dataCriacao = const Value.absent(),
            Value<bool> concluido = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            tipo: tipo,
            exercicioNome: exercicioNome,
            exercicioId: exercicioId,
            valorAlvo: valorAlvo,
            valorInicial: valorInicial,
            dataCriacao: dataCriacao,
            concluido: concluido,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tipo,
            Value<String?> exercicioNome = const Value.absent(),
            Value<int?> exercicioId = const Value.absent(),
            required double valorAlvo,
            Value<double?> valorInicial = const Value.absent(),
            required String dataCriacao,
            Value<bool> concluido = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            tipo: tipo,
            exercicioNome: exercicioNome,
            exercicioId: exercicioId,
            valorAlvo: valorAlvo,
            valorInicial: valorInicial,
            dataCriacao: dataCriacao,
            concluido: concluido,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({exercicioId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exercicioId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exercicioId,
                    referencedTable:
                        $$GoalsTableReferences._exercicioIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._exercicioIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool exercicioId})>;
typedef $$BodyMeasurementsTableCreateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  Value<int> id,
  required String data,
  Value<double?> peso,
  Value<double?> gorduraPercentual,
  Value<double?> massaMagra,
  Value<double?> imc,
  Value<double?> peito,
  Value<double?> cintura,
  Value<double?> bracoEsquerdo,
  Value<double?> bracoDireito,
  Value<double?> coxaEsquerda,
  Value<double?> coxaDireita,
  Value<double?> panturrilhaEsquerda,
  Value<double?> panturrilhaDireita,
  Value<String?> fotoPath,
});
typedef $$BodyMeasurementsTableUpdateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  Value<int> id,
  Value<String> data,
  Value<double?> peso,
  Value<double?> gorduraPercentual,
  Value<double?> massaMagra,
  Value<double?> imc,
  Value<double?> peito,
  Value<double?> cintura,
  Value<double?> bracoEsquerdo,
  Value<double?> bracoDireito,
  Value<double?> coxaEsquerda,
  Value<double?> coxaDireita,
  Value<double?> panturrilhaEsquerda,
  Value<double?> panturrilhaDireita,
  Value<String?> fotoPath,
});

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get gorduraPercentual => $composableBuilder(
      column: $table.gorduraPercentual,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get massaMagra => $composableBuilder(
      column: $table.massaMagra, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get imc => $composableBuilder(
      column: $table.imc, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get peito => $composableBuilder(
      column: $table.peito, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cintura => $composableBuilder(
      column: $table.cintura, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bracoEsquerdo => $composableBuilder(
      column: $table.bracoEsquerdo, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bracoDireito => $composableBuilder(
      column: $table.bracoDireito, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coxaEsquerda => $composableBuilder(
      column: $table.coxaEsquerda, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coxaDireita => $composableBuilder(
      column: $table.coxaDireita, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get panturrilhaEsquerda => $composableBuilder(
      column: $table.panturrilhaEsquerda,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get panturrilhaDireita => $composableBuilder(
      column: $table.panturrilhaDireita,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoPath => $composableBuilder(
      column: $table.fotoPath, builder: (column) => ColumnFilters(column));
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peso => $composableBuilder(
      column: $table.peso, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get gorduraPercentual => $composableBuilder(
      column: $table.gorduraPercentual,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get massaMagra => $composableBuilder(
      column: $table.massaMagra, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get imc => $composableBuilder(
      column: $table.imc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get peito => $composableBuilder(
      column: $table.peito, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cintura => $composableBuilder(
      column: $table.cintura, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bracoEsquerdo => $composableBuilder(
      column: $table.bracoEsquerdo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bracoDireito => $composableBuilder(
      column: $table.bracoDireito,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coxaEsquerda => $composableBuilder(
      column: $table.coxaEsquerda,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coxaDireita => $composableBuilder(
      column: $table.coxaDireita, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get panturrilhaEsquerda => $composableBuilder(
      column: $table.panturrilhaEsquerda,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get panturrilhaDireita => $composableBuilder(
      column: $table.panturrilhaDireita,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoPath => $composableBuilder(
      column: $table.fotoPath, builder: (column) => ColumnOrderings(column));
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<double> get peso =>
      $composableBuilder(column: $table.peso, builder: (column) => column);

  GeneratedColumn<double> get gorduraPercentual => $composableBuilder(
      column: $table.gorduraPercentual, builder: (column) => column);

  GeneratedColumn<double> get massaMagra => $composableBuilder(
      column: $table.massaMagra, builder: (column) => column);

  GeneratedColumn<double> get imc =>
      $composableBuilder(column: $table.imc, builder: (column) => column);

  GeneratedColumn<double> get peito =>
      $composableBuilder(column: $table.peito, builder: (column) => column);

  GeneratedColumn<double> get cintura =>
      $composableBuilder(column: $table.cintura, builder: (column) => column);

  GeneratedColumn<double> get bracoEsquerdo => $composableBuilder(
      column: $table.bracoEsquerdo, builder: (column) => column);

  GeneratedColumn<double> get bracoDireito => $composableBuilder(
      column: $table.bracoDireito, builder: (column) => column);

  GeneratedColumn<double> get coxaEsquerda => $composableBuilder(
      column: $table.coxaEsquerda, builder: (column) => column);

  GeneratedColumn<double> get coxaDireita => $composableBuilder(
      column: $table.coxaDireita, builder: (column) => column);

  GeneratedColumn<double> get panturrilhaEsquerda => $composableBuilder(
      column: $table.panturrilhaEsquerda, builder: (column) => column);

  GeneratedColumn<double> get panturrilhaDireita => $composableBuilder(
      column: $table.panturrilhaDireita, builder: (column) => column);

  GeneratedColumn<String> get fotoPath =>
      $composableBuilder(column: $table.fotoPath, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()> {
  $$BodyMeasurementsTableTableManager(
      _$AppDatabase db, $BodyMeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<double?> peso = const Value.absent(),
            Value<double?> gorduraPercentual = const Value.absent(),
            Value<double?> massaMagra = const Value.absent(),
            Value<double?> imc = const Value.absent(),
            Value<double?> peito = const Value.absent(),
            Value<double?> cintura = const Value.absent(),
            Value<double?> bracoEsquerdo = const Value.absent(),
            Value<double?> bracoDireito = const Value.absent(),
            Value<double?> coxaEsquerda = const Value.absent(),
            Value<double?> coxaDireita = const Value.absent(),
            Value<double?> panturrilhaEsquerda = const Value.absent(),
            Value<double?> panturrilhaDireita = const Value.absent(),
            Value<String?> fotoPath = const Value.absent(),
          }) =>
              BodyMeasurementsCompanion(
            id: id,
            data: data,
            peso: peso,
            gorduraPercentual: gorduraPercentual,
            massaMagra: massaMagra,
            imc: imc,
            peito: peito,
            cintura: cintura,
            bracoEsquerdo: bracoEsquerdo,
            bracoDireito: bracoDireito,
            coxaEsquerda: coxaEsquerda,
            coxaDireita: coxaDireita,
            panturrilhaEsquerda: panturrilhaEsquerda,
            panturrilhaDireita: panturrilhaDireita,
            fotoPath: fotoPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String data,
            Value<double?> peso = const Value.absent(),
            Value<double?> gorduraPercentual = const Value.absent(),
            Value<double?> massaMagra = const Value.absent(),
            Value<double?> imc = const Value.absent(),
            Value<double?> peito = const Value.absent(),
            Value<double?> cintura = const Value.absent(),
            Value<double?> bracoEsquerdo = const Value.absent(),
            Value<double?> bracoDireito = const Value.absent(),
            Value<double?> coxaEsquerda = const Value.absent(),
            Value<double?> coxaDireita = const Value.absent(),
            Value<double?> panturrilhaEsquerda = const Value.absent(),
            Value<double?> panturrilhaDireita = const Value.absent(),
            Value<String?> fotoPath = const Value.absent(),
          }) =>
              BodyMeasurementsCompanion.insert(
            id: id,
            data: data,
            peso: peso,
            gorduraPercentual: gorduraPercentual,
            massaMagra: massaMagra,
            imc: imc,
            peito: peito,
            cintura: cintura,
            bracoEsquerdo: bracoEsquerdo,
            bracoDireito: bracoDireito,
            coxaEsquerda: coxaEsquerda,
            coxaDireita: coxaDireita,
            panturrilhaEsquerda: panturrilhaEsquerda,
            panturrilhaDireita: panturrilhaDireita,
            fotoPath: fotoPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyMeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutSplitsTableTableManager get workoutSplits =>
      $$WorkoutSplitsTableTableManager(_db, _db.workoutSplits);
  $$WorkoutDaysTableTableManager get workoutDays =>
      $$WorkoutDaysTableTableManager(_db, _db.workoutDays);
  $$WorkoutDayExercisesTableTableManager get workoutDayExercises =>
      $$WorkoutDayExercisesTableTableManager(_db, _db.workoutDayExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$ExerciseLogsTableTableManager get exerciseLogs =>
      $$ExerciseLogsTableTableManager(_db, _db.exerciseLogs);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$WeeklyWeightsTableTableManager get weeklyWeights =>
      $$WeeklyWeightsTableTableManager(_db, _db.weeklyWeights);
  $$WeeklySchedulesTableTableManager get weeklySchedules =>
      $$WeeklySchedulesTableTableManager(_db, _db.weeklySchedules);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
}
