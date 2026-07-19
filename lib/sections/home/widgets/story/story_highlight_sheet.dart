import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryHighlightSheet extends StatelessWidget {
  final String currentMediaUrl;
  final ValueChanged<String> onCompleted;

  const StoryHighlightSheet({
    super.key,
    required this.currentMediaUrl,
    required this.onCompleted,
  });

  void _showCreateHighlightDialog(BuildContext context, ValueNotifier<String> selectedHighlightNotifier) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "New Highlight", 
            style: GoogleFonts.ibmPlexSansArabic(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          ),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter highlight name",
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C57FC))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.ibmPlexSansArabic(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  selectedHighlightNotifier.value = name;
                }
                Navigator.pop(context);
              },
              child: Text("Create", style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF7C57FC), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedHighlightNotifier = ValueNotifier<String>("Highlight");

    return ValueListenableBuilder<String>(
      valueListenable: selectedHighlightNotifier,
      builder: (context, selectedHighlight, child) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131722),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Add to highlight",
                style: GoogleFonts.ibmPlexSansArabic(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      selectedHighlightNotifier.value = "Highlight";
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedHighlight == "Highlight"
                                  ? const Color(0xFF7C57FC)
                                  : Colors.white24,
                              width: 2.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: ClipOval(
                              child: currentMediaUrl.startsWith('http')
                                  ? CachedNetworkImage(imageUrl: currentMediaUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24))
                                  : Image.asset(currentMediaUrl, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Highlight",
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: selectedHighlight == "Highlight"
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  GestureDetector(
                    onTap: () => _showCreateHighlightDialog(context, selectedHighlightNotifier),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedHighlight != "Highlight"
                                  ? const Color(0xFF7C57FC)
                                  : Colors.white24,
                              width: 2.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Color(0xFF7C57FC), size: 28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedHighlight != "Highlight" ? selectedHighlight : "New",
                          style: GoogleFonts.ibmPlexSansArabic(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: selectedHighlight != "Highlight"
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onCompleted(selectedHighlight);
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C57FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Continue",
                    style: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
