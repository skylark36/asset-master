import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/portfolio_controller.dart';
import '../models/valuation.dart';
import '../theme/app_theme.dart';

class AddAssetDialog extends StatefulWidget {
  final HoldingValuation? editHolding;
  final String? prefilledSymbol;
  const AddAssetDialog({super.key, this.editHolding, this.prefilledSymbol});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _customBrokerController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final _controller = Get.find<PortfolioController>();
  bool _loading = false;
  String? _verifiedSymbol;

  late String _selectedBroker;
  late List<String> _brokers;

  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  Timer? _debounceTimer;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();

    _brokers = _controller.availableBrokers.where((b) => b != 'All').toList();
    if (!_brokers.contains('Other')) {
      _brokers.add('Other');
    }

    _selectedBroker = _brokers.firstWhere(
      (b) => b != 'Other',
      orElse: () => 'IBKR',
    );

    if (widget.editHolding != null) {
      final h = widget.editHolding!;
      _symbolController.text = h.symbol;
      _nameController.text = h.name;
      _quantityController.text = h.quantity.toStringAsFixed(2);
      _priceController.text = h.purchasePrice.toString();
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(h.purchaseDate);
      _verifiedSymbol = h.symbol.toUpperCase();

      final rawAsset = _controller.assets.firstWhereOrNull((a) => a.id == h.id);
      if (rawAsset != null) {
        _selectedBroker = rawAsset.broker;
        if (!_brokers.contains(_selectedBroker)) {
          if (_brokers.contains('Other')) {
            _brokers.insert(_brokers.indexOf('Other'), _selectedBroker);
          } else {
            _brokers.add(_selectedBroker);
          }
        }
      }
    } else {
      if (widget.prefilledSymbol != null) {
        final symbol = widget.prefilledSymbol!.toUpperCase();
        _symbolController.text = symbol;
        _verifiedSymbol = symbol;

        final valuation = _controller.valuation.value;
        if (valuation != null) {
          final existing = valuation.holdings.firstWhereOrNull(
            (h) => h.symbol.toUpperCase() == symbol,
          );
          if (existing != null) {
            _nameController.text = existing.name;
          }
        }

        _controller.apiClient.getLivePrice(symbol).then((price) {
          if (price != null && mounted) {
            _priceController.text = price.toStringAsFixed(2);
          }
        });
      } else {
        _symbolController.addListener(_onSymbolChanged);
      }
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    if (widget.editHolding == null && widget.prefilledSymbol == null) {
      _symbolController.removeListener(_onSymbolChanged);
    }
    _symbolController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _customBrokerController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSymbolChanged() {
    final query = _symbolController.text.trim();
    if (_verifiedSymbol != query.toUpperCase()) {
      setState(() {
        _verifiedSymbol = null;
        _nameController.clear();
      });
    }
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searching = false;
        });
        _updateOverlay();
      }
      return;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      _updateOverlay();

      final results = await _controller.apiClient.searchAssets(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
        _updateOverlay();
      }
    });
  }

  void _showOverlay() {
    _hideOverlay();

    final overlayState = Overlay.of(context);
    final theme = TDTheme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 382,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: theme.bgColorContainer,
                  border: Border.all(
                    color: theme.componentBorderColor,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _searching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.brandNormalColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: Text(
                              'No assets found matching query',
                              style: TextStyle(
                                color: theme.textColorSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final res = _searchResults[index];
                            final sym = res['symbol'] as String;
                            final name = res['name'] as String;
                            final type = res['type'] as String;
                            final exch = res['exchDisp'] as String;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  _hideOverlay();
                                  setState(() {
                                    _symbolController.text = sym;
                                    _nameController.text = name;
                                    _verifiedSymbol = sym.toUpperCase();
                                  });

                                  final price = await _controller.apiClient
                                      .getLivePrice(sym);
                                  if (price != null && mounted) {
                                    setState(() {
                                      _priceController.text = price
                                          .toStringAsFixed(2);
                                    });
                                  }
                                },
                                hoverColor: theme.brandNormalColor.withValues(
                                  alpha: 0.08,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  sym,
                                                  style: TextStyle(
                                                    color:
                                                        theme.textColorPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                TDTag(
                                                  type.toUpperCase(),
                                                  size: TDTagSize.small,
                                                  theme: TDTagTheme.primary,
                                                  shape: TDTagShape.square,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: theme.textColorSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        exch,
                                        style: TextStyle(
                                          color: theme.textColorPlaceholder,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else {
      final query = _symbolController.text.trim();
      if (query.isNotEmpty &&
          widget.editHolding == null &&
          widget.prefilledSymbol == null) {
        _showOverlay();
      }
    }
  }

  void _selectDate(BuildContext context) {
    final minDate = DateTime(
      DateTime.now().year - 5,
      DateTime.now().month,
      DateTime.now().day,
    );
    final now = DateTime.now();
    TDPicker.showDatePicker(
      context,
      title: 'Select Purchase Date',
      onConfirm: (selected) {
        if (mounted) {
          setState(() {
            _selectedDate = DateTime(
              selected['year'] ?? now.year,
              selected['month'] ?? now.month,
              selected['day'] ?? now.day,
            );
          });
        }
        Navigator.of(context).pop();
      },
      dateStart: [minDate.year, minDate.month, minDate.day],
      dateEnd: [now.year, now.month, now.day],
      initialDate: [_selectedDate.year, _selectedDate.month, _selectedDate.day],
    );
  }

  void _showBrokerPicker(BuildContext context) {
    final theme = TDTheme.of(context);
    Navigator.of(context).push(
      TDSlidePopupRoute(
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (ctx) {
          return TDPopupBottomDisplayPanel(
            title: 'Select Broker',
            closeClick: () => Navigator.maybePop(ctx),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _brokers
                    .map(
                      (b) => InkWell(
                        onTap: () {
                          Navigator.maybePop(ctx);
                          setState(() {
                            _selectedBroker = b;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.componentBorderColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                b,
                                style: TextStyle(
                                  color: _selectedBroker == b
                                      ? theme.brandNormalColor
                                      : theme.textColorPrimary,
                                  fontSize: 14,
                                  fontWeight: _selectedBroker == b
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_selectedBroker == b)
                                Icon(
                                  Icons.check,
                                  color: theme.brandNormalColor,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final theme = TDTheme.of(context);
    setState(() => _loading = true);

    final String finalBroker = _selectedBroker == 'Other'
        ? _customBrokerController.text.trim()
        : _selectedBroker;

    bool success;
    if (widget.editHolding != null) {
      success = await _controller.editAssetHolding(
        assetId: widget.editHolding!.id,
        symbol: _symbolController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        purchasePrice: double.parse(_priceController.text),
        purchaseDate: _selectedDate,
        broker: finalBroker,
      );
    } else {
      success = await _controller.addAssetHolding(
        symbol: _symbolController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        quantity: double.parse(_quantityController.text),
        purchasePrice: double.parse(_priceController.text),
        purchaseDate: _selectedDate,
        broker: finalBroker,
      );
    }

    if (mounted) setState(() => _loading = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.editHolding != null
            ? 'Purchase record updated.'
            : 'Asset holding added.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: theme.successNormalColor,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return GestureDetector(
      onTap: () {
        _hideOverlay();
        _updateOverlay();
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: theme.bgColorPage,
        appBar: AppBar(
          backgroundColor: theme.bgColorContainer,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.textColorPrimary,
              size: 16,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            widget.editHolding != null
                ? 'Edit Purchase Record'
                : 'Add Purchase Record',
            style: TextStyle(
              color: theme.textColorPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: theme.componentBorderColor, height: 1),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: isMobile ? 12 : 16,
              right: isMobile ? 12 : 16,
              top: 16,
              bottom: isMobile ? 80 : 16,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: FormField<String>(
                          validator: (val) {
                            final text = _symbolController.text;
                            if (text.trim().isEmpty) return 'Required';
                            if (_verifiedSymbol == null ||
                                text.trim().toUpperCase() != _verifiedSymbol) {
                              return 'Select from search';
                            }
                            return null;
                          },
                          builder: (state) => TDInput(
                            controller: _symbolController,
                            textStyle: TextStyle(
                              color: theme.textColorPrimary,
                              fontSize: 13,
                            ),
                            hintTextStyle: TextStyle(
                              color: theme.textColorPlaceholder,
                              fontSize: 13,
                            ),
                            readOnly:
                                widget.editHolding != null ||
                                widget.prefilledSymbol != null,
                            hintText: 'e.g. AAPL',
                            leftLabel: 'Symbol',
                            backgroundColor: Colors.transparent,
                            showBottomDivider: true,
                            additionInfo: state.hasError
                                ? state.errorText!
                                : '',
                            additionInfoColor: theme.errorNormalColor,
                            onChanged: (val) {
                              state.didChange(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      FormField<String>(
                        validator: (val) {
                          final text = _nameController.text;
                          return text.trim().isEmpty ? 'Required' : null;
                        },
                        builder: (state) => TDInput(
                          controller: _nameController,
                          textStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                          ),
                          hintTextStyle: TextStyle(
                            color: theme.textColorPlaceholder,
                            fontSize: 13,
                          ),
                          readOnly: true,
                          hintText: widget.editHolding != null
                              ? ''
                              : 'Select from search',
                          leftLabel: 'Name',
                          backgroundColor: Colors.transparent,
                          showBottomDivider: true,
                          additionInfo: state.hasError ? state.errorText! : '',
                          additionInfoColor: theme.errorNormalColor,
                          onChanged: (val) {
                            state.didChange(val);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      FormField<String>(
                        validator: (val) {
                          final text = _quantityController.text;
                          if (text.trim().isEmpty) return 'Required';
                          if (double.tryParse(text) == null)
                            return 'Invalid qty';
                          if (double.parse(text) <= 0) return 'Must be > 0';
                          return null;
                        },
                        builder: (state) => TDInput(
                          controller: _quantityController,
                          textStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                          ),
                          hintTextStyle: TextStyle(
                            color: theme.textColorPlaceholder,
                            fontSize: 13,
                          ),
                          inputType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hintText: 'e.g. 10.5',
                          leftLabel: 'Qty',
                          backgroundColor: Colors.transparent,
                          showBottomDivider: true,
                          additionInfo: state.hasError ? state.errorText! : '',
                          additionInfoColor: theme.errorNormalColor,
                          onChanged: (val) {
                            state.didChange(val);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      FormField<String>(
                        validator: (val) {
                          final text = _priceController.text;
                          if (text.trim().isEmpty) return 'Required';
                          if (double.tryParse(text) == null)
                            return 'Invalid price';
                          if (double.parse(text) < 0) return 'Must be >= 0';
                          return null;
                        },
                        builder: (state) => TDInput(
                          controller: _priceController,
                          textStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                          ),
                          hintTextStyle: TextStyle(
                            color: theme.textColorPlaceholder,
                            fontSize: 13,
                          ),
                          inputType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hintText: 'e.g. 175.20',
                          leftLabel:
                              'Price (${AppTheme.getCurrencySymbol(_controller.selectedPortfolio.value?.currency ?? 'USD')})',
                          backgroundColor: Colors.transparent,
                          showBottomDivider: true,
                          additionInfo: state.hasError ? state.errorText! : '',
                          additionInfoColor: theme.errorNormalColor,
                          onChanged: (val) {
                            state.didChange(val);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      TDCell(
                        title: 'Purchase Date',
                        note: DateFormat('yyyy-MM-dd').format(_selectedDate),
                        arrow: false,
                        showBottomBorder: true,
                        onClick: (_) => _selectDate(context),
                        style: TDCellStyle(
                          backgroundColor: Colors.transparent,
                          titleStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                          ),
                          noteStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          borderedColor: theme.componentBorderColor,
                        ),
                        rightIconWidget: Icon(
                          Icons.calendar_today,
                          color: theme.brandNormalColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 10),

                      TDCell(
                        title: 'Broker / Custodian',
                        note: _selectedBroker,
                        arrow: false,
                        showBottomBorder: true,
                        onClick: (_) => _showBrokerPicker(context),
                        style: TDCellStyle(
                          backgroundColor: Colors.transparent,
                          titleStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                          ),
                          noteStyle: TextStyle(
                            color: theme.textColorPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 16,
                          ),
                          borderedColor: theme.componentBorderColor,
                        ),
                        rightIconWidget: Icon(
                          Icons.arrow_drop_down,
                          color: theme.textColorSecondary,
                          size: 22,
                        ),
                      ),
                      if (_selectedBroker == 'Other') ...[
                        const SizedBox(height: 10),
                        FormField<String>(
                          validator: (val) {
                            final text = _customBrokerController.text;
                            if (text.trim().isEmpty) return 'Required';
                            return null;
                          },
                          builder: (state) => TDInput(
                            controller: _customBrokerController,
                            textStyle: TextStyle(
                              color: theme.textColorPrimary,
                              fontSize: 13,
                            ),
                            hintTextStyle: TextStyle(
                              color: theme.textColorPlaceholder,
                              fontSize: 13,
                            ),
                            hintText: 'e.g. Coinbase',
                            leftLabel: 'Broker Name',
                            backgroundColor: Colors.transparent,
                            showBottomDivider: true,
                            additionInfo: state.hasError
                                ? state.errorText!
                                : '',
                            additionInfoColor: theme.errorNormalColor,
                            onChanged: (val) {
                              state.didChange(val);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      TDButton(
                        onTap: _loading ? null : _submit,
                        size: TDButtonSize.large,
                        type: TDButtonType.fill,
                        theme: TDButtonTheme.primary,
                        text: widget.editHolding != null ? 'Save' : 'Add',
                        isBlock: true,
                        iconWidget: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
