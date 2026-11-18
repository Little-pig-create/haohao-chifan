import 'package:flutter/material.dart';

import '../services/llm_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

void openLlmSettingsPage(BuildContext context) {
  Navigator.of(context).push(
    slidePageRoute(
      const SubpageFrame(title: 'AI 模型', child: LlmSettingsScreen()),
    ),
  );
}

class LlmSettingsScreen extends StatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  State<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends State<LlmSettingsScreen> {
  final _name = TextEditingController();
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  String _presetId = 'deepseek';
  bool _adding = false;
  bool _testing = false;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    final preset = llmPresets.first;
    _name.text = preset.name;
    _baseUrl.text = preset.baseUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  void _applyPreset(LlmPreset preset) {
    setState(() {
      _presetId = preset.id;
      if (preset.id != 'custom') {
        _name.text = preset.name;
        _baseUrl.text = preset.baseUrl;
      }
    });
  }

  Future<void> _add() async {
    final state = AppScope.of(context);
    final name = _name.text.trim();
    final baseUrl = _baseUrl.text.trim();
    if (name.isEmpty) {
      showToast(context, '给这个提供商起个名字', icon: Icons.edit_note_rounded);
      return;
    }
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      showToast(
        context,
        'Base URL 需要以 http(s):// 开头',
        icon: Icons.link_off_rounded,
      );
      return;
    }
    setState(() => _adding = true);
    await state.addLlmProvider(
      name: name,
      baseUrl: baseUrl,
      apiKey: _apiKey.text,
    );
    if (!mounted) return;
    setState(() => _adding = false);
    _apiKey.clear();
    if (state.llmError != null) {
      showToast(context, state.llmError!, icon: Icons.error_outline_rounded);
    } else {
      showToast(context, '已添加「$name」，并自动拉取模型列表');
    }
  }

  Future<void> _test() async {
    final state = AppScope.of(context);
    setState(() => _testing = true);
    try {
      final reply = await state.testLlm();
      if (!mounted) return;
      showToast(
        context,
        '连通正常：${reply.length > 40 ? '${reply.substring(0, 40)}…' : reply}',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      showToast(
        context,
        '$error'.replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _pickModel(LlmProvider provider) async {
    final state = AppScope.of(context);
    if (provider.models.isEmpty) {
      await state.fetchLlmModels(provider.id);
      if (!mounted) return;
      if (state.llmError != null) {
        showToast(
          context,
          '${state.llmError!}，可在下方手动添加模型 ID',
          icon: Icons.info_outline_rounded,
        );
      }
    }
    if (!mounted) return;
    final latest = state.llmProviders.firstWhere(
      (item) => item.id == provider.id,
      orElse: () => provider,
    );
    final preset = presetForBaseUrl(latest.baseUrl);
    final suggestions = latest.models.isEmpty
        ? (preset?.fallbackModels ?? const <String>[])
        : const <String>[];
    final result = await showModalBottomSheet<_ModelSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ModelPickerSheet(provider: latest, suggestions: suggestions),
    );
    if (result == null || result.enabled.isEmpty || !mounted) return;
    final active = result.active ?? result.enabled.first;
    await state.updateProviderModels(provider.id, result.enabled, active);
    if (!mounted) return;
    showToast(context, '已启用 ${result.enabled.length} 个模型 · 当前 $active');
  }

  Future<void> _remove(LlmProvider provider) async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除这个提供商？', style: TextStyle(fontSize: 18)),
        content: Text(
          '「${provider.name}」的密钥会从系统安全存储中一并删除。',
          style: const TextStyle(fontSize: 12, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.removeLlmProvider(provider.id);
    if (!mounted) return;
    showToast(context, '已删除「${provider.name}」');
  }

  String _maskKey(String key) {
    if (key.trim().isEmpty) return '未填写密钥';
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.activeProvider;
    final model = state.activeModel ?? active?.model;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 30),
      children: [
        const PageHeader(
          eyebrow: 'AI Engine',
          title: '模型与提供商',
          subtitle: '优先接入国内模型服务，接口兼容 OpenAI 规范。密钥只写入本机系统安全存储，不会打包进应用。',
        ),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF3FAE2), Color(0xFFFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: const Color(0xFFE8F0D9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '当前引擎',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  SoftTag(
                    active == null ? '未配置' : (model == null ? '待选模型' : '已就绪'),
                    background: active == null
                        ? const Color(0xFFF0F1EC)
                        : AppColors.accent,
                    color: AppColors.ink,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                model ?? '还没有连接模型',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active == null
                    ? '添加一个提供商后，AI 记录、拍照识别和对话都会走真实模型。'
                    : '${active.name} · ${_maskKey(active.apiKey)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
              if (active != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: _testing ? '测试中…' : '测试连通性',
                        icon: Icons.bolt_rounded,
                        tone: PillTone.outline,
                        expand: true,
                        onPressed: _testing ? null : _test,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PillButton(
                        label: state.llmBusy ? '拉取中…' : '刷新模型',
                        icon: Icons.refresh_rounded,
                        tone: PillTone.outline,
                        expand: true,
                        onPressed: state.llmBusy
                            ? null
                            : () => state.fetchLlmModels(active.id),
                      ),
                    ),
                  ],
                ),
              ],
              if (state.llmError != null) ...[
                const SizedBox(height: 9),
                Text(
                  state.llmError!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA6553F),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('已添加的提供商', style: titleStyle(size: 18)),
                  const Spacer(),
                  Text(
                    '${state.llmProviders.length} 个',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (state.llmProviders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '还没有提供商。下面选一个预设，填入你自己的 API Key 即可开始。',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                      height: 1.6,
                    ),
                  ),
                )
              else
                ...state.llmProviders.map((provider) {
                  final isActive = provider.id == state.activeProviderId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF4FAE7)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFDDE9C8)
                            : AppColors.line,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (isActive)
                              const SoftTag(
                                '使用中',
                                background: AppColors.accent,
                                color: AppColors.ink,
                              ),
                            const SizedBox(width: 4),
                            IconPill(
                              icon: Icons.delete_outline_rounded,
                              size: 26,
                              background: Colors.white,
                              color: const Color(0xFFA6553F),
                              onTap: () => _remove(provider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.baseUrl,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.models.isEmpty
                              ? '${provider.model ?? '未选模型'} · 还没有模型列表'
                              : '${provider.model ?? '未选模型'} · 已勾选 ${provider.enabledModels.isEmpty ? provider.models.length : provider.enabledModels.length}/${provider.models.length}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.ink2,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: isActive ? '切换模型' : '启用并选模型',
                                icon: Icons.tune_rounded,
                                tone: PillTone.outline,
                                expand: true,
                                height: 36,
                                onPressed: () => _pickModel(provider),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: PillButton(
                                label: '拉取模型',
                                icon: Icons.download_outlined,
                                tone: PillTone.outline,
                                expand: true,
                                height: 36,
                                onPressed: state.llmBusy
                                    ? null
                                    : () => state.fetchLlmModels(provider.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('添加提供商', style: titleStyle(size: 18)),
              const SizedBox(height: 4),
              const Text(
                '选一个国内服务预设，或手填兼容地址。',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: llmPresets.map((preset) {
                  final activePreset = preset.id == _presetId;
                  return Pressable(
                    onTap: () => _applyPreset(preset),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: activePreset
                            ? AppColors.ink
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: activePreset ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: activePreset ? Colors.white : AppColors.ink2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 11),
              _field('名称', _name, '例如：我的 DeepSeek'),
              const SizedBox(height: 9),
              _field(
                'Base URL',
                _baseUrl,
                'https://api.deepseek.com/v1',
                keyboard: TextInputType.url,
              ),
              const SizedBox(height: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _apiKey,
                    obscureText: !_showKey,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'sk-…',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showKey
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _showKey = !_showKey),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              PillButton(
                label: _adding ? '正在添加并拉取模型…' : '添加并拉取模型',
                icon: Icons.add_rounded,
                expand: true,
                onPressed: _adding ? null : _add,
              ),
              const SizedBox(height: 9),
              const Text(
                '密钥只保存在本机 Keychain / Keystore。请求直接从设备发往你选择的提供商，不经过本应用的服务器。',
                style: TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF98A096),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          autocorrect: false,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }
}

class _ModelSelection {
  final List<String> enabled;
  final String? active;
  const _ModelSelection({required this.enabled, this.active});
}

class _ModelPickerSheet extends StatefulWidget {
  final LlmProvider provider;

  /// 服务不支持 GET /models 时，用预设里的常用模型兜底。
  final List<String> suggestions;
  const _ModelPickerSheet({
    required this.provider,
    this.suggestions = const [],
  });

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final _query = TextEditingController();
  final _manual = TextEditingController();
  late Set<String> _enabled;
  String? _active;
  final List<String> _extra = [];

  @override
  void initState() {
    super.initState();
    _active = widget.provider.model;
    final base = widget.provider.models.isNotEmpty
        ? widget.provider.models.map((model) => model.id).toList()
        : widget.suggestions;
    _enabled = widget.provider.enabledModels.isEmpty
        ? base.toSet()
        : widget.provider.enabledModels.toSet();
    if (_active != null) _enabled.add(_active!);
  }

  @override
  void dispose() {
    _query.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_enabled.remove(id)) {
        _enabled.add(id);
      } else if (_active == id) {
        _active = _enabled.isEmpty ? null : _enabled.first;
      }
    });
  }

  void _select(String id) {
    setState(() {
      _enabled.add(id);
      _active = id;
    });
  }

  void _addManual() {
    final id = _manual.text.trim();
    if (id.isEmpty) return;
    setState(() {
      if (!_extra.contains(id)) _extra.add(id);
      _enabled.add(id);
      _active = id;
      _manual.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _query.text.trim().toLowerCase();
    final all = <String>{
      ...widget.provider.models.map((model) => model.id),
      ...widget.suggestions,
      ..._extra,
    }.toList();
    final models = all
        .where((id) => keyword.isEmpty || id.toLowerCase().contains(keyword))
        .toList();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD9DDD3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          SheetHeader(
            icon: Icons.checklist_rounded,
            title: '勾选可用模型',
            subtitle: '${widget.provider.name} · 勾选后才会出现在切换列表里，点名字设为当前使用。',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '搜索模型，例如：qwen / glm / deepseek',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已勾选 ${_enabled.length}/${all.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Pressable(
                  onTap: () => setState(() => _enabled = all.toSet()),
                  child: const Text(
                    '全选',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Pressable(
                  onTap: () => setState(() {
                    _enabled = {if (_active != null) _active!};
                  }),
                  child: const Text(
                    '只留当前',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              itemCount: models.length,
              itemBuilder: (context, index) {
                final id = models[index];
                final checked = _enabled.contains(id);
                final active = id == _active;
                return Pressable(
                  onTap: () => _select(id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFF2F8E4)
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFDDE9C8)
                            : AppColors.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => _toggle(id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: checked
                                  ? AppColors.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: checked
                                    ? AppColors.ink
                                    : const Color(0xFFD3D8CD),
                              ),
                            ),
                            child: checked
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (active)
                          const SoftTag(
                            '当前',
                            background: AppColors.accent,
                            color: AppColors.ink,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manual,
                        onSubmitted: (_) => _addManual(),
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: '手动添加模型 ID',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconPill(icon: Icons.add_rounded, onTap: _addManual),
                  ],
                ),
                const SizedBox(height: 8),
                PillButton(
                  label: '完成 · 启用 ${_enabled.length} 个模型',
                  icon: Icons.check_rounded,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(
                    _ModelSelection(
                      enabled: _enabled.toList(),
                      active: _active,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
