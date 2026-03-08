import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A utility class that provides an interface to interact with AI services
/// Used to centralize AI API calls and make them more portable across the application
/// Supports both OpenAI and DeepSeek API formats
class AIApi {
  /// Base URL for the AI API
  final String _baseUrl;

  /// API key for authentication
  final String _apiKey;

  /// Default timeout duration for API calls
  final Duration _timeout;

  /// API provider (e.g., 'openai', 'deepseek')
  final String _provider;

  /// Singleton instance of AIApi
  static AIApi? _instance;

  /// Private constructor
  AIApi._({
    required String baseUrl,
    required String apiKey,
    required Duration timeout,
    required String provider,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _timeout = timeout,
        _provider = provider;

  /// Factory constructor to get or create an instance of AIApi
  /// No parameters needed as they are loaded from environment variables
  factory AIApi() {
    if (_instance == null) {
      // Load configuration from environment variables
      final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'openai';
      final baseUrl = provider == 'deepseek'
          ? dotenv.env['AI_API_BASE_URL'] ?? 'https://api.deepseek.com'
          : dotenv.env['AI_API_BASE_URL'] ?? 'https://api.openai.com/v1';

      final apiKey = provider == 'deepseek'
          ? dotenv.env['DEEPSEEK_API_KEY'] ?? ''
          : dotenv.env['OPENAI_API_KEY'] ?? '';

      final timeoutSeconds =
          int.tryParse(dotenv.env['AI_API_TIMEOUT'] ?? '30') ?? 30;

      if (apiKey.isEmpty) {
        debugPrint(
            'Warning: AI API key is not set in the environment variables.');
      }

      _instance = AIApi._(
        baseUrl: baseUrl,
        apiKey: apiKey,
        timeout: Duration(seconds: timeoutSeconds),
        provider: provider,
      );
    }
    return _instance!;
  }

  /// Get the singleton instance of AIApi
  static AIApi get instance {
    if (_instance == null) {
      // Auto-initialize with environment variables if not initialized
      return AIApi();
    }
    return _instance!;
  }

  /// Reset the singleton instance (useful for testing or changing API credentials)
  static void reset() {
    _instance = null;
  }

  /// Check if the API is properly configured
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Get the current API configuration (for debugging, hides the actual API key)
  Map<String, dynamic> get configuration => {
        'provider': _provider,
        'baseUrl': _baseUrl,
        'apiKeyConfigured': _apiKey.isNotEmpty,
        'timeoutSeconds': _timeout.inSeconds,
      };

  /// Make a text completion request to the AI API
  ///
  /// [prompt] - The prompt to send to the AI
  /// [maxTokens] - Maximum number of tokens to generate
  /// [temperature] - Controls randomness (0.0 to 1.0)
  Future<String> completeText({
    required String prompt,
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    if (!isConfigured) {
      throw AIApiException(
        'AI API is not properly configured. Please check your environment variables.',
        0,
      );
    }

    try {
      // For DeepSeek, we'll convert this to a chat completion format
      if (_provider == 'deepseek') {
        final messages = [
          {'role': 'user', 'content': prompt}
        ];

        return await chatCompletion(
          messages: messages,
          model: 'deepseek-chat',
          temperature: temperature,
        );
      }

      // Original OpenAI implementation
      final response = await http
          .post(
            Uri.parse('$_baseUrl/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'text-davinci-003',
              'prompt': prompt,
              'max_tokens': maxTokens,
              'temperature': temperature,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['text'].trim();
      } else {
        throw AIApiException(
          'API request failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI API Error: $e');
      }
      rethrow;
    }
  }

  /// Generate a chat completion using the AI API
  ///
  /// [messages] - List of message objects with 'role' and 'content'
  /// [model] - The model to use (defaults based on provider)
  /// [temperature] - Controls randomness (0.0 to 1.0)
  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String? model,
    double temperature = 0.7,
  }) async {
    if (!isConfigured) {
      throw AIApiException(
        'AI API is not properly configured. Please check your environment variables.',
        0,
      );
    }

    try {
      // Set default model based on provider
      final modelToUse = model ??
          (_provider == 'deepseek' ? 'deepseek-chat' : 'gpt-3.5-turbo');

      // Add system message for expense tracker context if not present
      bool hasSystemMessage = messages.any((m) => m['role'] == 'system');

      final finalMessages = [...messages];
      if (!hasSystemMessage) {
        finalMessages.insert(0, {
          'role': 'system',
          'content':
              'You are a helpful financial assistant for the Expense Tracker app. Help users categorize expenses and provide financial insights.'
        });
      }

      // Endpoint URL based on provider
      final endpoint = _provider == 'deepseek'
          ? '$_baseUrl/chat/completions'
          : '$_baseUrl/chat/completions';

      final Map<String, dynamic> requestBody = {
        'model': modelToUse,
        'messages': finalMessages,
        'temperature': temperature,
      };

      // Add stream parameter for DeepSeek
      if (_provider == 'deepseek') {
        requestBody['stream'] = false;
      }

      if (kDebugMode) {
        print('Sending request to: $endpoint');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Extract the actual content from the response body
        String cleanResponseBody = response.body;

        // Get the response content from the API response
        final data = jsonDecode(cleanResponseBody);
        final choices = data['choices'];
        final content = choices[0]['message']['content'].toString().trim();

        // Clean the content by removing markdown and extracting valid JSON
        String cleanedContent = _cleanJsonContent(content);

        if (kDebugMode) {
          print('Original content: $content');
          print('Cleaned content: $cleanedContent');
        }

        // Return the cleaned content
        return cleanedContent;
      } else {
        // Improved error handling for non-200 responses
        String errorMessage =
            'API request failed with status code: ${response.statusCode}';

        try {
          // Try to extract more detailed error info from response
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            if (error is Map && error['message'] != null) {
              errorMessage = 'API error: ${error['message']}';
            } else if (error is String) {
              errorMessage = 'API error: $error';
            }
          }
        } catch (_) {
          // If error parsing fails, use the default message
        }

        throw AIApiException(errorMessage, response.statusCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI Chat Completion Error: $e');
      }
      rethrow;
    }
  }

  /// Helper method to clean and extract JSON content from AI responses
  String _cleanJsonContent(String content) {
    String cleanedContent = content;

    // Remove markdown code block markers completely
    if (cleanedContent.contains("```json") || cleanedContent.contains("```")) {
      cleanedContent =
          cleanedContent.replaceAll("```json", "").replaceAll("```", "").trim();
    }

    // Remove triple quote markdown for json
    if (cleanedContent.contains("'''json") || cleanedContent.contains("'''")) {
      cleanedContent =
          cleanedContent.replaceAll("'''json", "").replaceAll("'''", "").trim();
    }

    // If cleanedContent doesn't start with a JSON syntax character, try to extract it
    if (!cleanedContent.trim().startsWith("{") &&
        !cleanedContent.trim().startsWith("[")) {
      // First try to extract a JSON array if that's what we're expecting
      final arrayPattern = RegExp(r'\[.*\]', dotAll: true);
      final arrayMatch = arrayPattern.firstMatch(cleanedContent);
      if (arrayMatch != null) {
        cleanedContent = arrayMatch.group(0) ?? cleanedContent;
      } else {
        // Fall back to object extraction if array not found
        final objectPattern = RegExp(r'\{.*\}', dotAll: true);
        final objectMatch = objectPattern.firstMatch(cleanedContent);
        if (objectMatch != null) {
          cleanedContent = objectMatch.group(0) ?? cleanedContent;
        }
      }
    }

    // Validate the extracted JSON
    try {
      // This will throw if it's not valid JSON
      json.decode(cleanedContent);
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Extracted content is not valid JSON: $e');
        print('Content: $cleanedContent');
      }
      // If JSON is invalid, try a more aggressive clean-up
      cleanedContent = _aggressiveJsonClean(cleanedContent);
    }

    return cleanedContent;
  }

  /// More aggressive JSON cleaning method for problematic responses
  String _aggressiveJsonClean(String content) {
    // Try to extract anything that looks like JSON
    RegExp jsonPattern;
    String result = content;

    // First try with array pattern which is more specific
    jsonPattern = RegExp(r'\[\s*\{\s*"type"\s*:.*\}\s*\]', dotAll: true);
    final arrayMatch = jsonPattern.firstMatch(result);
    if (arrayMatch != null) {
      result = arrayMatch.group(0) ?? result;
      return result;
    }

    // Try with generic array pattern
    jsonPattern = RegExp(r'\[[\s\S]*?\]', dotAll: true);
    final genericArrayMatch = jsonPattern.firstMatch(result);
    if (genericArrayMatch != null) {
      result = genericArrayMatch.group(0) ?? result;
      return result;
    }

    // Fall back to object pattern
    jsonPattern = RegExp(r'\{[\s\S]*?\}', dotAll: true);
    final objectMatch = jsonPattern.firstMatch(result);
    if (objectMatch != null) {
      result = objectMatch.group(0) ?? result;
    }

    return result;
  }

  /// Generate an image using the AI API
  ///
  /// [prompt] - The description of the image to generate
  /// [size] - The size of the image (e.g., '1024x1024')
  Future<String> generateImage({
    required String prompt,
    String size = '512x512',
  }) async {
    if (!isConfigured) {
      throw AIApiException(
        'AI API is not properly configured. Please check your environment variables.',
        0,
      );
    }

    try {
      // Image generation is primarily supported by OpenAI
      // DeepSeek might not have this capability
      if (_provider == 'deepseek') {
        throw AIApiException(
          'Image generation is not supported by the DeepSeek API.',
          400,
        );
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/images/generations'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'prompt': prompt,
              'size': size,
              'n': 1,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][0]['url'];
      } else {
        throw AIApiException(
          'Image generation failed with status code: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI Image Generation Error: $e');
      }
      rethrow;
    }
  }

