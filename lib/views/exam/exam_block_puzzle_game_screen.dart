import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_theme.dart';
import '../../controllers/exam_controller.dart';
import '../../models.dart';
import '../../core/routes/app_routes.dart';

class Point2D {
  final int r;
  final int c;
  const Point2D(this.r, this.c);
}

class BlockPiece {
  final String id;
  final List<Point2D> cells;
  final Color color;
  final int width;
  final int height;

  BlockPiece({
    required this.id,
    required this.cells,
    required this.color,
  })  : width = cells.map((e) => e.c).reduce(max) + 1,
        height = cells.map((e) => e.r).reduce(max) + 1;
}

class PlacedCell {
  final Color color;
  PlacedCell(this.color);
}

class ExamBlockPuzzleGameScreen extends StatefulWidget {
  final String examId;

  const ExamBlockPuzzleGameScreen({
    super.key,
    required this.examId,
  });

  @override
  State<ExamBlockPuzzleGameScreen> createState() => _ExamBlockPuzzleGameScreenState();
}

class _ExamBlockPuzzleGameScreenState extends State<ExamBlockPuzzleGameScreen> {
  static const int rows = 8;
  static const int cols = 8;

  List<List<PlacedCell?>> _grid = List.generate(rows, (_) => List.filled(cols, null));
  List<BlockPiece> _availablePieces = [];
  
  int _score = 0;
  int _bestScore = 0;
  bool _isGameOver = false;

