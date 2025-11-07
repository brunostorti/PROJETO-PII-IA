const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');
const axios = require('axios');
const { VertexAI } = require('@google-cloud/vertexai');

// Inicializar Firebase Admin
admin.initializeApp();

// Inicializar Google Cloud Vision API
const visionClient = new vision.ImageAnnotatorClient();

// Nota: Funções callable do Firebase lidam com CORS automaticamente
// A região explícita (.region('us-central1')) garante deploy correto

// Helper: Gemini diff (Vertex AI) - gera relatório JSON estruturado APENAS com Gemini
// Prompt especializado para análise de progresso de obras
async function geminiDiff({ projectId, location, model, baseImageBuffer, comparedImageBuffer, pontoObra, etapaObra, temperature = 0.2 }) {
  // Lista de modelos para tentar (fallback)
  const modelNames = [
    model,
    'gemini-2.5-flash-preview-09-2025',
    'gemini-2.5-flash',
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash-002',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash',
    'gemini-1.5-pro-002',
    'gemini-1.5-pro-001',
    'gemini-1.5-pro',
    'gemini-pro',
  ].filter(Boolean);
  
  // Prompt especializado para análise de obras
  const specializedPrompt = `Você é um engenheiro civil perito com mais de 20 anos de experiência em gestão de obras, segurança do trabalho e controle de qualidade.

ANÁLISE SOLICITADA:
Compare a IMAGEM IDEAL (primeira imagem) com a IMAGEM REAL (segunda imagem) do ponto de obra "${pontoObra}" na etapa "${etapaObra}".

INSTRUÇÕES DETALHADAS:

1. PROGRESSO GERAL (overallPercentage):
   - Analise quantitativamente o quanto da obra ideal foi executado na imagem real
   - Considere: elementos estruturais concluídos, acabamentos, instalações, áreas construídas
   - Use escala de 0-100% (0% = nada iniciado, 100% = totalmente conforme o ideal)
   - Subscores (presence, objects, colors, extras): detalhe a contribuição de cada fator
   - Rationale: explique o cálculo do progresso de forma técnica e objetiva

2. SEGURANÇA DO TRABALHO (safetyFindings):
   - EPIs: Verifique se trabalhadores estão usando capacete, óculos, luvas, calçados de segurança, cinto de segurança
   - Riscos: Identifique áreas sem proteção (guarda-corpos, redes, sinalização), escavações abertas, materiais soltos, fiação exposta, máquinas sem proteção
   - Comportamentos inseguros: trabalhadores em altura sem proteção, manuseio incorreto de materiais, áreas de risco sem sinalização
   - Severidade: "critical" (risco imediato de morte/lesão grave), "high" (risco significativo), "medium" (risco moderado), "low" (risco baixo mas presente)
   - Confidence: 0.0 a 1.0 baseado na clareza da evidência visual

3. MATERIAIS FALTANTES (missingMaterials):
   - Compare elementos estruturais, acabamentos, instalações que estão na imagem ideal mas NÃO estão na imagem real
   - Exemplos: pilares, vigas, lajes, paredes, portas, janelas, revestimentos, instalações elétricas/hidráulicas
   - Element: nome técnico do elemento (ex: "Pilar P-05", "Viga V-12", "Revestimento cerâmico")
   - Description: descrição detalhada do que está faltando e onde deveria estar
   - Confidence: 0.0 a 1.0 baseado na certeza da identificação

4. DISCREPÂNCIAS (discrepancies):
   - Compare dimensões, posicionamento, alinhamento, qualidade entre ideal e real
   - Element: nome do elemento (ex: "Parede Norte", "Pilar Central", "Laje do 2º andar")
   - Metric: tipo de medição (ex: "altura", "largura", "alinhamento vertical", "esquadro", "nível")
   - Expected: valor esperado conforme projeto ideal
   - Measured: valor observado na imagem real (estimativa visual)
   - Delta: diferença entre esperado e medido
   - Tolerance: tolerância aceitável (ex: "±2cm", "±5mm")
   - Severity: "high" (fora de tolerância crítica), "medium" (fora de tolerância), "low" (dentro mas próximo do limite)
   - Confidence: 0.0 a 1.0 baseado na precisão da estimativa visual

5. AÇÕES SUGERIDAS (suggestedActions):
   - Priorize ações baseadas na severidade dos problemas encontrados
   - Priority: "high" (urgente, risco imediato), "medium" (importante, corrigir em breve), "low" (melhoria, pode aguardar)
   - Title: título curto e objetivo da ação
   - Description: descrição detalhada do que fazer, como fazer e por que é importante

IMPORTANTE:
- Seja PRECISO e TÉCNICO nas análises
- Base suas conclusões APENAS no que é visível nas imagens
- Se algo não estiver claro, indique baixa confidence
- Gere APENAS JSON válido, sem texto adicional, sem markdown, sem comentários
- O JSON deve ser parseável diretamente

FORMATO JSON OBRIGATÓRIO (sem markdown, apenas JSON puro):
{
  "progress": {
    "overallPercentage": number,
    "subscores": {
      "presence": number,
      "objects": number,
      "colors": number,
      "extras": number
    },
    "rationale": "string explicativa detalhada"
  },
  "safetyFindings": [
    {
      "type": "epi_missing|hazard|unsafe_behavior",
      "description": "string detalhada",
      "severity": "low|medium|high|critical",
      "confidence": number
    }
  ],
  "missingMaterials": [
    {
      "element": "string",
      "description": "string detalhada",
      "confidence": number
    }
  ],
  "discrepancies": [
    {
      "element": "string",
      "metric": "string",
      "expected": "string",
      "measured": "string",
      "delta": "string",
      "tolerance": "string",
      "severity": "low|medium|high",
      "confidence": number
    }
  ],
  "suggestedActions": [
    {
      "title": "string",
      "description": "string detalhada",
      "priority": "low|medium|high"
    }
  ]
}`;
  
  for (const modelName of modelNames) {
    try {
      console.log('🤖 Tentando modelo Gemini:', { projectId, location, model: modelName, temperature, baseSize: baseImageBuffer.length, comparedSize: comparedImageBuffer.length });
      const vertexAI = new VertexAI({ project: projectId, location });
      const generativeModel = vertexAI.getGenerativeModel({ model: modelName });
      const input = [
        {
          role: 'user',
          parts: [
            { text: specializedPrompt },
            // Imagem ideal (projeto)
            { inlineData: { mimeType: 'image/jpeg', data: baseImageBuffer.toString('base64') } },
            // Imagem real (obra atual)
            { inlineData: { mimeType: 'image/jpeg', data: comparedImageBuffer.toString('base64') } },
          ]
        }
      ];
      console.log('📤 Enviando requisição para Gemini...');
      const result = await generativeModel.generateContent({ contents: input, generationConfig: { temperature } });
      console.log('✅ Resposta do Gemini recebida com modelo:', modelName);
      const parts = result?.response?.candidates?.[0]?.content?.parts || [];
      let text = parts.map(p => p.text).filter(Boolean).join('\n') || '{}';
      console.log('📝 Texto retornado pelo Gemini (primeiros 500 chars):', text.substring(0, 500));
      
      // Remover marcadores de código markdown se presentes (```json ... ```)
      text = text.trim();
      if (text.startsWith('```')) {
        // Remove ```json ou ``` do início
        text = text.replace(/^```(?:json)?\s*\n?/i, '');
        // Remove ``` do final
        text = text.replace(/\n?```\s*$/i, '');
        text = text.trim();
      }
      
      try {
        const parsed = JSON.parse(text);
        console.log('✅ JSON parseado com sucesso. Chaves:', Object.keys(parsed));
        return parsed;
      } catch (parseError) {
        console.error('❌ Erro ao fazer parse do JSON do Gemini:', parseError?.message);
        console.error('❌ Texto completo (primeiros 2000 chars):', text.substring(0, 2000));
        return { error: 'Erro ao parsear resposta do Gemini', rawText: text.substring(0, 1000) };
      }
    } catch (e) {
      // Se for erro 404 (modelo não encontrado), tenta o próximo
      if (e?.code === 404 || e?.status === 404 || e?.message?.includes('404') || e?.message?.includes('not found')) {
        console.warn(`⚠️ Modelo ${modelName} não encontrado, tentando próximo...`);
        continue; // Tenta próximo modelo
      }
      // Se for outro erro, loga e tenta próximo também
      console.warn(`⚠️ Erro com modelo ${modelName}:`, e?.message || e);
      if (modelName === modelNames[modelNames.length - 1]) {
        // Último modelo, retorna erro
        console.error('❌ Todos os modelos falharam');
        return { error: e?.message || 'Erro desconhecido no Gemini', code: e?.code, status: e?.status };
      }
      continue; // Tenta próximo modelo
    }
  }
  
  // Se chegou aqui, todos os modelos falharam
  return { error: 'Nenhum modelo Gemini disponível ou acessível' };
}

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

  const { baseImageUrl, comparedImageUrl, pontoObra, etapaObra, projectId, pontoId } = data;

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

    // Utilitários
    const toBox = (poly) => {
      // poly.normalizedVertices = [{x,y} ...]
      if (!poly || !poly.normalizedVertices || poly.normalizedVertices.length === 0) {
        return null;
      }
      const xs = poly.normalizedVertices.map(v => Math.min(Math.max(v.x || 0, 0), 1));
      const ys = poly.normalizedVertices.map(v => Math.min(Math.max(v.y || 0, 0), 1));
      const minX = Math.min(...xs), maxX = Math.max(...xs);
      const minY = Math.min(...ys), maxY = Math.max(...ys);
      return { x: minX, y: minY, w: Math.max(0, maxX - minX), h: Math.max(0, maxY - minY) };
    };

    const boxIoU = (a, b) => {
      if (!a || !b) return 0;
      const ax2 = a.x + a.w, ay2 = a.y + a.h;
      const bx2 = b.x + b.w, by2 = b.y + b.h;
      const interX1 = Math.max(a.x, b.x);
      const interY1 = Math.max(a.y, b.y);
      const interX2 = Math.min(ax2, bx2);
      const interY2 = Math.min(ay2, by2);
      const interW = Math.max(0, interX2 - interX1);
      const interH = Math.max(0, interY2 - interY1);
      const interArea = interW * interH;
      const union = a.w * a.h + b.w * b.h - interArea;
      return union > 0 ? interArea / union : 0;
    };

    const clamp01 = (v) => Math.max(0, Math.min(1, v));

    // Comparar labels (objetos detectados)
    const baseLabelsArray = baseResult.labelAnnotations || [];
    const comparedLabelsArray = comparedResult.labelAnnotations || [];
    
    const baseLabels = new Set(
      baseLabelsArray.map((label) => label.description)
    );
    const comparedLabels = new Set(
      comparedLabelsArray.map((label) => label.description)
    );

    // Scores de labels de construção (disponíveis para ambos os fluxos)
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

    // Se projectId/pontoId presentes, calcular conformidade Ideal vs Atual com pesos por projeto
    const db = admin.firestore();
    let finalEvolution = 0;
    let debugScores = {};
    
    const totalBaseObjects = baseResult.localizedObjectAnnotations?.length || 0;
    const totalComparedObjects = comparedResult.localizedObjectAnnotations?.length || 0;
    
    if (projectId && pontoId) {
      // Pesos padrão
      let weights = { presence: 0.4, objects: 0.3, colors: 0.2, extrasPenalty: 0.1 };
      // Thresholds padrão
      let thresholds = { iou: 0.35, minObjectMatchRatio: 0.5, extrasPenaltyScale: 1.0 };
      try {
        const cfg = await db.collection('projects').doc(projectId).collection('config').doc('weights').get();
        if (cfg.exists) {
          const dataW = cfg.data() || {};
          weights = {
            presence: typeof dataW.presence === 'number' ? dataW.presence : weights.presence,
            objects: typeof dataW.objects === 'number' ? dataW.objects : weights.objects,
            colors: typeof dataW.colors === 'number' ? dataW.colors : weights.colors,
            extrasPenalty: typeof dataW.extrasPenalty === 'number' ? dataW.extrasPenalty : weights.extrasPenalty,
          };
        }
        const thrDoc = await db.collection('projects').doc(projectId).collection('config').doc('thresholds').get();
        if (thrDoc.exists) {
          const t = thrDoc.data() || {};
          thresholds = {
            iou: typeof t.iou === 'number' ? t.iou : thresholds.iou,
            minObjectMatchRatio: typeof t.minObjectMatchRatio === 'number' ? t.minObjectMatchRatio : thresholds.minObjectMatchRatio,
            extrasPenaltyScale: typeof t.extrasPenaltyScale === 'number' ? t.extrasPenaltyScale : thresholds.extrasPenaltyScale,
          };
        }
      } catch (e) {
        console.warn('⚠️ Falha ao carregar pesos do projeto, usando defaults', e?.message);
      }

      // Análise do ideal (rótulos/objetos/cores) – cachear em projects/{projectId}/pontos/{pontoId}
      let pontoDoc;
      try {
        pontoDoc = await db.collection('projects').doc(projectId).collection('pontos').doc(pontoId).get();
      } catch (e) {
        console.warn('⚠️ Falha ao ler ponto', e?.message);
      }

      let idealAnalysis = pontoDoc?.data()?.idealAnalysis;
      // Extrair dados do ideal a partir do baseResult (baseImageUrl é a imagem ideal neste fluxo)
      const idealLabels = baseLabelsArray.map(l => (l.description || '').toLowerCase()).filter(Boolean);
      const baseObjectsFull = (baseResult.localizedObjectAnnotations || []).map(o => ({
        name: (o.name || '').toLowerCase(),
        box: toBox(o.boundingPoly),
      })).filter(o => !!o.name && !!o.box);
      const idealObjects = baseObjectsFull.map(o => o.name);
      let idealDominantRgb = null;
      let idealPalette = [];
      try {
        const colors = baseResult.imagePropertiesAnnotation?.dominantColors?.colors || [];
        colors.slice(0, 5).forEach(c => {
          if (c.color) {
            idealPalette.push({
              rgb: [Math.round(c.color.red || 0), Math.round(c.color.green || 0), Math.round(c.color.blue || 0)],
              score: c.score || 0,
            });
          }
        });
        if (idealPalette.length > 0) idealDominantRgb = idealPalette[0].rgb;
      } catch (_) {}

      if (!idealAnalysis) {
        // Salvar idealAnalysis para cache
        try {
          await db.collection('projects').doc(projectId).collection('pontos').doc(pontoId).set(
            {
              idealAnalysis: {
                labels: idealLabels,
                objects: idealObjects,
                objectsWithBoxes: baseObjectsFull,
                dominantColorRgb: idealDominantRgb,
                colorPalette: idealPalette,
              },
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        } catch (e) {
          console.warn('⚠️ Falha ao salvar idealAnalysis (cache)', e?.message);
        }
      } else {
        // Sobrescrever a partir do cache para consistência
        if (Array.isArray(idealAnalysis.labels)) {
          // ok
        } else {
          idealAnalysis.labels = idealLabels;
        }
        if (Array.isArray(idealAnalysis.objects)) {
          // ok
        } else {
          idealAnalysis.objects = idealObjects;
        }
        if (Array.isArray(idealAnalysis.dominantColorRgb)) {
          idealDominantRgb = idealAnalysis.dominantColorRgb;
        }
        if (Array.isArray(idealAnalysis.colorPalette)) {
          idealPalette = idealAnalysis.colorPalette;
        }
      }

      // Presença de labels esperados (ideal) na imagem atual
      const idealLabelSet = new Set(idealLabels);
      const comparedLabelSetLc = new Set(comparedLabelsArray.map(l => (l.description || '').toLowerCase()).filter(Boolean));
      let matched = 0;
      idealLabelSet.forEach(l => { if (comparedLabelSetLc.has(l)) matched += 1; });
      const presenceScore = idealLabelSet.size > 0 ? matched / idealLabelSet.size : 0;

      // Penalização por sobras (labels na atual que não estão no ideal)
      let extras = 0;
      comparedLabelSetLc.forEach(l => { if (!idealLabelSet.has(l)) extras += 1; });
      const extrasPenalty = (idealLabelSet.size + comparedLabelSetLc.size) > 0
        ? clamp01((extras / Math.max(1, idealLabelSet.size)) * (thresholds.extrasPenaltyScale || 1))
        : 0;

      // Similaridade de objetos localizados com IoU e contagem
      const comparedObjectsFull = (comparedResult.localizedObjectAnnotations || []).map(o => ({
        name: (o.name || '').toLowerCase(),
        box: toBox(o.boundingPoly),
      })).filter(o => !!o.name && !!o.box);

      const idealByClass = {};
      baseObjectsFull.forEach(obj => {
        if (!idealByClass[obj.name]) idealByClass[obj.name] = [];
        idealByClass[obj.name].push(obj.box);
      });
      const realByClass = {};
      comparedObjectsFull.forEach(obj => {
        if (!realByClass[obj.name]) realByClass[obj.name] = [];
        realByClass[obj.name].push(obj.box);
      });

      let totalIdealInstances = 0;
      let totalMatchedInstances = 0;
      let iouSum = 0;
      let iouCount = 0;

      Object.keys(idealByClass).forEach(cls => {
        const ideals = idealByClass[cls];
        const reals = realByClass[cls] || [];
        totalIdealInstances += ideals.length;
        const used = new Array(reals.length).fill(false);
        ideals.forEach(ibox => {
          let bestIoU = 0;
          let bestIdx = -1;
          reals.forEach((rbox, idx) => {
            if (used[idx]) return;
            const iou = boxIoU(ibox, rbox);
            if (iou > bestIoU) { bestIoU = iou; bestIdx = idx; }
          });
          if (bestIoU >= thresholds.iou) {
            totalMatchedInstances += 1;
            iouSum += bestIoU;
            iouCount += 1;
            if (bestIdx >= 0) used[bestIdx] = true;
          }
        });
      });

      const objectMatchRatio = totalIdealInstances > 0 ? totalMatchedInstances / totalIdealInstances : 0;
      const iouAverage = iouCount > 0 ? (iouSum / iouCount) : 0;
      // Compor um score de objetos considerando match ratio e IoU médio
      const objectsSimilarity = objectMatchRatio * 0.7 + iouAverage * 0.3;

      // Similaridade de cor dominante
      let colorSimilarity = 0;
      try {
        const realColors = comparedResult.imagePropertiesAnnotation?.dominantColors?.colors || [];
        const realPalette = realColors.slice(0, 5).map(c => ({
          rgb: c.color ? [Math.round(c.color.red || 0), Math.round(c.color.green || 0), Math.round(c.color.blue || 0)] : [0,0,0],
          score: c.score || 0,
        }));
        if (idealPalette.length > 0 && realPalette.length > 0) {
          // Distância média mínima entre paletas, ponderada pelos scores
          const deltaE = (a, b) => {
            // RGB -> XYZ -> LAB (aprox.) e DeltaE CIE76
            const toLab = (rgb) => {
              const srgb = rgb.map(v => v/255);
              const lin = srgb.map(v => v <= 0.04045 ? v/12.92 : Math.pow((v+0.055)/1.055, 2.4));
              const X = lin[0]*0.4124 + lin[1]*0.3576 + lin[2]*0.1805;
              const Y = lin[0]*0.2126 + lin[1]*0.7152 + lin[2]*0.0722;
              const Z = lin[0]*0.0193 + lin[1]*0.1192 + lin[2]*0.9505;
              const xn=0.95047, yn=1.00000, zn=1.08883;
              const f = (t) => t > 0.008856 ? Math.cbrt(t) : (7.787*t + 16/116);
              const fx = f(X/xn), fy = f(Y/yn), fz = f(Z/zn);
              return { L: 116*fy - 16, a: 500*(fx - fy), b: 200*(fy - fz) };
            };
            const la = toLab(a), lb = toLab(b);
            const dL = la.L - lb.L, da = la.a - lb.a, db = la.b - lb.b;
            return Math.sqrt(dL*dL + da*da + db*db);
          };
          let accum = 0, weightSum = 0;
          idealPalette.forEach(ic => {
            // encontre melhor correspondência no real
            let best = 1e9;
            realPalette.forEach(rc => { best = Math.min(best, deltaE(ic.rgb, rc.rgb)); });
            // normalizar DeltaE em [0..1] assumindo 100 como “muito diferente”
            const sim = 1 - Math.min(1, best / 100);
            const w = ic.score || 1;
            accum += sim * w;
            weightSum += w;
          });
          if (weightSum > 0) colorSimilarity = clamp01(accum / weightSum);
        } else if (idealDominantRgb && realPalette.length > 0) {
          const v2 = realPalette[0].rgb;
          const dr = idealDominantRgb[0] - v2[0], dg = idealDominantRgb[1] - v2[1], dbv = idealDominantRgb[2] - v2[2];
          const dist = Math.sqrt(dr*dr + dg*dg + dbv*dbv);
          const maxDist = Math.sqrt(3 * 255 * 255);
          colorSimilarity = 1 - Math.min(1, dist / maxDist);
        }
      } catch (_) {}

      const rawScore =
        (presenceScore * weights.presence) +
        (objectsSimilarity * weights.objects) +
        (colorSimilarity * weights.colors) -
        (extrasPenalty * weights.extrasPenalty);

      finalEvolution = Math.max(0, Math.min(100, Math.round(Math.max(0, rawScore) * 1000) / 10));

      debugScores = {
        presence: (presenceScore * 100).toFixed(1) + '%',
        objects: (objectsSimilarity * 100).toFixed(1) + '%',
        colors: (colorSimilarity * 100).toFixed(1) + '%',
        extrasPenalty: (extrasPenalty * 100).toFixed(1) + '%',
        weights,
        thresholds,
        objectMatchRatio: (objectMatchRatio * 100).toFixed(1) + '%',
        iouAverage: (iouAverage * 100).toFixed(1) + '%',
        idealInstances: totalIdealInstances,
        matchedInstances: totalMatchedInstances,
      };

      console.log('📊 Andamento (ideal vs atual):', { ...debugScores, final: finalEvolution.toFixed(1) + '%' });
    } else {
      // ALGORITMO ORIGINAL (base antiga vs nova) – mantém comportamento anterior
      // Mudança na quantidade de objetos (40%), complexidade de labels (30%), mudanças (20%), dissimilaridade (10%)
    let objectChangeFactor = 0;
    if (totalBaseObjects > 0) {
      const objectGrowth = (totalComparedObjects - totalBaseObjects) / totalBaseObjects;
        objectChangeFactor = Math.max(0, Math.min(1, (objectGrowth + 0.5) / 1.5));
    } else if (totalComparedObjects > 0) {
        objectChangeFactor = 1;
      }

    let complexityFactor = 0;
    if (baseConstructionScore > 0) {
      complexityFactor = Math.min(1, comparedConstructionScore / baseConstructionScore);
    } else if (comparedConstructionScore > 0) {
      complexityFactor = 1;
    }
    
    const newElementsCount = addedLabels.length;
    const removedElementsCount = removedLabels.length;
      const netChange = newElementsCount - (removedElementsCount * 0.5);
    const maxExpectedChanges = Math.max(10, (baseLabelsArray.length + comparedLabelsArray.length) / 2);
    const changeFactor = Math.min(1, Math.max(0, netChange / maxExpectedChanges));
    
    const dissimilarityFactor = 1 - similarityScore;
    
    const evolutionPercentage = Math.round(
      (objectChangeFactor * 0.40 + 
       complexityFactor * 0.30 + 
       changeFactor * 0.20 + 
       dissimilarityFactor * 0.10) * 100 * 10
    ) / 10;
    
      finalEvolution = Math.max(0, Math.min(100, evolutionPercentage));

      console.log('📊 Cálculo de evolução (antigo):', {
      final: finalEvolution.toFixed(1) + '%'
    });
    }

    // Mudanças detectadas: apenas usar se Gemini não estiver habilitado
    // Se Gemini estiver habilitado, ele gera todas as análises
    const detectedChanges = [];

    // Análise completa com Gemini (Vertex) - fonte principal do relatório
    let geminiReport = null;
    try {
      if (projectId && pontoId) {
        console.log('🔍 Verificando configuração Gemini para projeto:', projectId);
        // 1) Config por projeto
        let g = null;
        try {
          const geminiCfgDoc = await db.collection('projects').doc(projectId).collection('config').doc('gemini').get();
          if (geminiCfgDoc.exists) {
            g = geminiCfgDoc.data();
            console.log('📋 Config Gemini do projeto encontrada:', { enabled: g?.enabled, model: g?.model, location: g?.location });
          } else {
            console.log('ℹ️ Config Gemini do projeto não encontrada');
          }
        } catch (e) {
          console.warn('⚠️ Erro ao ler config Gemini do projeto:', e?.message);
        }

        // 2) Fallback global: app_config/gemini
        if (!g || !g.enabled) {
          console.log('🔍 Tentando config global app_config/gemini...');
          try {
            const globalDoc = await db.collection('app_config').doc('gemini').get();
            if (globalDoc.exists) {
              const gg = globalDoc.data();
              console.log('📋 Config Gemini global encontrada:', { enabled: gg?.enabled, model: gg?.model, location: gg?.location });
              if (gg?.enabled) {
                g = gg;
                console.log('✅ Usando config global do Gemini');
              }
            } else {
              console.log('ℹ️ Config Gemini global não encontrada');
            }
          } catch (e) {
            console.warn('⚠️ Erro ao ler config Gemini global:', e?.message);
          }
        }

        if (g?.enabled) {
          console.log('✅ Gemini habilitado, iniciando análise completa (100% Gemini)...');
          // Usar APENAS Gemini para análise - prompt especializado faz tudo
          geminiReport = await geminiDiff({
            projectId: process.env.GCLOUD_PROJECT || projectId,
            location: g.location || 'us-central1',
            model: g.model || 'gemini-2.5-flash-preview-09-2025',
            baseImageBuffer,
            comparedImageBuffer,
            pontoObra: pontoObra || 'Ponto da Obra',
            etapaObra: etapaObra || 'Etapa da Obra',
            temperature: typeof g.temperature === 'number' ? g.temperature : 0.2,
          });
          if (geminiReport && !geminiReport.error) {
            console.log('✅ Relatório Gemini gerado com sucesso');
          } else {
            console.warn('⚠️ Gemini retornou erro ou vazio:', geminiReport);
          }
        } else {
          console.log('ℹ️ Gemini desabilitado. Config:', g ? { enabled: g.enabled } : 'não encontrada');
        }
      } else {
        console.log('ℹ️ Gemini não será chamado (projectId ou pontoId ausentes)');
      }
    } catch (e) {
      console.error('❌ Erro ao invocar Gemini:', {
        message: e?.message,
        stack: e?.stack?.substring(0, 500),
      });
    }

    // Se Gemini gerou relatório, usar seus dados como fonte principal
    let finalPercentage = finalEvolution;
    if (geminiReport && !geminiReport.error && geminiReport.progress) {
      // Usar progresso do Gemini como fonte principal
      finalPercentage = geminiReport.progress.overallPercentage || finalEvolution;
      console.log('📊 Usando progresso do Gemini:', finalPercentage + '%');
    }

    // Retornar resultados (callable retorna direto)
    return {
      success: true,
      evolutionPercentage: finalPercentage,
      similarityScore: Math.round(similarityScore * 100) / 100,
      detectedChanges: detectedChanges,
      metadata: {
        baseObjectsCount: totalBaseObjects,
        comparedObjectsCount: totalComparedObjects,
        baseLabelsCount: baseLabelsArray.length,
        comparedLabelsCount: comparedLabelsArray.length,
        ...(projectId && pontoId ? { debugScores } : {}),
        // Gemini report é a fonte principal quando disponível
        ...(geminiReport ? { gemini: geminiReport } : {}),
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

