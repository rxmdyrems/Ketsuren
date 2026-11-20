import 'dart:math';

class VoiceSearchArtwork {
  VoiceSearchArtwork({Random? random}) : _random = random ?? Random();

  static const urls = [
    'https://media.tenor.com/EjowFmPUajMAAAAj/death-note-l-lawliet.gif',
    '',
  ];

  final Random _random;
  String? _previous;

  String next() {
    final choices = urls
        .where((url) => url != _previous)
        .toList(growable: false);
    final chosen = choices[_random.nextInt(choices.length)];
    _previous = chosen;
    return chosen;
  }
}
