// lib/widgets/post_card.dart
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/server_constants.dart';
import '../models/post_model.dart';
import '../repositories/auth_local_repository.dart';
import '../theme/app_theme.dart';
import 'skeleton_loaders.dart';
import 'package:timeago/timeago.dart' as timeago;

// Max attachments shown per post
const _kMaxAttachments = 5;

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final VoidCallback onTap;
  final Future<Post> Function(String id) onUpvote;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onUpvote,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    _post = widget.post;
  }

  Future<void> _handleUpvote() async {
    final updated = await widget.onUpvote(_post.id);
    if (mounted) setState(() => _post = updated);
  }

  /// Download URL for an attachment id — requires Bearer token but
  /// Flutter's Image.network can't add headers; we proxy via the dio client.
  /// For display, we use NetworkImage with the correct auth header via
  /// a FutureBuilder approach — or simply build the URL and rely on the
  /// interceptor caching in dio. Here we expose the URL string; the
  /// _AttachmentThumbnail widget handles token injection.
  static String _attachmentUrl(String id) =>
      '${ServerConstants.baseURL}/attachments/$id/download';

  @override
  Widget build(BuildContext context) {
    final attachments = _post.attachments.take(_kMaxAttachments).toList();
    final hasAttachments = attachments.isNotEmpty;
    final communityName = _post.collegeName.isNotEmpty
        ? _post.collegeName
        : _post.communityId.isNotEmpty
        ? '#${_post.communityId.substring(0, 8)}'
        : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  // Avatar
                  _post.authorPicture != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(_post.authorPicture!),
                          backgroundColor: AppTheme.primaryLight,
                        )
                      : CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryLight,
                          child: Text(
                            _post.authorAlias.isNotEmpty
                                ? _post.authorAlias[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textOnPrimary,
                            ),
                          ),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${_post.authorAlias}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              timeago.format(_post.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                            // Community name chip
                            if (communityName != null) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  communityName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: AppTheme.textLight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100),
                child: ClipRect(
                  child: MarkdownBody(
                    data: _post.content,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.45,
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
                        fontSize: 12,
                        backgroundColor: AppTheme.surface,
                        color: AppTheme.primary,
                      ),
                      h1: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                      h2: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      h3: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Attachments ───────────────────────────────────────────────
            if (hasAttachments) ...[
              const SizedBox(height: 10),
              _AttachmentsRow(
                attachmentIds: attachments,
                buildUrl: _attachmentUrl,
              ),
            ],

            // ── Location tag ──────────────────────────────────────────────
            if (_post.locationLabel != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _post.locationLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, indent: 14, endIndent: 14),

            // ── Footer ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_post.answerCount}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: AppTheme.textLight,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handleUpvote,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
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
                          const SizedBox(width: 4),
                          Text(
                            '${_post.upvotes}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attachments row ───────────────────────────────────────────────────────────

class _AttachmentsRow extends StatelessWidget {
  final List<String> attachmentIds;
  final String Function(String id) buildUrl;

  const _AttachmentsRow({required this.attachmentIds, required this.buildUrl});

  @override
  Widget build(BuildContext context) {
    final count = attachmentIds.length;

    // Single attachment — show full width
    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _AttachmentTile(
            url: buildUrl(attachmentIds[0]),
            height: 180,
            width: double.infinity,
          ),
        ),
      );
    }

    // 2 attachments — side by side
    if (count == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _AttachmentTile(
                  url: buildUrl(attachmentIds[0]),
                  height: 140,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _AttachmentTile(
                  url: buildUrl(attachmentIds[1]),
                  height: 140,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3+ attachments — one large left + stacked right column
    final remaining = count - 3; // extras beyond the 3 shown
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large left tile
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _AttachmentTile(
                url: buildUrl(attachmentIds[0]),
                height: 180,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Right column — up to 2 stacked tiles
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _AttachmentTile(
                    url: buildUrl(attachmentIds[1]),
                    height: 88,
                  ),
                ),
                const SizedBox(height: 4),
                // Third tile — with "+N more" overlay if there are extras
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      _AttachmentTile(
                        url: buildUrl(attachmentIds[2]),
                        height: 88,
                      ),
                      if (remaining > 0)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.textPrimary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: AppTheme.textOnPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
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

/// Single tile — fetches bytes via Dio (with Bearer token) then renders.
class _AttachmentTile extends StatelessWidget {
  final String url;
  final double height;
  final double? width;

  const _AttachmentTile({required this.url, required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: _AuthenticatedImage(url: url),
    );
  }
}

/// Fetches an image with a Bearer token via Dio and renders it as [Image.memory].
/// Falls back to a file-chip placeholder on any error.
class _AuthenticatedImage extends ConsumerStatefulWidget {
  final String url;
  const _AuthenticatedImage({required this.url});

  @override
  ConsumerState<_AuthenticatedImage> createState() =>
      _AuthenticatedImageState();
}

class _AuthenticatedImageState extends ConsumerState<_AuthenticatedImage> {
  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchBytes();
  }

  @override
  void didUpdateWidget(_AuthenticatedImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() => _future = _fetchBytes());
    }
  }

  Future<Uint8List> _fetchBytes() async {
    final local = ref.read(authLocalRepositoryProvider);
    final token = await local.getAccessToken();

    final dio = Dio();
    final response = await dio.get<List<int>>(
      widget.url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        // Follow redirects and accept any 2xx
        validateStatus: (s) => s != null && s < 400,
      ),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Empty response');
    }
    return Uint8List.fromList(response.data!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Shimmer(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Container(
            color: AppTheme.surface,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 28,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 4),
                Text(
                  'Attachment',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }
        return Image.memory(
          snap.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.surface,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 28,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 4),
                Text(
                  'Attachment',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
