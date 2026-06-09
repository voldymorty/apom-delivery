// import 'package:delivery/repository/analytics_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:delivery/global/colortheme.dart';
// import 'package:delivery/widgets/custom_app_bar.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class AnalyticalHomeScreen extends ConsumerWidget {
//   const AnalyticalHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     AppSize.init(context);
//     final asyncDashboard = ref.watch(analyticsControllerProvider);
//     final asyncWeekly = ref.watch(weeklyPerformanceControllerProvider);

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Column(
//         children: [
//           CustomAppBar(
//             centerTitle: true,
//             backgroundColor: AppColors.deliveryColor,
//             title: 'Analytical Dashboard',
//             subtitle: 'Overview of your logistics performance',
//             titleFontSize: 20,
//           ),
//           const SizedBox(height: 30),
//           Expanded(
//             child: asyncDashboard.when(
//               data: (dashboard) {
//                 final data = dashboard.data;
//                 return RefreshIndicator(
//                   onRefresh: () async {
//                     await ref
//                         .read(analyticsControllerProvider.notifier)
//                         .fetch();
//                     await ref
//                         .read(weeklyPerformanceControllerProvider.notifier)
//                         .fetch();
//                   },
//                   child: SingleChildScrollView(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: EdgeInsets.symmetric(
//                       horizontal: AppSize.width * 0.05,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 10),

//                         // Summary Stats Section - Row 1
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildSummaryCard(
//                                 label: "COMPLETE",
//                                 value: data.completed.total.toString(),
//                                 icon: Icons.check_circle_outline_rounded,
//                                 color: Colors.green,
//                                 pickups: data.completed.pickups,
//                                 deliveries: data.completed.deliveries,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _buildSummaryCard(
//                                 label: "IN PROGRESS",
//                                 value: data.inProgress.total.toString(),
//                                 icon: Icons.pending_actions_rounded,
//                                 color: AppColors.deliveryColor,
//                                 pickups: data.inProgress.pickups,
//                                 deliveries: data.inProgress.deliveries,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         // Summary Stats Section - Row 2
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildSummaryCard(
//                                 label: "UPCOMING",
//                                 value: data.upcoming.total.toString(),
//                                 icon: Icons.calendar_today_rounded,
//                                 color: Colors.blue,
//                                 pickups: data.upcoming.pickups,
//                                 deliveries: data.upcoming.deliveries,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: _buildSummaryCard(
//                                 label: "PENDING",
//                                 value: data.pending.total.toString(),
//                                 icon: Icons.hourglass_empty_rounded,
//                                 color: Colors.orange,
//                                 pickups: data.pending.pickups,
//                                 deliveries: data.pending.deliveries,
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 32),

//                         // Weekly Analysis Section
//                         _buildSectionTitle("LOGISTICS FLOW ARCHIVE"),
//                         const SizedBox(height: 16),
//                         Container(
//                           padding: const EdgeInsets.all(24),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(32),
//                             border: Border.all(
//                               color: AppColors.divider.withValues(alpha: 0.5),
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withValues(alpha: 0.02),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   _buildLegendItem("Pickups", Colors.orange),
//                                   const SizedBox(width: 16),
//                                   _buildLegendItem(
//                                     "Deliveries",
//                                     AppColors.deliveryColor,
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 32),
//                               SizedBox(
//                                 height: 200,
//                                 child: Stack(
//                                   children: [
//                                     // Grid Lines
//                                     Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: List.generate(
//                                         4,
//                                         (_) => Divider(
//                                           height: 0.5,
//                                           color: AppColors.divider.withValues(
//                                             alpha: 0.5,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     asyncWeekly.when(
//                                       data: (weekly) {
//                                         double maxVal = 0;
//                                         bool hasAnyActivity = false;
//                                         for (var d in weekly.data) {
//                                           if (d.pickups > 0 ||
//                                               d.deliveries > 0) {
//                                             hasAnyActivity = true;
//                                           }
//                                           if (d.pickups > maxVal) {
//                                             maxVal = d.pickups.toDouble();
//                                           }
//                                           if (d.deliveries > maxVal) {
//                                             maxVal = d.deliveries.toDouble();
//                                           }
//                                         }

//                                         if (!hasAnyActivity) {
//                                           return Center(
//                                             child: Text(
//                                               "Weekly archive is empty",
//                                               style: TextStyle(
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.w600,
//                                                 color: AppColors.textSecondary
//                                                     .withValues(alpha: 0.4),
//                                               ),
//                                             ),
//                                           );
//                                         }

//                                         if (maxVal == 0) maxVal = 1.0;

//                                         return Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.spaceBetween,
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.end,
//                                           children:
//                                               weekly.data
//                                                   .map(
//                                                     (d) => _buildBar(
//                                                       pickups: d.pickups,
//                                                       deliveries: d.deliveries,
//                                                       label: d.day,
//                                                       maxCount: maxVal,
//                                                     ),
//                                                   )
//                                                   .toList(),
//                                         );
//                                       },
//                                       loading:
//                                           () => const Center(
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: AppColors.deliveryColor,
//                                             ),
//                                           ),
//                                       error:
//                                           (error, _) => Center(
//                                             child: Text(
//                                               "Analytics unavailable",
//                                               style: TextStyle(
//                                                 fontSize: 12,
//                                                 color: Colors.red.withValues(
//                                                   alpha: 0.6,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(
//                           height: 50,
//                         ), // Bottom padding for floating bottom bar
//                       ],
//                     ),
//                   ),
//                 );
//               },
//               loading:
//                   () => const Center(
//                     child: CircularProgressIndicator(
//                       color: AppColors.deliveryColor,
//                     ),
//                   ),
//               error:
//                   (error, _) => Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           size: 48,
//                           color: Colors.red,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           "Failed to load dashboard\n${error.toString()}",
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton(
//                           onPressed:
//                               () =>
//                                   ref
//                                       .read(
//                                         analyticsControllerProvider.notifier,
//                                       )
//                                       .fetch(),
//                           child: const Text("Retry"),
//                         ),
//                       ],
//                     ),
//                   ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTaskProgressRow({
//     required String title,
//     required String status,
//     required double progress,
//     required IconData icon,
//     required Color color,
//   }) {
//     final percent = (progress * 100).round();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: color.withValues(alpha: 0.08),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Icon(icon, color: color, size: 20),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w900,
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     status,
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textSecondary.withValues(alpha: 0.5),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   "$percent%",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w900,
//                     color: color,
//                   ),
//                 ),
//                 Container(
//                   width: 4,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Stack(
//           children: [
//             Container(
//               height: 8,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: color.withValues(alpha: 0.08),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 800),
//               curve: Curves.easeOutCubic,
//               height: 8,
//               width: AppSize.width * 0.8 * progress,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [color, color.withValues(alpha: 0.7)],
//                 ),
//                 borderRadius: BorderRadius.circular(4),
//                 boxShadow: [
//                   BoxShadow(
//                     color: color.withValues(alpha: 0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildLegendItem(String label, Color color) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 8,
//           height: 8,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w800,
//             color: AppColors.textSecondary.withValues(alpha: 0.6),
//             letterSpacing: 0.5,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w800,
//         color: AppColors.textSecondary.withValues(alpha: 0.6),
//         letterSpacing: 1.2,
//       ),
//     );
//   }

//   Widget _buildSummaryCard({
//     required String label,
//     required String value,
//     required IconData icon,
//     required Color color,
//     int? pickups,
//     int? deliveries,
//   }) {
//     return Container(
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(32),
//         boxShadow: [
//           BoxShadow(
//             color: color.withValues(alpha: 0.12),
//             blurRadius: 30,
//             offset: const Offset(0, 15),
//           ),
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           // Background Gradient Mesh
//           // Positioned(
//           //   top: -20,
//           //   right: -20,
//           //   child: Container(
//           //     width: 100,
//           //     height: 100,
//           //     decoration: BoxDecoration(
//           //       shape: BoxShape.circle,
//           //       gradient: RadialGradient(
//           //         colors: [
//           //           color.withValues(alpha: 0.15),
//           //           color.withValues(alpha: 0.0),
//           //         ],
//           //       ),
//           //     ),
//           //   ),
//           // ),
//           // Watermark Icon
//           // Positioned(
//           //   bottom: -15,
//           //   right: -15,
//           //   child: Icon(
//           //     icon,
//           //     size: 100,
//           //     color: color.withValues(alpha: 0.05),
//           //   ),
//           // ),
//           // Content
//           Padding(
//             padding: const EdgeInsets.all(22),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: color.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       child: Icon(icon, color: color, size: 20),
//                     ),
//                     if (pickups != null || deliveries != null)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: color.withValues(alpha: 0.06),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Row(
//                           children: [
//                             if (pickups != null) ...[
//                               Icon(
//                                 Icons.inventory_2_rounded,
//                                 size: 15,
//                                 color: color.withValues(alpha: 0.8),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 pickups.toString(),
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w900,
//                                   color: color,
//                                 ),
//                               ),
//                             ],
//                             if (pickups != null && deliveries != null)
//                               const SizedBox(width: 8),
//                             if (deliveries != null) ...[
//                               Icon(
//                                 Icons.local_shipping_rounded,
//                                 size: 15,
//                                 color: AppColors.deliveryColor.withValues(
//                                   alpha: 0.8,
//                                 ),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 deliveries.toString(),
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w900,
//                                   color: AppColors.deliveryColor,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 TweenAnimationBuilder(
//                   tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
//                   duration: const Duration(milliseconds: 1800),
//                   curve: Curves.easeOutExpo,
//                   builder:
//                       (context, value, child) => Text(
//                         value.toString(),
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.w900,
//                           color: AppColors.textPrimary,
//                           height: 1,
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.textSecondary.withValues(alpha: 0.6),
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // _buildMiniStat removed as it's now integrated directly into summary card Row for better customization

//   Widget _buildBar({
//     required int pickups,
//     required int deliveries,
//     required String label,
//     required double maxCount,
//   }) {
//     final pickupHeight = maxCount > 0 ? (160 * (pickups / maxCount)) : 0.0;
//     final deliveryHeight = maxCount > 0 ? (160 * (deliveries / maxCount)) : 0.0;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Pickup Bar
//               _buildSingleBar(pickupHeight, Colors.orange),
//               const SizedBox(width: 4),
//               // Delivery Bar
//               _buildSingleBar(deliveryHeight, AppColors.deliveryColor),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             label.substring(0, 3).toUpperCase(),
//             style: TextStyle(
//               fontSize: 9,
//               fontWeight: FontWeight.w900,
//               color: AppColors.textSecondary.withValues(alpha: 0.5),
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSingleBar(double height, Color color) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 1000),
//       curve: Curves.elasticOut,
//       width: 10,
//       height: height.clamp(4, double.infinity),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [color, color.withValues(alpha: 0.6)],
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
//         boxShadow: [
//           BoxShadow(
//             color: color.withValues(alpha: 0.2),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:delivery/repository/analytics_repository.dart';
import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class AnalyticalHomeScreen extends ConsumerStatefulWidget {
  const AnalyticalHomeScreen({super.key});

  @override
  ConsumerState<AnalyticalHomeScreen> createState() =>
      _AnalyticalHomeScreenState();
}

class _AnalyticalHomeScreenState extends ConsumerState<AnalyticalHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final asyncDashboard = ref.watch(analyticsControllerProvider);
    final asyncWeekly = ref.watch(weeklyPerformanceControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F8),
      body: Column(
        children: [
          _Header(entryController: _entryController),
          Expanded(
            child: asyncDashboard.when(
              data: (dashboard) {
                final data = dashboard.data;
                final grandTotal = data.completed.total +
                    data.inProgress.total +
                    data.upcoming.total +
                    data.pending.total;

                return RefreshIndicator(
                  color: AppColors.deliveryColor,
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
                        const SizedBox(height: 24),
                        _buildSectionLabel("Overview"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: "Complete",
                                value: data.completed.total,
                                icon: Icons.check_circle_rounded,
                                accentColor: const Color(0xFF22C55E),
                                pickups: data.completed.pickups,
                                deliveries: data.completed.deliveries,
                                grandTotal: grandTotal,
                                animController: _entryController,
                                delay: 0.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: "In Progress",
                                value: data.inProgress.total,
                                icon: Icons.pending_rounded,
                                accentColor: AppColors.deliveryColor,
                                pickups: data.inProgress.pickups,
                                deliveries: data.inProgress.deliveries,
                                grandTotal: grandTotal,
                                animController: _entryController,
                                delay: 0.08,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: "Upcoming",
                                value: data.upcoming.total,
                                icon: Icons.calendar_month_rounded,
                                accentColor: const Color(0xFF3B82F6),
                                pickups: data.upcoming.pickups,
                                deliveries: data.upcoming.deliveries,
                                grandTotal: grandTotal,
                                animController: _entryController,
                                delay: 0.14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: "Pending",
                                value: data.pending.total,
                                icon: Icons.hourglass_top_rounded,
                                accentColor: const Color(0xFFF97316),
                                pickups: data.pending.pickups,
                                deliveries: data.pending.deliveries,
                                grandTotal: grandTotal,
                                animController: _entryController,
                                delay: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _buildSectionLabel("Weekly Flow"),
                        const SizedBox(height: 12),
                        _WeeklyChart(
                          asyncWeekly: asyncWeekly,
                          barController: _barController,
                        ),
                        if (grandTotal > 0) ...[
                          const SizedBox(height: 28),
                          _buildSectionLabel("Distribution"),
                          const SizedBox(height: 12),
                          _DistributionChart(
                            data: data,
                            grandTotal: grandTotal,
                          ),
                        ],
                        const SizedBox(height: 28),
                        _buildSectionLabel("Task Breakdown"),
                        const SizedBox(height: 12),
                        _TaskBreakdownCard(
                          data: data,
                          grandTotal: grandTotal,
                          barController: _barController,
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.deliveryColor,
                  strokeWidth: 2,
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.error_outline_rounded,
                            size: 40, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Could not load dashboard",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(analyticsControllerProvider.notifier)
                            .fetch(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deliveryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: AppColors.textSecondary.withValues(alpha: 0.55),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AnimationController entryController;

  const _Header({required this.entryController});

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: entryController,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -20 * (1 - entryController.value)),
        child: Opacity(
          opacity: entryController.value.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(22, statusBarH + 18, 22, 22),
            decoration: const BoxDecoration(
              color: AppColors.deliveryColor,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "LIVE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Analytics",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Logistics performance overview",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 24,
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accentColor;
  final int? pickups;
  final int? deliveries;
  final int grandTotal;
  final AnimationController animController;
  final double delay;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.pickups,
    this.deliveries,
    required this.grandTotal,
    required this.animController,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = grandTotal > 0 ? value / grandTotal : 0.0;

    return AnimatedBuilder(
      animation: animController,
      builder: (_, __) {
        final t =
            ((animController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Transform.translate(
          offset: Offset(0, 16 * (1 - curve)),
          child: Opacity(
            opacity: curve.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      Text(
                        "${(fraction * 100).round()}%",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 1600),
                    curve: Curves.easeOutExpo,
                    builder: (_, v, __) => Text(
                      v.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: fraction),
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOutCubic,
                      builder: (_, f, __) => LinearProgressIndicator(
                        value: f,
                        backgroundColor: accentColor.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  if (pickups != null || deliveries != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (pickups != null) ...[
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 11,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "$pickups",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (pickups != null && deliveries != null)
                          const SizedBox(width: 8),
                        if (deliveries != null) ...[
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 11,
                            color:
                                AppColors.deliveryColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "$deliveries",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deliveryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────

class _WeeklyChart extends ConsumerWidget {
  final AsyncValue asyncWeekly;
  final AnimationController barController;

  const _WeeklyChart({
    required this.asyncWeekly,
    required this.barController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pickups & Deliveries",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _legendDot(const Color(0xFFF97316), "Pickup"),
                  const SizedBox(width: 12),
                  _legendDot(AppColors.deliveryColor, "Delivery"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: asyncWeekly.when(
              data: (weekly) {
                double maxVal = 0;
                bool hasActivity = false;
                for (final d in weekly.data) {
                  if (d.pickups > 0 || d.deliveries > 0) hasActivity = true;
                  if (d.pickups > maxVal) maxVal = d.pickups.toDouble();
                  if (d.deliveries > maxVal) maxVal = d.deliveries.toDouble();
                }
                if (!hasActivity) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 32,
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No activity this week",
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (maxVal == 0) maxVal = 1.0;

                // Cast to List<Widget> to avoid List<dynamic> type error
                final bars = weekly.data
                    .map<Widget>((d) => _WeeklyBarItem(
                          label: d.day.length >= 3
                              ? d.day.substring(0, 3).toUpperCase()
                              : d.day.toUpperCase(),
                          pickups: d.pickups,
                          deliveries: d.deliveries,
                          maxVal: maxVal,
                          controller: barController,
                        ))
                    .toList();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bars,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.deliveryColor,
                ),
              ),
              error: (_, __) => Center(
                child: Text(
                  "Unavailable",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ─── Weekly Bar Item (AnimatedBuilder inside, no List<dynamic> risk) ──────────

class _WeeklyBarItem extends StatelessWidget {
  final String label;
  final int pickups;
  final int deliveries;
  final double maxVal;
  final AnimationController controller;

  const _WeeklyBarItem({
    required this.label,
    required this.pickups,
    required this.deliveries,
    required this.maxVal,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        const maxHeight = 140.0;
        final t = Curves.easeOutCubic.transform(controller.value);
        final pHeight =
            (maxHeight * (pickups / maxVal) * t).clamp(3.0, maxHeight);
        final dHeight =
            (maxHeight * (deliveries / maxVal) * t).clamp(3.0, maxHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SingleBar(height: pHeight, color: const Color(0xFFF97316)),
                const SizedBox(width: 3),
                _SingleBar(height: dHeight, color: AppColors.deliveryColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SingleBar extends StatelessWidget {
  final double height;
  final Color color;

  const _SingleBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      ),
    );
  }
}

// ─── Distribution Chart ───────────────────────────────────────────────────────

class _DistributionChart extends StatelessWidget {
  final dynamic data;
  final int grandTotal;

  const _DistributionChart({
    required this.data,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    final total = grandTotal.toDouble();

    final sections = <_DonutSection>[
      _DonutSection(
        "Completed",
        data.completed.total / total,
        const Color(0xFF22C55E),
      ),
      _DonutSection(
        "In Progress",
        data.inProgress.total / total,
        AppColors.deliveryColor,
      ),
      _DonutSection(
        "Upcoming",
        data.upcoming.total / total,
        const Color(0xFF3B82F6),
      ),
      _DonutSection(
        "Pending",
        data.pending.total / total,
        const Color(0xFFF97316),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _DonutPainter(sections: sections, progress: t),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections.map<Widget>((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        "${(s.fraction * 100).round()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: s.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutSection {
  final String label;
  final double fraction;
  final Color color;

  const _DonutSection(this.label, this.fraction, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSection> sections;
  final double progress;

  const _DonutPainter({required this.sections, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy);
    final innerR = outerR * 0.62;
    const gap = 0.04;

    double startAngle = -math.pi / 2;
    for (final s in sections) {
      final sweep = s.fraction * 2 * math.pi * progress - gap;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerR - innerR
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: (outerR + innerR) / 2),
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );
      startAngle += s.fraction * 2 * math.pi * progress;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.sections != sections;
}

// ─── Task Breakdown Card (replaces static PerformanceCard) ───────────────────

class _TaskBreakdownCard extends StatelessWidget {
  final dynamic data;
  final int grandTotal;
  final AnimationController barController;

  const _TaskBreakdownCard({
    required this.data,
    required this.grandTotal,
    required this.barController,
  });

  @override
  Widget build(BuildContext context) {
    if (grandTotal == 0) return const SizedBox.shrink();

    final rows = <_BreakdownRow>[
      _BreakdownRow(
        label: "Completed",
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF22C55E),
        pickups: data.completed.pickups as int,
        deliveries: data.completed.deliveries as int,
        fraction: data.completed.total / grandTotal,
      ),
      _BreakdownRow(
        label: "In Progress",
        icon: Icons.pending_rounded,
        color: AppColors.deliveryColor,
        pickups: data.inProgress.pickups as int,
        deliveries: data.inProgress.deliveries as int,
        fraction: data.inProgress.total / grandTotal,
      ),
      _BreakdownRow(
        label: "Upcoming",
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF3B82F6),
        pickups: data.upcoming.pickups as int,
        deliveries: data.upcoming.deliveries as int,
        fraction: data.upcoming.total / grandTotal,
      ),
      _BreakdownRow(
        label: "Pending",
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF97316),
        pickups: data.pending.pickups as int,
        deliveries: data.pending.deliveries as int,
        fraction: data.pending.total / grandTotal,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map<Widget>((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: isLast
                ? null
                : BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                  ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: row.color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(row.icon, color: row.color, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            row.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.inventory_2_rounded,
                                size: 11,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "${row.pickups}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 11,
                                color: AppColors.deliveryColor
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "${row.deliveries}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deliveryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: barController,
                        builder: (_, __) {
                          final t = Curves.easeOutCubic
                              .transform(barController.value);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: row.fraction * t,
                              backgroundColor:
                                  row.color.withValues(alpha: 0.08),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(row.color),
                              minHeight: 4,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${(row.fraction * 100).round()}%",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: row.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BreakdownRow {
  final String label;
  final IconData icon;
  final Color color;
  final int pickups;
  final int deliveries;
  final double fraction;

  const _BreakdownRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.pickups,
    required this.deliveries,
    required this.fraction,
  });
}