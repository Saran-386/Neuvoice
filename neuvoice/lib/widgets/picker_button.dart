import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class PickerButton extends StatelessWidget {
  final String title;
  final String? selectedValue;
  final List<String> options;
  final Function(String) onChanged;
  final IconData? icon;
  final String? subtitle;

  const PickerButton({
    super.key,
    required this.title,
    required this.options,
    required this.onChanged,
    this.selectedValue,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: icon != null
            ? Icon(icon, size: ResponsiveUtils.isPhone(context) ? 20 : 24)
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, base: 16),
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 12),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              )
            : Text(
                selectedValue ?? 'Select option',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 14),
                ),
                overflow: TextOverflow.ellipsis,
              ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showPicker(context),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(ResponsiveUtils.getPadding(context)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, base: 18),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 16),

              // Options - Fixed with Expanded
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  shrinkWrap: false, // Changed to false for better performance
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selectedValue;

                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getFontSize(context, base: 16),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
