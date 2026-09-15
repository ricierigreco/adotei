import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ImageHelper {
  // Comprime e redimensiona imagem usando o pacote 'image' (100% compatível com Web, Android, iOS e Windows)
  static Future<Uint8List?> compressImage(
    XFile file, {
    int maxWidth = 800,
    int quality = 80,
  }) async {
    try {
      final Uint8List originalBytes = await file.readAsBytes();

      // Decodifica a imagem
      final img.Image? decoded = img.decodeImage(originalBytes);
      if (decoded == null) return null;

      // Mantém a proporção e redimensiona se for maior que o maxWidth
      img.Image resized = decoded;
      if (decoded.width > maxWidth || decoded.height > maxWidth) {
        if (decoded.width > decoded.height) {
          resized = img.copyResize(decoded, width: maxWidth);
        } else {
          resized = img.copyResize(decoded, height: maxWidth);
        }
      }

      // Codifica de volta para JPEG com qualidade especificada
      final List<int> compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      print('Erro ao comprimir imagem: $e');
      return null;
    }
  }

  // Converter bytes comprimidos em URI de dados (útil para exibir na Web sem precisar salvar em arquivo temporário)
  static String bytesToDataUrl(Uint8List bytes, String mimeType) {
    final String base64String = Uri.encodeComponent(
      String.fromCharCodes(bytes),
    );
    return 'data:$mimeType;base64,$base64String';
  }
}
