import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionsService {
  // Nome da função callable (usando a função existente)
  static const String _compareImagesFunction = 'compareImages';
  
  // Região onde a função está deployada
  static const String _region = 'us-central1';

  /// Chama a Cloud Function para comparar duas imagens
  /// 
  /// [baseImageUrl] - URL da imagem antiga (base)
  /// [comparedImageUrl] - URL da imagem nova (comparada)
  /// [pontoObra] - Ponto da obra
  /// [etapaObra] - Etapa da obra
  /// 
  /// Retorna um Map com os resultados da comparação
  static Future<Map<String, dynamic>> compareImages({
    required String baseImageUrl,
    required String comparedImageUrl,
    required String pontoObra,
    required String etapaObra,
  }) async {
    try {
      // Configurar Firebase Functions com região explícita
      final functions = FirebaseFunctions.instanceFor(
        region: _region,
      );
      
      // Preparar dados para enviar
      final requestData = {
        'baseImageUrl': baseImageUrl,
        'comparedImageUrl': comparedImageUrl,
        'pontoObra': pontoObra,
        'etapaObra': etapaObra,
      };

      print('🔵 Chamando Cloud Function: $_compareImagesFunction');
      print('🔵 Região: $_region');
      print('📤 Dados enviados: ${jsonEncode(requestData)}');

      // Chamar função callable
      final callable = functions.httpsCallable(_compareImagesFunction);
      final result = await callable.call(requestData).timeout(
        const Duration(seconds: 120), // Timeout aumentado para 120 segundos (IA pode demorar)
      );

      print('✅ Resposta recebida: ${result.data}');
      
      // Funções callable retornam os dados em result.data
      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erro ao chamar Cloud Function: $e');
      print('❌ Tipo do erro: ${e.runtimeType}');
      if (e is FirebaseFunctionsException) {
        print('❌ Código: ${e.code}');
        print('❌ Mensagem: ${e.message}');
        print('❌ Detalhes: ${e.details}');
      }
      rethrow;
    }
  }

  /// Verifica o status de uma comparação em processamento
  static Future<Map<String, dynamic>> getComparisonStatus(String comparisonId) async {
    try {
      // Configurar Firebase Functions com região explícita
      final functions = FirebaseFunctions.instanceFor(
        region: _region,
      );
      
      final callable = functions.httpsCallable('getComparisonStatus');
      final result = await callable.call({'comparisonId': comparisonId})
          .timeout(const Duration(seconds: 30));

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Erro ao verificar status: $e');
      rethrow;
    }
  }
}

