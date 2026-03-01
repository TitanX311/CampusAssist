// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'campus_map_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _ds = DataService();
  late Post _post;
  List<Answer> _answers = [];
  bool _loading = true;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    final ans = await _ds.getAnswers(_post.id);
    if (mounted) {
      setState(() {
        _answers = ans;
        _loading = false;
      });
    }
  }

  Future<void> _upvotePost() async {
    final updated = await _ds.upvotePost(_post.id);
    if (mounted) setState(() => _post = updated);
  }

  Future<void> _upvoteAnswer(Answer a) async {
    final updated = await _ds.upvoteAnswer(_post.id, a.id);
    setState(() {
      final idx = _answers.indexWhere((x) => x.id == a.id);
      if (idx != -1) _answers[idx] = updated;
    });
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final ans = await _ds.createAnswer(postId: _post.id, body: text);
    _answerCtrl.clear();
    setState(() {
      _answers.insert(0, ans);
      _submitting = false;
      _post = Post(
        id: _post.id,
        title: _post.title,
        body: _post.body,
        authorAlias: _post.authorAlias,
        collegeId: _post.collegeId,
        collegeName: _post.collegeName,
        category: _post.category,
        upvotes: _post.upvotes,
        hasUpvoted: _post.hasUpvoted,
        answerCount: _post.answerCount + 1,
        createdAt: _post.createdAt,
        locationLabel: _post.locationLabel,
      );
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColor(_post.category.label);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_post.category.label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post card full
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.07),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      AppTheme.categoryIcon(
                                        _post.category.label,
                                      ),
                                      size: 13,
                                      color: catColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _post.category.label,
                                      style: TextStyle(
                                        color: catColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeago.format(_post.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _post.body,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              if (_post.locationLabel != null) ...[
                                const SizedBox(height: 14),
                                _CampusMapBanner(
                                  locationLabel: _post.locationLabel!,
                                  onTap: () => _openCampusMap(),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 14,
                                    color: AppTheme.textLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '@${_post.authorAlias}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '· ${_post.collegeName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _upvotePost,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _post.hasUpvoted
                                            ? AppTheme.primary
                                            : AppTheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _post.hasUpvoted
                                              ? AppTheme.primary
                                              : AppTheme.divider,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 15,
                                            color: _post.hasUpvoted
                                                ? Colors.white
                                                : AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${_post.upvotes}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: _post.hasUpvoted
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Upvote',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _post.hasUpvoted
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Answers header
                  Row(
                    children: [
                      Text(
                        '${_post.answerCount} Answers',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Top',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_answers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: AppTheme.textLight.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Be the first to answer!',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._answers.map(
                      (a) => _AnswerCard(
                        answer: a,
                        onUpvote: () => _upvoteAnswer(a),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Answer input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppTheme.divider)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _answerCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write an answer...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _submitting ? null : _submitAnswer,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCampusMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampusMapScreen(
          collegeId: _post.collegeId,
          collegeName: _post.collegeName,
          locationLabel: _post.locationLabel,
          postTitle: _post.title,
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final Answer answer;
  final VoidCallback onUpvote;
  const _AnswerCard({required this.answer, required this.onUpvote});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer.body,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                '@${answer.authorAlias}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${timeago.format(answer.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onUpvote,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: answer.hasUpvoted
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: answer.hasUpvoted
                          ? AppTheme.primary
                          : AppTheme.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 13,
                        color: answer.hasUpvoted
                            ? AppTheme.primary
                            : AppTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${answer.upvotes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: answer.hasUpvoted
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Campus Map Banner widget (used in post detail) ───────────────────────────
class _CampusMapBanner extends StatelessWidget {
  final String locationLabel;
  final VoidCallback onTap;

  const _CampusMapBanner({required this.locationLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.08),
              AppTheme.primaryLight.withOpacity(0.06),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View on Campus Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        locationLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
