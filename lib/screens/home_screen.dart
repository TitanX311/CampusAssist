// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/category_filter.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _ds = DataService();
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
    final results = await Future.wait([
      _ds.getMyCollegePosts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      ),
      _ds.getAcrossIndiaPosts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      ),
    ]);
    if (mounted) {
      setState(() {
        _myCollegePosts = results[0];
        _indiaPosts = results[1];
        _loading = false;
      });
    }
  }

  void _onCategoryChanged(String cat) {
    setState(() => _selectedCategory = cat);
    _load();
  }

  Future<Post> _upvotePost(String id) async {
    final updated = await _ds.upvotePost(id);
    _load(); // refresh both lists
    return updated;
  }

  void _openPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final college = _ds.selectedCollege;
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
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
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
            _PostList(
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
          showCollegeName: showCollege,
          onTap: () => onTap(posts[i]),
          onUpvote: onUpvote,
        ),
      ),
    );
  }
}
