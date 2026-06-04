import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';

class InspirationBoard extends StatefulWidget {
  const InspirationBoard({super.key});

  @override
  State<InspirationBoard> createState() => _InspirationBoardState();
}

class _InspirationBoardState extends State<InspirationBoard> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedType = 'link';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context, SongProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add Inspiration Card',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type selector
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Link/Track'),
                            selected: _selectedType == 'link',
                            selectedColor: const Color(0xFF00E5FF),
                            labelStyle: TextStyle(
                              color: _selectedType == 'link' ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setDialogState(() => _selectedType = 'link');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Image URL'),
                            selected: _selectedType == 'image',
                            selectedColor: const Color(0xFF00E5FF),
                            labelStyle: TextStyle(
                              color: _selectedType == 'image' ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setDialogState(() => _selectedType = 'image');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Title (e.g. Bass Synthesizer Reference)',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: _selectedType == 'link'
                            ? 'YouTube / Spotify URL'
                            : 'Unsplash Image Link',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      provider.addInspirationItem(title, _selectedType, content);
                      _titleController.clear();
                      _contentController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommentsDialog(BuildContext context, SongProvider provider, InspirationItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Discussion: ${item.title}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                height: 350,
                child: Column(
                  children: [
                    // Comments list
                    Expanded(
                      child: item.comments.isEmpty
                          ? const Center(
                              child: Text(
                                'No comments yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              itemCount: item.comments.length,
                              itemBuilder: (context, index) {
                                final comment = item.comments[index];
                                final timeStr = DateFormat('hh:mm a').format(comment.timestamp);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252535),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            comment.author,
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.text,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(color: Colors.white10),
                    // New Comment row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Add team comment...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF13131A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                          onPressed: () {
                            final commentText = _commentController.text.trim();
                            if (commentText.isNotEmpty) {
                              provider.addInspirationComment(item.id, 'Artist (Me)', commentText);
                              _commentController.clear();
                              // Refresh dialog UI
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final song = provider.activeSong;

    if (song == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Inspiration Board',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                  foregroundColor: const Color(0xFF00E5FF),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAddItemDialog(context, provider),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inspiration visual grid layout
          Expanded(
            child: song.inspirationItems.isEmpty
                ? const Center(
                    child: Text(
                      'No inspiration cards added. Build an references grid for tracks/moodboards.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: song.inspirationItems.length,
                    itemBuilder: (context, index) {
                      final item = song.inspirationItems[index];
                      final hasImage = item.type == 'image';

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Visual Preview Area
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252535),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  image: hasImage
                                      ? DecorationImage(
                                          image: NetworkImage(item.content),
                                          fit: BoxFit.cover,
                                          onError: (err, stack) {},
                                        )
                                      : null,
                                ),
                                child: !hasImage
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.link, color: Color(0xFF00E5FF), size: 30),
                                            const SizedBox(height: 6),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Text(
                                                item.content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // Footer Details
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Comment Count trigger
                                        InkWell(
                                          onTap: () => _showCommentsDialog(context, provider, item),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.comment, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${item.comments.length}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Remove Item
                                        InkWell(
                                          onTap: () {
                                            provider.deleteInspirationItem(item.id);
                                          },
                                          child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
