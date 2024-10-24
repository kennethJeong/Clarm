// import 'package:flutter/material.dart';
// import 'package:Clarm/models/providers.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class BottomNav extends ConsumerStatefulWidget {
//   const BottomNav({super.key});
//
//   @override
//   BottomNavState createState() => BottomNavState();
// }
//
// class BottomNavState extends ConsumerState<BottomNav> {
//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       type: BottomNavigationBarType.fixed,
//       selectedFontSize: 20,
//       unselectedFontSize: 20,
//       fixedColor: Colors.purple,
//       currentIndex: ref.watch(bottomNavIndex),
//       onTap: (int index) {
//         ref.watch(bottomNavIndex.notifier).state = index;
//       },
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(null, size: 0,),
//           label: "A",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(null, size: 0,),
//           label: "B",
//         ),
//       ],
//     );
//   }
// }