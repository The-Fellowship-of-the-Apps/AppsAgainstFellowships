import 'package:appsagainsthumanity/data/features/game/game_repository.dart';
import 'package:appsagainsthumanity/data/features/users/model/user.dart';
import 'package:appsagainsthumanity/data/features/game/model/game_state.dart';
import 'package:appsagainsthumanity/ui/creategame/create_game_screen.dart';
import 'package:appsagainsthumanity/ui/game/game_screen.dart';
import 'package:appsagainsthumanity/ui/home/bloc/bloc.dart';
import 'package:appsagainsthumanity/ui/home/widgets/join_room_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appsagainsthumanity/internal.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.925);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(context.repository(), context.repository())..add(HomeStarted()),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (BuildContext context, HomeState state) {
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
      },
      builder: (context, state) {
        return Scaffold(
          body: ListView(
            children: [
              if (state.games.isNotEmpty)
                AspectRatio(
                  aspectRatio: 312 / 436,
                  child: PageView(
                    controller: _pageController,
                    children: [_buildTitleCard(state, includeMargin: false), _buildPastGamesCard(state)],
                  ),
                ),
              if (state.games.isEmpty) _buildTitleCard(state),
              Column(
                children: [
                  _buildJoinGameAction(),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: FloatingActionButton.extended(
                      label: Container(
                        margin: const EdgeInsets.only(left: 32, right: 48),
                        child: Text("NEW GAME"),
                      ),
                      icon: Icon(MdiIcons.gamepad),
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateGameScreen()));
                      },
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleCard(HomeState state, {bool includeMargin = true}) {
    return Container(
      margin: includeMargin
          ? const EdgeInsets.only(left: 24, right: 24, top: 24)
          : const EdgeInsets.only(left: 8, right: 8, top: 24),
      child: AspectRatio(
        aspectRatio: 312 / 436,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                child: Text(
                  context.strings.appNameDisplay,
                  style: context.theme.textTheme.headline3
                      .copyWith(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 48),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      child: state.isLoading
                          ? _buildLoadingUserTile()
                          : state.error != null ? _buildErrorUserTile(state.error) : _buildUserTile(state.user)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastGamesCard(HomeState state) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 24),
      child: AspectRatio(
        aspectRatio: 312 / 436,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                child: Text(
                  "Past Games",
                  style: context.theme.textTheme.headline3
                      .copyWith(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 48),
                ),
              ),
              Divider(
                color: Colors.black12,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: state.games.length,
                    itemBuilder: (context, index) {
                      var game = state.games[index];
                      print("Render ${game.gid}");
                      return ListTile(
                        title: Text(
                          game.gid,
                          style: context.theme.textTheme.subtitle1
                              .copyWith(color: AppColors.secondary, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          game.state.label,
                          style: context.theme.textTheme.bodyText2.copyWith(color: Colors.black54),
                        ),
                        trailing: Text(
                          timeago.format(game.joinedAt),
                          style: context.theme.textTheme.bodyText2.copyWith(color: Colors.black26),
                        ),
                        onTap: game.state == GameState.inProgress || game.state == GameState.waitingRoom
                            ? () async {
                                // Fetch and load game
                                try {
                                  var existingGame = await context.repository<GameRepository>()
                                      .findGame(game.gid);

                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => GameScreen(existingGame)
                                  ));
                                } catch (e) {
                                  Scaffold.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(SnackBar(
                                      content: Text("$e"),
                                    ));
                                }
                              }
                            : null,
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinGameAction() {
    return Container(
      height: 56,
      width: double.maxFinite,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Material(
        clipBehavior: Clip.hardEdge,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white30)),
        child: Builder(builder: (context) {
          return InkWell(
            onTap: () async {
              var gameId = await showJoinRoomDialog(context);
              if (gameId != null) {
                try {
                  var game = await context.repository<GameRepository>().joinGame(gameId);

                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(game)));
                } catch (e) {
                  Scaffold.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text("$e"),
                    ));
                }
              }
            },
            child: Row(
              children: [
                Container(
                  child: Icon(
                    MdiIcons.gamepadVariantOutline,
                    color: Colors.white70,
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                Container(
                  child: Text(
                    "Join game",
                    style: context.theme.textTheme.subtitle1.copyWith(color: Colors.white70),
                  ),
                )
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingUserTile() {
    return ListTile(
      title: Text(
        "Loading...",
        style: context.theme.textTheme.subtitle1.copyWith(color: Colors.black87),
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.withOpacity(0.4),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorUserTile(String error) {
    return ListTile(
      title: Text(
        "Error loading user",
        style: context.theme.textTheme.subtitle1.copyWith(color: Colors.black87),
      ),
      subtitle: Text(error),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.redAccent,
        child: Icon(
          MdiIcons.accountRemoveOutline,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        user.name,
        style: context.theme.textTheme.subtitle1.copyWith(color: Colors.black87),
      ),
      subtitle: Text(
        user.id,
        style: context.theme.textTheme.bodyText1.copyWith(color: Colors.black38),
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(user.avatarUrl),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
