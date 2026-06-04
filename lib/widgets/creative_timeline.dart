import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';

class CreativeTimeline extends StatefulWidget {
  const CreativeTimeline({super.key});

  @override
  State<CreativeTimeline> createState() => _CreativeTimelineState();
}

class _CreativeTimelineState extends State<CreativeTimeline> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addNewTask(SongProvider provider) {
    final title = _taskController.text.trim();
    if (title.isNotEmpty) {
      provider.addTask(title);
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final song = provider.activeSong;

    if (song == null) return const SizedBox();

    // Define timeline stages and progress representation
    final stages = [
      {'label': 'Idea', 'status': SongStatus.idea, 'color': const Color(0xFF9E9E9E)},
      {'label': 'Drafting', 'status': SongStatus.drafting, 'color': const Color(0xFFD03BFF)},
      {'label': 'Recording', 'status': SongStatus.recording, 'color': const Color(0xFFFF5252)},
      {'label': 'Mixing', 'status': SongStatus.mixing, 'color': const Color(0xFF00FFCC)},
      {'label': 'Mastered', 'status': SongStatus.mastered, 'color': const Color(0xFFFFD700)},
    ];

    // Compute progress value
    final activeStageIndex = stages.indexWhere((element) => element['status'] == song.status);
    final percentComplete = (activeStageIndex + 1) / stages.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Side: Horizontal DAW timeline track
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: Color(0xFFFF5252)),
                    const SizedBox(width: 8),
                    const Text(
                      'Creative Roadmap',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Timeline progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentComplete,
                    backgroundColor: const Color(0xFF13131A),
                    color: stages[activeStageIndex >= 0 ? activeStageIndex : 0]['color'] as Color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                // Stages grid tracks (Ableton Live layout style)
                Expanded(
                  child: ListView.builder(
                    itemCount: stages.length,
                    itemBuilder: (context, index) {
                      final stage = stages[index];
                      final stageStatus = stage['status'] as SongStatus;
                      final isCurrent = song.status == stageStatus;
                      final isPassed = song.status.index >= stageStatus.index;
                      final stageColor = stage['color'] as Color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? stageColor.withOpacity(0.12)
                              : isPassed
                                  ? const Color(0xFF252535).withOpacity(0.4)
                                  : const Color(0xFF13131A).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent ? stageColor : Colors.white.withOpacity(0.02),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isPassed ? stageColor : Colors.grey[700],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  stage['label'] as String,
                                  style: TextStyle(
                                    color: isPassed ? Colors.white : Colors.grey[600],
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            // Quick status setter button
                            if (!isCurrent) ...[
                              InkWell(
                                onTap: () {
                                  provider.updateActiveSongMetadata(status: stageStatus);
                                },
                                child: Text(
                                  'Set Active',
                                  style: TextStyle(
                                    color: Colors.blueAccent[100],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: stageColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 24, color: Colors.white10),
          // Right Side: Song to-do checklist
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_box_outlined, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Milestone Checklist',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Add task text input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'New task details...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFF13131A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addNewTask(provider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.amber),
                      onPressed: () => _addNewTask(provider),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tasks list
                Expanded(
                  child: song.tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No checklists added yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          itemCount: song.tasks.length,
                          itemBuilder: (context, index) {
                            final task = song.tasks[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Checkbox(
                                  value: task.isCompleted,
                                  activeColor: Colors.amber,
                                  checkColor: Colors.black,
                                  side: const BorderSide(color: Colors.white30),
                                  onChanged: (val) {
                                    provider.toggleTask(task.id);
                                  },
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    color: task.isCompleted ? Colors.grey : Colors.white,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                  onPressed: () {
                                    provider.deleteTask(task.id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
