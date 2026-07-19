import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../view_models/story_editor_view_model.dart';

class MentionInputPanel extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  const MentionInputPanel({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyEditorViewModelProvider);
    final notifier = ref.read(storyEditorViewModelProvider.notifier);

    if (!state.isEditingMention) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        hintText: "Enter username...",
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      onChanged: notifier.updateMentionSuggestions,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C57FC)),
                  onPressed: onSubmit,
                  child: Text("Done", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Live followed suggestions list
            if (state.mentionSuggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: state.mentionSuggestions.length,
                  itemBuilder: (context, index) {
                    final user = state.mentionSuggestions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: user['avatar_url'] != null
                            ? CachedNetworkImageProvider(user['avatar_url'])
                            : null,
                        child: user['avatar_url'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        user['username'] ?? '',
                        style: GoogleFonts.ibmPlexSansArabic(color: Colors.white),
                      ),
                      onTap: () {
                        controller.text = user['username'] ?? '';
                        onSubmit();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
