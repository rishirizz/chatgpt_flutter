import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/constants.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final urlController = TextEditingController();
  final commandController = TextEditingController();
  final codeController = TextEditingController();
  String? message;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  bool isApiCallProcess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'CHAT GPT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.deepPurple,
                Colors.deepPurple.shade200,
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                // _messages.clear();
              });
            },
            child: Row(
              children: const [
                Icon(Icons.clear_all),
                Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: urlController,
                            decoration: const InputDecoration(
                              labelText: 'URL Name',
                              hintText: 'google.com',
                            ),
                            validator: (value) {
                              if (value!.length < 2 && value.length == 1) {
                                return 'Please enter proper url name.';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              urlController.text = value!;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: commandController,
                            decoration: const InputDecoration(
                              labelText: 'Test Step',
                              hintText:
                                  'Specify the actions to be performed in details.',
                            ),
                            validator: (value) {
                              if (value!.length < 2 && value.length == 1) {
                                return 'Please specify the steps properly.';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              commandController.text = value!;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            controller: codeController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: 'Langauge Used',
                              hintText: 'For eg: Java, Dart etc.',
                            ),
                            validator: (value) {
                              if (value == 'C' || value == 'c') {
                                return null;
                              } else if (value!.length < 2 &&
                                  value.length == 1) {
                                return 'Specify the language.';
                              } else {
                                return null;
                              }
                            },
                            onSaved: (value) {
                              codeController.text = value!;
                            },
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade200,
                              ),
                              onPressed: () {
                                submitCommand();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Text(
                                  'Generate Response',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          if (isApiCallProcess)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: LinearProgressIndicator(),
                            ),
                          if (message != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Here\'s the solution :',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(message!),
                                const SizedBox(
                                  height: 20,
                                ),
                                const Text(
                                  'Do you want to save this response?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        saveFile();
                                      },
                                      child: const Text('Yes'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          message = null;
                                          urlController.text = '';
                                          codeController.text = '';
                                          commandController.text = '';
                                        });
                                        SnackBar snackBar = const SnackBar(
                                          content: Text(
                                              'Your previous response has been cleared.'),
                                        );
                                        ScaffoldMessenger.of(
                                                scaffoldKey.currentContext!)
                                            .showSnackBar(snackBar);
                                      },
                                      child: const Text('No'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool submitCommand() {
    final form = formKey.currentState;
    if (form != null) {
      if (form.validate()) {
        form.save();
        setState(() {
          isApiCallProcess = true;
        });
        generateResponse(
                'Can you create a test script using Selenium and${codeController.text}for${commandController.text}for the url${urlController.text}')
            .then((value) {
          setState(() {
            isApiCallProcess = false;
            message = value;
          });
        });
      }
      return true;
    }
    debugPrint('The Form is null');
    return false;
  }

  Future<String> generateResponse(String prompt) async {
    var url = Uri.https(domain, path);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $apiKey"
      },
      body: json.encode({
        "model": "text-davinci-003",
        "prompt": prompt,
        'temperature': 0,
        'max_tokens': 2000,
        'top_p': 1,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      }),
    );

    Map<String, dynamic> newresponse = jsonDecode(response.body);
    debugPrint(newresponse.toString());
    return newresponse['choices'][0]['text'];
  }

  Future<String> getFilePath() async {
    Directory? appDocumentsDirectory = await getDownloadsDirectory();
    String appDocumentsPath = appDocumentsDirectory!.path;
    String filePath = '$appDocumentsPath/Testscript.txt';
    return filePath;
  }

  void saveFile() async {
    File file = File(await getFilePath());
    file.writeAsString(message!).then((value) {
      SnackBar snackBar = const SnackBar(
        content: Text('Your file has been saved successfully.'),
      );
      ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(snackBar);
    });
  }
}
