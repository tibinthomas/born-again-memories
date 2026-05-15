import 'dart:convert';
import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GooglePhotoItem {
  final String id;
  final String baseUrl;
  final String mimeType;
  final String filename;
  final bool isVideo;

  const GooglePhotoItem({
    required this.id,
    required this.baseUrl,
    required this.mimeType,
    required this.filename,
    required this.isVideo,
  });

  factory GooglePhotoItem.fromJson(Map<String, dynamic> json) {
    final mimeType = json['mimeType'] as String? ?? 'image/jpeg';
    return GooglePhotoItem(
      id: json['id'] as String,
      baseUrl: json['baseUrl'] as String,
      mimeType: mimeType,
      filename: json['filename'] as String? ?? '',
      isVideo: mimeType.startsWith('video/'),
    );
  }

  String get thumbnailUrl => '$baseUrl=w300-h300-c';
}

class GooglePhotoAlbum {
  final String id;
  final String title;
  final int mediaItemsCount;

  const GooglePhotoAlbum({
    required this.id,
    required this.title,
    required this.mediaItemsCount,
  });

  factory GooglePhotoAlbum.fromJson(Map<String, dynamic> json) {
    return GooglePhotoAlbum(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      mediaItemsCount:
          int.tryParse(json['mediaItemsCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class GooglePhotosService {
  static const photosScope =
      'https://www.googleapis.com/auth/photoslibrary.readonly';
  static const _baseUrl = 'https://photoslibrary.googleapis.com/v1';

  static Future<bool> requestScope(GoogleSignIn gs) =>
      gs.requestScopes([photosScope]);

  static Future<http.Client> _client(GoogleSignIn gs) async {
    final client =
        await gs.authenticatedClient().timeout(const Duration(seconds: 20));
    if (client == null) throw Exception('Not signed in with Google');
    return client;
  }

  static Future<({List<GooglePhotoItem> items, String? nextPageToken})>
      listMediaItems(
    GoogleSignIn gs, {
    String? pageToken,
    String? albumId,
  }) async {
    final client = await _client(gs);
    http.Response response;
    if (albumId != null) {
      final uri = Uri.parse('$_baseUrl/mediaItems:search');
      response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'albumId': albumId,
          'pageSize': 50,
          'pageToken': ?pageToken,
        }),
      );
    } else {
      final uri = Uri.parse('$_baseUrl/mediaItems').replace(
        queryParameters: {
          'pageSize': '50',
          'pageToken': ?pageToken,
        },
      );
      response = await client.get(uri);
    }

    if (response.statusCode != 200) {
      throw Exception('Google Photos API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['mediaItems'] as List? ?? [])
        .map((e) => GooglePhotoItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      items: items,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  static Future<List<GooglePhotoAlbum>> listAlbums(GoogleSignIn gs) async {
    final client = await _client(gs);
    final uri = Uri.parse('$_baseUrl/albums').replace(
      queryParameters: {'pageSize': '50'},
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['albums'] as List? ?? [])
        .map((e) => GooglePhotoAlbum.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String> downloadItem(
    GoogleSignIn gs,
    GooglePhotoItem item,
  ) async {
    final client = await _client(gs);
    final downloadUrl =
        item.isVideo ? '${item.baseUrl}=dv' : '${item.baseUrl}=d';
    final response = await client.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }
    final dir = await getTemporaryDirectory();
    final ext = item.isVideo ? 'mp4' : 'jpg';
    final safeName = item.id
        .replaceAll(RegExp(r'[^\w]'), '')
        .substring(0, item.id.length.clamp(0, 20));
    final path = '${dir.path}/gphoto_$safeName.$ext';
    await File(path).writeAsBytes(response.bodyBytes);
    return path;
  }
}
