import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/dtc_search_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/fulltext_search_screen.dart';
import '../screens/document_list_screen.dart';
import '../screens/pdf_viewer_screen.dart';
import '../models/category.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/dtc',
      builder: (_, state) => DTCDetailScreen(code: state.extra as String?),
    ),
    GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
    GoRoute(
      path: '/search',
      builder: (_, state) => FullTextSearchScreen(initialQuery: state.extra as String?),
    ),
    GoRoute(
      path: '/documents/:id',
      builder: (_, state) {
        final cat = state.extra as Category;
        return DocumentListScreen(category: cat);
      },
    ),
    GoRoute(
      path: '/pdf',
      builder: (_, state) {
        final data = state.extra as Map<String, String>;
        return PdfViewerScreen(pdfAssetPath: data['path']!, title: data['title']!);
      },
    ),
  ],
);
