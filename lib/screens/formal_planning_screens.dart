import 'package:flutter/material.dart';

import '../app/app_composition_root.dart';
import '../app/ui_tokens.dart';
import '../models/enums.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_enums.dart';
import '../models/maintenance_plan_step.dart';
import '../models/milestone.dart';
import '../models/milestone_enums.dart';
import '../repositories/formal_planning_editor.dart';
import '../widgets/ui_v2_components.dart';

enum PlanningContentKind { maintenancePlan, reminder, milestone, schedule }

FormalPlanningEditor? formalPlanningEditor(BuildContext context) =>
    FormalPlanningEditor.from(AppCompositionScope.of(context));

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<EditableCategory>? _categories;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await formalPlanningEditor(context)!.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = values;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ManagementScaffold(
      title: '管理分類',
      intro: '分類只是協助整理生活項目，可以先用簡單、看得懂的名稱。',
      onAdd: () => _open(null),
      child: _error != null
          ? _LoadMessage(onRetry: _load)
          : _categories == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                for (final category in _categories!)
                  _ManagementTile(
                    title: category.displayName,
                    subtitle: category.systemCode == null ? '自訂分類' : '系統建議分類',
                    enabled: category.status != 'archived',
                    onTap: () => _open(category),
                  ),
              ],
            ),
    );
  }

  Future<void> _open(EditableCategory? value) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CategoryFormScreen(value: value)),
    );
    if (changed == true) await _load();
  }
}

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.value});

  final EditableCategory? value;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sortOrder;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.value?.customName ?? widget.value?.displayName,
    );
    _sortOrder = TextEditingController(
      text: (widget.value?.sortOrder ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingSystemName = widget.value?.systemCode != null;
    return _FormScaffold(
      title: widget.value == null ? '新增分類' : '編輯分類',
      saving: _saving,
      onSave: widget.value?.status == 'archived' ? null : _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _FormIntro(
              text: existingSystemName
                  ? '可以調整畫面上看到的名稱；系統分類本身不會被改掉。'
                  : '輸入一個你平常會使用的分類名稱，例如「家中證件」。',
            ),
            TextFormField(
              key: const ValueKey('category-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: '分類名稱'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '顯示順序',
                helperText: '數字較小的分類排在前面。',
              ),
              validator: (value) =>
                  int.tryParse(value ?? '') == null ? '請輸入整數' : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.value;
    try {
      await formalPlanningEditor(context)!.saveCategory(
        EditableCategory(
          id: old?.id ?? _newId('category'),
          systemCode: old?.systemCode,
          customName: _name.text.trim(),
          displayName: _name.text.trim(),
          sortOrder: int.parse(_sortOrder.text),
          status: old?.status ?? 'active',
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          archivedAt: old?.archivedAt,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.value});

  final EditableItem? value;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _years;
  late final TextEditingController _note;
  List<EditableCategory>? _categories;
  String? _categoryId;
  String _status = 'active';
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _name = TextEditingController(text: value?.name);
    _location = TextEditingController(text: value?.location);
    _years = TextEditingController(text: value?.expectedLifeYears?.toString());
    _note = TextEditingController(text: value?.note);
    _categoryId = value?.categoryId;
    _status = value?.status ?? 'active';
    _purchaseDate = value?.purchaseDate;
    _warrantyDate = value?.warrantyEndDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_categories == null) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final values = (await formalPlanningEditor(
      context,
    )!.loadCategories()).where((entry) => entry.status != 'archived').toList();
    if (!mounted) return;
    setState(() {
      _categories = values;
      _categoryId ??= values.isEmpty ? null : values.first.id;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _years.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archived = widget.value?.status == 'archived';
    return _FormScaffold(
      title: widget.value == null ? '新增生活項目' : '編輯生活項目',
      saving: _saving,
      onSave: archived || _categories == null || _categories!.isEmpty
          ? null
          : _save,
      child: _categories == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  const _FormIntro(text: '先填最重要的名稱與分類，其他資料可以之後再補。'),
                  TextFormField(
                    key: const ValueKey('item-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: '項目名稱'),
                    validator: _requiredText,
                  ),
                  const SizedBox(height: 16),
                  if (_categories!.isEmpty)
                    _MissingCategoryAction(onCreate: _createFirstCategory)
                  else
                    DropdownButtonFormField<String>(
                      key: const ValueKey('item-category'),
                      initialValue: _categoryId,
                      isExpanded: true,
                      menuMaxHeight: 320,
                      decoration: const InputDecoration(labelText: '分類'),
                      items: [
                        for (final category in _categories!)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: archived
                          ? null
                          : (value) => setState(() => _categoryId = value),
                      validator: (value) => value == null ? '請選擇分類' : null,
                    ),
                  const SizedBox(height: 16),
                  _StatusField(
                    value: _status,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: '放置位置（選填）'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _years,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '預計管理年限（選填）'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return null;
                      final years = int.tryParse(value!);
                      return years == null || years <= 0 ? '請輸入大於 0 的年數' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: '購買或開始日期',
                    value: _purchaseDate,
                    onChanged: (value) => setState(() => _purchaseDate = value),
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: '保固或合約到期日',
                    value: _warrantyDate,
                    onChanged: (value) => setState(() => _warrantyDate = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '備註（選填）'),
                  ),
                  if (archived) const _ReadOnlyNotice('已封存的生活項目不能再修改。'),
                ],
              ),
            ),
    );
  }

  Future<void> _createFirstCategory() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CategoryFormScreen()));
    if (changed == true) await _loadCategories();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.value;
    try {
      await formalPlanningEditor(context)!.saveItem(
        EditableItem(
          id: old?.id ?? _newId('item'),
          name: _name.text,
          categoryId: _categoryId!,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          purchaseDate: _purchaseDate,
          warrantyEndDate: _warrantyDate,
          expectedLifeYears: _years.text.trim().isEmpty
              ? null
              : int.parse(_years.text),
          location: _location.text,
          note: _note.text,
          status: _status,
          archivedAt: old?.archivedAt,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  List<EditableItem>? _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final values = await formalPlanningEditor(context)!.loadItems();
    if (mounted) setState(() => _items = values);
  }

  @override
  Widget build(BuildContext context) => _ManagementScaffold(
    title: '生活項目',
    intro: '生活項目是所有提醒、保養與階段重點的起點。',
    onAdd: () => _open(null),
    child: _items == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              for (final item in _items!)
                _ManagementTile(
                  title: item.name,
                  subtitle: item.location?.trim().isNotEmpty == true
                      ? item.location!
                      : '尚未設定位置',
                  enabled: item.status != 'archived',
                  onTap: () => _open(item),
                ),
            ],
          ),
  );

  Future<void> _open(EditableItem? value) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ItemFormScreen(value: value)),
    );
    if (changed == true) await _load();
  }
}

