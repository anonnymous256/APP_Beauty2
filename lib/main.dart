import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:async';
import 'galeria.dart';

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
          _imageUrl = null;
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
          _imageUrl = null;
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
      'X-Rapidapi-Key': '8079d63219msh1992ba512dcacdap10779djsndc05125d4009',
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
        'X-Rapidapi-Key': '8079d63219msh1992ba512dcacdap10779djsndc05125d4009',
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
    extendBody: true,
    body: Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 254, 238, 238),
            Color.fromARGB(255, 254, 238, 238),
          ],
        ),
      ),
      child: Padding(
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
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
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
                  _buildButton(
                    text: 'Selecione Foto',
                    color: Colors.pink.shade600,
                    onPressed: _EscolherImagem,
                    textocor: Colors.white,
                  ),
                  _buildButton(
                    text: 'Tirar foto',
                    color: Colors.pink.shade600,
                    onPressed: _TirarImagem,
                    textocor: Colors.white,
                  ),
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
child: Stack(
  children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
      ),
    ),
    Positioned(
      bottom: -10,  
      right: -10,   
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.add_circle,
            color: Colors.pink.shade600,
            size: 30,
          ),
          onPressed: _adicionarImagem,
        ),
      ),
    ),
  ],
)
                    

                    ),
                  ),
                )
              else
                Text(
                  'Nenhuma imagem recuperada',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
         
          IconButton(
            icon: Icon(Icons.image_search, color: Colors.pink.shade600),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GalleryScreen(savedImages: _savedImages)),
              );
            },
            iconSize: 36,
          ),
        ],
      ),
    ),
  );
}




  // funcao para construir os botoes
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
