import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/image_retrieval_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đảm bảo tất cả các plugin đã được khởi tạo
  await SystemChannels.platform.invokeMethod<void>('SystemChrome.setPreferredOrientations', []);
  // DartVLC.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Text Retrieval',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const ImageRetrievalPage(),
    );
  }
}