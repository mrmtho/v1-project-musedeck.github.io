import 'package:flutter/material.dart';
import 'dashboard.dart';
import '../widgets/floating_particles_background.dart';
import 'all_creators.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class Creator {
  final String name;
  final String username;
  final String status;
  final String imageUrl;
  final int likes;
  final int comments;
  final String bio;
  final int songsInProgress;
  final List<Map<String, String>> releases;

  const Creator({
    required this.name,
    required this.username,
    required this.status,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.bio,
    required this.songsInProgress,
    required this.releases,
  });
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  late Creator _selectedCreator;

  final List<Creator> _creators = const [
    Creator(
      name: 'Aria North',
      username: 'arianorth',
      status: 'Melody session at midnight 🌙',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      likes: 96,
      comments: 18,
      bio:
          'Melody chaser. Story teller. Building sonic worlds that feel like home. Indie artist & producer from LA.',
      songsInProgress: 17,
      releases: [
        {'title': 'Glass House', 'type': 'EP • 2024'},
        {'title': 'Overthinker', 'type': 'Single • 2024'},
        {'title': 'Bloom', 'type': 'EP • 2023'},
      ],
    ),
    Creator(
      name: 'kai.wav',
      username: 'kaiwav',
      status: 'Working on a new lofi EP',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      likes: 128,
      comments: 24,
      bio:
          'Bedroom producer blending lofi beats with jazz chords. Always searching for the perfect vinyl crackle. Creating sounds to study, relax, or sleep to from my home studio in Seattle.',
      songsInProgress: 8,
      releases: [
        {'title': 'Chilled Waves', 'type': 'EP • 2025'},
        {'title': 'Rainy Sundays', 'type': 'Single • 2025'},
      ],
    ),
    Creator(
      name: 'prodbylance',
      username: 'prodbylance',
      status: 'Finishing touches on my new beat',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      likes: 210,
      comments: 36,
      bio:
          'Multi-genre producer and sound designer. Specializing in hard-hitting trap beats, cinematic ambient soundscapes, and synth-heavy pop tracks. Let\'s build something legendary.',
      songsInProgress: 22,
      releases: [
        {'title': 'Neo Tokyo', 'type': 'Album • 2025'},
        {'title': 'Shattered Mirrors', 'type': 'EP • 2024'},
      ],
    ),
    Creator(
      name: 'milesonit',
      username: 'milesonit',
      status: 'Writing hooks that hit different',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
      likes: 77,
      comments: 12,
      bio:
          'Guitarist and composer. Blending blues riffs with modern electronic elements. I write hooks that stay in your head all day. Session musician and co-writer based in London.',
      songsInProgress: 6,
      releases: [
        {'title': 'String Theory', 'type': 'Single • 2025'},
      ],
    ),
    Creator(
      name: 'sunnie.day',
      username: 'sunnieday',
      status: 'Vocal layering in progress',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      likes: 142,
      comments: 31,
      bio:
          'Vocalist and topliner. Specializing in warm, airy harmonies and uplifting hooks. Collaborating with electronic and house music producers worldwide.',
      songsInProgress: 15,
      releases: [
        {'title': 'Golden Hour', 'type': 'EP • 2024'},
        {'title': 'Lost in the Groove', 'type': 'Single • 2024'},
      ],
    ),
    Creator(
      name: 'kidsonny',
      username: 'kidsonny',
      status: 'Drum textures experiment',
      imageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61',
      likes: 88,
      comments: 17,
      bio:
          'Drummer and percussion designer. Crafting unique organic rhythms and acoustic fusions. Bridging the gap between live instruments and synthesized beats.',
      songsInProgress: 11,
      releases: [
        {'title': 'Pulse', 'type': 'EP • 2024'},
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCreator = _creators[0];
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      body: Stack(
        children: [
          // Pleasingly floating particle background behind the content
          const Positioned.fill(child: FloatingParticlesBackground()),

          // Main layout containing fixed header and scrollable content
          Positioned.fill(
            child: Column(
              children: [
                // Top Header (Fixed at the top)
                _buildHeader(context),

                // Scrollable hero content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Main Content Area (Max width wrapper for desktop elegance)
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                // Hero Section
                                _buildHeroSection(),
                                const SizedBox(height: 100),

                                // Value Propositions Section
                                _buildValuePropsSection(),
                                const SizedBox(height: 100),

                                // Social Proof Section (Pinterest layout & profile preview)
                                _buildSocialProofSection(),
                                const SizedBox(height: 80),

                                // Listen Everywhere Banner
                                // _buildListenEverywhereSection(),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),

                        // Footer Section
                        _buildFooterSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF07070B).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
        ),
      ),
      child: Row(
        children: [
          // Logo (left side)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD03BFF), Color(0xFF00FFCC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.waves, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Studduo',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // CTA & Login button (right side)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3BF5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF6C3BF5).withOpacity(0.4),
            ),
            onPressed: _navigateToDashboard,
            child: const Text(
              'Start Right Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _navigateToDashboard,
            icon: const Icon(Icons.person_outline, size: 16),
            label: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = (screenWidth * 0.08).clamp(36.0, 120.0);
    final double subtitleFontSize = (titleFontSize * 0.25).clamp(15.0, 30.0);
    final double titleLetterSpacing = (titleFontSize * -0.0125).clamp(-1.8, -0.4);

    return Column(
      children: [
        const SizedBox(height: 60),
        // H1 Heading
        Text(
          'Make Songs That\nMove Your Soul',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleFontSize,
            height: 1.1,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
            letterSpacing: titleLetterSpacing,
          ),
        ),
        const SizedBox(height: 24),
        // H3 Subheading
        Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Text(
            'Create nuanced melodies, rich textures, and the emotional resonance your music deserves.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: subtitleFontSize,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 50),

        // Grid of 3 Artists making music
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 750;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isMobile ? 1.4 : 0.85,
              children: [
                _buildArtistCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1593697972672-b1c1902219e4',
                  title: 'Create',
                  description: 'Spark ideas in your space',
                  // subText: 'Coming up with the music in their bedroom',
                  icon: Icons.edit_note,
                ),
                _buildArtistCard(
                  imageUrl:
                      'https://plus.unsplash.com/premium_photo-1683115179716-8463fcfca85b',
                  title: 'Produce',
                  description: 'Shape your sound with depth',
                  // subText: 'Recording/producing music in studio',
                  icon: Icons.graphic_eq,
                ),
                _buildArtistCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819',
                  title: 'Perform',
                  description: 'Share it. Feel it. Live it.',
                  // subText: 'Performing music on stage',
                  icon: Icons.mic_external_on,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 40),

        // CTA: Start Right Now ->
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C3BF5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF6C3BF5).withOpacity(0.5),
          ),
          onPressed: _navigateToDashboard,
          icon: const Text(
            'Start Right Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          label: const Icon(Icons.arrow_forward, size: 16),
        ),
      ],
    );
  }

  Widget _buildArtistCard({
    required String imageUrl,
    required String title,
    required String description,
    // String subText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(imageUrl, fit: BoxFit.cover),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // Text Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF00FFCC),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                // Text(
                //   subText,
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.4),
                //     fontSize: 11,
                //     fontStyle: FontStyle.italic,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- VALUE PROPS SECTION ---
  Widget _buildValuePropsSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F16),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile) ...[
                _buildValuePropsLeft(),
                const SizedBox(height: 40),
                _buildValuePropsRight(isMobile),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildValuePropsLeft()),
                    const SizedBox(width: 40),
                    Expanded(flex: 3, child: _buildValuePropsRight(isMobile)),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildValuePropsLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUILT FOR CREATORS',
          style: TextStyle(
            color: Color(0xFFD03BFF),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Go deep,\nnot just fast.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 45,
            height: 1.1,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C3BF5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: _navigateToDashboard,
          icon: const Text(
            'Start Right Now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          label: const Icon(Icons.arrow_forward, size: 14),
        ),
      ],
    );
  }

  Widget _buildValuePropsRight(bool isMobile) {
    Widget buildCol(IconData icon, String title, String desc) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C3BF5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C3BF5).withOpacity(0.2),
                ),
              ),
              child: Icon(icon, color: const Color(0xFF00FFCC), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        buildCol(
          Icons.local_cafe_outlined,
          'Brew every idea',
          'Capture every inspiration and cook it up nicely at your pace until it’s ready.',
        ),
        buildCol(
          Icons.people_outline,
          'Link up with colleagues',
          'Find your teams and bring your artistic vision to life together.',
        ),
        buildCol(
          Icons.trending_up,
          'Stay uptodate with industry',
          'Get curated insights, trends, and tools to keep you on point.',
        ),
      ],
    );
  }

  // --- SOCIAL PROOF / PINTEREST SECTION ---
  Widget _buildSocialProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 650;
            final Widget headerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'People are '),
                      TextSpan(
                        text: 'working',
                        style: TextStyle(color: Color(0xFF00FFCC)),
                      ),
                      TextSpan(text: ' on Studduo'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '1,245 creators online right now',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final Widget button = OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllCreatorsScreen(),
                  ),
                );
              },
              child: const Text(
                'View all creators',
                style: TextStyle(fontSize: 12),
              ),
            );

            if (isSmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [headerText, const SizedBox(height: 16), button],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: headerText),
                  const SizedBox(width: 16),
                  button,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 32),

        // Responsive grid view of creators + Profile view panel
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 900;
            if (isMobile) {
              return Column(
                children: [
                  _buildSelectedCreatorProfileCard(),
                  const SizedBox(height: 24),
                  _buildCreatorGrid(isMobile: true),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildCreatorGrid(isMobile: false)),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: _buildSelectedCreatorProfileCard()),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildCreatorGrid({required bool isMobile}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _creators.length,
      itemBuilder: (context, index) {
        final creator = _creators[index];
        final isSelected = _selectedCreator.username == creator.username;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCreator = creator;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1C1B26)
                  : const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C3BF5)
                    : Colors.white.withOpacity(0.04),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(creator.imageUrl, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(creator.imageUrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  creator.status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.pink, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${creator.likes}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.mode_comment,
                      color: Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${creator.comments}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCreatorProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image & Avatar Overlay
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C3BF5), Color(0xFFD03BFF)],
                  ),
                ),
                child: Opacity(
                  opacity: 0.3,
                  child: Image.network(
                    _selectedCreator.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF13131A),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: NetworkImage(_selectedCreator.imageUrl),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),

          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedCreator.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_selectedCreator.username}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3BF5).withOpacity(0.2),
                    foregroundColor: const Color(0xFFD03BFF),
                    side: const BorderSide(color: Color(0xFF6C3BF5), width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Follow',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedCreator.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Color(0xFF00FFCC),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedCreator.songsInProgress} songs in progress',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 40, color: Colors.white10),

          // Public Releases
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Public Releases',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(color: Color(0xFF00FFCC), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          ..._selectedCreator.releases.map(
            (release) => _buildReleaseItem(release['title']!, release['type']!),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReleaseItem(String title, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF6C3BF5).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.album,
                color: Color(0xFF6C3BF5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // DSP icons
            Row(
              children: [
                _buildDspIcon(Icons.play_circle_fill, Colors.green),
                const SizedBox(width: 6),
                _buildDspIcon(Icons.apple, Colors.white),
                const SizedBox(width: 6),
                _buildDspIcon(Icons.video_library, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDspIcon(IconData icon, Color color) {
    return Tooltip(
      message: 'Listen',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  // --- LISTEN EVERYWHERE ---
  Widget _buildListenEverywhereSection() {
    Widget buildBrand(IconData icon, String name, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Listen everywhere',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your music, everywhere your fans are.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 10,
          children: [
            buildBrand(Icons.play_circle_fill, 'Spotify', Colors.green),
            buildBrand(Icons.apple, 'Apple Music', Colors.white),
            buildBrand(Icons.video_library, 'YouTube', Colors.red),
            buildBrand(Icons.cloud_queue, 'SoundCloud', Colors.orange),
            buildBrand(Icons.library_music, 'Deezer', Colors.cyan),
            buildBrand(Icons.music_video, 'Tidal', Colors.blueAccent),
          ],
        ),
      ],
    );
  }

  // --- FOOTER SECTION ---
  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF040406),
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 30),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;
                  return Column(
                    children: [
                      if (isMobile) ...[
                        _buildFooterAbout(),
                        const SizedBox(height: 40),
                        _buildFooterLinks(),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildFooterAbout()),
                            const Spacer(),
                            Expanded(flex: 6, child: _buildFooterLinks()),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const Divider(height: 60, color: Colors.white10),
              // Bottom bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 Studduo. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF13131A),
                    value: 'English',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Row(
                          children: [
                            Icon(Icons.language, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'English',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD03BFF), Color(0xFF00FFCC)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.waves, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Studduo',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'AI Powered Workstation for Music Artists',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSocialIcon(Icons.camera_alt),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.chat_bubble_outline),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.play_circle_outline),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.hub_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
    );
  }

  Widget _buildFooterLinks() {
    Widget buildCol(String title, List<String> links) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                link,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCol('Company', ['About Us', 'Contact Us', 'Operational Status']),
        buildCol('Resources', [
          'Help Center',
          'Pricing',
          'Blog',
          'Community',
          'Download Android',
          'Download iOS',
          'Download Huawei',
        ]),
        buildCol('Legal', [
          'Terms and Conditions',
          'Privacy Policy',
          'Cookie Policy',
        ]),
      ],
    );
  }
}
