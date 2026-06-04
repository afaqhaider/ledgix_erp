import 'package:flutter/material.dart';

class ErpSidePane extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isLoading;
  final String saveLabel;

  const ErpSidePane({
    super.key,
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onSave,
    this.isLoading = false,
    this.saveLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final paneWidth = isMobile ? screenWidth : 600.0;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: paneWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              left: BorderSide(color: theme.dividerColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.iconTheme.color?.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: child,
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.05),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              saveLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErpGlassModal extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isLoading;
  final String saveLabel;
  final double width;

  const ErpGlassModal({
    super.key,
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onSave,
    this.isLoading = false,
    this.saveLabel = 'Save',
    this.width = 500,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: theme.iconTheme.color?.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            // Footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isLoading ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            saveLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErpFormStyle {
  static TextStyle labelStyle(BuildContext context) => TextStyle(
    fontSize: 11,
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    fontWeight: FontWeight.w500,
  );

  static TextStyle inputStyle(BuildContext context) =>
      TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface);

  static TextStyle sectionHeaderStyle(BuildContext context) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.onSurface,
    letterSpacing: 0.5,
  );

  static InputDecoration inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: labelStyle(context),
      prefixIcon: icon != null
          ? Icon(
              icon,
              size: 18,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            )
          : null,
      prefixText: prefixText,
      prefixStyle: inputStyle(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      fillColor: theme.brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.01),
      filled: true,
    );
  }
}

Future<T?> showErpSidePane<T>({
  required BuildContext context,
  required Widget builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Side Pane',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => builder,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}
