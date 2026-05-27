import 'dart:io' as io;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<void> saveAndLaunchFile(Uint8List bytes, String fileName) async {
  io.Directory? targetDir = await getDownloadsDirectory();
  
  // Respaldo en móviles si Downloads devuelve null
  if (targetDir == null) {
    targetDir = await getApplicationDocumentsDirectory();
  }

  // Separador universal '/' compatible con Windows/Android/iOS
  String excelPath = '${targetDir.path}/$fileName';
  
  io.File(excelPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}