  /// Analyze text for expense categorization or other financial analysis
  ///
  /// [text] - The text to analyze
  /// [type] - The type of analysis to perform (e.g., 'sentiment', 'category')
  Future<Map<String, dynamic>> analyzeText({
    required String text,
    required String type,
  }) async {
    if (!isConfigured) {
      throw AIApiException(
        'AI API is not properly configured. Please check your environment variables.',
        0,
      );
    }

    try {
      // Create a prompt based on the analysis type
      String prompt;
      List<Map<String, String>> messages = [];

      switch (type.toLowerCase()) {
        case 'sentiment':
          prompt =
              'Analyze the sentiment of the following text and respond with only one word (positive, negative, or neutral): $text';
          messages = [
            {
              'role': 'system',
              'content':
                  'You are a financial sentiment analyzer. Respond with only one word: positive, negative, or neutral.'
            },
            {
              'role': 'user',
              'content':
                  'Analyze the sentiment of this expense description: $text'
            }
          ];
          break;
        case 'category':
          prompt =
              'Categorize the following expense into one of these categories (food, travel, entertainment, shopping, transportation, utilities, healthcare, education, other): $text';
          messages = [
            {
              'role': 'system',
              'content':
                  'You are a financial expense categorizer. Respond with only one category from this list: food, travel, entertainment, shopping, transportation, utilities, healthcare, education, other.'
            },
            {'role': 'user', 'content': 'Categorize this expense: $text'}
          ];
          break;
        default:
          prompt = 'Analyze the following text for $type: $text';
          messages = [
            {'role': 'system', 'content': 'You are a financial text analyzer.'},
            {
              'role': 'user',
              'content': 'Analyze this financial text for $type: $text'
            }
          ];
      }

      // Use chat completion for both providers
      final response = _provider == 'deepseek'
          ? await chatCompletion(messages: messages, temperature: 0.3)
          : await completeText(prompt: prompt, maxTokens: 50, temperature: 0.3);

      return {
        'type': type,
        'result': response.trim(),
        'text': text,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Text Analysis Error: $e');
      }
      rethrow;
    }
  }
}

/// Custom exception class for AI API errors
class AIApiException implements Exception {
  final String message;
  final int statusCode;

  AIApiException(this.message, this.statusCode);

  @override
  String toString() => 'AIApiException: $message (Status Code: $statusCode)';
}
