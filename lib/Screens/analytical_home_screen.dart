import 'package:delivery/repository/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:delivery/widgets/custom_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticalHomeScreen extends ConsumerWidget {
  const AnalyticalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppSize.init(context);
    final asyncDashboard = ref.watch(analyticsControllerProvider);
    final asyncWeekly = ref.watch(weeklyPerformanceControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CustomAppBar(
            centerTitle: true,
            backgroundColor: AppColors.deliveryColor,
            title: 'Analytical Dashboard',
            subtitle: 'Overview of your logistics performance',
            titleFontSize: 20,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: asyncDashboard.when(
              data: (dashboard) {
                final data = dashboard.data;
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(analyticsControllerProvider.notifier)
                        .fetch();
                    await ref
                        .read(weeklyPerformanceControllerProvider.notifier)
                        .fetch();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSize.width * 0.05,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Summary Stats Section - Row 1
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                label: "COMPLETE",
                                value: data.completed.total.toString(),
                                icon: Icons.check_circle_outline_rounded,
                                color: Colors.green,
                                pickups: data.completed.pickups,
                                deliveries: data.completed.deliveries,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                label: "IN PROGRESS",
                                value: data.inProgress.total.toString(),
                                icon: Icons.pending_actions_rounded,
                                color: AppColors.deliveryColor,
                                pickups: data.inProgress.pickups,
                                deliveries: data.inProgress.deliveries,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Summary Stats Section - Row 2
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                label: "UPCOMING",
                                value: data.upcoming.total.toString(),
                                icon: Icons.calendar_today_rounded,
                                color: Colors.blue,
                                pickups: data.upcoming.pickups,
                                deliveries: data.upcoming.deliveries,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                label: "PENDING",
                                value: data.pending.total.toString(),
                                icon: Icons.hourglass_empty_rounded,
                                color: Colors.orange,
                                pickups: data.pending.pickups,
                                deliveries: data.pending.deliveries,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Pickup & Delivery Progress Section
                        // _buildSectionTitle("ACTIVE DISTRIBUTION"),
                        // const SizedBox(height: 16),
                        // Container(
                        //   padding: const EdgeInsets.all(24),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(32),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.black.withValues(alpha: 0.04),
                        //         blurRadius: 24,
                        //         offset: const Offset(0, 12),
                        //       ),
                        //     ],
                        //   ),
                        //   child: Column(
                        //     children: [
                        //       _buildTaskProgressRow(
                        //         title: "Pickups",
                        //         status: "${data.inProgress.pickups} Today",
                        //         progress: data.inProgress.total > 0
                        //             ? data.inProgress.pickups /
                        //                 data.inProgress.total
                        //             : 0.0,
                        //         icon: Icons.inventory_2_rounded,
                        //         color: Colors.orange,
                        //       ),
                        //       const SizedBox(height: 24),
                        //       _buildTaskProgressRow(
                        //         title: "Deliveries",
                        //         status:
                        //             "${data.inProgress.deliveries} Today",
                        //         progress: data.inProgress.total > 0
                        //             ? data.inProgress.deliveries /
                        //                 data.inProgress.total
                        //             : 0.0,
                        //         icon: Icons.local_shipping_rounded,
                        //         color: AppColors.deliveryColor,
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        // const SizedBox(height: 32),

                        // Weekly Analysis Section
                        _buildSectionTitle("LOGISTICS FLOW ARCHIVE"),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColors.divider.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildLegendItem("Pickups", Colors.orange),
                                  const SizedBox(width: 16),
                                  _buildLegendItem(
                                    "Deliveries",
                                    AppColors.deliveryColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 200,
                                child: Stack(
                                  children: [
                                    // Grid Lines
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        4,
                                        (_) => Divider(
                                          height: 0.5,
                                          color: AppColors.divider.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    asyncWeekly.when(
                                      data: (weekly) {
                                        double maxVal = 0;
                                        bool hasAnyActivity = false;
                                        for (var d in weekly.data) {
                                          if (d.pickups > 0 ||
                                              d.deliveries > 0) {
                                            hasAnyActivity = true;
                                          }
                                          if (d.pickups > maxVal) {
                                            maxVal = d.pickups.toDouble();
                                          }
                                          if (d.deliveries > maxVal) {
                                            maxVal = d.deliveries.toDouble();
                                          }
                                        }

                                        if (!hasAnyActivity) {
                                          return Center(
                                            child: Text(
                                              "Weekly archive is empty",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          );
                                        }

                                        if (maxVal == 0) maxVal = 1.0;

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children:
                                              weekly.data
                                                  .map(
                                                    (d) => _buildBar(
                                                      pickups: d.pickups,
                                                      deliveries: d.deliveries,
                                                      label: d.day,
                                                      maxCount: maxVal,
                                                    ),
                                                  )
                                                  .toList(),
                                        );
                                      },
                                      loading:
                                          () => const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.deliveryColor,
                                            ),
                                          ),
                                      error:
                                          (error, _) => Center(
                                            child: Text(
                                              "Analytics unavailable",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.withValues(
                                                  alpha: 0.6,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 50,
                        ), // Bottom padding for floating bottom bar
                      ],
                    ),
                  ),
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.deliveryColor,
                    ),
                  ),
              error:
                  (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load dashboard\n${error.toString()}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  ref
                                      .read(
                                        analyticsControllerProvider.notifier,
                                      )
                                      .fetch(),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskProgressRow({
    required String title,
    required String status,
    required double progress,
    required IconData icon,
    required Color color,
  }) {
    final percent = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$percent%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 8,
              width: AppSize.width * 0.8 * progress,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary.withValues(alpha: 0.6),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    int? pickups,
    int? deliveries,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient Mesh
          // Positioned(
          //   top: -20,
          //   right: -20,
          //   child: Container(
          //     width: 100,
          //     height: 100,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       gradient: RadialGradient(
          //         colors: [
          //           color.withValues(alpha: 0.15),
          //           color.withValues(alpha: 0.0),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
          // Watermark Icon
          // Positioned(
          //   bottom: -15,
          //   right: -15,
          //   child: Icon(
          //     icon,
          //     size: 100,
          //     color: color.withValues(alpha: 0.05),
          //   ),
          // ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (pickups != null || deliveries != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            if (pickups != null) ...[
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 15,
                                color: color.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pickups.toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                            ],
                            if (pickups != null && deliveries != null)
                              const SizedBox(width: 8),
                            if (deliveries != null) ...[
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 15,
                                color: AppColors.deliveryColor.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                deliveries.toString(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.deliveryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder(
                  tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutExpo,
                  builder:
                      (context, value, child) => Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _buildMiniStat removed as it's now integrated directly into summary card Row for better customization

  Widget _buildBar({
    required int pickups,
    required int deliveries,
    required String label,
    required double maxCount,
  }) {
    final pickupHeight = maxCount > 0 ? (160 * (pickups / maxCount)) : 0.0;
    final deliveryHeight = maxCount > 0 ? (160 * (deliveries / maxCount)) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pickup Bar
              _buildSingleBar(pickupHeight, Colors.orange),
              const SizedBox(width: 4),
              // Delivery Bar
              _buildSingleBar(deliveryHeight, AppColors.deliveryColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label.substring(0, 3).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBar(double height, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      width: 10,
      height: height.clamp(4, double.infinity),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
