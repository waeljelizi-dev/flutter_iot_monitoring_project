import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_viewmodel.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bienvenue'),
              actions: [
                TextButton(
                  onPressed: () => viewModel.skip(context),
                  child: const Text('Ignorer',
                      style: TextStyle(color: const Color(0xFF256C98))),
                )
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: viewModel.pageController,
                    itemCount: viewModel.pages.length,
                    onPageChanged: viewModel.updatePage,
                    itemBuilder: (context, index) {
                      final page = viewModel.pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(page.imageAsset, height: 200),
                            const SizedBox(height: 32),
                            Text(
                              page.title,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.description,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    viewModel.pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: viewModel.currentPage == index ? 12 : 8,
                      height: viewModel.currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        color: viewModel.currentPage == index
                            ? Colors.blue
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () => viewModel.nextPage(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF256C98).withOpacity(0.8),
                    ),
                    child: Text(
                      viewModel.currentPage == viewModel.pages.length - 1
                          ? 'Commencer'
                          : 'Suivant',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
