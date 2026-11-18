import 'dart:convert';

import 'package:http/http.dart' as http;

class LlmResponseException implements Exception {
  final String message;
  final String rawBody;
  final String model;
  final String? finishReason;

  const LlmResponseException(
    this.message, {
    required this.rawBody,
    required this.model,
    this.finishReason,
  });

  @override
  String toString() => message;
}

class LlmModel {
  final String id;
  final int? created;
  final String? ownedBy;
  const LlmModel({required this.id, this.created, this.ownedBy});

  Map<String, dynamic> toJson() => {
    'id': id,
    'created': created,
    'ownedBy': ownedBy,
  };

  factory LlmModel.fromJson(Map<String, dynamic> json) => LlmModel(
    id: json['id'] as String,
    created: (json['created'] as num?)?.toInt(),
    ownedBy: json['ownedBy'] as String?,
  );
}

class LlmProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final List<LlmModel> models;
  final String? model;

  /// 用户勾选后真正参与切换的模型；为空表示全部可用。
  final List<String> enabledModels;

  const LlmProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey = '',
    this.models = const [],
    this.model,
    this.enabledModels = const [],
  });

  LlmProvider copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    List<LlmModel>? models,
    String? model,
    List<String>? enabledModels,
  }) => LlmProvider(
    id: id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    models: models ?? this.models,
    model: model ?? this.model,
    enabledModels: enabledModels ?? this.enabledModels,
  );

  Map<String, dynamic> toJson({bool includeKey = false}) => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    if (includeKey) 'apiKey': apiKey,
    'models': models.map((item) => item.toJson()).toList(),
    'model': model,
    'enabledModels': enabledModels,
  };

  factory LlmProvider.fromJson(Map<String, dynamic> json) => LlmProvider(
    id: json['id'] as String,
    name: json['name'] as String? ?? '未命名提供商',
    baseUrl: json['baseUrl'] as String? ?? '',
    apiKey: json['apiKey'] as String? ?? '',
    models: (json['models'] as List? ?? [])
        .map(
          (item) => LlmModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    model: json['model'] as String?,
    enabledModels: (json['enabledModels'] as List? ?? [])
        .map((item) => '$item')
        .toList(),
  );
}

class LlmPreset {
  final String id;
  final String name;
  final String baseUrl;

  /// 部分国内服务不提供 GET /models，用内置清单兜底。
  final List<String> fallbackModels;
  const LlmPreset(
    this.id,
    this.name,
    this.baseUrl, [
    this.fallbackModels = const [],
  ]);
}

const llmPresets = <LlmPreset>[
  LlmPreset('deepseek', 'DeepSeek', 'https://api.deepseek.com/v1', [
    'deepseek-chat',
    'deepseek-reasoner',
  ]),
  LlmPreset(
    'dashscope',
    '通义千问',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ['qwen-max', 'qwen-plus', 'qwen-turbo', 'qwen-vl-max'],
  ),
  LlmPreset('moonshot', 'Kimi', 'https://api.moonshot.cn/v1', [
    'kimi-k2-0905-preview',
    'moonshot-v1-32k',
    'moonshot-v1-8k',
  ]),
  LlmPreset('zhipu', '智谱 GLM', 'https://open.bigmodel.cn/api/paas/v4', [
    'glm-4.6',
    'glm-4-plus',
    'glm-4-flash',
  ]),
  LlmPreset('ark', '火山方舟', 'https://ark.cn-beijing.volces.com/api/v3', [
    'doubao-seed-1-6-250615',
    'doubao-1-5-pro-32k-250115',
  ]),
  LlmPreset('siliconflow', '硅基流动', 'https://api.siliconflow.cn/v1', [
    'deepseek-ai/DeepSeek-V3',
    'Qwen/Qwen3-235B-A22B',
    'THUDM/GLM-4-9B-0414',
  ]),
  LlmPreset('minimax', 'MiniMax', 'https://api.minimaxi.com/v1', [
    'MiniMax-M2',
    'abab6.5s-chat',
  ]),
  LlmPreset('hunyuan', '腾讯混元', 'https://api.hunyuan.cloud.tencent.com/v1', [
    'hunyuan-turbos-latest',
    'hunyuan-large',
  ]),
  LlmPreset('qianfan', '百度千帆', 'https://qianfan.baidubce.com/v2', [
    'ernie-4.5-turbo-128k',
    'ernie-speed-128k',
  ]),
  LlmPreset('custom', '自定义', ''),
];

LlmPreset? presetForBaseUrl(String baseUrl) {
  final normalized = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  for (final preset in llmPresets) {
    if (preset.baseUrl.isEmpty) continue;
    if (preset.baseUrl.replaceAll(RegExp(r'/+$'), '') == normalized)
      return preset;
  }
  return null;
}

