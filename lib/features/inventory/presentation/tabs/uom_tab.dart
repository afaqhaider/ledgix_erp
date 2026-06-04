import 'package:flutter/material.dart';
import 'package:ledgixerp/core/auth/app_user.dart';
import 'package:ledgixerp/core/widgets/side_panel.dart';
import '../../models/inventory_models.dart';
import '../../services/inventory_service.dart';
import '../widgets/uom_pane.dart';
import '../widgets/uom_conversion_pane.dart';

class UomTab extends StatelessWidget {
  final AppUser user;
  const UomTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('UOMs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => SidePanel.show(context: context, title: 'Add UOM', child: UomPane(user: user)), icon: const Icon(Icons.add, size: 18)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<UomModel>>(
                  stream: inventoryService.getUoms(user.companyId!),
                  builder: (context, snapshot) {
                    final uoms = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: uoms.length,
                      itemBuilder: (context, index) {
                        final uom = uoms[index];
                        return ListTile(
                          dense: true,
                          title: Text(uom.uomName, style: const TextStyle(fontSize: 12)),
                          subtitle: Text(uom.uomCode, style: const TextStyle(fontSize: 10)),
                          onTap: () => SidePanel.show(context: context, title: 'Edit UOM', child: UomPane(user: user, uom: uom)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Conversions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: () => SidePanel.show(context: context, title: 'Add Conversion', child: UomConversionPane(user: user)), icon: const Icon(Icons.add, size: 18)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<UomConversionModel>>(
                  stream: inventoryService.getUomConversions(user.companyId!),
                  builder: (context, snapshot) {
                    final convs = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: convs.length,
                      itemBuilder: (context, index) {
                        final conv = convs[index];
                        return ListTile(
                          dense: true,
                          title: Text('1 ${conv.fromUomId} = ${conv.conversionFactor} ${conv.toUomId}', style: const TextStyle(fontSize: 12)),
                          subtitle: Text(conv.itemId != null ? 'Item Specific' : 'Global', style: const TextStyle(fontSize: 10)),
                          onTap: () => SidePanel.show(context: context, title: 'Edit Conversion', child: UomConversionPane(user: user, conversion: conv)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
