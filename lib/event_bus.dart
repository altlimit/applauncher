class EventBus {
  late Map<String, List<Function>> _listeners;

  EventBus() {
    _listeners = Map<String, List<Function>>();
  }

  void on(String event, Function callback) {
    if (!_listeners.containsKey(event)) {
      _listeners[event] = List<Function>.empty(growable: true);
    }
    if (!_listeners[event]!.contains(callback)) {
      _listeners[event]!.add(callback);
    }
  }

  void off(String event, Function callback) {
    if (_listeners.containsKey(event)) {
      var idx = _listeners[event]!.indexOf(callback);
      if (idx != -1) {
        _listeners[event]!.removeAt(idx);
      }
        }
  }

  void emit(String event, {dynamic payload}) {
    if (_listeners.containsKey(event) && _listeners[event]!.length > 0) {
      _listeners[event]!.forEach((callback) {
        if (payload != null) {
          callback(payload: payload);
        } else {
          callback();
        }
      });
    } else {
      print('EventBus: no listeners found for ' + event);
    }
  }
}
