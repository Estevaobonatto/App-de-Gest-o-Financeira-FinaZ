import 'dart:async';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final _controller = StreamController<String>.broadcast();

  Stream<String> get onDatabaseChanged => _controller.stream;

  void notifyDatabaseChanged(String event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
