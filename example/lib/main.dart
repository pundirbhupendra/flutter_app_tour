import 'package:flutter/material.dart';
import 'package:flutter_app_tour/flutter_app_tour.dart';

void main() => runApp(const TourExampleApp());

class TourExampleApp extends StatelessWidget {
  const TourExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App Tour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b87)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tourId = 'home-tour-v2';

  final _fabKey = GlobalKey();
  final _searchKey = GlobalKey();
  final _profileKey = GlobalKey();
  final _insightsKey = GlobalKey();
  final _storage = const SharedPreferencesTourStorage();

  late final _tourController = TourController(
    storage: _storage,
    theme: const TourTheme(
      overlayColor: Color(0xff102a43),
      overlayOpacity: 0.72,
      spotlightPadding: 10,
      spotlightRadius: 16,
      spotlightShape: SpotlightShape.roundedRectangle,
      progressIndicatorType: TourProgressIndicatorType.fraction,
    ),
    steps: [
      TourStep(
        id: TourId('search'),
        targetKey: _searchKey,
        title: 'Search',
        description: 'Use search to find projects, notes, and teammates.',
        tooltipPosition: TooltipPosition.bottom,
        spotlightShape: SpotlightShape.circle,
      ),
      TourStep(
        id: TourId('insights'),
        targetKey: _insightsKey,
        title: 'Your weekly insights',
        description:
            'This card appears farther down the page to demonstrate automatic scrolling.',
        tooltipPosition: TooltipPosition.auto,
        scrollToTarget: true,
      ),
      TourStep(
        id: TourId('profile'),
        targetKey: _profileKey,
        title: 'Your Profile',
        description: 'Update your preferences and account details here.',
        tooltipPosition: TooltipPosition.left,
        spotlightShape: SpotlightShape.circle,
      ),
      TourStep(
        id: TourId('create'),
        targetKey: _fabKey,
        title: 'Create a project',
        description: 'Start something new whenever inspiration strikes.',
        tooltipPosition: TooltipPosition.top,
      ),
    ],
    onCompleted: () => _storage.markSeen(_tourId),
    onSkipped: () => _storage.markSeen(_tourId),
  );

  @override
  void dispose() {
    _tourController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return TourScope(
      controller: _tourController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workspace'),
          actions: [
            TourTarget(
              id: TourId('search'),
              controller: _tourController,
              targetKey: _searchKey,
              child: IconButton(
                tooltip: 'Search',
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ),
            TourTarget(
              id: TourId('profile'),
              controller: _tourController,
              targetKey: _profileKey,
              child: IconButton(
                tooltip: 'Profile',
                onPressed: () {},
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            Text(
              'Good morning, Alex',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Here is what is happening across your workspace.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Metric(label: 'Tasks done', value: '24'),
                        _Metric(label: 'Projects', value: '08'),
                        _Metric(label: 'Focus hours', value: '18h'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 420),
            Card(
              key: _insightsKey,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.insights_outlined),
                    const SizedBox(height: 16),
                    Text(
                      'Weekly insights',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are most productive on Tuesday mornings. Keep that momentum going.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: TourTarget(
          id: TourId('create'),
          controller: _tourController,
          targetKey: _fabKey,
          child: FloatingActionButton(
            onPressed: () => _showMessage('New project action'),
            tooltip: 'Create project',
            child: const Icon(Icons.add),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: _tourController.start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start product tour'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
