import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../controllers/exam_controller.dart';
import '../../core/routes/app_routes.dart';

class ReviewGameItem {
  final String prompt;
  final List<String> options;
  final String correctOption;

  ReviewGameItem({
    required this.prompt,
    required this.options,
    required this.correctOption,
  });
}

class ExamBlastGameScreen extends StatefulWidget {
  final String examId;

  const ExamBlastGameScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamBlastGameScreen> createState() => _ExamBlastGameScreenState();
}

class _ExamBlastGameScreenState extends State<ExamBlastGameScreen> {
  List<ReviewGameItem> _items = [];
  int _currentIndex = 0;
  int _score = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isGameOver = false;

  String? _feedbackMessage;
  Color _feedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  void _initGame() {
    final controller = context.read<ExamController>();
    if (controller.reviewQuestions.isEmpty) return;

    _items = controller.reviewQuestions.map((q) {
      final correctOpt = q.options.firstWhere(
        (o) => o.isCorrect,
        orElse: () => q.options.first,
      );
      
      final optionsText = q.options.map((o) => o.content).toList();
      optionsText.shuffle(Random());

      return ReviewGameItem(
        prompt: q.content,
        options: optionsText,
        correctOption: correctOpt.content,
      );
    }).toList();

    _items.shuffle(Random());
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _remainingSeconds = 60;
      _isGameOver = false;
      _feedbackMessage = null;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isGameOver = true;
    });
  }

  void _onOptionTap(String selectedOption) {
    if (_isGameOver || _items.isEmpty) return;

    final currentItem = _items[_currentIndex];
    final isCorrect = selectedOption == currentItem.correctOption;

    setState(() {
      if (isCorrect) {
        _score += 10;
        _correctCount++;
        _feedbackMessage = '+10';
        _feedbackColor = AppColors.success;
      } else {
        _wrongCount++;
        _remainingSeconds = max(0, _remainingSeconds - 5);
        _feedbackMessage = '-5s';
        _feedbackColor = AppColors.error;
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _feedbackMessage = null;
        if (isCorrect) {
          if (_currentIndex < _items.length - 1) {
            _currentIndex++;
          } else {
            _endGame();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Blast Game')),
        body: const Center(child: Text('Không đủ dữ liệu để chơi game.')),
      );
    }

    if (_isGameOver) {
      return _buildResultScreen();
    }

    final currentItem = _items[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark space background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                const SizedBox(width: 4),
                Text('$_score', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.timer_rounded, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  '${_remainingSeconds}s',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds <= 10 ? Colors.redAccent : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Prompt area
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.panel),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                currentItem.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),

          // Options / Asteroids
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currentItem.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _onOptionTap(option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Feedback overlay
          if (_feedbackMessage != null)
            Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: _feedbackColor,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final totalAnswered = _correctCount + _wrongCount;
    final accuracy = totalAnswered > 0 ? (_correctCount / totalAnswered * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.rocket_launch_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Kết quả trò chơi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.panel),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    _ResultRow(label: 'Điểm số', value: '$_score', valueColor: AppColors.primary),
                    const Divider(height: 24),
                    _ResultRow(label: 'Số câu đúng', value: '$_correctCount', valueColor: AppColors.success),
                    const SizedBox(height: 8),
                    _ResultRow(label: 'Số câu sai', value: '$_wrongCount', valueColor: AppColors.error),
                    const Divider(height: 24),
                    _ResultRow(label: 'Độ chính xác', value: '$accuracy%', valueColor: AppColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Chơi lại'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  final exam = context.read<ExamController>().reviewExam;
                  if (exam != null) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.studentExamTaking,
                      arguments: exam,
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu làm bài'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Quay lại ôn tập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
