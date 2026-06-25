/// =====================================================
/// 文件：lib/services/ai_madness_service.dart
/// 功能：AI 发疯文学生成器
/// 描述：通过 DeepSeek API 网络请求生成发疯语录，
///        网络失败时自动回退到本地 JSON 兜底
/// =====================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

class AIMadnessService {
  /// ============ 静态方法：获取发疯语录 ============
  ///
  /// 第一步：尝试调用 DeepSeek API 生成
  /// 第二步：网络失败时读取本地 assets/madness_local.json 兜底
  /// 第三步：本地也没有则返回硬编码默认值
  static Future<List<String>> getMadnessPhrases(String emoji) async {
    try {
      // ---- 第一步：尝试网络请求 ----
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer sk-ee9ca25f01cd4070901b123aebd7c672',
        },
      ));

      final response = await dio.post(
        'https://api.deepseek.com/v1/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  '你是一个深谙当代大学生发疯文学的文案大师。根据用户发送的一个Emoji心情，生成3句非常接地气、幽默、带点摆烂或治愈风格的短句，每句不超过25个字。必须返回合法的JSON数组，例如 ["句1", "句2", "句3"]，不要返回其他任何内容。',
            },
            {
              'role': 'user',
              'content': '我今天的心情是 $emoji',
            },
          ],
          'temperature': 0.9,
          'max_tokens': 200,
        },
      );

      // 解析 JSON 响应
      final responseData = response.data as Map<String, dynamic>;
      final choices = responseData['choices'] as List;
      final content = choices[0]['message']['content'] as String;

      // 尝试解析返回的 JSON 数组
      final phrases = _parsePhrasesFromContent(content);
      print('🟢 AI 发疯文学生成成功: $phrases');
      return phrases;
    } on DioException catch (e) {
      // ---- 第二步：网络异常，读取本地兜底 ----
      print('⚠️ 网络请求失败 (${e.message})，使用本地兜底数据');
      return await _loadLocalPhrases(emoji);
    } catch (e) {
      // JSON 解析错误或其他异常
      print('⚠️ AI 响应解析失败: $e，使用本地兜底数据');
      return await _loadLocalPhrases(emoji);
    }
  }

  /// ============ 解析 AI 返回的内容 ============
  static List<String> _parsePhrasesFromContent(String content) {
    try {
      // 尝试直接 JSON 解析
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      final phrases =
          jsonList.map((item) => item.toString()).toList();
      if (phrases.length >= 3) {
        return phrases.sublist(0, 3);
      }
      return phrases;
    } catch (e) {
      print('⚠️ JSON 解析失败: $e');
      // 如果不是 JSON 数组，尝试按行分割
      final lines = content
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'^\d+[\.\)、]\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.length >= 3) {
        return lines.sublist(0, 3);
      }
      throw FormatException('无法解析 AI 返回的内容: $content');
    }
  }

  /// ============ 读取本地兜底 JSON ============
  static Future<List<String>> _loadLocalPhrases(String emoji) async {
    try {
      final jsonString = await rootBundle.loadString('assets/madness_local.json');
      final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 查找对应 Emoji 的语录
      if (data.containsKey(emoji)) {
        final List<dynamic> phrases = data[emoji] as List<dynamic>;
        final result = phrases.map((p) => p.toString()).toList();
        print('🟡 本地兜底数据加载成功: $emoji -> $result');
        return result;
      }

      print('⚠️ 本地 JSON 中没有 $emoji 的语录');
      // 如果找不到该 emoji，尝试返回任意一个的语录
      final fallback = data.values.first as List<dynamic>;
      return fallback.map((p) => p.toString()).toList();
    } catch (e) {
      // ---- 第三步：本地也没有，返回硬编码默认值 ----
      print('❌ 本地兜底数据加载失败: $e');
      return ['今天适合发疯', '管他呢', '冲鸭'];
    }
  }
}
