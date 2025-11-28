import 'package:flutter/material.dart';
import 'dart:math';

/// Crestadel Meme Integration for the Best Meme Award! 👑
/// 
/// Features castle puns, crown culture, and Cardano royalty vibes
/// Crestadel = Crypto + Estate + Delicacy

class CardanoMemes {
  static final Random _random = Random();

  // Royal quotes and wisdom
  static const List<String> royalQuotes = [
    "Every castle starts with a single brick... and one ADA 🏰",
    "Crypto kings don't rent, they own fractions! 👑",
    "Build your kingdom, one token at a time 🌍",
    "In the realm of DeFi, patience crowns the wise 🐢",
    "Your portfolio is your castle, defend it wisely! 🛡️",
    "From peasant to property baron in one transaction 🚀",
    "The crown jewels? That's your Crestadel holdings! 💎",
    "Welcome to the court of crypto nobility! 🎉",
  ];

  // Crestadel community memes
  static const List<String> communityMemes = [
    "When ADA finally hits \$10: Time to buy the whole castle 🏰🌙",
    "Me explaining Crestadel to my family: 'It's like Monopoly but real' 🎲",
    "POV: You just became crypto royalty with your first fraction 👑✨",
    "Lords and Ladies checking their portfolio every 5 minutes 👀",
    "Trust the crown, trust Cardano, trust Crestadel 🤝",
    "Not your keys, not your kingdom! 🔐",
    "When gas fees are high but you're on Cardano like a true noble 😎",
    "Wen Lambo? After wen castle! 🏰🏎️",
    "Building empires while others build sandcastles 🏖️🏰",
    "My portfolio is not just mooning, it's ascending the throne 👑🚀",
  ];

  // Castle-themed loading messages
  static const List<String> loadingMessages = [
    "Raising the drawbridge...",
    "Consulting the royal treasury...",
    "Summoning the blockchain knights...",
    "Forging your deed of ownership...",
    "The royal scribes are verifying...",
    "Counting your ADA in gold coins...",
    "Preparing the throne room...",
    "Polishing the crown jewels...",
    "Alerting the kingdom guards...",
    "Rolling out the red carpet...",
  ];

  // Victory celebration messages
  static const List<String> successMessages = [
    "Huzzah! Transaction confirmed! 👑",
    "You've claimed your throne! Long live the investor! 🏰",
    "The kingdom celebrates your acquisition! 🎉",
    "One small deed, one giant leap for your empire! 🌙",
    "Property acquired! The realm expands! 🚀",
    "History written in the blockchain scrolls! 📜",
    "The royal treasury grows stronger! 💰",
    "Welcome to crypto nobility! 👑✨",
    "A new tower added to your castle! 🏰",
    "The crown approves this transaction! ✅",
  ];

  // Royal error messages
  static const List<String> errorMessages = [
    "Alas! Even kingdoms face setbacks... 😅",
    "The castle gremlins are at it again! 👾",
    "Transaction failed, but your crown remains! 👑",
    "Error 404: Castle not found (yet) 🏰",
    "The moat was too wide this time... 🌊",
    "Fear not, noble one! Try again! ⚔️",
  ];

  // Estate puns
  static const List<String> estatePuns = [
    "I'm not a landlord, I'm a blockchain baron! 👑",
    "Real estate? More like REGAL estate! 🏰",
    "My portfolio has more floors than your building 📈",
    "Fractional? I prefer 'royally accessible' 💎",
    "Property investment? Call it throne acquisition! 👑",
    "I don't flip houses, I flip kingdoms 🔄",
  ];

  // Crown tier titles based on holdings
  static const Map<int, String> crownTiers = {
    0: 'Peasant',
    1: 'Squire',
    5: 'Knight',
    10: 'Baron',
    25: 'Viscount',
    50: 'Earl',
    100: 'Duke',
    250: 'Prince',
    500: 'King',
    1000: 'Emperor',
  };

  static String getRandomQuote() {
    return royalQuotes[_random.nextInt(royalQuotes.length)];
  }

  static String getCommunityMeme() {
    return communityMemes[_random.nextInt(communityMemes.length)];
  }

  static String getLoadingMessage() {
    return loadingMessages[_random.nextInt(loadingMessages.length)];
  }

  static String getSuccessMessage() {
    return successMessages[_random.nextInt(successMessages.length)];
  }

