import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sri_master/models/files.dart';

void main() {
  runApp(MaterialApp(
    home: DirectoryScreen(key: Key('directory_screen'), directory: 'server/'),
  ));
}

class DirectoryScreen extends StatefulWidget {
  final String directory;

  const DirectoryScreen({required Key key, required this.directory})
      : super(key: key);

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  Future<List<Files>> getFiles(String directory) async {
    final response = await http
        .get(Uri.parse('http://localhost:5000/files?directory=$directory'));

    if (response.statusCode == 200) {
      return filesFromJson(response.body);
    } else {
      throw Exception('Failed to load files');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Directory: ${widget.directory}'),
      ),
      body: FutureBuilder<List<Files>>(
        future: getFiles(widget.directory),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data?.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(snapshot.data?[index].name ?? ''),
                  onTap: snapshot.data?[index].type == Type.DIRECTORY
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DirectoryScreen(
                                key: Key('directory_screen'),
                                directory: snapshot.data![index].url,
                              ),
                            ),
                          );
                        }
                      : null,
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner.
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
