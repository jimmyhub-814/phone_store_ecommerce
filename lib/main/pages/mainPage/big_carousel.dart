import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/storages.dart';
import 'package:shimmer/shimmer.dart';

class BigCarouselWidget extends StatefulWidget {
  const BigCarouselWidget({super.key});

  @override
  State<BigCarouselWidget> createState() => _BigCarouselWidgetState();
}

Future<List<String>> getAllCarousel() async {
  final ref = Storages.carousels;
  final result = await ref.listAll();
  List<String> urls = [];

  for (var item in result.items) {
    final url = await item.getDownloadURL();
    urls.add(url);
  }

  return urls;
}

class _BigCarouselWidgetState extends State<BigCarouselWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getAllCarousel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 131,
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const SizedBox(
            height: 131,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Không thể tải hình ảnh',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final carouselImages = snapshot.data ?? [];

        if (carouselImages.isEmpty) {
          return const SizedBox(
            height: 131,
            child: Center(child: Text('Không có ảnh')),
          );
        }

        return Container(
          height: 131,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Swiper(
              itemBuilder: (context, index) {
                return Image.network(
                  carouselImages[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 131,
                        width: double.infinity,
                        color: Colors.black,
                      ),
                    );
                  },
                );
              },
              itemCount: carouselImages.length,
              autoplay: true,
            ),
          ),
        );
      },
    );
  }
}
