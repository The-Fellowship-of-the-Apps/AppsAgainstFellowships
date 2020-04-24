import 'package:appsagainsthumanity/data/features/game/game_repository.dart';
import 'package:appsagainsthumanity/ui/creategame/bloc/bloc.dart';
import 'package:appsagainsthumanity/internal.dart';
import 'package:appsagainsthumanity/ui/game/game_screen.dart';
import 'package:appsagainsthumanity/ui/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kt_dart/kt.dart';

class CreateGameScreen extends StatefulWidget {
  final Set<String> cardSets;

  CreateGameScreen({Set<String> sets}) : cardSets = sets ?? Set();

  @override
  State<StatefulWidget> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateGameBloc(
        widget.cardSets,
        context.repository(),
        context.repository(),
      )..add(ScreenLoaded()),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return BlocConsumer<CreateGameBloc, CreateGameState>(listener: (context, state) {
      if (state.error != null) {
        Scaffold.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(state.error), Icon(Icons.error)],
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    }, builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.strings.titleNewGame),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 8,
          color: AppColors.primary,
          shape: CircularNotchedRectangle(),
          child: Container(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "${state.selectedSets.size} Selected",
                      style: context.theme.textTheme.headline6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.play_arrow),
          onPressed: state.selectedSets.isNotEmpty()
              ? () async {
                  // Start game?
                  var newGame = await context.repository<GameRepository>().createGame(state.selectedSets);
                  Navigator.of(context)
                      .pushReplacement(GamePageRoute(newGame));
                }
              : null,
        ),
        body: _buildBody(state),
      );
    });
  }

  Widget _buildBody(CreateGameState state) {
    return Column(
      children: [
        Expanded(
          child: state.isLoading ? _buildLoading() : _buildList(state.cardSets, state.selectedSets),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      height: double.maxFinite,
      alignment: Alignment.center,
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildList(KtList<String> sets, KtSet<String> selected) {
    return ListView.builder(
      itemCount: sets.size,
      itemBuilder: (context, index) {
        var item = sets[index];
        var isSelected = selected.contains(item);
        return ListTile(
          title: Text(item),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          leading: Checkbox(
            value: isSelected,
            activeColor: AppColors.secondary,
            onChanged: (value) {
              context.bloc<CreateGameBloc>().add(CardSetSelected(item));
            },
          ),
          onTap: () {
            context.bloc<CreateGameBloc>().add(CardSetSelected(item));
          },
        );
      },
    );
  }
}