class PlanningContentScreen extends StatefulWidget {
  const PlanningContentScreen({
    super.key,
    required this.kind,
    this.initialItemId,
  });

  final PlanningContentKind kind;
  final String? initialItemId;

  @override
  State<PlanningContentScreen> createState() => _PlanningContentScreenState();
}

class _PlanningContentScreenState extends State<PlanningContentScreen> {
  List<EditableItem>? _items;
  String? _itemId;
  List<Object>? _entries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_items == null) _loadItems();
  }

  Future<void> _loadItems() async {
    final values = (await formalPlanningEditor(
      context,
    )!.loadItems()).where((item) => item.status != 'archived').toList();
    if (!mounted) return;
    setState(() {
      _items = values;
      _itemId = values.any((item) => item.id == widget.initialItemId)
          ? widget.initialItemId
          : values.isEmpty
          ? null
          : values.first.id;
    });
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    final id = _itemId;
    if (id == null) {
      if (mounted) setState(() => _entries = const []);
      return;
    }
    final editor = formalPlanningEditor(context)!;
    final values = switch (widget.kind) {
      PlanningContentKind.maintenancePlan => await editor.loadPlans(id),
      PlanningContentKind.reminder => await editor.loadReminders(id),
      PlanningContentKind.milestone => await editor.loadMilestones(id),
      PlanningContentKind.schedule => await editor.loadSchedules(id),
    };
    if (mounted) setState(() => _entries = List<Object>.from(values));
  }

  @override
  Widget build(BuildContext context) {
    return _ManagementScaffold(
      title: _contentTitle(widget.kind),
      intro: _contentIntro(widget.kind),
      onAdd: _itemId == null ? null : () => _open(null),
      child: _items == null
          ? const Center(child: CircularProgressIndicator())
          : _items!.isEmpty
          ? const _ReadOnlyNotice('請先建立生活項目，才能新增這項內容。')
          : Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _itemId,
                  decoration: const InputDecoration(labelText: '要管理的生活項目'),
                  items: [
                    for (final item in _items!)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _itemId = value;
                      _entries = null;
                    });
                    await _loadEntries();
                  },
                ),
                const SizedBox(height: 18),
                if (_entries == null)
                  const Center(child: CircularProgressIndicator())
                else if (_entries!.isEmpty)
                  const _ReadOnlyNotice('目前還沒有內容，可以從右上角新增。')
                else
                  for (final entry in _entries!)
                    _ManagementTile(
                      title: _entryTitle(entry),
                      subtitle: _entrySubtitle(entry),
                      enabled: !_entryLocked(entry),
                      onTap: () => _open(entry),
                    ),
              ],
            ),
    );
  }

  Future<void> _open(Object? value) async {
    final itemId = _itemId!;
    final route = switch (widget.kind) {
      PlanningContentKind.maintenancePlan => MaterialPageRoute<bool>(
        builder: (_) => MaintenancePlanFormScreen(
          itemId: itemId,
          value: value as MaintenancePlan?,
        ),
      ),
      PlanningContentKind.reminder => MaterialPageRoute<bool>(
        builder: (_) => ReminderFormScreen(
          itemId: itemId,
          value: value as EditableReminder?,
        ),
      ),
      PlanningContentKind.milestone => MaterialPageRoute<bool>(
        builder: (_) =>
            MilestoneFormScreen(itemId: itemId, value: value as Milestone?),
      ),
      PlanningContentKind.schedule => MaterialPageRoute<bool>(
        builder: (_) => ScheduleFormScreen(
          itemId: itemId,
          value: value as EditableSchedule?,
        ),
      ),
    };
    final changed = await Navigator.of(context).push<bool>(route);
    if (changed == true) await _loadEntries();
  }
}

