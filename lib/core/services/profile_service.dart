import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';

import 'user_session.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    this.idRol,
    this.ciudad,
    this.semestreActual,
    this.telefono,
    this.edad,
    this.sexo,
    this.fechaNacimiento,
    this.idioma,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String nombres;
  final String apellidos;
  final String correo;
  final int? idRol;
  final String? ciudad;
  final String? semestreActual;
  final String? telefono;
  final int? edad;
  final String? sexo;
  final DateTime? fechaNacimiento;
  final String? idioma;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  String get fechaNacimientoFormateada {
    final fecha = fechaNacimiento;
    if (fecha == null) return '';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? firstNonEmptyString(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return null;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
      }
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
      }
      if (value is String) {
        final raw = value.trim();
        if (raw.isEmpty) return null;

        final parsedIso = DateTime.tryParse(raw);
        if (parsedIso != null) return parsedIso;

        final slashParts = raw.split('/');
        if (slashParts.length == 3) {
          final day = int.tryParse(slashParts[0]);
          final month = int.tryParse(slashParts[1]);
          final year = int.tryParse(slashParts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      return null;
    }

    return UserProfile(
      id: parseInt(json['id']),
      nombres: (json['nombres'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      idRol: parseNullableInt(json['id_rol']),
      ciudad: firstNonEmptyString([
        json['ciudad'],
        json['city'],
        json['municipio'],
      ]),
      semestreActual: firstNonEmptyString([
        json['semestre_actual'],
        json['semestre'],
        json['semester'],
      ]),
      telefono: json['telefono']?.toString(),
      edad: parseNullableInt(json['edad']),
      sexo: json['sexo']?.toString(),
      fechaNacimiento: parseDate(
        json['fecha_nacimiento'] ??
            json['fechaNacimiento'] ??
            json['birth_date'],
      ),
      idioma: json['idioma']?.toString(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}

class ProfileService {
  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _authHeaders() {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa. Inicia sesion nuevamente.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<UserProfile> fetchProfile() async {
    final uri = Uri.parse('$_baseUrl/api/users/profile');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar el perfil (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final rawProfile = decoded['data'];
      if (rawProfile is Map<String, dynamic>) {
        return UserProfile.fromJson(rawProfile);
      }
      return UserProfile.fromJson(decoded);
    }

    throw Exception('Respuesta de perfil invalida.');
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/api/settings/profile');
    final response = await http.put(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo actualizar el perfil (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final rawProfile = decoded is Map<String, dynamic>
        ? decoded['data'] ?? decoded['user']
        : null;

    if (rawProfile is Map<String, dynamic>) {
      return UserProfile.fromJson(rawProfile);
    } else if (decoded is Map<String, dynamic>) {
      return UserProfile.fromJson(decoded);
    }

    throw Exception('Respuesta de actualización invalida.');
  }
}
