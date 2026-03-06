// lib/screens/home_screen.dart
import 'package:campusassist/widgets/app_logo_icon.dart';
import 'package:campusassist/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../repositories/post_remote_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/category_filter.dart';
import 'post_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'All';
  List<Post> _myCollegePosts = [];
  List<Post> _indiaPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // TODO: replace with real API calls once college-scoped and India-wide
    // post endpoints are available (e.g. GET /api/posts?college=... and
    // GET /api/posts?scope=india).
    if (mounted) {
      setState(() {
        _myCollegePosts = [];
        _indiaPosts = [];
        _loading = false;
      });
    }
  }

  void _onCategoryChanged(String cat) {
    setState(() => _selectedCategory = cat);
    _load();
  }

  Future<Post> _upvotePost(String id) async {
    Post? toggled;
    setState(() {
      Post _toggle(Post p) {
        final t = p.copyWith(
          upvotes: p.hasUpvoted ? p.upvotes - 1 : p.upvotes + 1,
          hasUpvoted: !p.hasUpvoted,
        );
        toggled = t;
        return t;
      }

      _myCollegePosts = _myCollegePosts
          .map((p) => p.id == id ? _toggle(p) : p)
          .toList();
      _indiaPosts = _indiaPosts
          .map((p) => p.id == id ? _toggle(p) : p)
          .toList();
    });
    ref.read(postRemoteRepositoryProvider).likePost(id).ignore();
    return toggled!;
  }

  void _openPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final college = ref.watch(selectedCollegeProvider);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
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
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('My College'),
                        ],
                      ),
                      if (college != null)
                        Text(
                          college.name,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Tab(
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
            (college == null || college.id.isEmpty)
                ? const _NoCollegeView()
                : _PostList(
                    posts: _myCollegePosts,
                    loading: _loading,
                    showCollege: false,
                    onUpvote: _upvotePost,
                    onTap: _openPost,
                  ),
            _PostList(
              posts: _indiaPosts,
              loading: _loading,
              showCollege: true,
              onUpvote: _upvotePost,
              onTap: _openPost,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<Post> posts;
  final bool loading;
  final bool showCollege;
  final Future<Post> Function(String) onUpvote;
  final void Function(Post) onTap;

  const _PostList({
    required this.posts,
    required this.loading,
    required this.showCollege,
    required this.onUpvote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
            const Text(
              'Be the first to post!',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: posts.length,
        itemBuilder: (_, i) => PostCard(
          post: posts[i],
          // showCollegeName: showCollege,
          onTap: () => onTap(posts[i]),
          onUpvote: onUpvote,
        ),
      ),
    );
  }
}

class _NoCollegeView extends StatelessWidget {
  const _NoCollegeView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 72,
              color: AppTheme.textLight.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'No college selected',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to the Community tab to select your college and see posts from your campus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
