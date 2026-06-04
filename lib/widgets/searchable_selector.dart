import 'package:flutter/material.dart';

class SearchableSelector<T> extends StatefulWidget {
  final String labelText;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final T? initialValue;
  final Function(T?) onSelected;
  final String addLabel;
  final VoidCallback onAdd;
  final String? Function(String?)? validator;
  final String? hintText;
  final bool autofocus;

  const SearchableSelector({
    super.key,
    required this.labelText,
    required this.items,
    required this.itemLabelBuilder,
    required this.onSelected,
    required this.addLabel,
    required this.onAdd,
    this.initialValue,
    this.validator,
    this.hintText,
    this.autofocus = false,
  });

  @override
  State<SearchableSelector<T>> createState() => _SearchableSelectorState<T>();
}

class _SearchableSelectorState<T> extends State<SearchableSelector<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue != null
          ? widget.itemLabelBuilder(widget.initialValue as T)
          : '',
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _openOverlay();
      } else {
        // Add a small delay to allow onTap to fire before closing the overlay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_focusNode.hasFocus) {
            _closeOverlay();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(SearchableSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      final newText = widget.initialValue != null
          ? widget.itemLabelBuilder(widget.initialValue as T)
          : '';
      if (_controller.text != newText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.text = newText;
          }
        });
      }
    }
    if (widget.items != oldWidget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _overlayEntry?.markNeedsBuild();
        }
      });
    }
  }

  @override
  void dispose() {
    _closeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openOverlay() {
    if (_isOpened) return;
    _overlayEntry = _createOverlayEntry();
    
    // Ensure we are not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isOpened) {
        Overlay.of(context).insert(_overlayEntry!);
        setState(() => _isOpened = true);
      }
    });
  }

  void _closeOverlay() {
    if (!_isOpened) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpened = false);
    } else {
      _isOpened = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        final filteredItems = widget.items.where((item) {
                          return widget
                              .itemLabelBuilder(item)
                              .toLowerCase()
                              .contains(value.text.toLowerCase());
                        }).toList();

                        if (filteredItems.isEmpty && value.text.isNotEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No matches found'),
                          );
                        }

                        final itemsToDisplay = value.text.isEmpty
                            ? widget.items
                            : filteredItems;

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: itemsToDisplay.length,
                          itemBuilder: (context, index) {
                            final item = itemsToDisplay[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                widget.itemLabelBuilder(item),
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () {
                                _controller.text = widget.itemLabelBuilder(
                                  item,
                                );
                                widget.onSelected(item);
                                _focusNode.unfocus();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    tileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    leading: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      widget.addLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      _closeOverlay();
                      _focusNode.unfocus();
                      widget.onAdd();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
        ),
        validator: widget.validator,
        onFieldSubmitted: (v) {
          // If there is an exact match, select it
          final match = widget.items
              .where(
                (item) =>
                    widget.itemLabelBuilder(item).toLowerCase() ==
                    v.toLowerCase(),
              )
              .firstOrNull;
          if (match != null) {
            widget.onSelected(match);
          }
        },
      ),
    );
  }
}
