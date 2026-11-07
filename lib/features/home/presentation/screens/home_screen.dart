import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_text_styles.dart';
import 'package:flutter_app/core/theme/app_input_styles.dart';
import 'package:flutter_app/features/home/presentation/screens/book_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/statistics_block.dart';
import 'package:flutter_app/features/home/presentation/widgets/target_block.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> openFiles(BuildContext context) async {
    final List<PlatformFile> results = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (results.single.path == null) return;
    String filePath = results.single.path!;
    if (context.mounted && filePath != '') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookReaderScreen(filePath: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedData = DateFormat(
      'EEEE, d MMMM',
      'ru_RU',
    ).format(DateTime.now());
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedData.toUpperCase(),
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      const Text("Моя полка", style: AppTextStyles.title),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/def_avatar.jpg'),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              decoration: AppInputStyles.search(
                label: 'Найти книгу или цитату',
              ),
            ),
          ),
          TargetBlock(key: key, total: 16, current: 7),
          StatisticsBlock(key: key),
          Container(
            margin: EdgeInsets.all(24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
              ),
              onPressed: () => openFiles(context),
              child: Text('Открыть файлы'),
            ),
          ),
        ],
      ),
    );
  }
}
