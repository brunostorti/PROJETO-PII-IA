import 'package:flutter/material.dart';
import '../models/project.dart';
import '../utils/app_theme.dart';
import 'safe_image.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.width < 400 ? 20 : 28),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.5,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.98),
                        AppTheme.surfaceColor.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.width < 400 ? 20 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Cabeçalho moderno com nome, status e botão de exclusão
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.project.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.project.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getStatusColor(widget.project.status),
                                      _getStatusColor(widget.project.status).withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getStatusColor(widget.project.status).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.project.status.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.onDelete != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.redAccent,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Excluir Obra',
                                  onPressed: widget.onDelete,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Informações de localização e data com design premium
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.08),
                              AppTheme.secondaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.15),
                                        AppTheme.primaryLight.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.project.location,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.secondaryColor.withOpacity(0.15),
                                        AppTheme.secondaryColor.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Início: ${_formatDate(widget.project.startDate)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.textPrimaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (widget.project.endDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fim: ${_formatDate(widget.project.endDate!)}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppTheme.textSecondaryColor,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Galeria de imagens premium
                      if (widget.project.imageUrls.isNotEmpty)
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.surfaceColor,
                                Colors.white.withOpacity(0.5),
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.project.imageUrls.length} imagem(ns)',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textPrimaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.project.imageUrls.length > 3 ? 3 : widget.project.imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: AppTheme.subtleShadow,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: SafeImage(
                                          imageUrl: widget.project.imageUrls[index],
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Data de atualização com estilo premium
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.surfaceColor.withOpacity(0.6),
                              Colors.white.withOpacity(0.4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.textLightColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.textLightColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppTheme.textLightColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Atualizado ${_formatDateTime(widget.project.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textLightColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppTheme.warningColor;
      case ProjectStatus.inProgress:
        return AppTheme.primaryColor;
      case ProjectStatus.completed:
        return AppTheme.successColor;
      case ProjectStatus.paused:
        return AppTheme.accentColor;
      case ProjectStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