  static String getErrorMessage() {
    return errorMessages[_random.nextInt(errorMessages.length)];
  }

  static String getEstatePun() {
    return estatePuns[_random.nextInt(estatePuns.length)];
  }

  static String getCrownTitle(int fractionsOwned) {
    String title = 'Peasant';
    for (var entry in crownTiers.entries) {
      if (fractionsOwned >= entry.key) {
        title = entry.value;
      }
    }
    return title;
  }

  // Legacy compatibility
  static String getCharlesQuote() => getRandomQuote();
}

/// Animated Crestadel Crown Logo
class AnimatedCrestadelLogo extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedCrestadelLogo({
    super.key,
    this.size = 100,
    this.color = const Color(0xFFD4AF37),
  });

  @override
  State<AnimatedCrestadelLogo> createState() => _AnimatedCrestadelLogoState();
}

class _AnimatedCrestadelLogoState extends State<AnimatedCrestadelLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: _glowAnimation.value),
                widget.color.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _glowAnimation.value * 0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '👑',
              style: TextStyle(fontSize: widget.size * 0.5),
            ),
          ),
        );
      },
    );
  }
}

// Keep legacy name for compatibility
class AnimatedCardanoLogo extends AnimatedCrestadelLogo {
  const AnimatedCardanoLogo({
    super.key,
    super.size = 100,
    super.color = const Color(0xFFD4AF37),
  });
}

/// Royal Easter Egg Widget - Tap to reveal wisdom
class CharlesEasterEgg extends StatefulWidget {
  final Widget child;
  final int tapsRequired;

  const CharlesEasterEgg({
    super.key,
    required this.child,
    this.tapsRequired = 5,
  });

  @override
  State<CharlesEasterEgg> createState() => _CharlesEasterEggState();
}

class _CharlesEasterEggState extends State<CharlesEasterEgg> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 2) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;

    if (_tapCount >= widget.tapsRequired) {
      _tapCount = 0;
      _showRoyalWisdom();
    }
  }

  void _showRoyalWisdom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                ),
              ),
              child: const Center(
                child: Text('👑', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Royal Wisdom',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CardanoMemes.getRandomQuote(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '- The Crestadel Court',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Long Live the Crown! 👑',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: widget.child,
    );
  }
}

/// Castle rise animation for successful transactions
class CastleRiseAnimation extends StatefulWidget {
  final VoidCallback? onComplete;

  const CastleRiseAnimation({super.key, this.onComplete});

  @override
  State<CastleRiseAnimation> createState() => _CastleRiseAnimationState();
}

