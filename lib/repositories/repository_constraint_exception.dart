class RepositoryConstraintException implements Exception {
  const RepositoryConstraintException(this.message);

  final String message;

  @override
  String toString() => 'RepositoryConstraintException: $message';
}
