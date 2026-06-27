import '../../domain/repositories/desires_repository.dart';
import '../datasources/desires_remote_data_source.dart';

/// Default [DesiresRepository] backed by [DesiresRemoteDataSource].
class DesiresRepositoryImpl implements DesiresRepository {
  const DesiresRepositoryImpl(this._remote);

  final DesiresRemoteDataSource _remote;

  @override
  Future<List<Map<String, dynamic>>> getDesires() => _remote.getDesires();

  @override
  Future<void> deleteStory(int storyId) => _remote.deleteStory(storyId);
}
