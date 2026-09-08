import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'admin_tambola_configurator_page.dart';

class AdminTicketsTab extends StatefulWidget {
  const AdminTicketsTab({super.key});

  @override
  State<AdminTicketsTab> createState() => _AdminTicketsTabState();
}

class _AdminTicketsTabState extends State<AdminTicketsTab> {
  int _currentPage = 1;
  static const int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Case-insensitive matcher for Ticket ID with support for '#', prefixes, and clean IDs
  bool _matchesTicketId(TicketModel ticket, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final ticketId = ticket.ticketId.toLowerCase();
    if (ticketId.contains(query)) return true;

    if (query.startsWith('#')) {
      final stripped = query.substring(1).trim();
      if (stripped.isNotEmpty && ticketId.contains(stripped)) return true;
    }

    final cleanQuery = query.replaceAll(RegExp(r'[\s\-_#]'), '');
    final cleanTicketId = ticketId.replaceAll(RegExp(r'[\s\-_#]'), '');
    if (cleanQuery.isNotEmpty && cleanTicketId.contains(cleanQuery)) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, provider, _) {
        final allTickets = provider.tickets;
        final totalPool = provider.formattedTotalPrizePool;
        final activeCount = provider.activeDrawsCount;

        final bool isFiltering = _searchQuery.trim().isNotEmpty;
        final List<TicketModel> filteredTickets = isFiltering
            ? allTickets.where((t) => _matchesTicketId(t, _searchQuery)).toList()
            : allTickets;

        final int totalTickets = filteredTickets.length;
        final int totalPages =
            (totalTickets / _pageSize).ceil().clamp(1, 999999);
        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }
        if (_currentPage < 1) {
          _currentPage = 1;
        }

        final int startIndex = (_currentPage - 1) * _pageSize;
        final int endIndex = (startIndex + _pageSize).clamp(0, totalTickets);
        final List<TicketModel> pagedTickets = totalTickets == 0
            ? <TicketModel>[]
            : filteredTickets.sublist(startIndex, endIndex);