class MaintenancePlanFormScreen extends StatefulWidget {
  const MaintenancePlanFormScreen({
    super.key,
    required this.itemId,
    this.value,
  });

  final String itemId;
  final MaintenancePlan? value;

  @override
  State<MaintenancePlanFormScreen> createState() =>
      _MaintenancePlanFormScreenState();
}

class _MaintenancePlanFormScreenState extends State<MaintenancePlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _minutes;
  late final TextEditingController _safety;
  late MaintenancePlanType _type;
  late RiskLevel _risk;
  late String _status;
  late List<_StepControllers> _steps;
  bool _requiredPhotos = false;
  bool _requiredNote = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _title = TextEditingController(text: value?.title);
    _description = TextEditingController(text: value?.description);
    _minutes = TextEditingController(text: value?.estimatedMinutes?.toString());
    _safety = TextEditingController(text: value?.safetyNotice);
    _type = value?.planType ?? MaintenancePlanType.cleaning;
    _risk = value?.riskLevel ?? RiskLevel.low;
    _status = value?.status.name ?? 'active';
    _requiredPhotos = value?.requiredPhotos ?? false;
    _requiredNote = value?.requiredNote ?? false;
    _steps = [
      for (final step in value?.steps ?? const <MaintenancePlanStep>[])
        _StepControllers.from(step),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _minutes.dispose();
    _safety.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archived = widget.value?.isArchived ?? false;
    return _FormScaffold(
      title: widget.value == null ? '新增保養項目' : '編輯保養項目',
      saving: _saving,
      onSave: archived ? null : _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const _FormIntro(text: '保養項目是長期管理內容；每一次提醒會由排程另外產生。'),
            TextFormField(
              key: const ValueKey('plan-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: '保養名稱'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MaintenancePlanType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '內容類型'),
              items: [
                for (final type in MaintenancePlanType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(_planTypeLabel(type)),
                  ),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RiskLevel>(
              initialValue: _risk,
              decoration: const InputDecoration(labelText: '安全注意程度'),
              items: [
                for (final risk in RiskLevel.values)
                  DropdownMenuItem(value: risk, child: Text(_riskLabel(risk))),
              ],
              onChanged: (value) => setState(() => _risk = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '說明（選填）'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '大約需要幾分鐘（選填）'),
              validator: _positiveOptionalInt,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _requiredPhotos,
              title: const Text('處理時需要照片'),
              onChanged: (value) => setState(() => _requiredPhotos = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _requiredNote,
              title: const Text('處理時需要備註'),
              onChanged: (value) => setState(() => _requiredNote = value),
            ),
            TextFormField(
              controller: _safety,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '安全提醒（選填）'),
            ),
            const SizedBox(height: 16),
            _StatusField(
              value: _status,
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '標準步驟',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('add-plan-step'),
                  onPressed: archived ? null : _addStep,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('加入步驟'),
                ),
              ],
            ),
            if (_steps.isEmpty) const _ReadOnlyNotice('步驟可以之後再補，不影響先建立保養項目。'),
            for (var index = 0; index < _steps.length; index++)
              _StepEditor(
                index: index,
                value: _steps[index],
                onRemove: archived ? null : () => _removeStep(index),
              ),
            if (archived) const _ReadOnlyNotice('已封存的保養項目不能再修改。'),
          ],
        ),
      ),
    );
  }

  void _addStep() => setState(() => _steps.add(_StepControllers.empty()));

  void _removeStep(int index) {
    final removed = _steps.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.value;
    try {
      await formalPlanningEditor(context)!.savePlan(
        MaintenancePlan(
          id: old?.id ?? _newId('plan'),
          itemId: widget.itemId,
          templateCardId: old?.templateCardId,
          title: _title.text.trim(),
          planType: _type,
          description: _textOrNull(_description.text),
          riskLevel: _risk,
          estimatedMinutes: _minutes.text.trim().isEmpty
              ? null
              : int.parse(_minutes.text),
          requiredPhotos: _requiredPhotos,
          requiredNote: _requiredNote,
          safetyNotice: _textOrNull(_safety.text),
          status: MaintenancePlanStatus.values.byName(_status),
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          archivedAt: old?.archivedAt,
          steps: [
            for (var index = 0; index < _steps.length; index++)
              MaintenancePlanStep(
                id: _steps[index].id ?? _newId('step-$index'),
                order: index,
                title: _steps[index].title.text.trim(),
                description: _steps[index].description.text.trim(),
                isRequired: _steps[index].required,
                photoRequired: _steps[index].photo,
                noteRequired: _steps[index].note,
              ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key, required this.itemId, this.value});

  final String itemId;
  final EditableReminder? value;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _type;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.value?.title);
    _description = TextEditingController(text: widget.value?.description);
    _type = widget.value?.reminderType ?? 'expiry';
    _status = widget.value?.status ?? 'active';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final archived = widget.value?.status == 'archived';
    return _FormScaffold(
      title: widget.value == null ? '新增一般提醒' : '編輯一般提醒',
      saving: _saving,
      onSave: archived ? null : _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const _FormIntro(text: '一般提醒適合保固、合約、證件、繳費或健康檢查等非保養事項。'),
            TextFormField(
              key: const ValueKey('reminder-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: '提醒名稱'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '提醒類型'),
              items: const [
                DropdownMenuItem(value: 'expiry', child: Text('到期或續約')),
                DropdownMenuItem(value: 'payment', child: Text('繳費')),
                DropdownMenuItem(value: 'healthCheck', child: Text('健康檢查')),
                DropdownMenuItem(value: 'documentUpdate', child: Text('文件更新')),
                DropdownMenuItem(value: 'custom', child: Text('其他提醒')),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '補充說明（選填）'),
            ),
            const SizedBox(height: 16),
            _StatusField(
              value: _status,
              onChanged: (value) => setState(() => _status = value),
            ),
            if (archived) const _ReadOnlyNotice('已封存的提醒不能再修改。'),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.value;
    try {
      await formalPlanningEditor(context)!.saveReminder(
        EditableReminder(
          id: old?.id ?? _newId('reminder'),
          itemId: widget.itemId,
          title: _title.text,
          description: _description.text,
          reminderType: _type,
          status: _status,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          archivedAt: old?.archivedAt,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class MilestoneFormScreen extends StatefulWidget {
  const MilestoneFormScreen({super.key, required this.itemId, this.value});

  final String itemId;
  final Milestone? value;

  @override
  State<MilestoneFormScreen> createState() => _MilestoneFormScreenState();
}

class _MilestoneFormScreenState extends State<MilestoneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _threshold;
  late final TextEditingController _unit;
  late final TextEditingController _lifeStage;
  late MilestoneKind _kind;
  late MilestoneTriggerType _trigger;
  DateTime? _triggerDate;
  List<MaintenancePlan> _plans = const [];
  List<Milestone> _milestones = const [];
  String? _sourcePlanId;
  String? _dependencyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _title = TextEditingController(text: value?.title);
    _description = TextEditingController(text: value?.description);
    _threshold = TextEditingController(text: value?.thresholdValue?.toString());
    _unit = TextEditingController(text: value?.thresholdUnit);
    _lifeStage = TextEditingController(text: value?.lifeStageCode);
    _kind = value?.kind ?? MilestoneKind.majorService;
    _trigger = value?.triggerType ?? MilestoneTriggerType.specificDate;
    _triggerDate = value?.triggerDate;
    _sourcePlanId = value?.sourcePlanId;
    _dependencyId = value?.dependencyMilestoneId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    final editor = formalPlanningEditor(context)!;
    final values = await Future.wait([
      editor.loadPlans(widget.itemId),
      editor.loadMilestones(widget.itemId),
    ]);
    if (!mounted) return;
    setState(() {
      _plans = values[0] as List<MaintenancePlan>;
      _milestones = (values[1] as List<Milestone>)
          .where((entry) => entry.id != widget.value?.id)
          .toList();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _threshold.dispose();
    _unit.dispose();
    _lifeStage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.value?.isClosed ?? false;
    final thresholdTrigger = {
      MilestoneTriggerType.usageYears,
      MilestoneTriggerType.mileage,
      MilestoneTriggerType.usageValue,
      MilestoneTriggerType.completionCount,
      MilestoneTriggerType.anomalyCount,
    }.contains(_trigger);
    return _FormScaffold(
      title: widget.value == null ? '新增階段性重點' : '編輯階段性重點',
      saving: _saving,
      onSave: locked ? null : _save,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const _FormIntro(text: '階段性重點適合大修、汰換評估、人生階段或達到條件後才出現的事情。'),
            TextFormField(
              key: const ValueKey('milestone-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: '重點名稱'),
              validator: _requiredText,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MilestoneKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: '重點類型'),
              items: [
                for (final value in MilestoneKind.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_milestoneKindLabel(value)),
                  ),
              ],
              onChanged: (value) => setState(() => _kind = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MilestoneTriggerType>(
              key: const ValueKey('milestone-trigger'),
              initialValue: _trigger,
              decoration: const InputDecoration(labelText: '什麼時候需要注意'),
              items: [
                for (final value in MilestoneTriggerType.values.where(
                  (value) => value != MilestoneTriggerType.unknown,
                ))
                  DropdownMenuItem(
                    value: value,
                    child: Text(_triggerTypeLabel(value)),
                  ),
              ],
              onChanged: (value) => setState(() => _trigger = value!),
            ),
            if (thresholdTrigger) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _threshold,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '達到多少'),
                validator: _positiveNumber,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: '單位（例如年、公里、次）'),
                validator: _requiredText,
              ),
            ],
            if (_trigger == MilestoneTriggerType.specificDate) ...[
              const SizedBox(height: 16),
              _DateField(
                label: '預定日期',
                value: _triggerDate,
                required: true,
                onChanged: (value) => setState(() => _triggerDate = value),
              ),
            ],
            if (_trigger == MilestoneTriggerType.lifeStage) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _lifeStage,
                decoration: const InputDecoration(labelText: '人生或照護階段'),
                validator: _requiredText,
              ),
            ],
            if (_trigger == MilestoneTriggerType.dependencyCompleted) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _dependencyId,
                decoration: const InputDecoration(labelText: '前一個重點完成後'),
                items: [
                  for (final value in _milestones)
                    DropdownMenuItem(value: value.id, child: Text(value.title)),
                ],
                onChanged: (value) => setState(() => _dependencyId = value),
                validator: (value) => value == null ? '請選擇前一個重點' : null,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _sourcePlanId,
              decoration: const InputDecoration(labelText: '相關保養項目（選填）'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('不指定'),
                ),
                for (final plan in _plans)
                  DropdownMenuItem(value: plan.id, child: Text(plan.title)),
              ],
              onChanged: (value) => setState(() => _sourcePlanId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '補充說明（選填）'),
            ),
            if (locked) const _ReadOnlyNotice('已結束的階段性重點不能再修改。'),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_trigger == MilestoneTriggerType.specificDate && _triggerDate == null) {
      _showSaveError(context, '請選擇預定日期');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = widget.value;
    final thresholdTrigger = {
      MilestoneTriggerType.usageYears,
      MilestoneTriggerType.mileage,
      MilestoneTriggerType.usageValue,
      MilestoneTriggerType.completionCount,
      MilestoneTriggerType.anomalyCount,
    }.contains(_trigger);
    try {
      await formalPlanningEditor(context)!.saveMilestone(
        Milestone(
          id: old?.id ?? _newId('milestone'),
          itemId: widget.itemId,
          title: _title.text.trim(),
          description: _textOrNull(_description.text),
          kind: _kind,
          triggerType: _trigger,
          sourcePlanId: _sourcePlanId,
          thresholdValue: thresholdTrigger
              ? double.parse(_threshold.text)
              : null,
          thresholdUnit: thresholdTrigger ? _unit.text.trim() : null,
          triggerDate: _trigger == MilestoneTriggerType.specificDate
              ? _triggerDate
              : null,
          dependencyMilestoneId:
              _trigger == MilestoneTriggerType.dependencyCompleted
              ? _dependencyId
              : null,
          lifeStageCode: _trigger == MilestoneTriggerType.lifeStage
              ? _lifeStage.text.trim()
              : null,
          status: old?.status ?? MilestoneStatus.pending,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          reachedAt: old?.reachedAt,
          acknowledgedAt: old?.acknowledgedAt,
          startedAt: old?.startedAt,
          completedAt: old?.completedAt,
          canceledAt: old?.canceledAt,
          archivedAt: old?.archivedAt,
          workCaseId: old?.workCaseId,
          cancellationReason: old?.cancellationReason,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ScheduleFormScreen extends StatefulWidget {
  const ScheduleFormScreen({super.key, required this.itemId, this.value});

  final String itemId;
  final EditableSchedule? value;

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _interval;
  late final TextEditingController _time;
  List<_SourceOption>? _sources;
  String? _sourceKey;
  late String _cycle;
  late String _anchor;
  late String _status;
  late DateTime _startDate;
  late DateTime _nextDate;
  DateTime? _userDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _interval = TextEditingController(text: (value?.interval ?? 1).toString());
    _time = TextEditingController(text: value?.reminderTime);
    _sourceKey = value == null ? null : '${value.sourceType}:${value.sourceId}';
    _cycle = value?.cycleType ?? 'monthly';
    _anchor = value?.anchorPolicy ?? 'fixedCalendarPeriod';
    _status = value?.status ?? 'active';
    _startDate = value?.startDate ?? DateTime.now();
    _nextDate = value?.nextDueDate ?? DateTime.now();
    _userDate = value?.userDefinedNextDate;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sources == null) _loadSources();
  }

  Future<void> _loadSources() async {
    final editor = formalPlanningEditor(context)!;
    final values = await Future.wait([
      editor.loadPlans(widget.itemId),
      editor.loadReminders(widget.itemId),
      editor.loadMilestones(widget.itemId),
    ]);
    final sources = <_SourceOption>[
      for (final plan in values[0] as List<MaintenancePlan>)
        if (!plan.isArchived)
          _SourceOption(
            type: 'maintenancePlan',
            id: plan.id,
            title: '保養：${plan.title}',
          ),
      for (final reminder in values[1] as List<EditableReminder>)
        if (reminder.status != 'archived')
          _SourceOption(
            type: 'generalReminder',
            id: reminder.id,
            title: '提醒：${reminder.title}',
          ),
      for (final milestone in values[2] as List<Milestone>)
        if (!milestone.isClosed)
          _SourceOption(
            type: 'milestone',
            id: milestone.id,
            title: '階段重點：${milestone.title}',
          ),
    ];
    final existing = widget.value;
    if (existing != null && !sources.any((entry) => entry.key == _sourceKey)) {
      sources.add(
        _SourceOption(
          type: existing.sourceType,
          id: existing.sourceId,
          title: '原有來源（僅供保留）',
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _sources = sources;
      _sourceKey ??= sources.isEmpty ? null : sources.first.key;
    });
  }

  @override
  void dispose() {
    _interval.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ended = widget.value?.status == 'ended';
    final unsupportedSource = widget.value?.sourceType == 'unknown';
    return _FormScaffold(
      title: widget.value == null ? '新增排程' : '編輯排程',
      saving: _saving,
      onSave: ended || unsupportedSource ? null : _save,
      child: _sources == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  const _FormIntro(text: '排程只決定何時提醒；保養、一般提醒與階段重點仍各自保留。'),
                  if (_sources!.isEmpty)
                    const _ReadOnlyNotice('請先建立保養項目、一般提醒或階段性重點。')
                  else
                    DropdownButtonFormField<String>(
                      key: const ValueKey('schedule-source'),
                      initialValue: _sourceKey,
                      decoration: const InputDecoration(labelText: '提醒內容'),
                      items: [
                        for (final source in _sources!)
                          DropdownMenuItem(
                            value: source.key,
                            child: Text(source.title),
                          ),
                      ],
                      onChanged: widget.value == null
                          ? (value) => setState(() => _sourceKey = value)
                          : null,
                      validator: (value) => value == null ? '請選擇提醒內容' : null,
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('schedule-cycle'),
                    initialValue: _cycle,
                    decoration: const InputDecoration(labelText: '多久一次'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('每天')),
                      DropdownMenuItem(value: 'weekly', child: Text('每週')),
                      DropdownMenuItem(value: 'monthly', child: Text('每月')),
                      DropdownMenuItem(value: 'quarterly', child: Text('每季')),
                      DropdownMenuItem(value: 'semiAnnual', child: Text('每半年')),
                      DropdownMenuItem(value: 'yearly', child: Text('每年')),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('自行指定下一次日期'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _cycle = value!;
                        if (value == 'custom') {
                          _anchor = 'userDefined';
                          _userDate ??= _nextDate;
                        } else if (_anchor == 'userDefined') {
                          _anchor = 'fixedCalendarPeriod';
                          _userDate = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _interval,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '間隔',
                      helperText: '例如每 2 個月一次，請填 2。',
                    ),
                    validator: _positiveInt,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('schedule-anchor'),
                    initialValue: _anchor,
                    decoration: const InputDecoration(labelText: '下一次日期怎麼算'),
                    items: _cycle == 'custom'
                        ? const [
                            DropdownMenuItem(
                              value: 'userDefined',
                              child: Text('由我指定下一次日期'),
                            ),
                          ]
                        : const [
                            DropdownMenuItem(
                              value: 'fixedCalendarPeriod',
                              child: Text('維持原本日曆週期（建議）'),
                            ),
                            DropdownMenuItem(
                              value: 'completionBased',
                              child: Text('從完成日期重新計算'),
                            ),
                          ],
                    onChanged: (value) => setState(() => _anchor = value!),
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: '開始日期',
                    value: _startDate,
                    required: true,
                    onChanged: (value) => setState(() => _startDate = value!),
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: '下次提醒日期',
                    value: _nextDate,
                    required: true,
                    onChanged: (value) => setState(() => _nextDate = value!),
                  ),
                  if (_anchor == 'userDefined') ...[
                    const SizedBox(height: 12),
                    _DateField(
                      label: '自行指定的下一次日期',
                      value: _userDate,
                      required: true,
                      onChanged: (value) => setState(() => _userDate = value),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _time,
                    decoration: const InputDecoration(
                      labelText: '提醒時間（選填，例如 09:00）',
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) return null;
                      return RegExp(
                            r'^([01]\d|2[0-3]):[0-5]\d$',
                          ).hasMatch(value!.trim())
                          ? null
                          : '請使用 24 小時格式，例如 09:00';
                    },
                  ),
                  const SizedBox(height: 16),
                  _StatusField(
                    value: _status,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  if (ended) const _ReadOnlyNotice('已結束的排程不能再修改。'),
                  if (unsupportedSource)
                    const _ReadOnlyNotice('這筆舊排程的來源無法確認，目前只保留原始資料。'),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _sourceKey == null) return;
    if (_anchor == 'userDefined' && _userDate == null) {
      _showSaveError(context, '請指定下一次日期');
      return;
    }
    setState(() => _saving = true);
    final source = _sources!.firstWhere((entry) => entry.key == _sourceKey);
    final now = DateTime.now();
    final old = widget.value;
    try {
      await formalPlanningEditor(context)!.saveSchedule(
        EditableSchedule(
          id: old?.id ?? _newId('schedule'),
          itemId: widget.itemId,
          sourceType: old?.sourceType ?? source.type,
          sourceId: old?.sourceId ?? source.id,
          cycleType: _cycle,
          interval: int.parse(_interval.text),
          startDate: _startDate,
          nextDueDate: _nextDate,
          reminderTime: _time.text,
          status: _status,
          anchorPolicy: _anchor,
          userDefinedNextDate: _anchor == 'userDefined' ? _userDate : null,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          endedAt: old?.endedAt,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showSaveError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ManagementScaffold extends StatelessWidget {
  const _ManagementScaffold({
    required this.title,
    required this.intro,
    required this.child,
    this.onAdd,
  });

  final String title;
  final String intro;
  final Widget child;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        if (onAdd != null)
          IconButton(
            key: const ValueKey('add-entry'),
            onPressed: onAdd,
            tooltip: '新增',
            icon: const Icon(Icons.add_rounded),
          ),
      ],
    ),
    body: ListView(
      padding: UiInsets.page,
      children: [
        UiCompactPageHeader(
          title: title,
          description: intro,
          icon: Icons.tune_rounded,
        ),
        child,
      ],
    ),
  );
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold({
    required this.title,
    required this.child,
    required this.saving,
    this.onSave,
  });

  final String title;
  final Widget child;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: Text(title),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          key: const ValueKey('item-form-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            UiSpace.md,
            UiSpace.xs,
            UiSpace.md,
            UiSpace.xxl,
          ),
          children: [child],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: UiMotion.standard,
        curve: UiMotion.standardCurve,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            UiSpace.md,
            UiSpace.xs,
            UiSpace.md,
            UiSpace.md,
          ),
          child: UiPrimaryButton(
            key: const ValueKey('save-form'),
            label: onSave == null ? '目前不可修改' : '儲存',
            icon: Icons.save_outlined,
            onPressed: onSave,
            loading: saving,
          ),
        ),
      ),
    );
  }
}

class _MissingCategoryAction extends StatelessWidget {
  const _MissingCategoryAction({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(UiSpace.md),
    decoration: BoxDecoration(
      color: UiColors.surfaceWarm,
      borderRadius: BorderRadius.circular(UiRadius.card),
      border: Border.all(color: UiColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('目前還沒有可使用的分類。', style: UiType.cardTitle),
        const SizedBox(height: UiSpace.xs),
        const Text('先建立一個熟悉的分類，完成後會回到這份生活項目表單。', style: UiType.body),
        const SizedBox(height: UiSpace.sm),
        OutlinedButton.icon(
          key: const ValueKey('create-first-category'),
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('新增分類'),
        ),
      ],
    ),
  );
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: UiColors.surfaceWarm,
      borderRadius: BorderRadius.circular(UiRadius.card),
      border: Border.all(color: UiColors.border),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: UiColors.textSupporting,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(enabled ? subtitle : '$subtitle · 已結束，僅供查看'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
      );
      if (picked != null) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: required ? '$label *' : '$label（選填）',
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(value == null ? '尚未設定' : _formatDate(value!)),
    ),
  );
}

class _StatusField extends StatelessWidget {
  const _StatusField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value == 'paused' ? 'paused' : 'active',
    decoration: const InputDecoration(labelText: '目前狀態'),
    items: const [
      DropdownMenuItem(value: 'active', child: Text('持續管理')),
      DropdownMenuItem(value: 'paused', child: Text('暫時停用')),
    ],
    onChanged: (value) => onChanged(value!),
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF687887),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LoadMessage extends StatelessWidget {
  const _LoadMessage({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('暫時無法讀取資料。'),
      TextButton(onPressed: onRetry, child: const Text('重新讀取')),
    ],
  );
}

class _StepControllers {
  _StepControllers({
    this.id,
    required this.title,
    required this.description,
    this.required = true,
    this.photo = false,
    this.note = false,
  });
  factory _StepControllers.empty() => _StepControllers(
    title: TextEditingController(),
    description: TextEditingController(),
  );
  factory _StepControllers.from(MaintenancePlanStep value) => _StepControllers(
    id: value.id,
    title: TextEditingController(text: value.title),
    description: TextEditingController(text: value.description),
    required: value.isRequired,
    photo: value.photoRequired,
    note: value.noteRequired,
  );
  final String? id;
  final TextEditingController title;
  final TextEditingController description;
  bool required;
  bool photo;
  bool note;
  void dispose() {
    title.dispose();
    description.dispose();
  }
}

class _StepEditor extends StatefulWidget {
  const _StepEditor({required this.index, required this.value, this.onRemove});
  final int index;
  final _StepControllers value;
  final VoidCallback? onRemove;
  @override
  State<_StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends State<_StepEditor> {
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '步驟 ${widget.index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close_rounded),
                tooltip: '移除步驟',
              ),
            ],
          ),
          TextFormField(
            controller: widget.value.title,
            decoration: const InputDecoration(labelText: '步驟名稱'),
            validator: _requiredText,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.value.description,
            decoration: const InputDecoration(labelText: '補充說明（選填）'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: widget.value.required,
            title: const Text('這是必要步驟'),
            onChanged: (value) =>
                setState(() => widget.value.required = value!),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: widget.value.photo,
            title: const Text('需要照片'),
            onChanged: (value) => setState(() => widget.value.photo = value!),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: widget.value.note,
            title: const Text('需要備註'),
            onChanged: (value) => setState(() => widget.value.note = value!),
          ),
        ],
      ),
    ),
  );
}

