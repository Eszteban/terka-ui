import 'package:flutter_bloc/flutter_bloc.dart';

enum MainSection {
  home,
  table,
  map,
  news,
  profile,
  tickets,
  addTicket,
  editTicket,
  managePassTypes,
  passTypeEditor,
  about,
  tripDetails,
  stopDetails,
  routeDetails,
}

class NavigationState {
  final MainSection currentSection;
  final List<MainSection> history;

  const NavigationState({
    required this.currentSection,
    required this.history,
  });

  factory NavigationState.initial() {
    return const NavigationState(
      currentSection: MainSection.home,
      history: [MainSection.home],
    );
  }

  NavigationState copyWith({
    MainSection? currentSection,
    List<MainSection>? history,
  }) {
    return NavigationState(
      currentSection: currentSection ?? this.currentSection,
      history: history ?? this.history,
    );
  }
}

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.initial());

  void navigateTo(MainSection section, {bool addToHistory = true}) {
    final history = List<MainSection>.from(state.history);
    if (addToHistory) {
      final current = history.isNotEmpty ? history.last : MainSection.home;
      if (current != section) {
        history.add(section);
      }
    }
    emit(state.copyWith(
      currentSection: section,
      history: history,
    ));
  }

  bool handleBackNavigation({
    bool hasPlannerResultsPayload = false,
    void Function()? onShowMainScreen,
  }) {
    if (state.currentSection == MainSection.table && hasPlannerResultsPayload) {
      if (onShowMainScreen != null) {
        onShowMainScreen();
      }
      emit(NavigationState.initial());
      return false;
    }

    if (state.history.length <= 1) {
      return true;
    }

    final history = List<MainSection>.from(state.history)..removeLast();
    final previousSection = history.last;

    emit(state.copyWith(
      currentSection: previousSection,
      history: history,
    ));
    return false;
  }
}
