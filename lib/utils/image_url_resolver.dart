class ImageUrlResolver {
  static const String _uploadsBase =
      'https://api.devjoelchagas.com.br/uploads';

  static String resolve(String source) {
    final value = source.trim();
    if (value.isEmpty) return value;

    final normalized = value.toLowerCase();
    final isRemote =
        normalized.startsWith('http://') || normalized.startsWith('https://');

    if (!isRemote) {
      return value;
    }

    final uploadsIndex = normalized.indexOf('/uploads/');
    if (uploadsIndex == -1) {
      return value;
    }

    final uploadsPath = value.substring(uploadsIndex + '/uploads/'.length);
    if (uploadsPath.isEmpty) {
      return _uploadsBase;
    }

    return '$_uploadsBase/$uploadsPath';
  }
}