class _SourceOption {
  const _SourceOption({
    required this.type,
    required this.id,
    required this.title,
  });
  final String type;
  final String id;
  final String title;
  String get key => '$type:$id';
}

String _contentTitle(PlanningContentKind kind) => switch (kind) {
  PlanningContentKind.maintenancePlan => '保養項目與步驟',
  PlanningContentKind.reminder => '一般提醒',
  PlanningContentKind.milestone => '階段性重點',
  PlanningContentKind.schedule => '提醒排程',
};

String _contentIntro(PlanningContentKind kind) => switch (kind) {
  PlanningContentKind.maintenancePlan => '建立長期需要管理的保養內容與標準步驟。',
  PlanningContentKind.reminder => '管理保固、合約、證件、繳費與其他非保養提醒。',
  PlanningContentKind.milestone => '管理大修、汰換評估與達到條件才需要注意的事情。',
  PlanningContentKind.schedule => '替既有內容安排提醒日期與週期。',
};

String _entryTitle(Object value) => switch (value) {
  MaintenancePlan(:final title) => title,
  EditableReminder(:final title) => title,
  Milestone(:final title) => title,
  EditableSchedule() => '提醒排程',
  _ => '未命名內容',
};

String _entrySubtitle(Object value) => switch (value) {
  MaintenancePlan(:final steps) => '${steps.length} 個標準步驟',
  EditableReminder(:final reminderType) => _reminderTypeLabel(reminderType),
  Milestone(:final triggerType) => _triggerTypeLabel(triggerType),
  EditableSchedule(:final cycleType, :final nextDueDate) =>
    '${_cycleLabel(cycleType)} · 下次 ${_formatDate(nextDueDate)}',
  _ => '',
};

