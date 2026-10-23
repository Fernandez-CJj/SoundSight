import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MicrophoneScreen extends StatefulWidget {
  const MicrophoneScreen({super.key});

  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

class _MicrophoneScreenState extends State<MicrophoneScreen> {
  final AudioRecorder audioRecorder = AudioRecorder();
  WebSocketChannel? channel;
  StreamSubscription<List<int>>? audioStreamSubscription;

  bool isListening = false;
  List<String> detectedNotes = [];

  final String backendWsUrl = 'ws://192.168.0.102:8000/ws';

  void toggleListening() {
    if (isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  Future<void> startListening() async {
    try {
      final hasPermission = await audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied.')),
          );
        }
        return;
      }

      channel = WebSocketChannel.connect(Uri.parse(backendWsUrl));

      channel!.stream.listen((message) {
        final data = jsonDecode(message as String);
        if (mounted) {
          setState(() {
            detectedNotes = List<String>.from(data['notes']);
          });
        }
      }, onError: (error) {
        debugPrint("WebSocket Error: $error");
        stopListening();
      });

      final stream = await audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 22050,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );

      audioStreamSubscription = stream.listen((data) {
        channel?.sink.add(data);
      });

      setState(() => isListening = true);
    } catch (e) {
      debugPrint("Error starting audio stream: $e");
      stopListening();
    }
  }

  Future<void> stopListening() async {
    await audioStreamSubscription?.cancel();
    await audioRecorder.stop();
    channel?.sink.close();
    
    if (mounted) {
      setState(() {
        isListening = false;
        detectedNotes.clear();
      });
    }
  }

  @override
  void dispose() {
    audioStreamSubscription?.cancel();
    audioRecorder.dispose();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SoundSight')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isListening ? Icons.mic : Icons.mic_off,
                size: 64,
                color: isListening ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 32),
              
              // Note Display Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: detectedNotes.isEmpty
                    ? const Text(
                        "Listening for notes...",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: detectedNotes.map((note) => Chip(
                          label: Text(
                            note,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.greenAccent,
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: toggleListening,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isListening ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                ),
                child: Text(
                  isListening ? "Stop" : "Start",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}