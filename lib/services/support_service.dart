import 'dart:convert';
import 'http_client.dart'; // Importe seu cliente HTTP/Dio customizado caso use um

class SupportService {
  // Ajuste a URL base conforme a configurada no seu app
  static const String baseUrl = 'https://capim.ufsj.edu.br/api';

  /// Envia o chamado de suporte (Rota Pública)
  static Future<bool> sendTicket({
    required String name,
    required String email,
    required String subject,
    required String description,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/support'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'subject': subject,
        'description': description,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Busca os chamados para o Painel Admin (Rota Privada)
  static Future<List<dynamic>> fetchTickets(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/support/tickets'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['tickets'] ?? [];
    }
    throw Exception('Falha ao carregar chamados.');
  }
}