        return Column(
          children: [
            // Admin Branded Header
            const GaGaAppHeader(
              compact: true,
              title: 'Ticket Management',
              subtitle: 'Admin Portal • Ticket Management',
              showSearch: false,
              showBalance: false,
            ),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: () => provider.fetchTickets(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingLarge,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Small Quick Action & Statistics Cards
                      _buildSmallCardsSection(
                        context,
                        totalTickets: allTickets.length,
                        activeDraws: activeCount,
                        totalPrizePool: totalPool,
                      ),

                      const SizedBox(height: 20),

                      // Section 2: Header with Live Ticket Count & Pagination Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Published Draw Tickets',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isFiltering
                                  ? '$totalTickets found • Page $_currentPage of $totalPages'
                                  : (allTickets.isEmpty
                                      ? '0 in DB'
                                      : '${allTickets.length} in DB • Page $_currentPage of $totalPages'),
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Section 2.5: Dedicated Ticket ID Search Filter Bar
                      _buildSearchFilterBar(
                        isFiltering: isFiltering,
                        totalResults: totalTickets,
                      ),

                      // Active Filter Indicator / Clear Action
                      if (isFiltering) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_alt_rounded,
                                    size: 13,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filtering by Ticket ID: "$_searchQuery"',
                                    style: const TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '($totalTickets ${totalTickets == 1 ? "match" : "matches"})',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: Color(0xFFD32F2F),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Clear Filter',
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Section 3: Tickets List with Pagination (Default 5)
                      if (provider.isLoading && allTickets.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                                color: AppColors.primaryGreen),
                          ),
                        )
                      else if (allTickets.isEmpty)
                        _buildEmptyState(context)
                      else if (filteredTickets.isEmpty)
                        _buildNoSearchResultsState(context, _searchQuery)
                      else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedTickets.length,
                          itemBuilder: (context, index) {
                            return _buildAdminTicketCard(
                              context,
                              pagedTickets[index],
                              isMatched: isFiltering &&
                                  _matchesTicketId(
                                      pagedTickets[index], _searchQuery),
                            );
                          },
                        ),
                        _buildPaginationControls(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          totalTickets: totalTickets,
                          startIndex: startIndex,
                          endIndex: endIndex,
                          isFiltered: isFiltering,
                        ),
                      ],

                      const SizedBox(
                          height: 80), // Extra scroll room for bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Small Cards: Create Ticket + 3 Statistics Cards
  Widget _buildSmallCardsSection(
    BuildContext context, {
    required int totalTickets,
    required int activeDraws,
    required String totalPrizePool,
  }) {
    return Column(
      children: [
        // Row 1: Create Ticket (Action) & Total Tickets (Stat)
        Row(
          children: [
            // Create Ticket Small Card
            Expanded(
              child: _buildCreateTicketCard(context),
            ),
            const SizedBox(width: 12),
            // Total Tickets Stat Card
            Expanded(
              child: _buildStatCard(
                title: 'Total Draws',
                value: '$totalTickets Tickets',
                subtitle: 'Created in Database',
                icon: Icons.confirmation_number_rounded,
                badgeColor: const Color(0xFFE8F5E9),
                iconColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Active Draws & Total Prize Pool
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Active Draws',
                value: '$activeDraws Live',
                subtitle: 'Open for Booking',
                icon: Icons.play_circle_filled_rounded,
                badgeColor: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total Pool',
                value: totalPrizePool,
                subtitle: 'Combined Prizes',
                icon: Icons.emoji_events_rounded,
                badgeColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Interactive Small Card to Create Ticket and open Modal
  Widget _buildCreateTicketCard(BuildContext context) {
    return InkWell(
      onTap: () => _showCreateTicketModal(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.greenGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+ Create Ticket',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap to Add Draw',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Small Statistic Card
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Admin Card representing a published draw ticket
  Widget _buildAdminTicketCard(
    BuildContext context,
    TicketModel ticket, {
    bool isMatched = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMatched
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withOpacity(0.18),
          width: isMatched ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isMatched
                ? AppColors.primaryGreen.withOpacity(0.14)
                : AppColors.primaryGreen.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Autogen Ticket ID, Status & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? AppColors.primaryGreen.withOpacity(0.18)
                          : AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMatched
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreen.withOpacity(0.25),
                        width: isMatched ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMatched) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          ticket.ticketId,
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                ticket.price,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Title & Schedule
          Text(
            ticket.ticketTitle,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                ticket.drawDate,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded,
                  size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                ticket.drawTime,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Pool: ${ticket.totalPrize}',
                style: const TextStyle(
                  color: Color(0xFF0F4A33),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Divider(height: 18),

          // Prizes Chips Preview
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...ticket.prizes.take(3).map((p) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBF9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 0.6),
                  ),
                  child: Text(
                    '${p.name}: ${p.price}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
              if (ticket.prizes.length > 3)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '+${ticket.prizes.length - 3} more',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Action Row: Prizes Count & Edit Ticket Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ticket.prizes.length} Prize Tiers Included',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Setup/View Tambola Numbers button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminTambolaConfiguratorPage(ticket: ticket),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00B894).withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.grid_on_rounded,
                            size: 14,
                            color: Color(0xFF00B894),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tambola Numbers',
                            style: TextStyle(
                              color: Color(0xFF00B894),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit Ticket
                  InkWell(
                    onTap: () => _showTicketModal(context, ticketToEdit: ticket),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 15,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Edit Ticket',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pagination controls with previous, next and page indicators
  Widget _buildPaginationControls({
    required int currentPage,
    required int totalPages,
    required int totalTickets,
    required int startIndex,
    required int endIndex,
    bool isFiltered = false,
  }) {
    if (totalTickets == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info: Showing 1–5 of 12 (Filtered)
          Text(
            isFiltered
                ? 'Showing ${startIndex + 1}–$endIndex of $totalTickets (Filtered)'
                : 'Showing ${startIndex + 1}–$endIndex of $totalTickets',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Pagination Buttons: [<] Page 1 of 3 [>]
          Row(
            children: [
              // Previous Page Button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: currentPage > 1
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                ),
                onPressed: currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Next Page Button
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: currentPage < totalPages
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                ),
                onPressed: currentPage < totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Search filter bar dedicated to filtering tickets by Ticket ID
  Widget _buildSearchFilterBar({
    required bool isFiltering,
    required int totalResults,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFiltering
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withOpacity(0.2),
          width: isFiltering ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFiltering
                ? AppColors.primaryGreen.withOpacity(0.12)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 14,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 3),
                Text(
                  'TICKET ID',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
              },
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by Ticket ID (e.g. GAGA26000001)...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12.5,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _currentPage = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            )
          else
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  /// Empty state when a search filter query has no matching tickets
  Widget _buildNoSearchResultsState(BuildContext context, String query) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 38,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Matching Tickets Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No published ticket matches Ticket ID "$query".\nPlease verify the Ticket ID or reset your search filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _currentPage = 1;
              });
            },
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Reset Search Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: AppColors.primaryGreen.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Draw Tickets in Database',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "+ Create Ticket" above to publish your first draw ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the Create or Edit Ticket Modal with Form Inputs and Editable Prizes
  void _showTicketModal(BuildContext context, {TicketModel? ticketToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateTicketBottomSheet(
        ticketToEdit: ticketToEdit,
        onSaved: () {
          setState(() {
            _currentPage = 1;
          });
        },
      ),
    );
  }

  void _showCreateTicketModal(BuildContext context) {
    _showTicketModal(context);
  }
}

/// Modal Bottom Sheet for Admin Ticket Creation & Editing
class _CreateTicketBottomSheet extends StatefulWidget {
  final TicketModel? ticketToEdit;
  final VoidCallback? onSaved;

  const _CreateTicketBottomSheet({super.key, this.ticketToEdit, this.onSaved});

  @override
  State<_CreateTicketBottomSheet> createState() =>
      _CreateTicketBottomSheetState();
}

class _CreateTicketBottomSheetState extends State<_CreateTicketBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _autogenTicketId;
  late TextEditingController _titleController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _priceController;
  String _status = 'Active';
  bool _isPublishing = false;

  // Editable Prizes List
  late List<PrizeItem> _prizes;

  bool get isEdit => widget.ticketToEdit != null;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TicketProvider>(context, listen: false);

    if (widget.ticketToEdit != null) {
      final t = widget.ticketToEdit!;
      _autogenTicketId = t.ticketId;
      _titleController = TextEditingController(text: t.ticketTitle);
      _dateController = TextEditingController(text: t.drawDate);
      _timeController = TextEditingController(text: t.drawTime);
      _priceController = TextEditingController(text: t.price);
      _status = t.status;
      _prizes = t.prizes.map((p) => p.copyWith()).toList();
    } else {
      _autogenTicketId = provider.nextTicketId;
      _titleController = TextEditingController(
        text: 'GaGa Housie Draw #${provider.totalTicketsCount + 1}',
      );
      final now = DateTime.now();
      _dateController = TextEditingController(
        text:
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      );
      _timeController = TextEditingController(text: '08:00 PM');
      _priceController = TextEditingController(text: '₹20');
      _status = 'Active';
      _prizes = TicketModel.defaultPrizes();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  int get _calculatedPool {
    int sum = 0;
    for (final p in _prizes) {
      final numStr = p.price.replaceAll(RegExp(r'[^0-9]'), '');
      sum += int.tryParse(numStr) ?? 0;
    }
    return sum;
  }

  String get _formattedPool {
    return '₹${_calculatedPool.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  void _handlePickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _handlePickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        _timeController.text =
            '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  void _addPrizeTier() {
    setState(() {
      _prizes.add(PrizeItem(name: 'Bonus Prize', price: '₹1000'));
    });
  }

  void _removePrizeTier(int index) {
    if (_prizes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one prize is required')),
      );
      return;
    }
    setState(() {
      _prizes.removeAt(index);
    });
  }

  void _handleSaveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPublishing = true;
    });

    final provider = Provider.of<TicketProvider>(context, listen: false);

    if (isEdit) {
      final updatedTicket = widget.ticketToEdit!.copyWith(
        ticketTitle: _titleController.text.trim(),
        drawDate: _dateController.text.trim(),
        drawTime: _timeController.text.trim(),
        price: _priceController.text.trim().startsWith('₹')
            ? _priceController.text.trim()
            : '₹${_priceController.text.trim()}',
        totalPrize: _formattedPool,
        prizes: _prizes,
        status: _status,
      );

      final success = await provider.updateTicket(updatedTicket);

      if (!mounted) return;

      setState(() {
        _isPublishing = false;
      });

      if (success) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Ticket $_autogenTicketId updated successfully in DB!'),
            backgroundColor: const Color(0xFF196144),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update ticket'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } else {
      final newTicket = TicketModel(
        ticketId: _autogenTicketId,
        ticketTitle: _titleController.text.trim(),
        drawDate: _dateController.text.trim(),
        drawTime: _timeController.text.trim(),
        price: _priceController.text.trim().startsWith('₹')
            ? _priceController.text.trim()
            : '₹${_priceController.text.trim()}',
        totalPrize: _formattedPool,
        prizes: _prizes,
        status: _status,
        createdAt: DateTime.now(),
      );

      final success = await provider.createTicket(newTicket);

      if (!mounted) return;

      setState(() {
        _isPublishing = false;
      });

      if (success) {
        widget.onSaved?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Draw Ticket $_autogenTicketId created! Opening Tambola Setup...'),
            backgroundColor: const Color(0xFF196144),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Automatically navigate to Tambola Ticket Configurator just after creation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminTambolaConfiguratorPage(
              ticket: newTicket,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to create ticket'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEdit
                              ? 'Edit Draw Ticket'
                              : 'Create New Draw Ticket',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Autogenerated Ticket ID Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? 'TICKET ID (LOCKED)'
                                    : 'AUTOGENERATED TICKET ID (YEAR 26)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _autogenTicketId,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isEdit ? 'Read-Only' : 'Auto-Set',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Draw Title
                    _buildFieldLabel('Draw Title / Name'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        hint: 'e.g. GaGa Housie Mega Draw',
                        icon: Icons.title_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Title is required'
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // Date & Time Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Draw Date'),
                              InkWell(
                                onTap: _handlePickDate,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    controller: _dateController,
                                    decoration: _inputDecoration(
                                      hint: 'DD/MM/YYYY',
                                      icon: Icons.calendar_today_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Draw Time'),
                              InkWell(
                                onTap: _handlePickTime,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    controller: _timeController,
                                    decoration: _inputDecoration(
                                      hint: '08:00 PM',
                                      icon: Icons.access_time_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Ticket Price
                    _buildFieldLabel('Ticket Entry Price'),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.text,
                      decoration: _inputDecoration(
                        hint: 'e.g. ₹20 or ₹50',
                        icon: Icons.currency_rupee_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Price is required'
                          : null,
                    ),

                    if (isEdit) ...[
                      const SizedBox(height: 14),
                      _buildFieldLabel('Draw Status'),
                      Row(
                        children:
                            ['Active', 'Completed', 'Cancelled'].map((st) {
                          final selected =
                              _status.toLowerCase() == st.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(st),
                              selected: selected,
                              selectedColor: AppColors.primaryGreen,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _status = st;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Editable Prizes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prizes & Rewards',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'Total: $_formattedPool',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addPrizeTier,
                          icon: const Icon(Icons.add,
                              size: 16, color: AppColors.primaryGreen),
                          label: const Text(
                            '+ Add Tier',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.primaryGreen.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // List of Editable Prize Rows
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prizes.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final item = _prizes[index];
                          return Row(
                            children: [
                              // Prize Name Input
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: item.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    hintText: 'Prize Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    item.name = val;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Prize Price Input
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: item.price,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    hintText: '₹ Amount',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      item.price =
                                          val.startsWith('₹') ? val : '₹$val';
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red, size: 20),
                                onPressed: () => _removePrizeTier(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.greenGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.glowGreen,
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _handleSaveTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                isEdit
                                    ? 'Save Changes '
                                    : 'Save',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 19),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
      ),
    );
  }
}
