const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');
const axios = require('axios');

// Inicializar Firebase Admin
admin.initializeApp();

// Inicializar Google Cloud Vision API
const visionClient = new vision.ImageAnnotatorClient();

// Nota: Funções callable do Firebase lidam com CORS automaticamente
// A região explícita (.region('us-central1')) garante deploy correto

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
// Função callable com região explícita e configuração correta
exports.compareImages = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 120,
    memory: '512MB'
  })
  .https
  .onCall(async (data, context) => {
  console.log('🔵 compareImages chamada', { data, userId: context.auth?.uid });
  
  // Verificar autenticação
  if (!context.auth) {
    console.error('❌ Usuário não autenticado');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Usuário não autenticado'
    );
  }

  const { baseImageUrl, comparedImageUrl, pontoObra, etapaObra } = data;

  if (!baseImageUrl || !comparedImageUrl) {
    console.error('❌ URLs faltando', { baseImageUrl: !!baseImageUrl, comparedImageUrl: !!comparedImageUrl });
    throw new functions.https.HttpsError(
      'invalid-argument',
      'URLs das imagens são obrigatórias'
    );
  }

  try {
    console.log('📥 Baixando imagens...');
    
    // Baixar imagens com timeout e tratamento de erro
    let baseImageResponse, comparedImageResponse;
    try {
      [baseImageResponse, comparedImageResponse] = await Promise.all([
        axios.get(baseImageUrl, { 
          responseType: 'arraybuffer',
          timeout: 30000, // 30 segundos
          maxContentLength: 10 * 1024 * 1024, // 10MB max
        }),
        axios.get(comparedImageUrl, { 
          responseType: 'arraybuffer',
          timeout: 30000,
          maxContentLength: 10 * 1024 * 1024,
        }),
      ]);
    } catch (downloadError) {
      console.error('❌ Erro ao baixar imagens:', downloadError.message);
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Erro ao baixar imagens: ${downloadError.message}`
      );
    }

    const baseImageBuffer = Buffer.from(baseImageResponse.data);
    const comparedImageBuffer = Buffer.from(comparedImageResponse.data);
    
    console.log('✅ Imagens baixadas', { 
      baseSize: baseImageBuffer.length, 
      comparedSize: comparedImageBuffer.length 
    });

    // Analisar imagens com Vision API - Múltiplas features para análise mais precisa
    console.log('🔍 Analisando imagens com Vision API (análise completa)...');
    
    let baseResult, comparedResult;
    try {
      // Análise completa da imagem base
      [baseResult] = await visionClient.annotateImage({
        image: { content: baseImageBuffer },
        features: [
          { type: 'LABEL_DETECTION', maxResults: 20 },
          { type: 'OBJECT_LOCALIZATION', maxResults: 20 },
          { type: 'TEXT_DETECTION' },
          { type: 'IMAGE_PROPERTIES' }, // Cores, dominância
          { type: 'SAFE_SEARCH_DETECTION' },
        ],
      });
      
      // Análise completa da imagem comparada
      [comparedResult] = await visionClient.annotateImage({
        image: { content: comparedImageBuffer },
        features: [
          { type: 'LABEL_DETECTION', maxResults: 20 },
          { type: 'OBJECT_LOCALIZATION', maxResults: 20 },
          { type: 'TEXT_DETECTION' },
          { type: 'IMAGE_PROPERTIES' },
          { type: 'SAFE_SEARCH_DETECTION' },
        ],
      });
      
      console.log('✅ Análise Vision API concluída');
    } catch (visionError) {
      console.error('❌ Erro na Vision API:', visionError);
      throw new functions.https.HttpsError(
        'internal',
        `Erro na análise de imagens: ${visionError.message || 'Erro desconhecido na Vision API'}`
      );
    }

    // Comparar labels (objetos detectados)
    const baseLabelsArray = baseResult.labelAnnotations || [];
    const comparedLabelsArray = comparedResult.labelAnnotations || [];
    
    const baseLabels = new Set(
      baseLabelsArray.map((label) => label.description)
    );
    const comparedLabels = new Set(
      comparedLabelsArray.map((label) => label.description)
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

    // ALGORITMO MELHORADO: Calcular percentual de evolução de forma mais fidedigna
    // Usa múltiplos fatores para uma análise mais precisa
    
    const totalBaseObjects = baseResult.localizedObjectAnnotations?.length || 0;
    const totalComparedObjects = comparedResult.localizedObjectAnnotations?.length || 0;
    
    // Fator 1: Mudança na quantidade de objetos estruturalmente detectados (peso: 40%)
    let objectChangeFactor = 0;
    if (totalBaseObjects > 0) {
      const objectGrowth = (totalComparedObjects - totalBaseObjects) / totalBaseObjects;
      objectChangeFactor = Math.max(0, Math.min(1, (objectGrowth + 0.5) / 1.5)); // Normaliza para 0-1
    } else if (totalComparedObjects > 0) {
      objectChangeFactor = 1; // Nova obra = 100% de evolução
    }
    
    // Fator 2: Mudança na complexidade dos labels (peso: 30%)
    // Labels relacionados a construção mais avançada indicam progresso
    const constructionLabels = [
      'building', 'construction', 'wall', 'roof', 'window', 'door',
      'concrete', 'brick', 'steel', 'scaffolding', 'crane', 'excavator',
      'foundation', 'structure', 'architecture', 'construction site'
    ];
    
    const baseConstructionScore = baseLabelsArray
      .filter(label => constructionLabels.some(cl => 
        label.description?.toLowerCase().includes(cl)
      ))
      .reduce((sum, label) => sum + (label.score || 0), 0);
    
    const comparedConstructionScore = comparedLabelsArray
      .filter(label => constructionLabels.some(cl => 
        label.description?.toLowerCase().includes(cl)
      ))
      .reduce((sum, label) => sum + (label.score || 0), 0);
    
    let complexityFactor = 0;
    if (baseConstructionScore > 0) {
      complexityFactor = Math.min(1, comparedConstructionScore / baseConstructionScore);
    } else if (comparedConstructionScore > 0) {
      complexityFactor = 1;
    }
    
    // Fator 3: Novos elementos adicionados vs removidos (peso: 20%)
    const newElementsCount = addedLabels.length;
    const removedElementsCount = removedLabels.length;
    const netChange = newElementsCount - (removedElementsCount * 0.5); // Remoções contam menos
    const maxExpectedChanges = Math.max(10, (baseLabelsArray.length + comparedLabelsArray.length) / 2);
    const changeFactor = Math.min(1, Math.max(0, netChange / maxExpectedChanges));
    
    // Fator 4: Similaridade inversa (peso: 10%)
    // Quanto menos similar, mais mudança houve
    const dissimilarityFactor = 1 - similarityScore;
    
    // Cálculo final ponderado
    const evolutionPercentage = Math.round(
      (objectChangeFactor * 0.40 + 
       complexityFactor * 0.30 + 
       changeFactor * 0.20 + 
       dissimilarityFactor * 0.10) * 100 * 10
    ) / 10;
    
    // Garantir que está entre 0 e 100
    const finalEvolution = Math.max(0, Math.min(100, evolutionPercentage));
    
    console.log('📊 Cálculo de evolução:', {
      objectChange: (objectChangeFactor * 100).toFixed(1) + '%',
      complexity: (complexityFactor * 100).toFixed(1) + '%',
      change: (changeFactor * 100).toFixed(1) + '%',
      dissimilarity: (dissimilarityFactor * 100).toFixed(1) + '%',
      final: finalEvolution.toFixed(1) + '%'
    });

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

    // Adicionar informações mais detalhadas sobre mudanças
    if (totalComparedObjects > totalBaseObjects) {
      const newObjectsCount = totalComparedObjects - totalBaseObjects;
      detectedChanges.push({
        type: 'added',
        description: `${newObjectsCount} novo(s) elemento(s) estrutural(is) detectado(s)`,
        confidence: 0.90,
      });
    }
    
    if (comparedConstructionScore > baseConstructionScore * 1.2) {
      detectedChanges.push({
        type: 'modified',
        description: 'Aumento significativo na complexidade estrutural detectada',
        confidence: 0.85,
      });
    }
    
    // Se não houver mudanças específicas, criar uma genérica baseada na evolução
    if (detectedChanges.length === 0 && finalEvolution > 10) {
      detectedChanges.push({
        type: 'modified',
        description: `Progresso de ${finalEvolution.toFixed(1)}% detectado na obra`,
        confidence: 0.75,
      });
    }

    // Retornar resultados (callable retorna direto, não precisa res.json)
    return {
      success: true,
      evolutionPercentage: finalEvolution,
      similarityScore: Math.round(similarityScore * 100) / 100,
      detectedChanges: detectedChanges,
      metadata: {
        baseObjectsCount: totalBaseObjects,
        comparedObjectsCount: totalComparedObjects,
        baseLabelsCount: baseLabelsArray.length,
        comparedLabelsCount: comparedLabelsArray.length,
        baseConstructionScore: Math.round(baseConstructionScore * 100) / 100,
        comparedConstructionScore: Math.round(comparedConstructionScore * 100) / 100,
        newElementsCount: newElementsCount,
        removedElementsCount: removedElementsCount,
      },
    };
  } catch (error) {
    console.error('❌ Erro completo ao comparar imagens:', {
      message: error.message,
      stack: error.stack,
      code: error.code,
      name: error.name,
    });
    
    // Se já é um HttpsError, re-lançar
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    // Caso contrário, criar um novo HttpsError com mensagem detalhada
    throw new functions.https.HttpsError(
      'internal',
      `Erro ao processar comparação: ${error.message || 'Erro desconhecido'}`
    );
  }
});

/**
 * Função auxiliar para verificar status de uma comparação
 */
exports.getComparisonStatus = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https
  .onCall(async (data, context) => {
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

