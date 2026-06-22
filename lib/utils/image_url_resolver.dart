import '../services/api_client.dart';

class ImageUrlResolver {
  /// Base publica das imagens no novo servidor (UFSJ), derivada da base da API.
  static String get _uploadsBase {
    final api = ApiClient.defaultBaseUrl; // .../api
    final root = api.endsWith('/api')
        ? api.substring(0, api.length - '/api'.length)
        : api;
    return '$root/uploads';
  }

  /// Normaliza a URL de uma imagem.
  ///
  /// - URLs absolutas (http/https) sao retornadas como estao. Isso preserva
  ///   tanto as imagens novas (URLs completas do servidor da UFSJ) quanto as
  ///   imagens legadas (ex.: api.devjoelchagas.com.br), que continuam
  ///   acessiveis no host original.
  /// - Caminhos relativos sao resolvidos contra a base de uploads atual.
  static String resolve(String source) {
    final value = source.trim();
    if (value.isEmpty) return value;

    final normalized = value.toLowerCase();
    final isAbsolute =
        normalized.startsWith('http://') || normalized.startsWith('https://');
    if (isAbsolute) {
      return value;
    }

    // Caminho relativo: resolve contra a base de uploads.
    final relIndex = value.indexOf('uploads/');
    final relative =
        relIndex == -1 ? value : value.substring(relIndex + 'uploads/'.length);
    final clean = relative.replaceFirst(RegExp(r'^/+'), '');
    return clean.isEmpty ? _uploadsBase : '$_uploadsBase/$clean';
  }
}