class LlmService {
  static String _url(String baseUrl, String path) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/$path';
  }

  static Map<String, String> _headers(String key) => {
    'Content-Type': 'application/json',
    if (key.trim().isNotEmpty) 'Authorization': 'Bearer ${key.trim()}',
  };

  Future<List<LlmModel>> fetchModels(LlmProvider provider) async {
    if (provider.baseUrl.trim().isEmpty) throw Exception('Base URL 不能为空');
    final response = await http
        .get(
          Uri.parse(_url(provider.baseUrl, 'models')),
          headers: _headers(provider.apiKey),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '拉取模型失败：HTTP ${response.statusCode} ${_errorBody(response.body)}',
      );
    }
    final decoded = jsonDecode(response.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    if (raw is! List) throw Exception('模型列表格式不正确');
    final models =
        raw
            .whereType<Map>()
            .map(
              (item) => LlmModel(
                id: '${item['id']}',
                created: (item['created'] as num?)?.toInt(),
                ownedBy: item['owned_by'] as String?,
              ),
            )
            .where((model) => model.id.isNotEmpty && !_isNonChatModel(model.id))
            .toList()
          ..sort((a, b) => (b.created ?? 0).compareTo(a.created ?? 0));
    if (models.isEmpty) throw Exception('提供商没有返回可用的对话模型');
    return models;
  }

  Future<String> chat({
    required LlmProvider provider,
    required String model,
    required List<Map<String, dynamic>> messages,
    double temperature = 0.4,
    int maxTokens = 10000,
  }) async {
    if (provider.baseUrl.trim().isEmpty) throw Exception('Base URL 不能为空');
    if (model.trim().isEmpty) throw Exception('还没有选择模型');
    final response = await http
        .post(
          Uri.parse(_url(provider.baseUrl, 'chat/completions')),
          headers: _headers(provider.apiKey),
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlmResponseException(
        '模型请求失败：HTTP ${response.statusCode} ${_errorBody(response.body)}',
        rawBody: response.body,
        model: model,
      );
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw LlmResponseException(
        '模型返回了无法解析的内容',
        rawBody: response.body,
        model: model,
      );
    }
    if (decoded is! Map) {
      throw LlmResponseException(
        '模型返回格式不正确，缺少 JSON 对象',
        rawBody: response.body,
        model: model,
      );
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw LlmResponseException(
        '模型没有返回 choices',
        rawBody: response.body,
        model: model,
      );
    }
    final choice = choices.first is Map
        ? Map<String, dynamic>.from(choices.first as Map)
        : <String, dynamic>{};
    final message = choice['message'];
    final content = message is Map ? message['content'] : null;
    if (content is String && content.trim().isNotEmpty) return content.trim();
    if (content is List) {
      final text = content
          .whereType<Map>()
          .map((part) => part['text'] ?? '')
          .join()
          .trim();
      if (text.isNotEmpty) return text;
    }
    final finishReason = '${choice['finish_reason'] ?? ''}'.trim();
    final reasoning = message is Map
        ? '${message['reasoning_content'] ?? message['reasoning'] ?? ''}'.trim()
        : '';
    final refusal = message is Map ? '${message['refusal'] ?? ''}'.trim() : '';
    final toolCalls = message is Map ? message['tool_calls'] : null;
    final usage = decoded['usage'];
    final usageText = usage is Map
        ? 'prompt ${usage['prompt_tokens'] ?? '-'} / completion ${usage['completion_tokens'] ?? '-'}'
        : null;
    var detail = '接口成功，但 message.content 为空';
    if (refusal.isNotEmpty) {
      detail = '模型拒绝回答：$refusal';
    } else if (finishReason == 'length') {
      detail = '输出被截断（finish_reason=length），token 可能被推理内容占满';
    } else if (reasoning.isNotEmpty) {
      detail = '只返回了 reasoning_content，没有最终 content';
    } else if (toolCalls is List && toolCalls.isNotEmpty) {
      detail = '模型返回了工具调用，没有文本结果';
    } else if (finishReason.isNotEmpty) {
      detail = '接口成功，但 message.content 为空（finish_reason=$finishReason）';
    }
    throw LlmResponseException(
      '模型返回了空内容：$detail${usageText == null ? '' : '（$usageText）'}',
      rawBody: response.body,
      model: model,
      finishReason: finishReason,
    );
  }

  Future<String> chatWithImage({
    required LlmProvider provider,
    required String model,
    required String prompt,
    required String dataUrl,
  }) async {
    try {
      return await chat(
        provider: provider,
        model: model,
        messages: [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
          },
        ],
        // 视觉模型常把大量 token 用在推理上，留足空间给最终 JSON。
        maxTokens: 10000,
      );
    } on LlmResponseException catch (error) {
      throw LlmResponseException(
        '${error.message}。图片识别还要求当前模型支持视觉输入，可换用 qwen-vl-max 等视觉模型。',
        rawBody: error.rawBody,
        model: error.model,
        finishReason: error.finishReason,
      );
    }
  }

  bool _isNonChatModel(String id) {
    final lower = id.toLowerCase();
    return lower.contains('embedding') ||
        lower.contains('embed') ||
        lower.contains('rerank') ||
        lower.contains('whisper') ||
        lower.contains('tts') ||
        lower.contains('asr') ||
        lower.contains('speech') ||
        lower.contains('audio') ||
        lower.contains('dall-e') ||
        lower.contains('moderation') ||
        lower.contains('image') ||
        lower.contains('wanx') ||
        lower.contains('cogview') ||
        lower.contains('stable-diffusion');
  }

  String _errorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map)
        return '${decoded['error']?['message'] ?? decoded['message'] ?? ''}'
            .trim();
    } catch (_) {}
    return body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }
}
