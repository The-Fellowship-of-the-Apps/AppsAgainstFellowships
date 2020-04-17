import 'package:appsagainsthumanity/data/features/game/model/game.dart';
import 'package:appsagainsthumanity/data/features/game/model/game_state.dart';
import 'package:appsagainsthumanity/ui/game/bloc/bloc.dart';
import 'package:appsagainsthumanity/ui/game/screens/gameplay/game_play_screen.dart';
import 'package:appsagainsthumanity/ui/game/screens/starting/starting_room_screen.dart';
import 'package:appsagainsthumanity/ui/game/screens/waiting/waiting_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This screen will serve as the central serving point for the ENTIRE game state
/// changing the root body content of what is displayed to the user based on the game
/// state. These states will be sub-divided into their own, bloc (or-not) controlled,
/// screens/widgets
class GameScreen extends StatelessWidget {

  final Game game;

  GameScreen(this.game);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GameBloc(game, context.repository())
        ..add(Subscribe(game.id)),
      child: BlocBuilder<GameBloc, GameViewState>(
        condition: (previousState, currentState) {
          return previousState.game.state != currentState.game.state;
        },
        builder: (context, state) {
          if (state.game.state == GameState.waitingRoom) {
            return WaitingRoomScreen();
          } else if (state.game.state == GameState.starting) {
            return StartingRoomScreen(state);
          } else if (state.game.state == GameState.inProgress) {
            return GamePlayScreen(state);
          } else if (state.game.state == GameState.completed) {
            throw 'Show Game Completed Ui';
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
