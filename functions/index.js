const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');
const axios = require('axios');

// Inicializar Firebase Admin
admin.initializeApp();

// Inicializar Google Cloud Vision API
const visionClient = new vision.ImageAnnotatorClient();

/**
 * Cloud Function para comparar duas imagens usando Google Vision API (CALLABLE)
 * 
 * Request data:
 * {
 *   "baseImageUrl": "https://...",
 *   "comparedImageUrl": "https://...",
 *   "pontoObra": "Ponto A",
 *   "etapaObra": "Fundação"
 * }
 */
exports.compareImages = functions.https.onCall(async (data, context) => {
  // Verificar autenticação
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário não autenticado'
    );
  }

  const { baseImageUrl, comparedImageUrl, pontoObra, etapaObra } = data;

  if (!baseImageUrl || !comparedImageUrl) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'URLs das imagens são obrigatórias'
    );
  }

  try {
    // Baixar imagens
    const [baseImageResponse, comparedImageResponse] = await Promise.all([
      axios.get(baseImageUrl, { responseType: 'arraybuffer' }),
      axios.get(comparedImageUrl, { responseType: 'arraybuffer' }),
    ]);

    const baseImageBuffer = Buffer.from(baseImageResponse.data);
    const comparedImageBuffer = Buffer.from(comparedImageResponse.data);

    // Analisar imagens com Vision API
    const [baseResult] = await visionClient.annotateImage({
      image: { content: baseImageBuffer },
      features: [
        { type: 'LABEL_DETECTION', maxResults: 10 },
        { type: 'OBJECT_LOCALIZATION', maxResults: 10 },
        { type: 'TEXT_DETECTION' },
      ],
    });

    const [comparedResult] = await visionClient.annotateImage({
      image: { content: comparedImageBuffer },
      features: [
        { type: 'LABEL_DETECTION', maxResults: 10 },
        { type: 'OBJECT_LOCALIZATION', maxResults: 10 },
        { type: 'TEXT_DETECTION' },
      ],
    });

    // Comparar labels (objetos detectados)
    const baseLabels = new Set(
      baseResult.labelAnnotations?.map((label) => label.description) || []
    );
    const comparedLabels = new Set(
      comparedResult.labelAnnotations?.map((label) => label.description) || []
    );

    // Calcular similaridade
    const allLabels = new Set([...baseLabels, ...comparedLabels]);
    const commonLabels = new Set(
      [...baseLabels].filter((label) => comparedLabels.has(label))
    );
    const similarityScore = allLabels.size > 0 
      ? commonLabels.size / allLabels.size 
      : 0;

    // Detectar mudanças
    const addedLabels = [...comparedLabels].filter(
      (label) => !baseLabels.has(label)
    );
    const removedLabels = [...baseLabels].filter(
      (label) => !comparedLabels.has(label)
    );

    // Calcular percentual de evolução
    // Baseado na quantidade de novos objetos detectados
    const totalBaseObjects = baseResult.localizedObjectAnnotations?.length || 0;
    const totalComparedObjects = comparedResult.localizedObjectAnnotations?.length || 0;
    
    let evolutionPercentage = 0;
    if (totalBaseObjects > 0) {
      evolutionPercentage = Math.min(
        100,
        ((totalComparedObjects - totalBaseObjects) / totalBaseObjects) * 100 + 50
      );
    } else if (totalComparedObjects > 0) {
      evolutionPercentage = 100; // Nova obra
    } else {
      evolutionPercentage = similarityScore * 100; // Fallback para similaridade
    }

    // Garantir que está entre 0 e 100
    evolutionPercentage = Math.max(0, Math.min(100, evolutionPercentage));

    // Criar lista de mudanças detectadas
    const detectedChanges = [];

    // Adicionar mudanças de labels
    addedLabels.forEach((label) => {
      detectedChanges.push({
        type: 'added',
        description: `Novo elemento detectado: ${label}`,
        confidence: 0.85,
      });
    });

    removedLabels.forEach((label) => {
      detectedChanges.push({
        type: 'removed',
        description: `Elemento removido: ${label}`,
        confidence: 0.75,
      });
    });

    // Adicionar mudanças de objetos localizados
    const baseObjects = baseResult.localizedObjectAnnotations || [];
    const comparedObjects = comparedResult.localizedObjectAnnotations || [];

    if (comparedObjects.length > baseObjects.length) {
      detectedChanges.push({
        type: 'added',
        description: `${comparedObjects.length - baseObjects.length} novo(s) objeto(s) estrutural(is) detectado(s)`,
        confidence: 0.90,
      });
    }

    // Se não houver mudanças específicas, criar uma genérica baseada na evolução
    if (detectedChanges.length === 0 && evolutionPercentage > 10) {
      detectedChanges.push({
        type: 'modified',
        description: 'Progresso significativo detectado na obra',
        confidence: 0.80,
      });
    }

    // Retornar resultados (callable retorna direto, não precisa res.json)
    return {
      success: true,
      evolutionPercentage: Math.round(evolutionPercentage * 10) / 10,
      similarityScore: Math.round(similarityScore * 100) / 100,
      detectedChanges: detectedChanges,
      metadata: {
        baseObjectsCount: totalBaseObjects,
        comparedObjectsCount: totalComparedObjects,
        baseLabelsCount: baseLabels.size,
        comparedLabelsCount: comparedLabels.size,
      },
    };
  } catch (error) {
    console.error('Erro ao comparar imagens:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Erro ao processar comparação: ${error.message}`
    );
  }
});

/**
 * Função auxiliar para verificar status de uma comparação
 */
exports.getComparisonStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário não autenticado'
    );
  }

  const { comparisonId } = data;

  if (!comparisonId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'ID da comparação é obrigatório'
    );
  }

  try {
    const doc = await admin
      .firestore()
      .collection('image_comparisons')
      .doc(comparisonId)
      .get();

    if (!doc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Comparação não encontrada'
      );
    }

    return {
      success: true,
      comparison: doc.data(),
    };
  } catch (error) {
    console.error('Erro ao buscar status:', error);
    throw new functions.https.HttpsError(
      'internal',
      `Erro ao buscar status: ${error.message}`
    );
  }
});

