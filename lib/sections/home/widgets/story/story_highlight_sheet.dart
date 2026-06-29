import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryHighlightSheet extends StatefulWidget {
  final String currentMediaUrl;
  final ValueChanged<String> onCompleted;

  const StoryHighlightSheet({
    super.key,
    required this.currentMediaUrl,
    required this.onCompleted,
  });

  @override
  State<StoryHighlightSheet> createState() => _StoryHighlightSheetState();
}

class _StoryHighlightSheetState extends State<StoryHighlightSheet> {
  String selectedHighlight = "Highlight";

  void _showCreateHighlightDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("New Highlight", style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: "Enter highlight name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.ibmPlexSansArabic(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    selectedHighlight = name;
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Create", style: GoogleFonts.ibmPlexSansArabic(color: const Color(0xFF7C57FC))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Add to highlight",
            style: GoogleFonts.ibmPlexSansArabic(
              color: Colors.black,
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
                  setState(() {
                    selectedHighlight = "Highlight";
                  });
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
                              : Colors.grey[300]!,
                          width: 2.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: ClipOval(
                          child: widget.currentMediaUrl.startsWith('http')
                              ? Image.network(widget.currentMediaUrl, fit: BoxFit.cover)
                              : Image.asset(widget.currentMediaUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Highlight",
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: const Color(0xFF1F1F1F),
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
                onTap: () => _showCreateHighlightDialog(context),
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
                              : Colors.grey[300]!,
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
                        color: const Color(0xFF1F1F1F),
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
              widget.onCompleted(selectedHighlight);
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
  }
}
