import 'package:flutter/material.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import 'loading_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTomorrowPlan(BuildContext context, String option) {
    final state = WardrobeScope.of(context);
    // Show transition loading screen while fetching updated outfit recommendation
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoadingScreen(
          displayUsername: state.username,
          task: () => state.updatePlan(option),
          nextRouteName: '/calendar',
          replaceCurrentOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = WardrobeScope.of(context);

    final matchingClothes = _query.trim().isEmpty
        ? const []
        : state.clothes.where((item) {
            final q = _query.toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                item.tags.toLowerCase().contains(q) ||
                item.color.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // Top header bar
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => state.setTab(0),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.limeBright,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/catalog'),
                icon: const Icon(
                  Icons.more_horiz,
                  color: Color(0xFF4A4A4A),
                  size: 28,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rounded black-bordered search input
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black, width: 2.2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val),
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: const InputDecoration(
                      hintText: 'Search wardrobe, colors, or tags...',
                      hintStyle: TextStyle(
                        color: Colors.black38,
                        fontSize: 13.5,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),

                // Live search results when user types a query
                if (matchingClothes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matching Clothes (${matchingClothes.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...matchingClothes.take(4).map(
                              (c) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text('${c.category} • ${c.color}'),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primaryGreen,
                                ),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/catalog'),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Suggestions header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/catalog'),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Card 1: Wardrobe Calendar
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/calendar'),
                  child: _SuggestionCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Wardrobe Calendar',
                    subtitle: 'click to see the changes',
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '5 new styles added on Mon, 31 Dec.',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.more_horiz,
                          color: Colors.black38,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Card 2: What's your plan for tomorrow?
                _SuggestionCard(
                  icon: Icons.assignment_outlined,
                  title: "What's your plan for tomorrow?",
                  subtitle: 'we will choose your style of dress for you',
                  child: Column(
                    children: [
                      _OptionRow(
                        label: 'I will be at the workplace',
                        isSelected:
                            state.selectedPlan == 'I will be at the workplace',
                        onTap: () => _selectTomorrowPlan(
                          context,
                          'I will be at the workplace',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OptionRow(
                        label: 'I will be free',
                        isSelected: state.selectedPlan == 'I will be free',
                        onTap: () => _selectTomorrowPlan(
                          context,
                          'I will be free',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _OptionRow(
                        label: "I'll try something new",
                        isSelected:
                            state.selectedPlan == "I'll try something new",
                        onTap: () => _selectTomorrowPlan(
                          context,
                          "I'll try something new",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Card 3: Style similarity prompt
                _SuggestionCard(
                  icon: Icons.question_mark_rounded,
                  title:
                      "this week's clothing styles are very similar to those of two weeks ago.",
                  child: Column(
                    children: [
                      _OptionRow(
                        label: "I'm gonna change my dress style for the week.",
                        centerText: true,
                        isSelected: state.selectedStyleChoice.contains('change'),
                        onTap: () {
                          state.updateStylePreference(
                            "I'm gonna change my dress style for the week.",
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Updated! Fresh style combinations prioritized for this week.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _OptionRow(
                        label: "I'll keep my dress style the same.",
                        isSelected: state.selectedStyleChoice.contains('keep'),
                        onTap: () {
                          state.updateStylePreference(
                            "I'll keep my dress style the same.",
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Got it! Keeping your current signature style.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Card 4: Monthly achievement banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "you've tried ${state.recommendation.monthlyStylesTried} different styles this month, you're amazing!",
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool centerText;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.isSelected,
    this.centerText = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: centerText ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: AppColors.textDark,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.limeBright,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: AppColors.primaryGreen, width: 1.5)
                    : null,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
