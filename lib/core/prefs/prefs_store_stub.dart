/// Hors navigateur (démo) : préférences gardées en mémoire.
final _memory = <String, String>{};

String? readPref(String key) => _memory[key];

void writePref(String key, String value) => _memory[key] = value;
