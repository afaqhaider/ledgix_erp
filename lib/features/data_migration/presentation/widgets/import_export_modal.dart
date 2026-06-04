import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/migration_models.dart';
import '../../services/data_migration_service.dart';
import '../../services/migration_config.dart';

class ImportExportModal extends StatefulWidget {
  final MigrationModule initialModule;
  final String companyId;

  const ImportExportModal({
    super.key,
    required this.initialModule,
    required this.companyId,
  });

  @override
  State<ImportExportModal> createState() => _ImportExportModalState();
}

class _ImportExportModalState extends State<ImportExportModal> {
  late MigrationModule selectedModule;
  final DataMigrationService _service = DataMigrationService();

  bool _isLoading = false;
  PlatformFile? _selectedFile;
  List<List<dynamic>> _rawHeaders = [];
  List<List<dynamic>> _rawData = [];
  List<ImportRow> _processedRows = [];
  Map<String, int> _mapping = {};

  int _step = 0; // 0: Select/Upload, 1: Preview/Map

  @override
  void initState() {
    super.initState();
    selectedModule = widget.initialModule;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        _selectedFile = result.files.first;
        _rawData = await _service.parseFile(_selectedFile!);

        if (_rawData.isNotEmpty) {
          _rawHeaders = [_rawData.first];
          final defs = MigrationConfig.getFields(selectedModule);
          _mapping = _service.autoMapFields(_rawHeaders.first, defs);
          _processData();
          if (mounted) {
            setState(() {
              _step = 1;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File is empty or could not be parsed.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processData() {
    final defs = MigrationConfig.getFields(selectedModule);
    _processedRows = _service.processData(_rawData, _mapping, defs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: size.width * 0.8,
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _step == 0
                    ? _buildUploadStep(theme)
                    : _buildPreviewStep(theme),
              ),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Smart Import - ${selectedModule.label}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButtonFormField<MigrationModule>(
            initialValue: selectedModule,
            decoration: const InputDecoration(
              labelText: 'Select Module',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items:
                [
                  MigrationModule.customers,
                  MigrationModule.suppliers,
                  MigrationModule.chartOfAccounts,
                  MigrationModule.inventory,
                ].map((m) {
                  return DropdownMenuItem(value: m, child: Text(m.label));
                }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => selectedModule = val);
            },
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Click to upload Excel (XLSX/XLS) or CSV file',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maximum file size: 10MB',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(ThemeData theme) {
    final defs = MigrationConfig.getFields(selectedModule);
    return Column(
      children: [
        _buildMappingSummary(theme, defs),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('#')),
                  ...defs.map(
                    (d) => DataColumn(
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Maps to: ${_getMappedHeaderName(d.key)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: _processedRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text((row.index + 1).toString())),
                      ...defs.map((d) {
                        final val = row.data[d.key];
                        final error = row.errors[d.key];
                        return DataCell(
                          InkWell(
                            onTap: () => _editCell(row, d),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: error != null
                                  ? BoxDecoration(
                                      color: theme.colorScheme.errorContainer
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  : null,
                              child: Text(
                                val?.toString() ?? '-',
                                style: TextStyle(
                                  color: error != null ? Colors.red : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      DataCell(
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _processedRows.remove(row);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _editCell(ImportRow row, FieldDefinition field) {
    final controller = TextEditingController(
      text: row.data[field.key]?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.label}'),
        content: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                row.data[field.key] = controller.text;
                // Re-validate row
                if (field.isRequired && controller.text.isEmpty) {
                  row.errors[field.key] = '${field.label} is required';
                } else {
                  row.errors.remove(field.key);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getMappedHeaderName(String key) {
    final index = _mapping[key];
    if (index != null && index < _rawHeaders.first.length) {
      return _rawHeaders.first[index].toString();
    }
    return 'Unmapped';
  }

  Widget _buildMappingSummary(ThemeData theme, List<FieldDefinition> defs) {
    int mappedCount = _mapping.length;
    int totalCount = defs.length;
    int errorCount = _processedRows.where((r) => !r.isValid).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          _summaryBadge(
            theme,
            'Mapped: $mappedCount/$totalCount',
            theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _summaryBadge(
            theme,
            'Rows: ${_processedRows.length}',
            theme.colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          if (errorCount > 0)
            _summaryBadge(
              theme,
              'Errors: $errorCount',
              theme.colorScheme.error,
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showMappingDialog(theme, defs),
            icon: const Icon(Icons.map),
            label: const Text('Adjust Mapping'),
          ),
        ],
      ),
    );
  }

  void _showMappingDialog(ThemeData theme, List<FieldDefinition> defs) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setMapState) => AlertDialog(
          title: const Text('Map Columns to Fields'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: defs.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _mapping[d.key],
                      decoration: InputDecoration(
                        labelText: d.label + (d.isRequired ? ' *' : ''),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Not Mapped'),
                        ),
                        ...List.generate(_rawHeaders.first.length, (i) {
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Text(_rawHeaders.first[i].toString()),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setMapState(() {
                          if (val == null) {
                            _mapping.remove(d.key);
                          } else {
                            _mapping[d.key] = val;
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _processData();
                });
                Navigator.pop(context);
              },
              child: const Text('Apply & Re-process'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBadge(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final bool hasErrors = _processedRows.any((r) => !r.isValid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_step == 1) ...[
            OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton(
            onPressed: (_step == 1 && _processedRows.isNotEmpty && !hasErrors)
                ? _performImport
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(_step == 0 ? 'Upload File' : 'Finalize Import'),
          ),
        ],
      ),
    );
  }

  void _performImport() async {
    setState(() => _isLoading = true);

    try {
      await _service.performBatchImport(
        selectedModule,
        _processedRows,
        widget.companyId,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${_processedRows.length} ${selectedModule.label}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import Failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
