import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../providers/app_provider.dart';
import '../services/audio_service.dart';

/// Text notes and voice memos tied to one block.
class NotesScreen extends StatefulWidget {
  final String blockId;
  const NotesScreen({super.key, required this.blockId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();
  final _audio = AudioService();
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  bool _recording = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final List<double> _waveformSamples = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final block = app.todayBlocks.firstWhere((b) => b.id == widget.blockId);
    _controller.text = block.notes ?? '';
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _audio.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording(AppProvider app) async {
    if (_recording) {
      final path = await _audio.stopRecording();
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      setState(() => _recording = false);
      if (path != null) await app.updateVoiceNote(widget.blockId, path);
    } else {
      try {
        _waveformSamples.clear();
        await _audio.startRecording(widget.blockId);
        _amplitudeSubscription = _audio
            .amplitudeStream(const Duration(milliseconds: 100))
            .listen((amplitude) {
          if (!mounted) return;
          final level = ((amplitude.current + 60) / 60).clamp(0.04, 1.0);
          setState(() => _waveformSamples.add(level.toDouble()));
        });
        setState(() => _recording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start recording: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePlayback(String path) async {
    if (_playing) {
      await _player.stop();
    } else {
      await _player.play(DeviceFileSource(path));
    }
  }

  Future<void> _seekBy(Duration offset) async {
    if (_duration == Duration.zero) return;
    final target = _position + offset;
    final bounded = target < Duration.zero
        ? Duration.zero
        : target > _duration
            ? _duration
            : target;
    await _player.seek(bounded);
  }

  Future<void> _seekToFraction(double fraction) async {
    if (_duration == Duration.zero) return;
    final boundedFraction = fraction.clamp(0.0, 1.0);
    await _player.seek(_duration * boundedFraction);
  }

  void _showSummarySetupMessage() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('AI summary is not connected'),
        content: const Text(
          'To summarize this recording, the app needs a speech-to-text service '
          'and an AI summarization service connected through a secure backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final block = app.todayBlocks.firstWhere((b) => b.id == widget.blockId);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes & Voice Memo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Text note',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'What did you learn / what happened during this block?',
            ),
            onChanged: (v) => app.updateNotes(widget.blockId, v),
          ),
          const SizedBox(height: 24),
          const Text('Voice memo',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _WaveformBar(
            samples: _waveformSamples,
            progress: _duration.inMilliseconds == 0
                ? 0
                : _position.inMilliseconds / _duration.inMilliseconds,
            active: _recording || _playing,
            onSeek: _recording ? null : _seekToFraction,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _toggleRecording(app),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _recording ? Colors.red : null,
                ),
                icon: Icon(_recording ? Icons.stop : Icons.mic),
                label: Text(_recording ? 'Stop' : 'Record'),
              ),
              const SizedBox(width: 12),
              if (block.voiceNotePath != null && !_recording)
                OutlinedButton.icon(
                  onPressed: () => _togglePlayback(block.voiceNotePath!),
                  icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  label: Text(_playing ? 'Stop playback' : 'Play'),
                ),
              if (block.voiceNotePath != null && !_recording)
                IconButton(
                  onPressed: () => _seekBy(const Duration(seconds: -10)),
                  tooltip: 'Back 10 seconds',
                  icon: const Icon(Icons.replay_10),
                ),
              if (block.voiceNotePath != null && !_recording)
                IconButton(
                  onPressed: () => _seekBy(const Duration(seconds: 10)),
                  tooltip: 'Forward 10 seconds',
                  icon: const Icon(Icons.forward_10),
                ),
              if (block.voiceNotePath != null && !_recording)
                OutlinedButton.icon(
                  onPressed: _showSummarySetupMessage,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI summary'),
                ),
            ],
          ),
          if (block.voiceNotePath != null) ...[
            const SizedBox(height: 8),
            Text('Saved memo attached',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  final List<double> samples;
  final double progress;
  final bool active;
  final ValueChanged<double>? onSeek;

  const _WaveformBar({
    required this.samples,
    required this.progress,
    required this.active,
    required this.onSeek,
  });

  void _seekAt(Offset position, double width) {
    onSeek?.call((position.dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTapDown: onSeek == null
            ? null
            : (details) => _seekAt(details.localPosition, constraints.maxWidth),
        onHorizontalDragUpdate: onSeek == null
            ? null
            : (details) => _seekAt(details.localPosition, constraints.maxWidth),
        child: CustomPaint(
          size: Size(constraints.maxWidth, 72),
          painter: _WaveformPainter(
            samples: samples,
            progress: progress,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final bool active;

  const _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    const barWidth = 3.0;
    const gap = 2.0;
    final count = (size.width / (barWidth + gap)).floor();
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final activePaint = Paint()
      ..color = active ? const Color(0xFF3A5BA0) : Colors.grey.shade500
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final progressX = size.width * progress.clamp(0.0, 1.0);

    for (var index = 0; index < count; index++) {
      final x = index * (barWidth + gap) + barWidth / 2;
      final sample = samples.isEmpty
          ? 0.12
          : samples[(index * samples.length / count)
              .floor()
              .clamp(0, samples.length - 1)];
      final halfHeight =
          (sample * size.height * 0.42).clamp(2.0, size.height * 0.42);
      final paint = x <= progressX ? activePaint : backgroundPaint;
      canvas.drawLine(Offset(x, center - halfHeight),
          Offset(x, center + halfHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.progress != progress ||
      oldDelegate.active != active;
}
