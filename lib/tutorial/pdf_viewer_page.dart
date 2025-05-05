// lib/tutorial/pdf_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerPage extends StatelessWidget {
  final String title;
  final String pdfAssetPath;

  const PDFViewerPage({
    Key? key,
    required this.title,
    required this.pdfAssetPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF27445D),
      ),
      body: SfPdfViewer.asset(pdfAssetPath),
    );
  }
}