bool _entryLocked(Object value) => switch (value) {
  MaintenancePlan(:final isArchived) => isArchived,
  EditableReminder(:final status) => status == 'archived',
  Milestone(:final isClosed) => isClosed,
  EditableSchedule(:final status, :final sourceType) =>
    status == 'ended' || sourceType == 'unknown',
  _ => false,
};

String _planTypeLabel(MaintenancePlanType value) => switch (value) {
  MaintenancePlanType.cleaning => '清潔',
  MaintenancePlanType.inspection => '檢查',
  MaintenancePlanType.replacement => '更換',
  MaintenancePlanType.routineService => '定期保養',
  MaintenancePlanType.expiryReview => '到期檢視',
  MaintenancePlanType.custom => '其他',
};

String _riskLabel(RiskLevel value) => switch (value) {
  RiskLevel.low => '一般注意',
  RiskLevel.medium => '需要多一點留意',
  RiskLevel.high => '建議尋求專業協助',
  RiskLevel.unknown => '尚未判斷',
};

String _milestoneKindLabel(MilestoneKind value) => switch (value) {
  MilestoneKind.majorService => '大修或全面保養',
  MilestoneKind.deepInspection => '深度檢查',
  MilestoneKind.replacementEvaluation => '汰換評估',
  MilestoneKind.renewal => '續約或換發',
  MilestoneKind.careTransition => '生活或照護階段',
  MilestoneKind.custom => '其他重點',
};