class _CastleRiseAnimationState extends State<CastleRiseAnimation>
    with TickerProviderStateMixin {
  late AnimationController _castleController;
  late AnimationController _starsController;
  late Animation<double> _castleAnimation;

  @override
  void initState() {
    super.initState();
    _castleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _starsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _castleAnimation = Tween<double>(begin: 1.2, end: 0.3).animate(
      CurvedAnimation(parent: _castleController, curve: Curves.easeOutBack),
    );

    _castleController.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _castleController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Stars/sparkles background
        ...List.generate(15, (index) {
          final random = Random(index);
          return Positioned(
            left: random.nextDouble() * MediaQuery.of(context).size.width,
            top: random.nextDouble() * MediaQuery.of(context).size.height * 0.7,
            child: AnimatedBuilder(
              animation: _starsController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.3 + (_starsController.value * 0.7),
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                );
              },
            ),
          );
        }),
        // Crown at top
        Positioned(
          left: 0,
          right: 0,
          top: 60,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: const Text('👑', style: TextStyle(fontSize: 50)),
            ),
          ),
        ),
        // Rising Castle
        AnimatedBuilder(
          animation: _castleAnimation,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * _castleAnimation.value,
              child: Column(
                children: [
                  const Text('🏰', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'KINGDOM EXPANDED!',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// Legacy compatibility
class MoonRocketAnimation extends CastleRiseAnimation {
  const MoonRocketAnimation({super.key, super.onComplete});
}

/// Crown Badge - Shows user's royal title
class CrownBadge extends StatelessWidget {
  final int fractionsOwned;
  final bool showTitle;

  const CrownBadge({
    super.key,
    required this.fractionsOwned,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = CardanoMemes.getCrownTitle(fractionsOwned);
    final crownEmoji = _getCrownEmoji(title);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(crownEmoji, style: const TextStyle(fontSize: 14)),
          if (showTitle) ...[
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCrownEmoji(String title) {
    switch (title) {
      case 'Emperor':
        return '👑';
      case 'King':
        return '🤴';
      case 'Prince':
        return '🏰';
      case 'Duke':
        return '🏛️';
      case 'Earl':
        return '🎖️';
      case 'Viscount':
        return '⚔️';
      case 'Baron':
        return '🛡️';
      case 'Knight':
        return '🗡️';
      case 'Squire':
        return '📜';
      default:
        return '🌱';
    }
  }
}

// Legacy compatibility
class DiamondHandsBadge extends StatelessWidget {
  final bool isHodler;

  const DiamondHandsBadge({super.key, this.isHodler = true});

  @override
  Widget build(BuildContext context) {
    if (!isHodler) return const SizedBox.shrink();
    return const CrownBadge(fractionsOwned: 10, showTitle: true);
  }
}

/// Royal Loading Spinner with messages
class RoyalLoadingSpinner extends StatefulWidget {
  final String? customMessage;

  const RoyalLoadingSpinner({super.key, this.customMessage});

  @override
  State<RoyalLoadingSpinner> createState() => _RoyalLoadingSpinnerState();
}

class _RoyalLoadingSpinnerState extends State<RoyalLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _message = widget.customMessage ?? CardanoMemes.getLoadingMessage();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    if (widget.customMessage == null) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _message = CardanoMemes.getLoadingMessage();
          });
          return true;
        }
        return false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3 + _controller.value * 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: _controller.value * 0.2,
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _message,
            key: ValueKey(_message),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// Legacy compatibility
class AdaLoadingSpinner extends RoyalLoadingSpinner {
  const AdaLoadingSpinner({super.key, super.customMessage});
}

/// Crown Victory Dialog
void showCrownVictory(BuildContext context, {String? message, VoidCallback? onDismiss}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF0A0A0F),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
              ).createShader(bounds),
              child: const Text(
                'VICTORY!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? CardanoMemes.getSuccessMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const CrownBadge(fractionsOwned: 10),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                onDismiss?.call();
              },
              child: const Text(
                'Long Live the Crown! 👑',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Legacy compatibility
void showWagmiSuccess(BuildContext context, {String? message, VoidCallback? onDismiss}) {
  showCrownVictory(context, message: message, onDismiss: onDismiss);
}

/// Estate Pun Tooltip
class EstatePunTooltip extends StatefulWidget {
  final Widget child;
  final double probability;

  const EstatePunTooltip({
    super.key,
    required this.child,
    this.probability = 0.1,
  });

  @override
  State<EstatePunTooltip> createState() => _EstatePunTooltipState();
}

class _EstatePunTooltipState extends State<EstatePunTooltip> {
  bool _showPun = false;
  String _pun = '';

  @override
  void initState() {
    super.initState();
    final random = Random();
    if (random.nextDouble() < widget.probability) {
      _showPun = true;
      _pun = CardanoMemes.getEstatePun();

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showPun = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_showPun)
          Positioned(
            top: -65,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a1a2e), Color(0xFF0A0A0F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏰', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _pun,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Legacy compatibility
class MemeTooltip extends EstatePunTooltip {
  const MemeTooltip({
    super.key,
    required super.child,
    super.probability = 0.1,
  });
}

/// Realm Rank Display - Shows complete royal hierarchy
class RealmRankDisplay extends StatelessWidget {
  final int fractionsOwned;
  final double totalValue;

  const RealmRankDisplay({
    super.key,
    required this.fractionsOwned,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final title = CardanoMemes.getCrownTitle(fractionsOwned);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a1a2e),
            const Color(0xFFD4AF37).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👑', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'of the Crestadel Realm',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Properties', fractionsOwned.toString(), '🏰'),
              _buildStat('Treasury', '${totalValue.toStringAsFixed(0)} ₳', '💰'),
              _buildStat('Rank', _getRankPosition(title), '🏆'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _getRankPosition(String title) {
    final ranks = ['Peasant', 'Squire', 'Knight', 'Baron', 'Viscount', 'Earl', 'Duke', 'Prince', 'King', 'Emperor'];
    final index = ranks.indexOf(title);
    return '#${10 - index}';
  }
}
