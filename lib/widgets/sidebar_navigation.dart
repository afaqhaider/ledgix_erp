import 'package:flutter/material.dart';
import 'package:ledgixerp/config/app_modules.dart';
import 'package:ledgixerp/core/auth/user_role.dart';
import 'package:ledgixerp/core/theme/app_colors.dart';
import 'package:ledgixerp/core/theme/theme_controller.dart';
import 'package:ledgixerp/features/auth/services/auth_service.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';
import 'package:ledgixerp/features/company/models/company_model.dart';
import 'package:ledgixerp/widgets/app_logo_image.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarNavigation extends StatefulWidget {
  final UserRole role;
  final AppModuleId selectedModuleId;
  final ValueChanged<AppModule> onModuleSelected;
  final String? companyId;

  const SidebarNavigation({
    super.key,
    required this.role,
    required this.selectedModuleId,
    required this.onModuleSelected,
    this.companyId,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  String? _expandedSection;
  final Set<AppModuleId> _expandedModules = {};
  final _companyService = CompanyService();
  Stream<CompanyModel?>? _companyStream;
  String? _lastCompanyId;

  @override
  void initState() {
    super.initState();
    _updateCompanyStream();
  }

  @override
  void didUpdateWidget(SidebarNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _updateCompanyStream();
    }
  }

  void _updateCompanyStream() {
    if (widget.companyId != null && widget.companyId != _lastCompanyId) {
      _lastCompanyId = widget.companyId;
      _companyStream = _companyService.getCompany(widget.companyId!);
    } else if (widget.companyId == null) {
      _lastCompanyId = null;
      _companyStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use theme's surface color (which we mapped to darkSidebar in darkTheme)
    final sidebarColor = theme.colorScheme.surfaceContainer;
    final activeColor = theme.colorScheme.primary;

    const double width = 204;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: AppModules.sections.map((section) {
                final visibleModules = section.modules
                    .where(
                      (module) => widget.role.hasPermission(module.permission),
                    )
                    .toList();

                if (visibleModules.isEmpty) return const SizedBox.shrink();

                final bool isSectionExpanded =
                    _expandedSection == section.header;

                if (!section.isCollapsible) {
                  return Column(
                    children: visibleModules.map((module) {
                      return _SidebarTile(
                        module: module,
                        isSelected: widget.selectedModuleId == module.id,
                        activeColor: activeColor,
                        onTap: () => widget.onModuleSelected(module),
                      );
                    }).toList(),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SidebarHeaderTile(
                      title: section.header,
                      icon: section.icon,
                      isSectionExpanded: isSectionExpanded,
                      onTap: () {
                        setState(() {
                          _expandedSection = isSectionExpanded
                              ? null
                              : section.header;
                        });
                      },
                    ),
                    if (isSectionExpanded)
                      ...visibleModules.expand((module) {
                        final List<Widget> subWidgets = [];
                        final visibleSubModules = module.subModules
                            .where(
                              (sub) =>
                                  widget.role.hasPermission(sub.permission),
                            )
                            .toList();
                        final hasSubModules = visibleSubModules.isNotEmpty;
                        final isModuleExpanded = _expandedModules.contains(
                          module.id,
                        );

                        subWidgets.add(
                          _SidebarTile(
                            module: module,
                            isSelected:
                                widget.selectedModuleId == module.id ||
                                visibleSubModules.any(
                                  (sub) => widget.selectedModuleId == sub.id,
                                ),
                            activeColor: activeColor,
                            onTap: () {
                              if (hasSubModules) {
                                setState(() {
                                  if (isModuleExpanded) {
                                    _expandedModules.remove(module.id);
                                  } else {
                                    _expandedModules.add(module.id);
                                  }
                                });
                                return;
                              }
                              widget.onModuleSelected(module);
                            },
                            isIndent: true,
                            hasSubItems: hasSubModules,
                            isExpanded: isModuleExpanded,
                          ),
                        );

                        if (hasSubModules && isModuleExpanded) {
                          subWidgets.addAll(
                            visibleSubModules.map(
                              (sub) => _SidebarTile(
                                module: sub,
                                isSelected: widget.selectedModuleId == sub.id,
                                activeColor: activeColor,
                                onTap: () => widget.onModuleSelected(sub),
                                isSubItem: true,
                              ),
                            ),
                          );
                        }
                        return subWidgets;
                      }),
                  ],
                );
              }).toList(),
            ),
          ),
          Divider(
            color: isDark ? Colors.white10 : AppColors.lightBorder,
            height: 1,
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: StreamBuilder<CompanyModel?>(
        stream: _companyStream,
        builder: (context, snapshot) {
          final company = snapshot.data;
          final name =
              company?.tradeName ??
              company?.companyLegalName ??
              "LedGix ERP";
          final logoUrl = company?.companyLogoUrl;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CompanyLogoImage(
                logoUrl: logoUrl,
                width: 96,
                height: 96,
                borderRadius: 12,
              ),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return _buildBottomAction(
                isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                isDark ? 'Theme: Dark' : 'Theme: Light',
                ThemeController.toggle,
              );
            },
          ),
          _buildBottomAction(Icons.logout_rounded, 'Logout', () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await AuthService().signOut();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      leading: Icon(icon, color: color, size: 18),
      title: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _SidebarHeaderTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSectionExpanded;
  final VoidCallback onTap;

  const _SidebarHeaderTile({
    required this.title,
    required this.icon,
    required this.isSectionExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idleColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final activeTextColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSectionExpanded ? activeTextColor : idleColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: isSectionExpanded ? activeTextColor : idleColor,
                  fontSize: 12,
                  fontWeight: isSectionExpanded
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              isSectionExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: idleColor.withValues(alpha: 0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final AppModule module;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  final bool isSubItem;
  final bool isIndent;
  final bool hasSubItems;
  final bool isExpanded;

  const _SidebarTile({
    required this.module,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    this.isSubItem = false,
    this.isIndent = false,
    this.hasSubItems = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idleColor = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final activeTextColor = theme.colorScheme.onSurface;
    final activeBackground = activeColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.15 : 0.12,
    );

    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 24 : (isIndent ? 12 : 0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (!isSubItem) ...[
                Icon(
                  module.icon,
                  color: isSelected ? activeTextColor : idleColor,
                  size: 16,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  module.label,
                  style: GoogleFonts.inter(
                    color: isSelected ? activeTextColor : idleColor,
                    fontSize: isSubItem ? 11.5 : 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 2,
                  height: 14,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                )
              else if (hasSubItems)
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 14,
                  color: idleColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
