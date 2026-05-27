import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';

// IMPORTACIÓN CONDICIONAL NATIVA (Moderno y sin librerías externas)
import 'save_file_stub.dart'
    if (dart.library.io) 'save_file_mobile.dart'
    if (dart.library.js_interop) 'save_file_web.dart';

abstract class ExcelTools {
  /// Convierte una lista de textos en una lista de TextCellValue para
  /// insertarla en un excel
  static List<TextCellValue> toTextCellValue(List<String> list) {
    return list.map((element) => TextCellValue(element)).toList();
  }

  static Future<void> generateFile(
    BuildContext context,
    Excel excel,
    String appName,
  ) async {
    // Nombre del archivo
    String excelName =
        '${appName}_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    // Obtener bytes codificados del Excel
    List<int>? fileBytes = excel.encode();

    if (fileBytes != null) {
      // Llamada única multiplataforma. Dart sabe cuál usar por detrás.
      await saveAndLaunchFile(Uint8List.fromList(fileBytes), excelName);

      // Asegurar que el contexto sigue activo antes de interactuar con la UI
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo excel exportado: $excelName')),
        );
      }
    }
  }
}
