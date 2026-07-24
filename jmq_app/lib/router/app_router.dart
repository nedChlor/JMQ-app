import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/dtc_search_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/document_list_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../models/category.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, _) => const HomeScreen()),
    GoRoute(
      path: '/dtc',
      builder: (context, state) => DTCDetailScreen(code: state.extra as String?),
    ),
    GoRoute(path: '/categories', builder: (context, _) => const CategoriesScreen()),
    GoRoute(
      path: '/documents/:id',
      builder: (context, state) {
        final cat = state.extra as Category;
        return DocumentListScreen(category: cat);
      },
    ),
    GoRoute(
      path: '/pdf',
      builder: (context, state) {
        final data = state.extra as Map<String, String>;
        return PdfViewerScreen(pdfAssetPath: data['path']!, title: data['title']!);
      },
    ),
  ],
);
