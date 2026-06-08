import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/floating_particles_background.dart';
import '../utils/synth_engine.dart';

class CreatorProfile {
  final String name;
  final String username;
  final String status;
  final String imageUrl;
  final String role;
  final int likes;
  final String bio;
  final int songsInProgress;
  final List<String> genres;

  const CreatorProfile({
    required this.name,
    required this.username,
    required this.status,
    required this.imageUrl,
    required this.role,
    required this.likes,
    required this.bio,
    required this.songsInProgress,
    required this.genres,
  });
}

class AllCreatorsScreen extends StatefulWidget {
  const AllCreatorsScreen({super.key});

  @override
  State<AllCreatorsScreen> createState() => _AllCreatorsScreenState();
}

class _AllCreatorsScreenState extends State<AllCreatorsScreen> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  // 16 Detailed premium mock creators
  final List<CreatorProfile> _allCreators = const [
    CreatorProfile(
      name: 'Aria North',
      username: 'arianorth',
      status: 'Melody session at midnight 🌙',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      role: 'Vocalist',
      likes: 96,
      bio: 'Melody chaser. Story teller. Building sonic worlds that feel like home. Indie artist & producer from LA.',
      songsInProgress: 17,
      genres: ['Indie Pop', 'Chillwave'],
    ),
    CreatorProfile(
      name: 'kai.wav',
      username: 'kaiwav',
      status: 'Working on a new lofi EP',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      role: 'Producer',
      likes: 128,
      bio: 'Bedroom producer blending lofi beats with jazz chords. Always searching for the perfect vinyl crackle from Seattle.',
      songsInProgress: 8,
      genres: ['Lofi Hip Hop', 'Jazz Fusion'],
    ),
    CreatorProfile(
      name: 'prodbylance',
      username: 'prodbylance',
      status: 'Finishing touches on my new beat',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      role: 'Producer',
      likes: 210,
      bio: 'Multi-genre producer and sound designer. Specializing in trap beats, cinematic ambient, and synth-heavy pop tracks.',
      songsInProgress: 22,
      genres: ['Trap', 'Pop', 'Ambient'],
    ),
    CreatorProfile(
      name: 'milesonit',
      username: 'milesonit',
      status: 'Writing hooks that hit different',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
      role: 'Musician',
      likes: 77,
      bio: 'Guitarist and composer. Blending blues riffs with modern electronic elements. Session musician based in London.',
      songsInProgress: 6,
      genres: ['Blues Rock', 'Synthpop'],
    ),
    CreatorProfile(
      name: 'sunnie.day',
      username: 'sunnieday',
      status: 'Vocal layering in progress',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      role: 'Vocalist',
      likes: 142,
      bio: 'Vocalist and topliner. Specializing in warm, airy harmonies and uplifting hooks. Collaborating worldwide.',
      songsInProgress: 15,
      genres: ['House', 'Vocal Trance'],
    ),
    CreatorProfile(
      name: 'kidsonny',
      username: 'kidsonny',
      status: 'Drum textures experiment',
      imageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61',
      role: 'Musician',
      likes: 88,
      bio: 'Drummer and percussion designer. Crafting unique organic rhythms and acoustic fusions.',
      songsInProgress: 11,
      genres: ['IDM', 'Acoustic Fusion'],
    ),
    CreatorProfile(
      name: 'Luna Eclipse',
      username: 'luna_eclipse',
      status: 'Deep dark synthwave lines tonight 🌌',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      role: 'Producer',
      likes: 184,
      bio: 'Synthwave explorer. Crafting nostalgic retro tracks with heavy analog baselines. Obsessed with 80s aesthetics.',
      songsInProgress: 14,
      genres: ['Synthwave', 'Cyberpunk'],
    ),
    CreatorProfile(
      name: 'Marcus Vox',
      username: 'marcusvox',
      status: 'Recording voice overs for podcasts',
      imageUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea',
      role: 'Vocalist',
      likes: 62,
      bio: 'Deep baritone vocalist and voice actor. Specializing in soulful spoken word, deep house overlays, and ambient hooks.',
      songsInProgress: 5,
      genres: ['Soulful House', 'Spoken Word'],
    ),
    CreatorProfile(
      name: 'Chloe Keys',
      username: 'chloekeys',
      status: 'Writing a piano ballad 🎹',
      imageUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04',
      role: 'Musician',
      likes: 155,
      bio: 'Classical pianist turned electronic composer. Mixing delicate keys with heavy industrial sub-bass.',
      songsInProgress: 19,
      genres: ['Neo-Classical', 'Ambient Techno'],
    ),
    CreatorProfile(
      name: 'DJ Spark',
      username: 'djspark',
      status: 'Setting up tour dates for Summer',
      imageUrl: 'https://images.unsplash.com/photo-1557296387-5358ad7997bb',
      role: 'Producer',
      likes: 290,
      bio: 'Club DJ and EDM producer from Berlin. Creating high-energy tech house and driving techno tracks.',
      songsInProgress: 25,
      genres: ['Tech House', 'Techno'],
    ),
    CreatorProfile(
      name: 'Elena Rose',
      username: 'elenarose',
      status: 'Acoustic sessions in the woods',
      imageUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956',
      role: 'Vocalist',
      likes: 104,
      bio: 'Folk singer-songwriter. Strumming my way through melancholic lyrics and rustic melodies.',
      songsInProgress: 9,
      genres: ['Indie Folk', 'Acoustic'],
    ),
    CreatorProfile(
      name: 'Bax Beatbox',
      username: 'baxbeatbox',
      status: 'Synthesizing vocal beats',
      imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6',
      role: 'Musician',
      likes: 92,
      bio: 'Professional beatboxer and organic sound designer. I create full song beats using 100% vocal frequencies.',
      songsInProgress: 7,
      genres: ['Hip Hop', 'Experimental'],
    ),
    CreatorProfile(
      name: 'Zoe Synth',
      username: 'zoesynth',
      status: 'Modulating modular grids 🎛️',
      imageUrl: 'https://images.unsplash.com/photo-1548142813-c348350df52b',
      role: 'Producer',
      likes: 215,
      bio: 'Eurorack enthusiast. Building complex generative soundscapes and algorithmic textures.',
      songsInProgress: 18,
      genres: ['Modular Ambient', 'Glitch'],
    ),
    CreatorProfile(
      name: 'Leo Bass',
      username: 'leobass',
      status: 'Slapping the low end 🎸',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
      role: 'Musician',
      likes: 110,
      bio: 'Groove-oriented electric bassist. Adding funk and drive to modern pop and hip-hop sessions.',
      songsInProgress: 12,
      genres: ['Funk', 'R&B', 'Neo-Soul'],
    ),
    CreatorProfile(
      name: 'Aiden Sparks',
      username: 'aidensparks',
      status: 'Foley recording in the city streets',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
      role: 'Producer',
      likes: 130,
      bio: 'Sound designer and cinematic producer. Transforming ambient street noises into rhythmic tracks.',
      songsInProgress: 16,
      genres: ['Cinematic', 'IDM'],
    ),
    CreatorProfile(
      name: 'Vera Harmonics',
      username: 'veraharmonics',
      status: 'Harp recordings with delay loops 🎼',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      role: 'Musician',
      likes: 172,
      bio: 'Classical harpist exploring electronic effects pedals, shimmer delays, and loop stations.',
      songsInProgress: 10,
      genres: ['Neo-Classical', 'Ambient Dream'],
    )
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredCreators = _allCreators.where((creator) {
      final matchesSearch = creator.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creator.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          creator.bio.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _selectedRoleFilter == 'All' || creator.role == _selectedRoleFilter;

      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF07070B),
      body: Stack(
        children: [
          // Floating particles background
          const Positioned.fill(
            child: FloatingParticlesBackground(),
          ),
          
          // Main content
          Positioned.fill(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar / Top Navigation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text(
                            'Back to Home',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD03BFF), Color(0xFF00FFCC)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.waves, color: Colors.black, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Studduo',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Directory Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Studduo Community',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect, brainstorm, and build song ideas with ${_allCreators.length} active creators online.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Search & Filters Row
                          _buildSearchAndFilters(),
                        ],
                      ),
                    ),
                  ),

                  // Creators Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    sliver: filteredCreators.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: Center(
                                child: Text(
                                  'No creators found matching your query.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getResponsiveGridColumns(context),
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 0.76,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final creator = filteredCreators[index];
                                return _buildCreatorCard(creator);
                              },
                              childCount: filteredCreators.length,
                            ),
                          ),
                  ),

                  // Footer Space
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getResponsiveGridColumns(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 950) return 2;
    if (width < 1250) return 3;
    return 4;
  }

  Widget _buildSearchAndFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 750;
        final searchField = Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name, handle, or bio...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        );

        final filters = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['All', 'Producer', 'Vocalist', 'Musician'].map((role) {
            final isSelected = _selectedRoleFilter == role;
            return ChoiceChip(
              label: Text(role == 'All' ? 'All Roles' : '${role}s'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedRoleFilter = role);
                }
              },
              backgroundColor: const Color(0xFF13131A),
              selectedColor: const Color(0xFF6C3BF5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.05),
                ),
              ),
            );
          }).toList(),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 16),
              filters,
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 24),
              filters,
            ],
          );
        }
      },
    );
  }

  Widget _buildCreatorCard(CreatorProfile creator) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Creator Image Header
          Expanded(
            flex: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  creator.imageUrl,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
                // Role Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C3BF5).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      creator.role,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // Overlay active status
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF00FFCC), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          creator.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Card Body
          Expanded(
            flex: 12,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          creator.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${creator.songsInProgress} active',
                        style: const TextStyle(color: Color(0xFFD03BFF), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${creator.username}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      creator.bio,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Genres Row
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: creator.genres.take(2).map((genre) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        genre,
                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  
                  // Action Vibe check button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FFCC).withOpacity(0.1),
                        foregroundColor: const Color(0xFF00FFCC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // Play preview vibration synth sounds
                        final randNotes = ['C', 'G', 'Am', 'F'];
                        final note = randNotes[Random().nextInt(randNotes.length)];
                        SynthEngine.playChord(note);
                        SynthEngine.playDrum('hat');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Previewing vibe sound signature for @${creator.username} in key of $note!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.volume_up_outlined, size: 12),
                      label: const Text('Vibe Check', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
