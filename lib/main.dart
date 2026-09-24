// Activity 05: The Basic (undergraduate)
// Starter: supplied lib/main.dart. Changes from the starter are marked "CHANGE".

// BLOCK 1: Import Flutter's Material widgets and launch the app.
import 'package:flutter/material.dart';

void main() => runApp(const CounterApp());

// BLOCK 2: This app shell does not change, so it is a StatelessWidget.
class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CounterPage(),
    );
  }
}

// BLOCK 3: This screen changes after user interactions, so it is stateful.
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  // BLOCK 4: State fields determine what the user sees at any moment.
  static const int _min = 0;
  static const int _max = 100;

  int _counter = 0; // committed value; changed only by _moveTo() and _undo()
  int _increment = 1; // last VALID increment; changed only by _readIncrement()
  final List<int> _history = []; // prior committed values, newest last
  final TextEditingController _incrementController =
      TextEditingController(text: '1');

  // CHANGE: live slider position while the thumb is being dragged.
  // null means "not dragging", so the slider shows _counter.
  double? _dragValue;

  // CHANGE: inline error for the increment field (null = input is valid).
  String? _inputError;

  @override
  void dispose() {
    // Controllers use resources; dispose them when this screen is removed.
    _incrementController.dispose();
    super.dispose();
  }

  // BLOCK 5: Helper methods enforce rules before they change UI state.
  bool _isValidValue(int value) => value >= _min && value <= _max;

  // Activity 05 color rule: red at 0, green above 50, black otherwise.
  // CHANGE: takes the value to color so the preview during a drag is correct.
  Color _counterColor(int value) {
    if (value == 0) return Colors.red;
    if (value > 50) return Colors.green;
    return Colors.black;
  }

  void _showMessage(String message) {
    // CHANGE: replace the current SnackBar instead of queueing a backlog,
    // so the message on screen always matches the latest action.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // Every change to _counter (except undo) goes through here.
  // CHANGE: [attempted] names the action so rejection feedback can say
  // what was tried, which rule blocked it, and what is still possible.
  void _moveTo(int nextValue, {String attempted = 'That move'}) {
    // Reject the action before changing state or creating a history record.
    if (!_isValidValue(nextValue)) {
      _showMessage(_limitMessage(nextValue, attempted));
      return;
    }

    // CHANGE: a "move" that does not change the value is not history.
    if (nextValue == _counter) return;

    setState(() {
      _history.add(_counter); // Save only the state that can be restored.
      _counter = nextValue;
    });
  }

  // CHANGE: boundary feedback = attempted action + violated limit + next option.
  String _limitMessage(int nextValue, String attempted) {
    if (nextValue > _max) {
      if (_counter == _max) {
        return '$attempted blocked: already at the max of $_max. '
            'You can Decrease, Undo, or Reset.';
      }
      return '$attempted blocked: $nextValue is above the max of $_max. '
          'Still at $_counter. Use an increment of ${_max - _counter} or less.';
    }
    if (_counter == _min) {
      return '$attempted blocked: already at the min of $_min. '
          'You can Increase or move the slider.';
    }
    return '$attempted blocked: $nextValue is below the min of $_min. '
        'Still at $_counter. Use an increment of ${_counter - _min} or less.';
  }

  void _readIncrement(String input) {
    final text = input.trim();
    final value = int.tryParse(text);
    String? error;

    // CHANGE (TODO done): each message says what was wrong, what is accepted,
    // and that the previous valid increment is still in use.
    if (text.isEmpty) {
      error = 'Empty. Enter a whole number from 1 to $_max.';
    } else if (text.contains('.')) {
      error = 'No decimals. Enter a whole number from 1 to $_max.';
    } else if (value == null) {
      error = '"$text" is not a number. Use digits only, 1 to $_max.';
    } else if (value <= 0) {
      error = 'Must be at least 1. Enter a whole number from 1 to $_max.';
    } else if (value > _max) {
      error = 'Too large. Enter a whole number from 1 to $_max.';
    }

    setState(() {
      if (error != null) {
        // Keep the last valid increment unchanged; only the error is new.
        _inputError = '$error Still using $_increment.';
      } else {
        _inputError = null;
        _increment = value!;
      }
    });
  }

  void _undo() {
    if (_history.isEmpty) {
      _showMessage('Nothing to undo. $_counter is the earliest value.');
      return;
    }
    setState(() => _counter = _history.removeLast());
  }

  void _reset() {
    if (_counter == 0) {
      _showMessage('Already at 0. Nothing to reset.');
      return;
    }
    _moveTo(0, attempted: 'Reset'); // goes through _moveTo, so Reset is undoable
  }

  @override
  Widget build(BuildContext context) {
    // BLOCK 6: Build reads state and connects widgets to user actions.
    // While dragging, preview the thumb value; otherwise show the committed value.
    final int shown = _dragValue?.round() ?? _counter;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity 05 Counter')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$shown',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: _counterColor(shown),
                  ),
            ),
            Slider(
              value: (_dragValue ?? _counter).toDouble(),
              min: _min.toDouble(),
              max: _max.toDouble(),
              divisions: _max - _min,
              label: '$shown',
              // CHANGE (TODO done): a slider drag enters history ONCE, when the
              // thumb is released. onChanged fires for every tick passed
              // (0 -> 40 could be 40 entries), which would make Undo walk back
              // one tick at a time. So onChanged only previews, and
              // onChangeEnd commits through _moveTo(), keeping range and
              // history rules in one place.
              onChanged: (value) => setState(() => _dragValue = value),
              onChangeEnd: (value) {
                setState(() => _dragValue = null);
                _moveTo(value.round(), attempted: 'Slider move');
              },
            ),
            // CHANGE (UI improvement): show the allowed range at the slider ends.
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Min 0'), Text('Max 100')],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _incrementController,
              keyboardType: TextInputType.number,
              // CHANGE (UI improvement): inline error + helper text so the user
              // sees the problem at the field, while typing, and always knows
              // which increment the buttons will use.
              decoration: InputDecoration(
                labelText: 'Increment amount',
                helperText: 'Buttons use $_increment (whole number, 1 to $_max)',
                errorText: _inputError,
                errorMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
              onChanged: _readIncrement,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // CHANGE (UI improvement): labels show the amount that will apply.
                ElevatedButton(
                  onPressed: () => _moveTo(_counter - _increment,
                      attempted: 'Decrease by $_increment'),
                  child: Text('Decrease by $_increment'),
                ),
                ElevatedButton(
                  onPressed: () => _moveTo(_counter + _increment,
                      attempted: 'Increase by $_increment'),
                  child: Text('Increase by $_increment'),
                ),
                OutlinedButton(onPressed: _reset, child: const Text('Reset')),
                OutlinedButton(onPressed: _undo, child: const Text('Undo')),
              ],
            ),
            const SizedBox(height: 20),
            Text(_history.isEmpty
                ? 'History: none'
                : 'History: ${_history.join(', ')}'),
          ],
        ),
      ),
    );
  }
}
