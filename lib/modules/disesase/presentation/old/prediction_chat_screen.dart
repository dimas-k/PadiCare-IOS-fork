import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/analyze_button.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/chat_section.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/image_section.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction_result_card.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/server_status_dialog.dart';

import '../../logic/models/prediction_model.dart';
import '../../logic/models/chat_model.dart';
import '../../logic/models/history_model.dart';
import '../../logic/services/api_service.dart';
import '../../logic/utils/disease_label.dart';
import '../../logic/services/auth_service.dart';
import '../history_screen.dart';
import '../login_screen.dart';

class PredictionChatScreen extends StatefulWidget {
  final PredictionHistoryItem? historyItem;
  final bool isHistoryMode;

  const PredictionChatScreen({
    Key? key,
    this.historyItem,
    this.isHistoryMode = false,
  }) : super(key: key);

  @override
  _PredictionChatScreenState createState() => _PredictionChatScreenState();
}

class _PredictionChatScreenState extends State<PredictionChatScreen>
    with TickerProviderStateMixin {
  // Services & Controllers
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // State variables
  File? _selectedImage;
  PredictionResult? _result;
  List<ChatMessageItem> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isChatMinimized = true;
  bool _isServerReachable = true;

  // Animation controllers
  late AnimationController _chatAnimationController;
  late Animation<double> _chatAnimation;

  // Colors
  final Color primaryColor = Colors.green.shade700;
  final Color accentColor = Colors.green.shade300;
  final Color backgroundColor = Colors.grey.shade50;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkServerStatus();

    if (widget.isHistoryMode && widget.historyItem != null) {
      _loadHistoryData();
    }
  }

  void _initializeAnimations() {
    _chatAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _chatAnimation = CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _mainScrollController.dispose();
    _chatAnimationController.dispose();
    super.dispose();
  }

  // ==================== SERVER STATUS ====================
  Future<void> _checkServerStatus() async {
    try {
      final isReachable = await _apiService.checkServerStatus();
      setState(() => _isServerReachable = isReachable);

      if (!isReachable) {
        ServerStatusDialog.showOfflineDialog(context, _checkServerStatus);
      }
    } catch (e) {
      setState(() => _isServerReachable = false);
    }
  }

  // ==================== HISTORY MODE ====================
  void _loadHistoryData() {
    print('📜 Loading history data...');
    final item = widget.historyItem!;

    setState(() {
      _result = PredictionResult(
        predictedClass: item.predictedClass,
        confidencePercentage: item.confidencePercentage,
        success: true,
        expertAdvice: item.expertAdvice,
        predictionId: item.id,
        topPredictions: item.topPredictions,
        processingTime: item.processingTime,
        savedToDatabase: true,
      );
      _messages = item.chatMessages;
      _isChatMinimized = _messages.isEmpty;
    });

    if (_messages.isNotEmpty) {
      _chatAnimationController.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  Future<String?> _getImageUrl(String predictionId) async {
    try {
      final response = await _apiService.getImageUrl(predictionId);
      return response;
    } catch (e) {
      print('❌ Error getting image URL: $e');
      return null;
    }
  }

  // ==================== IMAGE PICKING ====================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _result = null;
          _messages.clear();
          _isChatMinimized = true;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil gambar: $e');
    }
  }

  // ==================== IMAGE ANALYSIS ====================
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showErrorSnackBar('Silakan pilih gambar terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.predictImage(_selectedImage!);

      setState(() {
        _result = result;
        _isLoading = false;
      });

      _showSuccessSnackBar('Analisis berhasil!');

      // Auto scroll to result
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mainScrollController.animateTo(
          _mainScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal menganalisis gambar: $e');
    }
  }

  // ==================== CHAT FUNCTIONS ====================
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _result == null) return;

    final userMessage = ChatMessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Tambah id
      message: messageText,
      isUser: true,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _apiService.chatWithExpert(
        messageText,
        formatDiseaseName(_result!.predictedClass),
        predictionId: _result!.predictionId,
      );

      if (response != null) {
        final aiMessage = ChatMessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: response.answer,
          isUser: false,
          createdAt: DateTime.now(),
        );

        setState(() {
          _messages.add(aiMessage);
          _isSending = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showErrorSnackBar('Gagal mengirim pesan: $e');
    }
  }

  void _toggleChat() {
    setState(() => _isChatMinimized = !_isChatMinimized);

    if (_isChatMinimized) {
      _chatAnimationController.reverse();
    } else {
      _chatAnimationController.forward();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== NAVIGATION ====================
  void _navigateToNewDiagnosis() {
    if (widget.isHistoryMode) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
      );
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
  }

  // ==================== LOGOUT ====================
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthService().logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ==================== IMAGE VIEWERS ====================
  void _showFullScreenImage(BuildContext context) {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(_selectedImage!),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenHistoryImage(BuildContext context, String imageUrl) {
    final fullImageUrl = '${ApiService.baseUrl}$imageUrl';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(fullImageUrl),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== SNACKBARS ====================
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _mainScrollController,
                  child: Column(
                    children: [
                      ImageSection(
                        isHistoryMode: widget.isHistoryMode,
                        selectedImage: _selectedImage,
                        historyImageFilename: widget.historyItem?.imageFilename,
                        historyImageUrlFuture:
                            widget.isHistoryMode && widget.historyItem != null
                            ? _getImageUrl(widget.historyItem!.id)
                            : null,
                        historyDate: widget.historyItem?.createdAt,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                        onCameraTap: () => _pickImage(ImageSource.camera),
                        onGalleryTap: () => _pickImage(ImageSource.gallery),
                        onImageTap: widget.isHistoryMode
                            ? () async {
                                final imageUrl = await _getImageUrl(
                                  widget.historyItem!.id,
                                );
                                if (imageUrl != null) {
                                  _showFullScreenHistoryImage(
                                    context,
                                    imageUrl,
                                  );
                                }
                              }
                            : () => _showFullScreenImage(context),
                      ),

                      if (!widget.isHistoryMode)
                        AnalyzeButton(
                          hasImage: _selectedImage != null,
                          isLoading: _isLoading,
                          onPressed: _analyzeImage,
                          primaryColor: primaryColor,
                        ),

                      if (_result != null)
                        PredictionResultCard(
                          result: _result!,
                          isHistoryMode: widget.isHistoryMode,
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                        ),

                      if (_result != null && _isChatMinimized)
                        SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              if (_result != null)
                ChatSection(
                  animation: _chatAnimation,
                  isChatMinimized: _isChatMinimized,
                  isHistoryMode: widget.isHistoryMode,
                  messages: _messages,
                  scrollController: _chatScrollController,
                  textController: _messageController,
                  isSending: _isSending,
                  onToggleChat: _toggleChat,
                  onSendMessage: _sendMessage,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.isHistoryMode ? 'Detail Riwayat' : 'Diagnosa & Konsultasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          ServerStatusIndicator(isServerReachable: _isServerReachable),
        ],
      ),
      centerTitle: true,
      elevation: 2,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        if (!_isServerReachable)
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkServerStatus,
            tooltip: 'Periksa Koneksi Server',
          ),
        if (widget.isHistoryMode) ...[
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _navigateToNewDiagnosis,
            tooltip: 'Diagnosa Baru',
          ),
          SizedBox(width: 8),
        ],
        if (!widget.isHistoryMode) ...[
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'Lihat Riwayat',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ],
    );
  }
}
