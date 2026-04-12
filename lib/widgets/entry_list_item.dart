import 'package:flutter/material.dart';
import 'package:mangabaka_app/models/series.dart';

class EntryListItem extends StatelessWidget {
  final Series series;

  const EntryListItem({
    Key? key,
    required this.series,
  }) : super(key: key);

  String capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF18181B),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: series.coverUrl.isNotEmpty
                  ? Image.network(
                      series.coverUrl,
                      width: 80,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: double.infinity,
                          color: Colors.grey[900],
                          child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: double.infinity,
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${capitalize(series.type)} - ${capitalize(series.status)} - ${series.year}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: series.genres.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final genre = series.genres[index];
                          final genreLabel = genre.isNotEmpty
                              ? genre[0].toUpperCase() + genre.substring(1)
                              : genre;
                          return Chip(
                            label: Text(
                              genreLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.white70, width: 0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}