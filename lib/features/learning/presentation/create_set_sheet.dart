import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/learning_providers.dart';

class CreateSetSheet extends ConsumerStatefulWidget {
  const CreateSetSheet({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<CreateSetSheet> createState() => _CreateSetSheetState();
}

class _CreateSetSheetState extends ConsumerState<CreateSetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _rawTextController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(firestoreRepositoryProvider)
          .createLearningSet(
            widget.uid,
            _titleController.text.trim(),
            _rawTextController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final errorStr = error.toString();
      if (errorStr.contains('free_limit_reached')) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade to Premium to create more than 3 sets'),
          ),
        );
        return;
      }

      setState(() {
        _errorMessage = errorStr.replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Learning Set',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Biology Unit 1',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rawTextController,
                  minLines: 8,
                  maxLines: 14,
                  decoration: const InputDecoration(
                    labelText: 'Source Text',
                    alignLabelWithHint: true,
                    hintText: 'Paste your notes, paragraph, or chapter content here.',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Source text is required';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Set'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
