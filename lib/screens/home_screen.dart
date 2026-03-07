// lib/screens/home_screen.dart
import 'package:campusassist/widgets/app_logo_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/category_filter.dart';
import '../viewmodel/post_viewmodel.dart';
import '../viewmodel/notification_viewmodel.dart';
import '../widgets/skeleton_loaders.dart';
import 'package:campusassist/screens/post_detail_screen.dart';
import 'package:campusassist/screens/notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) {
    setState(() => _selectedCategory = cat);
    ref
        .read(feedProvider.notifier)
        .refresh(category: cat == 'All' ? null : cat);
    ref
        .read(globalFeedProvider.notifier)
        .refresh(category: cat == 'All' ? null : cat);
  }

  void _openPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myFeedAsync = ref.watch(feedProvider);
    final globalAsync = ref.watch(globalFeedProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.cardBg,
            elevation: 0,
            title: Row(
              children: [
                const AppLogoIcon.small(),
                const SizedBox(width: 10),
                const Text(
                  'CampusAssist',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () {},
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: AppTheme.textOnPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('My Feed'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Across India'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CategoryFilter(
                selected: _selectedCategory,
                onChanged: _onCategoryChanged,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── My Feed tab ────────────────────────────────────────────────
            _AsyncPostList(
              postsAsync: myFeedAsync,
              emptyMessage: 'Join communities and be the first to post!',
              onRefresh: () => ref
                  .read(feedProvider.notifier)
                  .refresh(
                    category: _selectedCategory == 'All'
                        ? null
                        : _selectedCategory,
                  ),
              onUpvote: (id) => ref.read(feedProvider.notifier).toggleLike(id),
              onTap: _openPost,
            ),
            // ── Across India tab ───────────────────────────────────────────
            _AsyncPostList(
              postsAsync: globalAsync,
              emptyMessage: 'No posts found across communities.',
              onRefresh: () => ref
                  .read(globalFeedProvider.notifier)
                  .refresh(
                    category: _selectedCategory == 'All'
                        ? null
                        : _selectedCategory,
                  ),
              onUpvote: (id) =>
                  ref.read(globalFeedProvider.notifier).toggleLike(id),
              onTap: _openPost,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Async post list ───────────────────────────────────────────────────────────

class _AsyncPostList extends StatelessWidget {
  final AsyncValue<List<Post>> postsAsync;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String id) onUpvote;
  final void Function(Post) onTap;

  const _AsyncPostList({
    required this.postsAsync,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return postsAsync.when(
      loading: () => const SkeletonPostList(count: 4),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 12),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: AppTheme.textLight.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No posts yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 100),
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(
              post: posts[i],
              onTap: () => onTap(posts[i]),
              onUpvote: (id) async {
                await onUpvote(id);
                return posts[i];
              },
            ),
          ),
        );
      },
    );
  }
}
