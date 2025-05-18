import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Supabase client
  final supabase = Supabase.instance.client;

  // User count state
  int userCount = 0;
  bool isLoading = true;
  String? errorMessage;
  double? growthRate;

  // New users data for bar chart
  List<UserGrowthData> userGrowthData = [];
  bool isLoadingChart = true;

  // Quiz game data for pie chart
  Map<String, QuizResultData> quizResultsData = {
    'Google Meet': QuizResultData(passed: 87, failed: 23),
    'Zoom': QuizResultData(passed: 76, failed: 34),
    'Gmail': QuizResultData(passed: 92, failed: 18),
    'Viber': QuizResultData(passed: 64, failed: 46),
    'WhatsApp': QuizResultData(passed: 83, failed: 27),
    'Cliqq': QuizResultData(passed: 59, failed: 51),
  };
  String selectedQuizPlatform = 'Google Meet';

  @override
  void initState() {
    super.initState();
    // Fetch user count when the page loads
    fetchUserCount();
    fetchUserGrowthData();
  }

  // Function to fetch user count from Supabase
  Future<void> fetchUserCount() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get current user count
      final response = await supabase.from('users').select('id');

      // Get count from one month ago for growth calculation
      final DateTime oneMonthAgo = DateTime.now().subtract(
        const Duration(days: 30),
      );
      final pastResponse = await supabase
          .from('users')
          .select('id')
          .lt('created_at', oneMonthAgo.toIso8601String());

      // Calculate current count and growth rate
      final currentCount = response.length;
      final pastCount = pastResponse.length;

      double growth = 0;
      if (pastCount > 0) {
        growth = ((currentCount - pastCount) / pastCount) * 100;
      }

      setState(() {
        userCount = currentCount;
        growthRate = growth;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load user count: ${e.toString()}';
        isLoading = false;
      });
      debugPrint('Error fetching user count: $e');
    }
  }

  // Function to fetch user growth data (new users over time)
  Future<void> fetchUserGrowthData() async {
    try {
      setState(() {
        isLoadingChart = true;
      });

      // Get data for the last 6 months
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      // Format date to ISO string for Supabase query
      final fromDate = sixMonthsAgo.toIso8601String();

      // Query users created after our starting date
      final response = await supabase
          .from('users')
          .select('created_at')
          .gte('created_at', fromDate)
          .order('created_at', ascending: true);

      // Group by month
      Map<String, int> monthlyCounts = {};

      // Initialize the last 6 months with zero counts
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('yyyy-MM').format(month);
        monthlyCounts[monthKey] = 0;
      }

      // Count users by creation month
      for (final user in response) {
        final createdAt = DateTime.parse(user['created_at']);
        final monthKey = DateFormat('yyyy-MM').format(createdAt);

        if (monthlyCounts.containsKey(monthKey)) {
          monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
        } else {
          monthlyCounts[monthKey] = 1;
        }
      }

      // Convert to our data class format
      List<UserGrowthData> data = [];
      monthlyCounts.forEach((monthKey, count) {
        final parts = monthKey.split('-');
        final month = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
        data.add(UserGrowthData(month: month, newUsers: count));
      });

      // Sort by date
      data.sort((a, b) => a.month.compareTo(b.month));

      setState(() {
        userGrowthData = data;
        isLoadingChart = false;
      });
    } catch (e) {
      debugPrint('Error fetching user growth data: $e');
      setState(() {
        isLoadingChart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FF), // Ghost white color
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed header section
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Data Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27445D),
                ),
              ),
            ),

            // User count tracking box - with loading state
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.symmetric(
                vertical: 14.0,
                horizontal: 20.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF3B6EA5).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B6EA5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF3B6EA5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Users',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B6EA5),
                            ),
                          ),
                        )
                      else if (errorMessage != null)
                        const Text(
                          'Error loading data',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        )
                      else
                        Text(
                          userCount.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B6EA5),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (!isLoading && errorMessage == null && growthRate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            growthRate! >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            growthRate! >= 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: growthRate! >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${growthRate!.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color:
                                  growthRate! >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isLoading || errorMessage != null)
                    Container(
                      width: 70, // Maintain consistent width
                    ),
                ],
              ),
            ),

            // Refresh button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  fetchUserCount();
                  fetchUserGrowthData();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B6EA5),
                ),
              ),
            ),

            // Analytics Overview Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: const Text(
                'Analytics Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B6EA5),
                ),
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // New Users Bar Chart - UPDATED WITH ENHANCED CHART
                    Container(
                      height: 320,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3B6EA5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Monthly growth analysis',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          if (isLoadingChart)
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            Expanded(
                              // Using the enhanced UserGrowthChart
                              child: UserGrowthChart(data: userGrowthData),
                            ),
                        ],
                      ),
                    ),

                    // Quiz Game Results Pie Chart
                    Container(
                      height: 320,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF3B6EA5).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Game Quiz Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B6EA5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pass/Fail rates by platform',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Platform selector
                          SizedBox(
                            height: 48,
                            child: DropdownButtonFormField<String>(
                              value: selectedQuizPlatform,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              items:
                                  quizResultsData.keys.map((platform) {
                                    return DropdownMenuItem<String>(
                                      value: platform,
                                      child: Text(platform),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedQuizPlatform = value;
                                  });
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Pie chart and legend
                          Expanded(
                            child: Row(
                              children: [
                                // Pie chart on the left
                                Expanded(
                                  flex: 3,
                                  child: QuizResultsPieChart(
                                    data:
                                        quizResultsData[selectedQuizPlatform]!,
                                  ),
                                ),

                                // Legend on the right
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Passed indicator
                                      Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF3B6EA5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Passed',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Failed indicator
                                      Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFE57373),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Failed',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Stats
                                      Text(
                                        'Total: ${quizResultsData[selectedQuizPlatform]!.total}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Pass Rate: ${quizResultsData[selectedQuizPlatform]!.passRate.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B6EA5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserGrowthChart extends StatefulWidget {
  final List<UserGrowthData> data;

  const UserGrowthChart({Key? key, required this.data}) : super(key: key);

  @override
  State<UserGrowthChart> createState() => _UserGrowthChartState();
}

class _UserGrowthChartState extends State<UserGrowthChart> {
  // Scroll controller for the horizontal chart
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find max value for scaling, with a minimum default of 10
    double maxValue = 10.0;
    if (widget.data.isNotEmpty) {
      final max = widget.data
          .map((e) => e.newUsers.toDouble())
          .reduce((a, b) => a > b ? a : b);
      // Add 20% padding to the max value and round to next multiple of 5
      maxValue = (max * 1.2);
      maxValue = (maxValue / 5).ceil() * 5.0;
    }

    // Create a list with all 12 months for the year
    List<UserGrowthData> fullYearData = [];

    // If data is not empty, fill in a full year of data
    if (widget.data.isNotEmpty) {
      // Determine the year to use (from the first data point)
      final int year = widget.data.first.month.year;

      // Create map of existing data for quick lookup
      Map<int, int> monthDataMap = {};
      for (var item in widget.data) {
        monthDataMap[item.month.month] = item.newUsers;
      }

      // Create a full year of data (January to December)
      for (int month = 1; month <= 12; month++) {
        fullYearData.add(
          UserGrowthData(
            month: DateTime(year, month, 1),
            newUsers: monthDataMap[month] ?? 0, // Use 0 if no data for month
          ),
        );
      }
    } else {
      // If no data, just use current year with zeros
      final int currentYear = DateTime.now().year;
      for (int month = 1; month <= 12; month++) {
        fullYearData.add(
          UserGrowthData(month: DateTime(currentYear, month, 1), newUsers: 0),
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate bar width and total content width
        final double barWidth = constraints.maxWidth * 0.1;
        final double barSpacing = barWidth * 0.5;

        // Calculate the total width needed for all 12 months
        final double totalWidth = (barWidth + barSpacing) * 12;

        // Minimum width is the constraint width, but could be larger
        final double contentWidth = math.max(constraints.maxWidth, totalWidth);

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 40.0, // Space for y-axis labels
                  right: 10.0,
                  bottom: 5.0,
                  top: 20.0, // Space for bar value labels
                ),
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white,
                        Colors.white,
                        Colors.white.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: CustomPaint(
                        size: Size(contentWidth, constraints.maxHeight * 0.85),
                        painter: BarChartPainter(
                          data: fullYearData,
                          maxValue: maxValue,
                          barWidth: barWidth,
                          barSpacing: barSpacing,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Month labels at the bottom - also scrollable
            SizedBox(
              height: 22,
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 10.0),
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white,
                        Colors.white,
                        Colors.white.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.05, 0.95, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    controller: _scrollController, // Use the same controller
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: contentWidth,
                      child: Row(
                        children: List.generate(fullYearData.length, (index) {
                          return SizedBox(
                            width: barWidth + barSpacing,
                            child: Center(
                              child: Text(
                                DateFormat(
                                  'MMM',
                                ).format(fullYearData[index].month),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Year label at the bottom
            SizedBox(
              height: 20,
              child: Padding(
                padding: const EdgeInsets.only(left: 40.0, right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (fullYearData.isNotEmpty)
                      Text(
                        fullYearData.first.month.year.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<UserGrowthData> data;
  final double maxValue;
  final double barWidth;
  final double barSpacing;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barWidth,
    required this.barSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Draw horizontal grid lines
    final int gridLines = 5;
    final Paint gridPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..strokeWidth = 1;

    for (int i = 0; i <= gridLines; i++) {
      final double y = height - (height / gridLines * i);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Drawing the values as simple text outside the chart area
      final String valueText = ((maxValue / gridLines) * i).toInt().toString();

      // Simple approach - draw a small rectangle with the value next to it
      final Paint textBgPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      // Draw a small background for the text to make it more readable
      canvas.drawRect(Rect.fromLTWH(-35, y - 7, 30, 14), textBgPaint);

      // Use drawParagraph instead of TextPainter
      final ui.ParagraphBuilder paragraphBuilder =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.right,
                fontSize: 10,
                maxLines: 1,
              ),
            )
            ..pushStyle(ui.TextStyle(color: Colors.grey))
            ..addText(valueText);

      final ui.Paragraph paragraph =
          paragraphBuilder.build()
            ..layout(const ui.ParagraphConstraints(width: 30));

      canvas.drawParagraph(paragraph, Offset(-35, y - 7));
    }

    // Draw bars with fixed width and spacing
    final Paint barPaint =
        Paint()
          ..color = const Color(0xFF3B6EA5)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final double barHeight = (data[i].newUsers / maxValue) * height;
      // Position bars with consistent spacing
      final double x = i * (barWidth + barSpacing);

      final Rect barRect = Rect.fromLTWH(
        x,
        height - barHeight,
        barWidth,
        barHeight,
      );
      final RRect roundedRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(roundedRect, barPaint);

      // Draw value on top of the bar if it's non-zero (optional)
      if (data[i].newUsers > 0) {
        final ui.ParagraphBuilder valueParagraphBuilder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.center,
                  fontSize: 10,
                  maxLines: 1,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: const Color(0xFF3B6EA5),
                  fontWeight: ui.FontWeight.bold,
                ),
              )
              ..addText(data[i].newUsers.toString());

        final ui.Paragraph valueParagraph =
            valueParagraphBuilder.build()
              ..layout(ui.ParagraphConstraints(width: barWidth));

        // Only show the value if the bar is tall enough
        if (barHeight > 25) {
          canvas.drawParagraph(
            valueParagraph,
            Offset(x, height - barHeight - 16),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Quiz Results Pie Chart Widget
class QuizResultsPieChart extends StatelessWidget {
  final QuizResultData data;

  const QuizResultsPieChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PieChartPainter(passed: data.passed, failed: data.failed),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${data.passRate.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B6EA5),
              ),
            ),
            const Text(
              'Pass Rate',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final int passed;
  final int failed;

  PieChartPainter({required this.passed, required this.failed});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = (passed + failed).toDouble();
    final double passedAngle = 2 * math.pi * (passed / total);

    final Paint passedPaint =
        Paint()
          ..color = const Color(0xFF3B6EA5)
          ..style = PaintingStyle.fill;

    final Paint failedPaint =
        Paint()
          ..color = const Color(0xFFE57373)
          ..style = PaintingStyle.fill;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.4;

    // Draw passed section
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      passedAngle,
      true,
      passedPaint,
    );

    // Draw failed section
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + passedAngle, // Start after passed section
      2 * math.pi - passedAngle,
      true,
      failedPaint,
    );

    // Draw inner circle for donut effect
    final Paint innerCirclePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * 0.6, // Inner circle radius
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data Classes
class UserGrowthData {
  final DateTime month;
  final int newUsers;

  UserGrowthData({required this.month, required this.newUsers});
}

class QuizResultData {
  final int passed;
  final int failed;

  QuizResultData({required this.passed, required this.failed});

  int get total => passed + failed;
  double get passRate => (passed / total) * 100;
}
