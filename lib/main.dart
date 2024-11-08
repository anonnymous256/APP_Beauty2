import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';

void main() {
  runApp(HairstyleChangerApp());
}

class HairstyleChangerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hairstyle Changerr',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HairstyleChangerScreen(),
    );
  }
}

class HairstyleChangerScreen extends StatefulWidget {
  @override
  _HairstyleChangerScreenState createState() => _HairstyleChangerScreenState();
}

class EstilosCabelo {
  final String name;
  final String imagePath;
  final String description;

  EstilosCabelo(this.name, this.imagePath, this.description);
}

class _HairstyleChangerScreenState extends State<HairstyleChangerScreen> {
  File? _selectedImage;
  final picker = ImagePicker();
  String? _taskId;
  String? _imageUrl;
  String _selectedStyle = '';
  final List<String> _savedImages = [];
  String _imageUrl2 = 'https://ailab-result-rapidapi.oss-accelerate.aliyuncs.com/faceBody/hairstyle/2024-11-08/Spiked_20241108210932106252_ilokdr1o57mf3n110h4d.jpeg';

  final List<EstilosCabelo> _EstilosCabeloOptions = [
    EstilosCabelo(
        'ShortPixieWithShavedSides',
        'lib/assets/img/Cabelo_ShortPixieWithShavedSides.png',
        'Laterais Raspadas'),
    EstilosCabelo('ShortNeatBob', 'lib/assets/img/Cabelo_ShortNeatBob.png',
        'Curto Elegante'),
    EstilosCabelo(
        'DoubleBun', 'lib/assets/img/Cabelo_DoubleBun.png', 'Coque Duplo'),
    EstilosCabelo('Updo', 'lib/assets/img/Cabelo_Updo.png', 'Cabelo Preso'),
    EstilosCabelo(
        'Spiked', 'lib/assets/img/Cabelo_Spiked.png', 'Cabelo Espetado'),
    EstilosCabelo(
        'bowlCut', 'lib/assets/img/Cabelo_bowlCut.png', 'Cortado em Tigela'),
    EstilosCabelo(
        'Chignon', 'lib/assets/img/Cabelo_Chignon.png', 'Cabelo Chignon'),
    EstilosCabelo(
        'PixieCut', 'lib/assets/img/Cabelo_PixedCut.png', 'Cabelo Pixie Cut'),
  ];

  void _mostrarImagemDaTarefa() {
  setState(() {
    // Exibe diretamente a imagem ao pressionar o botão
    _imageUrl = 'https://ailab-result-rapidapi.oss-accelerate.aliyuncs.com/faceBody/hairstyle/2024-11-08/Spiked_20241108210932106252_ilokdr1o57mf3n110h4d.jpeg';
  });
}


