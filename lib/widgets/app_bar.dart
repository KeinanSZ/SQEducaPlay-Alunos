import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../theme/design_tokens.dart';
import '../services/user_service.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showProfileAvatar;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  const AppTopBar({
    super.key,
    required this.title,
    this.showProfileAvatar = true,
    this.showBackButton = true,
    this.actions,
    this.bottom,
  });

  String _initialFor(User? user) {
    final name = user?.fullName.trim() ?? '';
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final username = user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      return username[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService().currentUser;
    final allActions = <Widget>[];
    if (actions != null) allActions.addAll(actions!);
    if (showProfileAvatar) {
      Widget avatarChild;
      final photoPath = user?.profilePhotoPath;
      if (photoPath != null && photoPath.isNotEmpty) {
        try {
          final file = File(photoPath);
          if (file.existsSync()) {
            avatarChild = ClipOval(
              child: Image.file(
                file,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            );
          } else {
            avatarChild = Text(
              _initialFor(user),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          }
        } catch (_) {
          avatarChild = Text(
            _initialFor(user),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        }
      } else {
        avatarChild = Text(
          _initialFor(user),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        );
      }

      allActions.add(
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () {},
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: avatarChild,
            ),
          ),
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
      backgroundColor: DesignTokens.primary,
      actions: allActions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
