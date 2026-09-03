import 'package:flutter/material.dart';

class SelectedFundamentalLessonScreen extends StatefulWidget {
  const SelectedFundamentalLessonScreen({
    super.key,
    required this.title,
    required this.slides,
  });

  final String title;
  final List<Map<String, dynamic>> slides;

  @override
  State<SelectedFundamentalLessonScreen> createState() =>
      _SelectedFundamentalLessonScreenState();
}

class _SelectedFundamentalLessonScreenState
    extends State<SelectedFundamentalLessonScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.slides.isEmpty
          ? const Center(child: Text('This lesson has no slides yet.'))
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.slides.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) =>
                          _buildSlide(widget.slides[index]),
                    ),
                  ),
                ),
                _buildControls(),
              ],
            ),
    );
  }

  Widget _buildControls() {
    final isFirstSlide = _currentPage == 0;
    final isLastSlide = _currentPage == widget.slides.length - 1;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: isFirstSlide
                  ? null
                  : () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentPage ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: isLastSlide
                  ? null
                  : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
              label: Text(isLastSlide ? 'Complete' : 'Next'),
              icon: Icon(isLastSlide ? Icons.check : Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    final type = slide['type'] as String?;
    final theme = Theme.of(context);

    if (type == 'image') {
      final imageUrl = slide['imageUrl'] as String? ?? '';
      if (imageUrl.isEmpty) {
        return const Center(child: Text('This slide image is unavailable.'));
      }

      return Card(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          child: Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) =>
                  loadingProgress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Unable to load this slide image.')),
            ),
          ),
        ),
      );
    }

    if (type == 'text') {
      return Card(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Text(
              slide['content'] as String? ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(height: 1.45),
            ),
          ),
        ),
      );
    }

    return const Center(child: Text('This slide format is not supported.'));
  }
}
