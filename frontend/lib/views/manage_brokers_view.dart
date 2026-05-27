import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';

class ManageBrokersView extends StatefulWidget {
  const ManageBrokersView({super.key});

  @override
  State<ManageBrokersView> createState() => _ManageBrokersViewState();
}

class _ManageBrokersViewState extends State<ManageBrokersView> {
  final _controller = Get.find<PortfolioController>();
  final _newBrokerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _brokerError = '';

  @override
  void dispose() {
    _newBrokerController.dispose();
    super.dispose();
  }

  void _addBroker() {
    setState(() {
      _brokerError = '';
    });

    final name = _newBrokerController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _brokerError = 'Please enter a broker name';
      });
      return;
    }
    final isPreset = PortfolioController.presetBrokers.any(
      (b) => b.toLowerCase() == name.toLowerCase(),
    );
    if (isPreset) {
      setState(() {
        _brokerError = 'This is already a preset broker';
      });
      return;
    }
    final isCustom = _controller.customBrokers.any(
      (b) => b.toLowerCase() == name.toLowerCase(),
    );
    if (isCustom) {
      setState(() {
        _brokerError = 'This broker has already been added';
      });
      return;
    }

    _controller.addCustomBroker(name);
    _newBrokerController.clear();

    final theme = TDTheme.of(context);
    Get.snackbar(
      'Success',
      'Broker "$name" added successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: theme.successNormalColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }

  void _deleteBroker(String name) {
    final theme = TDTheme.of(context);
    Get.defaultDialog(
      title: 'Delete Broker',
      middleText:
          'Are you sure you want to delete the custom broker "$name"? Any assets assigned to this broker will remain unaffected but the broker will be removed from your management list.',
      backgroundColor: theme.bgColorContainer,
      titleStyle: TextStyle(
        color: theme.textColorPrimary,
        fontWeight: FontWeight.bold,
      ),
      middleTextStyle: TextStyle(color: theme.textColorSecondary),
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: theme.errorNormalColor,
      onConfirm: () {
        Get.back();
        _controller.removeCustomBroker(name);
        Get.snackbar(
          'Removed',
          'Broker "$name" removed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: theme.warningNormalColor,
          colorText: Colors.white,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
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
          'Manage Brokers',
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
      body: SingleChildScrollView(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preset/System default brokers section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.bgColorContainer,
                    borderRadius: BorderRadius.circular(
                      theme.radiusMap['medium'] ?? 8,
                    ),
                    border: Border.all(
                      color: theme.componentBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            color: theme.brandNormalColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PRESET BROKERS',
                            style: TextStyle(
                              color: theme.textColorPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'These standard brokers are built into the platform and are always available for assignation:',
                        style: TextStyle(
                          color: theme.textColorSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: PortfolioController.presetBrokers.length,
                        separatorBuilder: (context, index) => Divider(
                          color: theme.componentBorderColor,
                          height: 8,
                        ),
                        itemBuilder: (context, index) {
                          final broker =
                              PortfolioController.presetBrokers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  broker,
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.bgColorSecondaryContainer,
                                    borderRadius: BorderRadius.circular(
                                      theme.radiusMap['small'] ?? 4,
                                    ),
                                    border: Border.all(
                                      color: theme.componentBorderColor,
                                    ),
                                  ),
                                  child: Text(
                                    'Preset',
                                    style: TextStyle(
                                      color: theme.textColorSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Custom brokers management section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.bgColorContainer,
                    borderRadius: BorderRadius.circular(
                      theme.radiusMap['medium'] ?? 8,
                    ),
                    border: Border.all(
                      color: theme.componentBorderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            color: theme.brandNormalColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CUSTOM BROKERS',
                            style: TextStyle(
                              color: theme.textColorPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        final list = _controller.customBrokers;
                        if (list.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No custom brokers added yet.',
                                style: TextStyle(
                                  color: theme.textColorSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => Divider(
                            color: theme.componentBorderColor,
                            height: 8,
                          ),
                          itemBuilder: (context, index) {
                            final broker = list[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    broker,
                                    style: TextStyle(
                                      color: theme.textColorPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.errorNormalColor,
                                      size: 16,
                                    ),
                                    onPressed: () => _deleteBroker(broker),
                                    tooltip: 'Delete custom broker',
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                      Divider(color: theme.componentBorderColor, height: 20),

                      // Form to add custom broker
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TDInput(
                              controller: _newBrokerController,
                              leftIcon: Icon(
                                Icons.add_business_outlined,
                                color: theme.textColorSecondary,
                                size: 16,
                              ),
                              hintText: 'e.g. TD Ameritrade, Webull',
                              textStyle: TextStyle(
                                color: theme.textColorPrimary,
                                fontSize: 12,
                              ),
                              hintTextStyle: TextStyle(
                                color: theme.textColorPlaceholder,
                                fontSize: 12,
                              ),
                              additionInfo: _brokerError,
                              additionInfoColor: theme.errorNormalColor,
                              showBottomDivider: true,
                              backgroundColor: Colors.transparent,
                              onSubmitted: (_) => _addBroker(),
                            ),
                            const SizedBox(height: 12),
                            TDButton(
                              onTap: _addBroker,
                              size: TDButtonSize.medium,
                              type: TDButtonType.fill,
                              theme: TDButtonTheme.primary,
                              isBlock: true,
                              icon: Icons.add,
                              text: 'Add Broker',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