  bool _showingQuestion = false;
  Question? _currentQuestion;
  int _wrongAttempts = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('block_puzzle_best_score_${widget.examId}') ?? 0;
    });
  }

  Future<void> _saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('block_puzzle_best_score_${widget.examId}', score);
  }

  void _initGame() {
    final controller = context.read<ExamController>();
    if (controller.reviewQuestions.isEmpty) return;

    setState(() {
      _grid = List.generate(rows, (_) => List.filled(cols, null));
      _score = 0;
      _isGameOver = false;
      _showingQuestion = false;
      _wrongAttempts = 0;
      _generateNewPieces();
    });
  }

  void _generateNewPieces() {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFFF472B6), // Pink
      AppColors.success,
      AppColors.accent,
    ];

    final shapes = [
      // 1x1
      [const Point2D(0, 0)],
      // 2x1 horizontal
      [const Point2D(0, 0), const Point2D(0, 1)],
      // 1x2 vertical
      [const Point2D(0, 0), const Point2D(1, 0)],
      // 3x1 horizontal
      [const Point2D(0, 0), const Point2D(0, 1), const Point2D(0, 2)],
      // 1x3 vertical
      [const Point2D(0, 0), const Point2D(1, 0), const Point2D(2, 0)],
      // 2x2 square
      [const Point2D(0, 0), const Point2D(0, 1), const Point2D(1, 0), const Point2D(1, 1)],
      // L shape small
      [const Point2D(0, 0), const Point2D(1, 0), const Point2D(1, 1)],
      // L shape mirrored
      [const Point2D(0, 1), const Point2D(1, 1), const Point2D(1, 0)],
      // T shape
      [const Point2D(0, 0), const Point2D(0, 1), const Point2D(0, 2), const Point2D(1, 1)],
    ];

    _availablePieces = [];
    for (int i = 0; i < 3; i++) {
      final shape = shapes[_random.nextInt(shapes.length)];
      final color = colors[_random.nextInt(colors.length)];
      _availablePieces.add(BlockPiece(
        id: DateTime.now().microsecondsSinceEpoch.toString() + i.toString(),
        cells: shape,
        color: color,
      ));
    }
    _checkGameOver();
  }

  void _checkGameOver() {
    if (_availablePieces.isEmpty) return;
    
    bool canFitAny = false;
    for (final piece in _availablePieces) {
      if (_canFitAnywhere(piece)) {
        canFitAny = true;
        break;
      }
    }

    if (!canFitAny) {
      setState(() {
        _isGameOver = true;
      });
      if (_score > _bestScore) {
        _bestScore = _score;
        _saveBestScore(_score);
      }
    }
  }

  bool _canFitAnywhere(BlockPiece piece) {
    for (int r = 0; r <= rows - piece.height; r++) {
      for (int c = 0; c <= cols - piece.width; c++) {
        if (_canPlace(piece, r, c)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canPlace(BlockPiece piece, int startR, int startC) {
    for (final cell in piece.cells) {
      final targetR = startR + cell.r;
      final targetC = startC + cell.c;
      if (targetR < 0 || targetR >= rows || targetC < 0 || targetC >= cols) {
        return false;
      }
      if (_grid[targetR][targetC] != null) {
        return false;
      }
    }
    return true;
  }

  void _placePiece(BlockPiece piece, int startR, int startC) {
    setState(() {
      for (final cell in piece.cells) {
        final targetR = startR + cell.r;
        final targetC = startC + cell.c;
        _grid[targetR][targetC] = PlacedCell(piece.color);
      }
      _score += piece.cells.length;
      _availablePieces.removeWhere((p) => p.id == piece.id);

      _clearLines();

      if (_availablePieces.isEmpty) {
        _pickRandomQuestion();
      } else {
        _checkGameOver();
      }
    });
  }

  void _clearLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    for (int r = 0; r < rows; r++) {
      bool full = true;
      for (int c = 0; c < cols; c++) {
        if (_grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) rowsToClear.add(r);
    }

    for (int c = 0; c < cols; c++) {
      bool full = true;
      for (int r = 0; r < rows; r++) {
        if (_grid[r][c] == null) {
          full = false;
          break;
        }
      }
      if (full) colsToClear.add(c);
    }

    if (rowsToClear.isEmpty && colsToClear.isEmpty) return;

    for (final r in rowsToClear) {
      for (int c = 0; c < cols; c++) {
        _grid[r][c] = null;
      }
      _score += 10;
    }

    for (final c in colsToClear) {
      for (int r = 0; r < rows; r++) {
        _grid[r][c] = null;
      }
      _score += 10;
    }

    if (rowsToClear.length + colsToClear.length >= 2) {
      _score += 10; // Combo bonus
    }
  }

  void _pickRandomQuestion() {
    final controller = context.read<ExamController>();
    if (controller.reviewQuestions.isEmpty) {
      _generateNewPieces();
      return;
    }
    setState(() {
      _showingQuestion = true;
      _wrongAttempts = 0;
      _currentQuestion = controller.reviewQuestions[_random.nextInt(controller.reviewQuestions.length)];
    });
  }

  void _onAnswerOption(AnswerOption option) {
    if (_wrongAttempts >= 3) return; // Wait for user to tap next

    setState(() {
      if (option.isCorrect) {
        _score += 20;
        _showingQuestion = false;
        _generateNewPieces();
      } else {
        _score = max(0, _score - 5);
        _wrongAttempts++;
      }
    });
  }

  void _skipQuestion() {
    setState(() {
      _showingQuestion = false;
      _generateNewPieces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ExamController>();
    if (controller.reviewQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Khối hộp')),
        body: const Center(child: Text('Không đủ dữ liệu để chơi game.')),
      );
    }

    if (_isGameOver) {
      return _buildResultScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Khối hộp'),
        backgroundColor: Colors.transparent,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'High Score: $_bestScore',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Score Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Điểm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.muted)),
                Text('$_score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.ink)),
              ],
            ),
          ),
          
          Expanded(
            child: _showingQuestion ? _buildQuestionPanel() : _buildGameBoard(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth - 48; // padding
            final double cellSize = availableWidth / cols;

            return DragTarget<BlockPiece>(
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: cellSize * cols,
                  height: cellSize * rows,
                  decoration: BoxDecoration(
                    color: AppColors.line.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines and placed cells
                      for (int r = 0; r < rows; r++)
                        for (int c = 0; c < cols; c++)
                          Positioned(
                            left: c * cellSize,
                            top: r * cellSize,
                            width: cellSize,
                            height: cellSize,
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: _grid[r][c] != null ? _grid[r][c]!.color : AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.offset);
                
                // Details offset is the top-left of the dragged widget
                // However, depending on where they grabbed it, the offset might be slightly off.
                // We estimate the startRow and startCol by dividing the local Y and X by cellSize.
                // Adding half a cellSize helps center the drop target.
                int startR = ((localPosition.dy + cellSize / 2) / cellSize).floor();
                int startC = ((localPosition.dx + cellSize / 2) / cellSize).floor();

                final piece = details.data;

                if (_canPlace(piece, startR, startC)) {
                  _placePiece(piece, startR, startC);
                }
              },
            );
          },
        ),
        
        const Spacer(),
        
        // Available Pieces
        Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _availablePieces.map((piece) => _buildDraggablePiece(piece)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggablePiece(BlockPiece piece) {
    const double baseCellSize = 30.0;
    
    final pieceWidget = SizedBox(
      width: piece.width * baseCellSize,
      height: piece.height * baseCellSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: piece.cells.map((cell) {
          return Positioned(
            left: cell.c * baseCellSize,
            top: cell.r * baseCellSize,
            width: baseCellSize,
            height: baseCellSize,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: piece.color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: piece.color.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );

    return Draggable<BlockPiece>(
      data: piece,
      feedback: pieceWidget,
      childWhenDragging: Opacity(opacity: 0.2, child: pieceWidget),
      child: pieceWidget,
    );
  }

  Widget _buildQuestionPanel() {
    if (_currentQuestion == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.panel),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Trả lời để nhận khối mới',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
                  onPressed: _pickRandomQuestion,
                  tooltip: 'Đổi câu hỏi khác',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _currentQuestion!.content,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            
            if (_wrongAttempts > 0 && _wrongAttempts < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Sai rồi! Bạn còn ${3 - _wrongAttempts} lần thử.',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_wrongAttempts >= 3)
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rất tiếc! Đáp án đúng là:',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentQuestion!.options.firstWhere((o) => o.isCorrect, orElse: () => _currentQuestion!.options.first).content,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text('Giải thích:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _currentQuestion!.explanation.trim().isEmpty 
                          ? 'Chưa có lời giải chi tiết.' 
                          : _currentQuestion!.explanation,
                    ),
                  ],
                ),
              ),

            if (_wrongAttempts < 3)
              ..._currentQuestion!.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.line),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(16),
                    ),
                    onPressed: () => _onAnswerOption(option),
                    child: Text(option.content, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                );
              }),

            if (_wrongAttempts >= 3)
              ElevatedButton(
                onPressed: _skipQuestion,
                child: const Text('Tiếp tục'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.extension_rounded, size: 80, color: Color(0xFFF472B6)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Hết chỗ trống!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF472B6),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Điểm của bạn', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted)),
                        Text('$_score', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kỷ lục', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted)),
                        Text('$_bestScore', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF472B6)),
                onPressed: _initGame,
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
