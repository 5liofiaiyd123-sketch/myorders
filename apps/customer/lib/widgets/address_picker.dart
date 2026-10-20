import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// The address the customer typed or picked, plus an optional map pin.
class AddressSelection extends ChangeNotifier {
  String details = '';
  LatLng? point;

  void set(String details, LatLng? point) {
    this.details = details;
    this.point = point;
    notifyListeners();
  }
}

/// Saved addresses, a free-text field and a map to drop a pin.
class AddressPicker extends StatefulWidget {
  final AddressSelection selection;
  final String? label;
  final bool showSaved;
  const AddressPicker({super.key, required this.selection, this.label, this.showSaved = true});

  @override
  State<AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  late final _text = TextEditingController(text: widget.selection.details);
  List<Address> _saved = [];
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSaved) _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await context.read<MyOrdersRepository>().addresses();
      if (!mounted) return;
      setState(() => _saved = saved);
      if (widget.selection.details.isEmpty && saved.isNotEmpty) _pick(saved.first);
    } catch (_) {
      // Not signed in yet.
    }
  }

  void _pick(Address a) {
    _text.text = a.details;
    widget.selection.set(a.details, a.lat == null ? null : LatLng(a.lat!, a.lng!));
    setState(() {});
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final here = await currentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (here == null) {
      showError(context, context.t('useMyLocation'));
      return;
    }
    widget.selection.set(_text.text, here);
    setState(() {});
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.selection.point;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_saved.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final a in _saved)
                  ChoiceChip(
                    label: Text(a.label.isEmpty ? a.details : a.label),
                    selected: a.details == widget.selection.details,
                    onSelected: (_) => _pick(a),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _text,
          onChanged: (v) => widget.selection.set(v, widget.selection.point),
          decoration: InputDecoration(
            labelText: widget.label ?? context.t('deliverTo'),
            hintText: context.t('addressHint'),
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: DahabMap(
            key: ValueKey(point),
            center: point,
            zoom: 14,
            pins: [if (point != null) MapPin(point, Icons.home_rounded, customerPinColor)],
            onTap: (p) {
              widget.selection.set(_text.text, p);
              setState(() {});
            },
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _locating ? null : _useMyLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(point == null ? context.t('useMyLocation') : context.t('locationSet')),
          ),
        ),
      ],
    );
  }
}
