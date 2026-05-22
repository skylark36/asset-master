import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';

class FeedbackView extends GetView<PortfolioController> {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TDTheme.of(context);

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
          'Share Feedback',
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
        child: Obx(() {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 700;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: isMobile ? 80 : 16,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (controller.feedbackSubmittedSuccess.value) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.successNormalColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  theme.radiusMap['default'] ?? 8,
                                ),
                                border: Border.all(
                                  color: theme.successNormalColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: theme.successNormalColor,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Feedback Received!',
                                    style: TextStyle(
                                      color: theme.textColorPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Thank you for helping us improve Asset Master. Your comments have been routed to our edge network.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.textColorSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: TDButton(
                                      onTap: () {
                                        controller
                                                .feedbackSubmittedSuccess
                                                .value =
                                            false;
                                        controller.feedbackText.value = '';
                                        controller.feedbackRating.value = 5;
                                        controller.feedbackCategory.value =
                                            'Feature Request';
                                      },
                                      size: TDButtonSize.medium,
                                      type: TDButtonType.outline,
                                      isBlock: true,
                                      text: 'Submit Another Feedback',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  color: theme.brandNormalColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SHARE YOUR THOUGHTS',
                                  style: TextStyle(
                                    color: theme.textColorPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Rate your experience:',
                              style: TextStyle(
                                color: theme.textColorSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TDRate(
                                value: controller.feedbackRating.value
                                    .toDouble(),
                                size: 32.0,
                                color: [
                                  const Color(0xFFFBBF24),
                                  theme.textColorPlaceholder,
                                ],
                                onChange: (val) {
                                  controller.feedbackRating.value = val.toInt();
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Select category:',
                              style: TextStyle(
                                color: theme.textColorSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  [
                                    'Feature Request',
                                    'Bug Report',
                                    'Usability',
                                    'Other',
                                  ].map((category) {
                                    final isSelected =
                                        controller.feedbackCategory.value ==
                                        category;
                                    return GestureDetector(
                                      onTap: () {
                                        controller.feedbackCategory.value =
                                            category;
                                      },
                                      child: TDTag(
                                        category,
                                        size: TDTagSize.medium,
                                        shape: TDTagShape.round,
                                        theme: isSelected
                                            ? TDTagTheme.primary
                                            : TDTagTheme.defaultTheme,
                                        isOutline: !isSelected,
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Your comments:',
                              style: TextStyle(
                                color: theme.textColorSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TDInput(
                              maxLines: 4,
                              type: TDInputType.longText,
                              hintText:
                                  'Tell us what you like or what we can improve...',
                              onChanged: (value) =>
                                  controller.feedbackText.value = value,
                              textStyle: TextStyle(
                                color: theme.textColorPrimary,
                                fontSize: 12,
                              ),
                              hintTextStyle: TextStyle(
                                color: theme.textColorPlaceholder,
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.transparent,
                              showBottomDivider: false,
                            ),
                            const SizedBox(height: 16),

                            Obx(() {
                              final isSubmitting =
                                  controller.isFeedbackSubmitting.value;
                              final hasText = controller.feedbackText.value
                                  .trim()
                                  .isNotEmpty;

                              return TDButton(
                                onTap: (hasText && !isSubmitting)
                                    ? () => controller.submitFeedback()
                                    : null,
                                size: TDButtonSize.medium,
                                type: TDButtonType.fill,
                                theme: TDButtonTheme.primary,
                                isBlock: true,
                                disabled: !hasText || isSubmitting,
                                text: 'Submit Feedback',
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                iconWidget: isSubmitting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
