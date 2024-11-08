import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
class GalleryScreen extends StatelessWidget {
  final List<String> savedImages;  

  GalleryScreen({required this.savedImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galeria de Imagens'),
        backgroundColor: Colors.pink,
      ),
      
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red,   
              Colors.green,    
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,  
              crossAxisSpacing: 8.0, 
              mainAxisSpacing: 8.0, 
            ),
            itemCount: savedImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        insetPadding: EdgeInsets.all(0),
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.network(
                                savedImages[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: Icon(
                                  Icons.save_alt,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  // Implementar lógica de salvar a imagem
                                  // Exemplo: adicionar à lista de imagens salvas
                                  _baixarImagem(savedImages[index], context);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    savedImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }




Future<void> _baixarImagem(String imageUrl, BuildContext context) async {
  try {
    // Verifique se o dispositivo é Android 11 (API 30) ou superior
    PermissionStatus status;
    if (Platform.isAndroid && (await _getAndroidVersion() >= 30)) {
      status = await Permission.manageExternalStorage.request();
    } else {
      // Para Android abaixo do 11, solicita WRITE_EXTERNAL_STORAGE - Conmfirgurar la no AndroidManifest
      status = await Permission.storage.request();
    }
    if (status == PermissionStatus.granted) {
      print('Permissão concedida. Baixando imagem...');
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.bodyBytes),
          quality: 80,
          name: "imagem_${DateTime.now().millisecondsSinceEpoch}"
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imagem salva com sucesso na galeria!'),
              duration: Duration(seconds: 3),
            ),
          );
          print('Imagem salva com sucesso na galeria.');
        } else {
          throw Exception('Erro ao salvar a imagem na galeria.');
        }
      } else {
        throw Exception('Erro ao baixar a imagem. Status: ${response.statusCode}');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissão de armazenamento negada.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print('Erro ao salvar a imagem: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao salvar a imagem. Tente novamente.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Future<int> _getAndroidVersion() async {
  return int.parse((await Process.run('getprop', ['ro.build.version.sdk'])).stdout.toString().trim());
}
}