String _triggerTypeLabel(MilestoneTriggerType value) => switch (value) {
  MilestoneTriggerType.usageYears => '使用一段年限後',
  MilestoneTriggerType.mileage => '達到指定里程',
  MilestoneTriggerType.usageValue => '達到指定使用量',
  MilestoneTriggerType.completionCount => '完成指定次數後',
  MilestoneTriggerType.specificDate => '到指定日期',
  MilestoneTriggerType.dependencyCompleted => '另一個重點完成後',
  MilestoneTriggerType.lifeStage => '進入某個生活階段',
  MilestoneTriggerType.anomalyCount => '異常發生指定次數後',
  MilestoneTriggerType.manual => '由我決定何時開始',
  MilestoneTriggerType.unknown => '尚未確認',
};

String _reminderTypeLabel(String value) => switch (value) {
  'expiry' => '到期或續約',
  'payment' => '繳費',
  'healthCheck' => '健康檢查',
  'documentUpdate' => '文件更新',
  _ => '其他提醒',
};

String _cycleLabel(String value) => switch (value) {
  'daily' => '每天',
  'weekly' => '每週',
  'monthly' => '每月',
  'quarterly' => '每季',
  'semiAnnual' => '每半年',
  'yearly' => '每年',
  _ => '自行指定',
};

String? _requiredText(String? value) =>
    (value ?? '').trim().isEmpty ? '請填寫這一欄' : null;
String? _positiveOptionalInt(String? value) {
  if ((value ?? '').trim().isEmpty) return null;
  final number = int.tryParse(value!);
  return number == null || number <= 0 ? '請輸入大於 0 的整數' : null;
}

String? _positiveInt(String? value) {
  final number = int.tryParse(value ?? '');
  return number == null || number <= 0 ? '請輸入大於 0 的整數' : null;
}

String? _positiveNumber(String? value) {
  final number = double.tryParse(value ?? '');
  return number == null || number <= 0 ? '請輸入大於 0 的數字' : null;
}

String? _textOrNull(String value) => value.trim().isEmpty ? null : value.trim();
String _newId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';
String _formatDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

void _showSaveError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error is String ? error : '無法儲存，請確認資料後再試一次。')),
  );
}
