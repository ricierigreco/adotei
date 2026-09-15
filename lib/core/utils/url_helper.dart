import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  // Abre conversa no WhatsApp com número formatado e mensagem pré-definida
  static Future<bool> openWhatsApp(String phone, String message) async {
    // Remove caracteres não numéricos do telefone
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    // Se o número não começar com o código do país (ex: 55 para o Brasil), adiciona
    String formattedPhone = cleanPhone;
    if (cleanPhone.length == 10 || cleanPhone.length == 11) {
      formattedPhone = '55$cleanPhone';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = 'https://wa.me/$formattedPhone?text=$encodedMessage';
    final Uri url = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback para web/desktop caso wa.me falhe, abrindo api.whatsapp.com
        final webUrl = Uri.parse(
          'https://api.whatsapp.com/send?phone=$formattedPhone&text=$encodedMessage',
        );
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erro ao abrir WhatsApp: $e');
      return false;
    }
  }

  // Faz ligação telefônica direta
  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
      return false;
    } catch (e) {
      print('Erro ao fazer ligação: $e');
      return false;
    }
  }

  // Abre cliente de e-mail padrão
  static Future<bool> sendEmail(
    String email,
    String subject,
    String body,
  ) async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
      return false;
    } catch (e) {
      print('Erro ao enviar e-mail: $e');
      return false;
    }
  }
}
