// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../repositories/post_remote_repository.dart';
import '../theme/app_theme.dart';
import '../viewmodel/post_viewmodel.dart';
import '../widgets/skeleton_loaders.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'campus_map_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late Post _post;
  final _answerCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _upvotePost() async {
    final wasUpvoted = _post.hasUpvoted;
    setState(
      () => _post = _post.copyWith(
        upvotes: wasUpvoted ? _post.upvotes - 1 : _post.upvotes + 1,
        hasUpvoted: !wasUpvoted,
      ),
    );
    try {
      await ref.read(postRemoteRepositoryProvider).likePost(_post.id);
    } catch (_) {
      if (mounted) {
        setState(
          () => _post = _post.copyWith(
            upvotes: wasUpvoted ? _post.upvotes + 1 : _post.upvotes - 1,
            hasUpvoted: wasUpvoted,
          ),
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final key = commentsProvider(
        postId: _post.id,
        communityId: _post.communityId,
      );
      await ref.read(key.notifier).addComment(text);
      _answerCtrl.clear();
      setState(
        () => _post = _post.copyWith(answerCount: _post.answerCount + 1),
      );
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post answer: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openCampusMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampusMapScreen(
          collegeId: _post.collegeId,
          collegeName: _post.collegeName,
          locationLabel: _post.locationLabel,
          postTitle: _post.content.length > 60
              ? '${_post.content.substring(0, 60)}...'
              : _post.content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColor(_post.category.label);
    final commentsAsync = ref.watch(
      commentsProvider(postId: _post.id, communityId: _post.communityId),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Full post card ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header strip
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
                                  mainAxisSize: MainAxisSize.min,
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

                        // Post body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Markdown-rendered content
                              MarkdownBody(
                                data: _post.content,
                                selectable: true,
                                styleSheet:
                                    MarkdownStyleSheet.fromTheme(
                                      Theme.of(context),
                                    ).copyWith(
                                      p: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        height: 1.55,
                                      ),
                                      strong: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      em: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      code: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12.5,
                                        backgroundColor: AppTheme.surface,
                                        color: AppTheme.primary,
                                      ),
                                      codeblockDecoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.divider,
                                        ),
                                      ),
                                      blockquoteDecoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.04,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border(
                                          left: BorderSide(
                                            color: AppTheme.primary.withOpacity(
                                              0.5,
                                            ),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),

                              // Location banner
                              if (_post.locationLabel != null) ...[
                                const SizedBox(height: 14),
                                _CampusMapBanner(
                                  locationLabel: _post.locationLabel!,
                                  onTap: _openCampusMap,
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Author + upvote
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
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '· ${_post.collegeName}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 15,
                                            color: _post.hasUpvoted
                                                ? AppTheme.textOnPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${_post.upvotes}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: _post.hasUpvoted
                                                  ? AppTheme.textOnPrimary
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Upvote',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _post.hasUpvoted
                                                  ? AppTheme.textOnPrimary
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

                  // ── Comments ───────────────────────────────────────────────
                  commentsAsync.when(
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_post.answerCount} Answers',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SkeletonCommentList(count: 3),
                      ],
                    ),
                    error: (e, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(
                                    commentsProvider(
                                      postId: _post.id,
                                      communityId: _post.communityId,
                                    ).notifier,
                                  )
                                  .refresh(),
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Retry',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString().replaceFirst('Exception: ', ''),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    data: (comments) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${comments.length} Answer${comments.length == 1 ? '' : 's'}',
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
                              'Latest',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (comments.isEmpty)
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
                          ...comments.map(
                            (c) => _AnswerCard(
                              comment: c,
                              onDelete: () => ref
                                  .read(
                                    commentsProvider(
                                      postId: _post.id,
                                      communityId: _post.communityId,
                                    ).notifier,
                                  )
                                  .deleteComment(c.id),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Answer input bar ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              border: const Border(top: BorderSide(color: AppTheme.divider)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.textPrimary.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.textOnPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _answerCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write an answer…',
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
                              color: AppTheme.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppTheme.textOnPrimary,
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
}

// ── Answer Card ────────────────────────────────────────────────────────────────

class _AnswerCard extends StatelessWidget {
  final Comment comment;
  final Future<void> Function() onDelete;

  const _AnswerCard({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: comment.body,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                  code: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.primary,
                  ),
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
                '@${comment.authorAlias}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${timeago.format(comment.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Campus Map Banner ──────────────────────────────────────────────────────────

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
                color: AppTheme.textOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
