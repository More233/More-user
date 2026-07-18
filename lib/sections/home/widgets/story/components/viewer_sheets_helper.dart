import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../story_views_sheet.dart';
import '../story_delete_dialog.dart';
import '../story_options_sheet.dart';
import '../story_highlight_sheet.dart';
import '../story_send_sheet.dart';
import '../story_mention_sheet.dart';
import '../story_composer_screen.dart';
import '../../../models/story_view_state.dart';
import '../../../view_models/story_view_model.dart';
import '../../../view_models/social_feed_view_model.dart';

Future<void> confirmDeleteStory({
  required BuildContext context,
  required WidgetRef ref,
  required int initialGroupIndex,
  required AnimationController animationController,
  required String storyId,
}) async {
  animationController.stop();
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const StoryDeleteDialog(),
  );

  if (confirm == true) {
    try {
      final notifier = ref.read(storyViewModelProvider(initialGroupIndex).notifier);
      await notifier.deleteStory(storyId);
      ref.read(socialFeedViewModelProvider.notifier).refreshFeed();
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error deleting story: $e");
      animationController.forward();
    }
  } else {
    animationController.forward();
  }
}

void showViewsBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int initialGroupIndex,
  required AnimationController animationController,
  required StoryViewState storyState,
  required String currentStoryId,
}) {
  animationController.stop();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StoryViewsSheet(
        storyState: storyState,
        currentStoryId: currentStoryId,
        onDeletePressed: () => confirmDeleteStory(
          context: context,
          ref: ref,
          initialGroupIndex: initialGroupIndex,
          animationController: animationController,
          storyId: currentStoryId,
        ),
      );
    },
  ).then((_) {
    animationController.forward();
  });
}

void showMoreOptionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int initialGroupIndex,
  required AnimationController animationController,
  required String storyId,
}) {
  animationController.stop();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StoryOptionsSheet(
        onAddToStory: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StoryComposerScreen(),
            ),
          );
        },
        onDeleteStory: () => confirmDeleteStory(
          context: context,
          ref: ref,
          initialGroupIndex: initialGroupIndex,
          animationController: animationController,
          storyId: storyId,
        ),
      );
    },
  ).then((_) {
    animationController.forward();
  });
}

void showHighlightBottomSheet({
  required BuildContext context,
  required AnimationController animationController,
  required String currentMediaUrl,
}) {
  animationController.stop();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StoryHighlightSheet(
        currentMediaUrl: currentMediaUrl,
        onCompleted: (selectedHighlight) {
          // Completed silently
        },
      );
    },
  ).then((_) {
    animationController.forward();
  });
}

void showSendBottomSheet({
  required BuildContext context,
  required AnimationController animationController,
}) {
  animationController.stop();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StorySendSheetContent(
        onDismissed: () {},
      );
    },
  ).then((_) {
    animationController.forward();
  });
}

void showMentionBottomSheet({
  required BuildContext context,
  required AnimationController animationController,
}) {
  animationController.stop();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StoryMentionSheetContent(
        onDismissed: () {},
      );
    },
  ).then((_) {
    animationController.forward();
  });
}
