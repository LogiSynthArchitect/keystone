abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

abstract class NoParamsUseCase<Output> {
  Future<Output> call();
}

class NoParams {
  const NoParams();
}
