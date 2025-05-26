// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'features/chat/data/datasources/chat_api_service.dart' as _i101;
import 'injection.dart' as _i464;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  gh.lazySingleton<String>(
    () => registerModule.baseUrl,
    instanceName: 'baseUrl',
  );
  gh.lazySingleton<_i101.ChatApiService>(() =>
      _i101.ChatApiService(baseUrl: gh<String>(instanceName: 'baseUrl')));
  return getIt;
}

class _$RegisterModule extends _i464.RegisterModule {}
