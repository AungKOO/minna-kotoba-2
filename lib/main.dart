import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute using
import 'package:preferences/preferences.dart'; // setting page
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // floating action button
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:provider/provider.dart';
import 'package:admob_flutter/admob_flutter.dart';

import 'Chapter.dart';
import 'AppModel.dart';
import 'FlashCard.dart';
import 'Speak.dart';
import 'GlobalVar.dart';
import 'AboutPage.dart';
import 'VocalSearch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefService.init(prefix: 'pref_');
  Admob.initialize(getAppId());
  runApp(ChangeNotifierProvider(
    builder: (context) => AppModel(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
        defaultBrightness: Brightness.light,
        data: (brightness) => ThemeData(
              primarySwatch: Colors.amber,
              brightness: brightness,
            ),
        themedWidgetBuilder: (context, theme) {
          return MaterialApp(
            title: appTitle,
            theme: theme,
            home: MyHomePage(title: appTitle),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyHomePage> {
  int _drawerIndex = 0, _tabIndex = 0;
  bool isShowDrawerMenu = true,
      _isShowFavMenu = false,
      _isShowSearchMenu = true,
      _dialVisible = true,
      _isShuffle = false;
  List<String> _isShowKotoba = [];
  List<Chapter> _chapters;
  List<ListItem> _allWords = [];
  List<Vocal> _allVocals = [];
  List<Vocal> _allN5Vocals = [];
  List<Vocal> _allN4Vocals = [];
  ScrollController _scrollController = ScrollController();
  Speak speak = Speak();

  void _toggleTheShuffle() {
    if (_isShuffle) {
      _chapters[_drawerIndex].words.shuffle();
    } else {
      _chapters[_drawerIndex].words.sort((a, b) => int.parse(a.no.split("/")[1])
          .compareTo(int.parse(b.no.split("/")[1])));
    }
  }

  List<Widget> _buildDrawerList(BuildContext context, List<Chapter> _chapters) {
    List<Widget> drawer = [
      DrawerHeader(
          decoration: BoxDecoration(
        image: DecorationImage(
          image: logoAsset(),
          fit: BoxFit.cover,
        ),
      )),
    ];

    List<Widget> chapterTile = [];
    for (int i = 0; i < _chapters.length; i++) {
      Chapter chapter = _chapters[i];
      chapterTile.add(ListTile(
        title: Text(chapter.title),
        onTap: () {
          setState(() {
            _drawerIndex = i;
          });
          print('drawer index $i $_drawerIndex');
          PrefService.setInt("drawer_index", _drawerIndex);
          Navigator.of(context).pop(); // dismiss the navigator
          _scrollController.animateTo(0.0,
              duration: Duration(milliseconds: 500), curve: Curves.easeOut);
          _toggleTheShuffle();
        },
      ));
    }

    drawer.addAll(chapterTile);

    return drawer;
  }

  Widget _buildBodyList(BuildContext context) {
    String selectedJapanese =
        PrefService.getString("list_japanese") ?? listJapanese[0];
    String selectedMeaning =
        PrefService.getString("list_meaning") ?? listMeaning[0];
    String selectedMemorizing =
        PrefService.getString("list_memorizing") ?? listMemorizing[0];

    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: 66.0),
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _chapters[_drawerIndex].words.length,
            itemBuilder: (BuildContext context, int index) {
              Text japaneseText =
                  Text(_chapters[_drawerIndex].words[index].hiragana);
              if (selectedJapanese == listJapanese[1]) {
                japaneseText = Text(_chapters[_drawerIndex].words[index].kanji);
              } else if (selectedJapanese == listJapanese[2]) {
                japaneseText =
                    Text(_chapters[_drawerIndex].words[index].romaji);
              }

              Text meaningText = Text(
                  _chapters[_drawerIndex].words[index].myanmar,
                  style: TextStyle(fontFamily: 'Masterpiece'));

              if (selectedMeaning == listMeaning[1]) {
                meaningText =
                    Text(_chapters[_drawerIndex].words[index].english);
              }

              if (selectedMemorizing == listMemorizing[1]) {
                Text tmpText = japaneseText;
                japaneseText = meaningText;
                meaningText = tmpText;
              }

              // favorite condition
              bool isFav = Provider.of<AppModel>(context)
                  .isFav(_chapters[_drawerIndex].words[index].no);

              return buildCard(
                ListTile(
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.redAccent),
                      Text(_chapters[_drawerIndex].words[index].no),
                    ],
                  ),
                  title: AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 500),
                    child: japaneseText,
                  ),
                  subtitle: AnimatedOpacity(
                    opacity: (_isShowKotoba.length == 0 ||
                            (_isShowKotoba.contains(
                                _chapters[_drawerIndex].words[index].no)))
                        ? 1.0
                        : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: meaningText,
                  ),
                  onTap: () {
                    speak.tts(_chapters[_drawerIndex].words[index], context);
                    setState(() {
                      if (_isShowKotoba.length > 0) {
                        int removeInd = _isShowKotoba
                            .indexOf(_chapters[_drawerIndex].words[index].no);
                        if (removeInd > -1) {
                          _isShowKotoba.removeAt(removeInd);
                          print('_isShowKotoba removeInd $removeInd');
                        } else {
                          _isShowKotoba
                              .add(_chapters[_drawerIndex].words[index].no);
                          print(
                              '_isShowKotoba add ${_chapters[_drawerIndex].words[index].no}');
                        }
                      }
                    });
                  },
                  onLongPress: () {
                    Provider.of<AppModel>(context)
                        .toggle(_chapters[_drawerIndex].words[index].no, isFav);
                  },
                ),
              );
            },
          ),
        ),
        getAdmobBanner()
      ],
    );
  }

  Widget _buildSearchBodyList(BuildContext context, {bool isFavPage = false}) {
    Set favoriteList = Provider.of<AppModel>(context).get();
    List<Vocal> favVocals = [];

    if (isFavPage) {
      if (favoriteList.length > 0) {
        favVocals = Provider.of<AppModel>(context).getFavVocal(_allWords);
      } else {
        return Container(
          child: Center(
            child: Text("Please long press on the word to save as favorite ❤️"),
          ),
        );
      }
    }

    Widget makeList(Vocal vocal, bool isFav) {
      Text myanmarText =
          Text(vocal.myanmar, style: TextStyle(fontFamily: 'Masterpiece'));

      return buildCard(ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${vocal.hiragana} ${vocal.romaji}'),
            Text(vocal.kanji),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            myanmarText,
            Text(
              vocal.english,
            )
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: Colors.redAccent),
            Text(vocal.no),
          ],
        ),
        onTap: () {
          speak.tts(vocal, context);
        },
        onLongPress: () {
          Provider.of<AppModel>(context).toggle(vocal.no, isFav);
        },
      ));
    }

    return Stack(children: <Widget>[
      Container(
        padding: EdgeInsets.only(bottom: 66.0),
        child: ListView.builder(
            controller: _scrollController,
            itemCount: isFavPage ? favVocals.length : _allWords.length,
            itemBuilder: (context, index) {
              if (isFavPage) {
                return makeList(favVocals[index], true);
              } else {
                if (_allWords[index] is ChapterTitle) {
                  ChapterTitle chapterTitle = _allWords[index] as ChapterTitle;
                  return ListTile(
                      title: Text(
                    chapterTitle.title,
                    style: Theme.of(context).textTheme.headline,
                  ));
                } else if (_allWords[index] is Vocal) {
                  Vocal vocal = _allWords[index] as Vocal;

                  // favorite condition
                  bool isFav = Provider.of<AppModel>(context).isFav(vocal.no);

                  return makeList(vocal, isFav);
                }
              }
              return null;
            }),
      ),
      getAdmobBanner()
    ]);
  }

  PreferencePage _preferencePage(BuildContext context) {
    return PreferencePage([
      PreferenceTitle("List"),
      DropdownPreference(
        'Japanese',
        'list_japanese',
        defaultVal: listJapanese[0],
        values: listJapanese,
      ),
      DropdownPreference(
        'Meaning',
        'list_meaning',
        defaultVal: listMeaning[0],
        values: listMeaning,
      ),
      DropdownPreference(
        'Memorizing',
        'list_memorizing',
        defaultVal: listMemorizing[0],
        values: listMemorizing,
      ),
      PreferenceTitle('Search'),
      DropdownPreference(
        'Flash Card Level',
        'search_flash_card_level',
        defaultVal: searchFlashCardLevel[0],
        values: searchFlashCardLevel,
      ),
      PreferenceTitle('Sound'),
      SwitchPreference('Text To Speech for Japanese', 'switch_tts',
          defaultVal: true),
      DropdownPreference(
        'Playback Source',
        'list_source',
        defaultVal: listTtsSource[0],
        values: listTtsSource,
      ),
      PreferenceTitle('Personalization'),
      RadioPreference(
        'Day Mode',
        'light',
        'ui_theme',
        isDefault: true,
        onSelect: () {
          DynamicTheme.of(context).setBrightness(Brightness.light);
        },
      ),
      RadioPreference(
        'Night Mode',
        'dark',
        'ui_theme',
        onSelect: () {
          DynamicTheme.of(context).setBrightness(Brightness.dark);
        },
      ),
      PreferenceTitle('Myanmar Font'),
      SwitchPreference('Zawgyi Keyboard', 'switch_zawgyi'),
      PreferenceTitle('About'),
      ListTile(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => AboutPage())),
        title: Text("About"),
        subtitle: Text(appVersion),
      )
    ]);
  }

  void initializeVar() {
    fetchPhotos(context).then((data) {
      setState(() {
        _chapters = data;
      });

      for (int i = 0; i < _chapters.length; i++) {
        _allWords.add(ChapterTitle(_chapters[i].title));
        _allWords.addAll(_chapters[i].words);
        _allVocals.addAll(_chapters[i].words);
        _allN4Vocals.addAll(_chapters[i].words);
        if (i < 25) {
          _allN5Vocals.addAll(_chapters[i].words);
        }
      }

      // shuffle for N5, N4 Vocals for Shuffle Card Usage
      _allN5Vocals.shuffle();
      _allN4Vocals.shuffle();

      print('_allWords ${_allWords.length}');
    }).catchError((error) {
      print('fetchPhotos error $error');
    });

    _drawerIndex = PrefService.getInt("drawer_index") ?? 0;
  }

  @override
  void initState() {
    print('initState');
    initializeVar();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTitle = 'Minna Kotoba 2';
    String selectedSearchFCLevel =
        PrefService.getString("search_flash_card_level") ??
            searchFlashCardLevel[0];

    Future<ConfirmAction> _clearFav() {
      // flutter defined function
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: Text("Empty favorite?"),
            content: Text("This will clear the favorite list."),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              FlatButton(
                child: Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop(ConfirmAction.CANCEL);
                },
              ),
              FlatButton(
                child: Text("Clear"),
                onPressed: () {
                  Navigator.of(context).pop(ConfirmAction.ACCEPT);
                },
              ),
            ],
          );
        },
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          appBar: AppBar(
            title: Text(appTitle),
            actions: <Widget>[
              Visibility(
                visible: _isShowSearchMenu,
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                        context: context,
                        delegate: (_tabIndex == 0)
                            ? VocalSearch(_chapters[_drawerIndex].words)
                            : (_tabIndex == 1
                                ? VocalSearch(_allVocals)
                                : VocalSearch(Provider.of<AppModel>(context)
                                    .getFavVocal(_allWords))));
                  },
                ),
              ),
              Visibility(
                visible: (_tabIndex == 0 || _tabIndex == 1),
                child: IconButton(
                    icon: Icon(Icons.crop_portrait),
                    onPressed: () {
                      print('flash card click');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => FlashCard(
                                (_tabIndex == 1)
                                    ? (selectedSearchFCLevel ==
                                            searchFlashCardLevel[0]
                                        ? _allN5Vocals
                                        : _allN4Vocals)
                                    : _chapters[_drawerIndex].words,
                                PrefService.getString("list_japanese") ??
                                    listJapanese[0],
                                PrefService.getString("list_meaning") ??
                                    listMeaning[0],
                                PrefService.getString("list_memorizing") ??
                                    listMemorizing[0],
                                "Flash Card")),
                      );
                    }),
              ),
              Visibility(
                visible: _isShowFavMenu,
                child: IconButton(
                    icon: Icon(Icons.delete_outline),
                    onPressed: () async {
                      ConfirmAction action = await _clearFav();
                      print('ConfirmAction $action');

                      if (action == ConfirmAction.ACCEPT) {
                        print('Clearing the favorite list');
                        Provider.of<AppModel>(context).clear();
                        PrefService.setStringList("list_favorite", []);
                      }
                    }),
              )
            ],
          ),
          onTap: () {
            print('app bar tap');
            _scrollController.animateTo(0.0,
                duration: Duration(milliseconds: 500), curve: Curves.easeOut);
          },
        ),
        drawer: isShowDrawerMenu
            ? Builder(builder: (context) {
                return _chapters != null
                    ? Drawer(
                        child: ListView(
                            padding: EdgeInsets.zero,
                            children: _buildDrawerList(context, _chapters)),
                      )
                    : Center(child: CircularProgressIndicator());
              })
            : null,
        body: TabBarView(
          children: [
            _chapters != null
                ? _buildBodyList(context)
                : Center(child: CircularProgressIndicator()),
            _allWords != null
                ? _buildSearchBodyList(context)
                : Center(child: CircularProgressIndicator()),
            _allWords != null
                ? _buildSearchBodyList(context, isFavPage: true)
                : Center(child: CircularProgressIndicator()),
            _preferencePage(context),
          ],
          physics: NeverScrollableScrollPhysics(),
        ),
        bottomNavigationBar: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.format_list_numbered_rtl)),
            Tab(icon: Icon(Icons.search)),
            Tab(icon: Icon(Icons.favorite, color: Colors.redAccent)),
            Tab(icon: Icon(Icons.settings)),
          ],
          onTap: (int index) {
            print('tab index $index');
            _tabIndex = index;

            setState(() {
              isShowDrawerMenu = false;
              _isShowFavMenu = false;
              _isShowSearchMenu = false;
              _dialVisible = false;
            });

            if (index == 0) {
              setState(() {
                isShowDrawerMenu = true;
                _isShowSearchMenu = true;
                _dialVisible = true;
              });
            } else if (index == 1) {
              setState(() {
                _isShowSearchMenu = true;
              });
            } else if (index == 2) {
              setState(() {
                _isShowFavMenu = true;
                _isShowSearchMenu = true;
              });
            }
          },
          labelColor: Colors.black,
          isScrollable: false,
        ),
        floatingActionButton: SpeedDial(
          // both default to 16
          marginRight: 18,
          marginBottom: 20,
          animatedIcon: AnimatedIcons.menu_close,
          animatedIconTheme: IconThemeData(size: 22.0),
          // this is ignored if animatedIcon is non null
          // child: Icon(Icons.add),
          visible: _dialVisible,
          // If true user is forced to close dial manually
          // by tapping main button and overlay is not rendered.
          closeManually: false,
          curve: Curves.bounceIn,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          onOpen: () => print('OPENING DIAL'),
          onClose: () => print('DIAL CLOSED'),
          tooltip: 'Speed Dial',
          heroTag: 'speed-dial-hero-tag',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 8.0,
          shape: CircleBorder(),
          children: [
            SpeedDialChild(
                child: Icon(Icons.shuffle),
                backgroundColor: _isShuffle ? Colors.amber : Colors.white,
                foregroundColor: _isShuffle ? Colors.white : Colors.black,
                label: _isShuffle ? 'Shuffling' : 'Shuffle',
                labelStyle: TextStyle(color: Colors.black),
                onTap: () {
                  setState(() {
                    _isShuffle = !_isShuffle;
                  });
                  print('_isShuffle $_isShuffle');
                  _toggleTheShuffle();
                }),
            SpeedDialChild(
              child: Icon(Icons.question_answer),
              backgroundColor:
                  _isShowKotoba.length > 0 ? Colors.redAccent : Colors.white,
              foregroundColor:
                  _isShowKotoba.length > 0 ? Colors.white : Colors.black,
              label: _isShowKotoba.length > 0 ? 'Memorizing' : 'Memorize',
              labelStyle: TextStyle(color: Colors.black),
              onTap: () {
                print('Memorizing');
                setState(() {
                  if (_isShowKotoba.length == 0) {
                    print('on');
                    _isShowKotoba.add("");
                  } else {
                    print('off ${_isShowKotoba.length}');
                    _isShowKotoba = [];
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
