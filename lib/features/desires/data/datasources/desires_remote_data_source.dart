import '/core/network/backend_client.dart';

/// Remote data source for the desires feature — thin wrapper over the relevant
/// slice of the shared [BackendClient].
abstract class DesiresRemoteDataSource {
  Future<List<Map<String, dynamic>>> getDesires();
  Future<void> deleteStory(int storyId);
}

class DesiresRemoteDataSourceImpl implements DesiresRemoteDataSource {
  const DesiresRemoteDataSourceImpl();

  @override
  Future<List<Map<String, dynamic>>> getDesires() => BackendClient.getDesires();

  @override
  Future<void> deleteStory(int storyId) => BackendClient.deleteStory(storyId);
}
