import 'dart:async';

/// Cria um [Stream] que busca [fetch] imediatamente e, em seguida, repete a
/// cada [interval]. Substitui o tempo real do Firestore (`snapshots()`) por
/// polling — mantendo as telas baseadas em `StreamBuilder` praticamente
/// inalteradas.
///
/// - Emite o primeiro valor o quanto antes (sem esperar o primeiro intervalo).
/// - Erros de uma busca individual sao repassados ao stream (o `StreamBuilder`
///   pode exibi-los), mas o polling continua na proxima iteracao.
/// - O timer e cancelado automaticamente quando o stream nao tem ouvintes.
Stream<T> pollingStream<T>(
  Future<T> Function() fetch, {
  Duration interval = const Duration(seconds: 25),
}) {
  late final StreamController<T> controller;
  Timer? timer;
  var isFetching = false;
  var closed = false;

  Future<void> tick() async {
    if (isFetching || closed) return;
    isFetching = true;
    try {
      final value = await fetch();
      if (!closed) controller.add(value);
    } catch (error, stack) {
      if (!closed) controller.addError(error, stack);
    } finally {
      isFetching = false;
    }
  }

  void start() {
    tick();
    timer = Timer.periodic(interval, (_) => tick());
  }

  void stop() {
    closed = true;
    timer?.cancel();
    timer = null;
  }

  controller = StreamController<T>(
    onListen: start,
    onCancel: stop,
  );

  return controller.stream;
}
