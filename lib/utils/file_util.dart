import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

Future<File> fileFromUrl(String imageUrl) async {
  // generate random number.
  final rng = Random();

  // get temporary directory of device.
  final tempDir = await getTemporaryDirectory();

  // get temporary path from temporary directory.
  final tempPath = tempDir.path;

  // create a new file in temporary path with random file name.
  final file = File('$tempPath${rng.nextInt(100)}');

  // call http.get method and pass imageUrl into it to get response.
  final response = await Dio().get<List<int>>(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );

  // write bodyBytes received in response to file.
  await file.writeAsBytes(response.data!);
  return file;
}

bool isUrl(String path) {
  return path.startsWith(RegExp(r'https?:\/\/'));
}
