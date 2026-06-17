// import 'package:flutter/material.dart';
// import 'package:delivery/utils/colortheme.dart';
// import 'package:delivery/Screens/pickup_details_screen.dart';
// import 'package:delivery/Screens/pickup_details_screen.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   String _getGreeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good Morning,';
//     if (hour < 17) return 'Good Afternoon,';
//     return 'Good Evening,';
//   }

//   @override
//   Widget build(BuildContext context) {
//     AppSize.init(context);
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: AppColors.background,
//         elevation: 0,
//         toolbarHeight: 80,
//         centerTitle: false,
//         titleSpacing: 0,
//         leadingWidth: 72,
//         leading: Center(
//           child: Container(
//             margin: const EdgeInsets.only(left: 20),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: const CircleAvatar(
//               radius: 20,
//               backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alex'),
//             ),
//           ),
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _getGreeting().toUpperCase(),
//               style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.textSecondary,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const Text(
//               'Alex Rivera',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w900,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//           ],
//         ),
//         // actions: [
//         //   _buildAppBarAction(Icons.auto_awesome_mosaic_rounded),
//         //   const SizedBox(width: 10),
//         //   _buildAppBarAction(Icons.notifications_none_rounded, showDot: true),
//         //   const SizedBox(width: 20),
//         // ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: AppSize.width * 0.05),
//           child: TweenAnimationBuilder<double>(
//             tween: Tween(begin: 0.0, end: 1.0),
//             duration: const Duration(milliseconds: 800),
//             curve: Curves.easeOutCubic,
//             builder: (context, value, child) {
//               return Transform.translate(
//                 offset: Offset(0, 30 * (1 - value)),
//                 child: Opacity(opacity: value, child: child),
//               );
//             },
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),
//                 // Stats Cards
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildStatCard(
//                         icon: Icons.fact_check_rounded,
//                         label: 'PICKUPS',
//                         value: '4',
//                         total: '6',
//                       ),
//                     ),
//                     const SizedBox(width: 15),
//                     Expanded(
//                       child: _buildStatCard(
//                         icon: Icons.inventory_2_rounded,
//                         label: 'DELIVERIES',
//                         value: '5',
//                         total: '6',
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 30),

//                 // Next Action Protocol
//                 Row(
//                   children: [
//                     Text(
//                       'NEXT ACTION PROTOCOL',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textSecondary.withValues(alpha: 0.5),
//                         letterSpacing: 1.2,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Divider(
//                         color: AppColors.textSecondary.withValues(alpha: 0.1),
//                         thickness: 1,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 // Action Card
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: AppColors.divider,
//                     borderRadius: BorderRadius.circular(32),
//                     border: Border.all(
//                       color: AppColors.deliveryColor,
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.04),
//                         blurRadius: 30,
//                         offset: const Offset(0, 15),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               color: AppColors.deliveryColor.withValues(
//                                 alpha: 0.1,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Row(
//                               children: [
//                                 Icon(
//                                   Icons.stars_rounded,
//                                   color: AppColors.deliveryColor,
//                                   size: 14,
//                                 ),
//                                 SizedBox(width: 6),
//                                 Text(
//                                   'PRIORITY VERIFICATION',
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w900,
//                                     color: AppColors.deliveryColor,
//                                     letterSpacing: 0.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Text(
//                             'ETA: 12 MIN',
//                             style: TextStyle(
//                               fontSize: 10,
//                               fontWeight: FontWeight.w800,
//                               color: AppColors.textSecondary.withValues(
//                                 alpha: 0.6,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       const Text(
//                         'Hillside Organic Farm',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.w900,
//                           color: AppColors.textPrimary,
//                           height: 1.1,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on_rounded,
//                             size: 16,
//                             color: AppColors.deliveryColor.withValues(
//                               alpha: 0.7,
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             'SITE #402 • SECTOR B',
//                             style: TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.textSecondary.withValues(
//                                 alpha: 0.8,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 28),
//                       Container(
//                         padding: const EdgeInsets.all(20),
//                         decoration: BoxDecoration(
//                           color: AppColors.background.withValues(alpha: 0.5),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(color: Colors.white, width: 1),
//                         ),
//                         child: Row(
//                           children: [
//                             _buildInfoColumn('TOTAL CARGO', '500 KG'),
//                             const Spacer(),
//                             _buildInfoColumn(
//                               'UNITS',
//                               '12 CRATES',
//                               isRight: true,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 28),
//                       ElevatedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (context) =>
//                                       const PickupDetailsScreen(taskId: '402'),
//                             ),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.deliveryColor,
//                           foregroundColor: Colors.white,
//                           minimumSize: const Size(double.infinity, 60),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           elevation: 8,
//                           shadowColor: AppColors.deliveryColor.withValues(
//                             alpha: 0.4,
//                           ),
//                         ),
//                         child: const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               'INITIATE PROTOCOL',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w900,
//                                 letterSpacing: 1,
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Icon(Icons.arrow_forward_rounded, size: 20),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 100),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBarAction(IconData icon, {bool showDot = false}) {
//     return Container(
//       width: 44,
//       height: 44,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Icon(icon, color: AppColors.textPrimary, size: 22),
//           if (showDot)
//             Positioned(
//               top: 12,
//               right: 12,
//               child: Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 1.5),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionChip(IconData icon, String label) {
//     return Container(
//       margin: const EdgeInsets.only(right: 12),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.textSecondary.withOpacity(0.05)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 18, color: AppColors.textPrimary),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.w900,
//               color: AppColors.textPrimary,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required String total,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: AppColors.deliveryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(icon, color: AppColors.deliveryColor, size: 22),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.w800,
//               color: AppColors.textSecondary.withOpacity(0.5),
//               letterSpacing: 0.5,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.baseline,
//             textBaseline: TextBaseline.alphabetic,
//             children: [
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.w900,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               Text(
//                 ' / $total',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoColumn(String label, String value, {bool isRight = false}) {
//     return Column(
//       crossAxisAlignment:
//           isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 10,
//             fontWeight: FontWeight.w800,
//             color: AppColors.textSecondary.withOpacity(0.5),
//             letterSpacing: 0.5,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w900,
//             color: AppColors.textPrimary,
//           ),
//         ),
//       ],
//     );
//   }
// }
