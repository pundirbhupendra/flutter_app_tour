import 'package:flutter/material.dart';
import 'package:flutter_app_tour/flutter_app_tour.dart';


void main() => runApp(const MaterialApp(home: HomePage()));

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _fabKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _profileKey = GlobalKey();

  late final _tourController = TourController(
    steps: [
      TourStep(
        id: TourId('search'),
        targetKey: _searchKey,
        title: 'Search',
        description: 'Find anything quickly from here.',
        tooltipPosition: TooltipPosition.bottom,
      ),
      TourStep(
        id: TourId('fab'),
        targetKey: _fabKey,
        title: 'Create',
        description: 'Tap here to add something new.',
        tooltipPosition: TooltipPosition.top,
      ),
      TourStep(
        id: TourId('profile'),
        targetKey: _profileKey,
        title: 'Your Profile',
        description: 'Manage your account settings here.',
        tooltipPosition: TooltipPosition.left,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return TourScope(
      controller: _tourController,
      child: Scaffold(
        appBar: AppBar(
          title: TourTarget(
            id: TourId('search'),
            controller: _tourController,
            targetKey: _searchKey,
            child: const Icon(Icons.search),
          ),
          actions: [
            TourTarget(
              id: TourId('profile'),
              controller: _tourController,
              targetKey: _profileKey,
              child: const CircleAvatar(child: Icon(Icons.person)),
            ),
          ],
        ),
        body: const Center(child: Text('Home content')),
        floatingActionButton: TourTarget(
          id: TourId('fab'),
          controller: _tourController,
          targetKey: _fabKey,
          child: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
        // Button to trigger the tour on demand, so you don't have to
        // clear SharedPreferences every hot restart just to see it again.
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: () => _tourController.start(),
              child: const Text('Start tour'),
            ),
          ),
        ),
      ),
    );
  }
}