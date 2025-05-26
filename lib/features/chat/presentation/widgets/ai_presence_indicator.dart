import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum AiPresenceState {
  idle,
  listening,
  thinking,
  responding,
  offline,
}

class AiPresenceIndicator extends StatefulWidget {
  final AiPresenceState initialState;

  const AiPresenceIndicator({
    Key? key,
    this.initialState = AiPresenceState.idle,
  }) : super(key: key);

  @override
  State<AiPresenceIndicator> createState() => _AiPresenceIndicatorState();
}

class _AiPresenceIndicatorState extends State<AiPresenceIndicator> {
  late AiPresenceState _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleState,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: _buildAnimationForState(),
      ),
    );
  }

  Widget _buildAnimationForState() {
    String animationPath;
    
    switch (_currentState) {
      case AiPresenceState.idle:
        animationPath = 'assets/lottie/ai_idle.json';
        break;
      case AiPresenceState.listening:
        animationPath = 'assets/lottie/ai_listening.json';
        break;
      case AiPresenceState.thinking:
        animationPath = 'assets/lottie/ai_thinking.json';
        break;
      case AiPresenceState.responding:
        animationPath = 'assets/lottie/ai_responding.json';
        break;
      case AiPresenceState.offline:
        animationPath = 'assets/lottie/ai_offline.json';
        break;
    }
    
    // We're using placeholders until actual Lottie files are added to the project
    return Lottie.asset(
      animationPath,
      fit: BoxFit.contain,
      frameRate: FrameRate.max,
    );
  }

  void _cycleState() {
    setState(() {
      switch (_currentState) {
        case AiPresenceState.idle:
          _currentState = AiPresenceState.listening;
          break;
        case AiPresenceState.listening:
          _currentState = AiPresenceState.thinking;
          break;
        case AiPresenceState.thinking:
          _currentState = AiPresenceState.responding;
          break;
        case AiPresenceState.responding:
          _currentState = AiPresenceState.offline;
          break;
        case AiPresenceState.offline:
          _currentState = AiPresenceState.idle;
          break;
      }
    });
  }
}