  Future<void> _EscolherImagem() async {
    if (_selectedStyle.isEmpty) {
      _mostrarAlerta(
          "Por favor, selecione um estilo de cabelo antes de escolher uma imagem.");
      return;
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _EnviarImagem();
      }
    }
  }

  Future<void> _TirarImagem() async {
    if (_selectedStyle.isEmpty) {
      _mostrarAlerta(
          "Por favor, selecione um estilo de cabelo antes de tirar uma foto.");
      return;
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        _EnviarImagem();
      }
    }
  }

  void _mostrarAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Atenção"),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _adicionarImagem() {
    if (_imageUrl != null) {
      print('imagem adicionada:$_imageUrl');
      setState(() {
        _savedImages.add(_imageUrl!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imagem adicionada à lista com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhuma imagem para adicionar.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _exibirImagensSalvas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Imagens Salvas'),
          content: SingleChildScrollView(
            child: Column(
              children: _savedImages.map((imageUrl) {
                return Row(
                  children: [
                    Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: Icon(Icons.download),
                      onPressed: () => _baixarImagem(imageUrl, context),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

 

Future<void> _baixarImagem(String imageUrl, BuildContext context) async {
  try {
    // Verifique se o dispositivo é Android 11 (API 30) ou superior
    PermissionStatus status;
    if (Platform.isAndroid && (await _getAndroidVersion() >= 30)) {
      status = await Permission.manageExternalStorage.request();
    } else {
      // Para Android abaixo do 11, solicita WRITE_EXTERNAL_STORAGE
      status = await Permission.storage.request();
    }
    
    if (status == PermissionStatus.granted) {
      print('Permissão concedida. Baixando imagem...');
      
      // Faz o download da imagem
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        // Salva a imagem na galeria
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





  // Envia a imagem para a API e obtem o resultado
  Future<void> _EnviarImagem() async {
    if (_selectedStyle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecione um estilo de cabelo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final url = Uri.parse(
        'https://hairstyle-changer-pro.p.rapidapi.com/facebody/editing/hairstyle-pro');
    final headers = {
      'X-Rapidapi-Key': '55700dbf37msh5e248cb1508858ep146cd9jsnf3c5b7fd107f',
      'X-Rapidapi-Host': 'hairstyle-changer-pro.p.rapidapi.com',
    };

    try {
      var request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers)
        ..fields['task_type'] = 'async'
        ..fields['hair_style'] = _selectedStyle
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
          filename: 'user_image.jpg',
        ));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = json.decode(responseData);
        setState(() {
          _taskId = decodedData['task_id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagem processada com sucesso'),
            duration: Duration(seconds: 2),
          ),
        );

        //  Recupera a imagem a cada 5 segundos
        await _RecuperarImagemPeriodicamente();
      } else {
        final responseData = await response.stream.bytesToString();
        print('Erro ao enviar imagem. Status: ${response.statusCode}');
        print('Resposta da API: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar a imagem'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao enviar a imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar a imagem. Tente novamente'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// Funcao para recuperação da imagem com delei de 5 em 5 segundos
  Future<void> _RecuperarImagemPeriodicamente() async {
    if (_taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhuma tarefa pendente para recuperação de imagem.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Timer.periodic(Duration(seconds: 5), (timer) async {
      final url = Uri.parse(
          'https://hairstyle-changer-pro.p.rapidapi.com/api/rapidapi/query-async-task-result?task_id=$_taskId');
      final headers = {
        'X-Rapidapi-Key': '55700dbf37msh5e248cb1508858ep146cd9jsnf3c5b7fd107f',
        'X-Rapidapi-Host': 'hairstyle-changer-pro.p.rapidapi.com',
      };

      try {
        final response = await http.get(url, headers: headers);
        if (response.statusCode == 200) {
          final decodedData = json.decode(response.body);
          if (decodedData['error_code'] == 0 &&
              decodedData['task_status'] == 2) {
            if (decodedData['data'] != null &&
                decodedData['data']['images'] != null) {
              setState(() {
                _imageUrl = decodedData['data']['images'][0];
              });
              timer.cancel(); // cancela o temporizadro
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Não foi possível recuperar a imagem processada.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          print('Erro ao recuperar a imagem: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao recuperar a imagem.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Erro ao recuperar imagem: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao recuperar a imagem.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Função para exibir o Dialog com os estilos de cabelo
  void _showStyleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione um Estilo de Cabelo'),
          content: SingleChildScrollView(
            child: Column(
              children: _EstilosCabeloOptions.map((estilo) {
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedStyle = estilo.name;
                      _taskId = null;
                      _imageUrl = null;
                    });
                    Navigator.of(context).pop();
                    if (_selectedImage != null) {
                      await _EnviarImagem();
                    }
                  },
                  child: Card(
                    elevation: 4,
                    color: _selectedStyle == estilo.name
                        ? Colors.pink.shade200
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.pink, width: 1),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset(
                          estilo.imagePath,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 10),
                        Text(
                          estilo.description,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Mudança de Cabelo'),
        centerTitle: true,
        backgroundColor: Colors.pink,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink.shade400, width: 3),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageUrl != null
                        ? Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'lib/assets/img/selecione3.webp',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Selecione um estilo de cabelo:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade600,
                ),
              ),
              SizedBox(height: 10),
              _buildButton(
                text: 'Escolher Estilo',
                color: Colors.pink.shade600,
                onPressed: _showStyleDialog,
                textocor: Colors.white,
              ),
              SizedBox(height: 20),
              Divider(thickness: 1, color: Colors.pink.shade200),
              SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionButton('Selecionar Imagem', _EscolherImagem),
                  _buildActionButton('Tirar Foto', _TirarImagem),
                ],
              ),
              SizedBox(height: 30),
              if (_imageUrl != null)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          insetPadding: EdgeInsets.all(0),
                          child: InteractiveViewer(
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Card(
                    color: Colors.pink.shade50,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'Nenhuma imagem recuperada',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

              // Botões de ação
              SizedBox(height: 20),
              _buildButton(
                text: 'Adicionar Lista',
                color: Colors.pink.shade600,
                onPressed: _adicionarImagem,
                textocor: Colors.white,
              ),
              SizedBox(height: 20),
              _buildButton(
                text: 'Recuperar Imagem',
                color: Colors.pink.shade600,
                onPressed: _exibirImagensSalvas,
                textocor: Colors.white,
              ),
              _buildButton(
                text: 'Mostrar Imagem da Tarefa',
                color: Colors.pink.shade600,
                onPressed: _mostrarImagemDaTarefa,
                textocor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // funcao para construir os botoes
  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFBF55EC),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 5,
      ),
      icon: Icon(Icons.photo, size: 18),
      label: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildButton(
      {required String text,
      required Color color,
      required VoidCallback onPressed,
      required Color textocor}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textocor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 5,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
