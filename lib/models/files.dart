// To parse this JSON data, do
//
//     final files = filesFromJson(jsonString);

import 'dart:convert';

List<Files> filesFromJson(String str) =>
    List<Files>.from(json.decode(str).map((x) => Files.fromJson(x)));

String filesToJson(List<Files> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Files {
  String downloadUrl;
  String name;
  Parent parent;
  Type type;
  String url;

  Files({
    required this.downloadUrl,
    required this.name,
    required this.parent,
    required this.type,
    required this.url,
  });

  factory Files.fromJson(Map<String, dynamic> json) => Files(
        downloadUrl: json["download_url"],
        name: json["name"],
        parent: parentValues.map[json["parent"]]!,
        type: typeValues.map[json["type"]]!,
        url: json["url"],
      );

  Map<String, dynamic> toJson() => {
        "download_url": downloadUrl,
        "name": name,
        "parent": parentValues.reverse[parent],
        "type": typeValues.reverse[type],
        "url": url,
      };
}

enum Parent { SERVER }

final parentValues = EnumValues({"server": Parent.SERVER});

enum Type { DIRECTORY, FILE }

final typeValues = EnumValues({"directory": Type.DIRECTORY, "file": Type.FILE});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
