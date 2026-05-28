import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rive/rive.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rive/rive.dart' as rive;

final modalController = BehaviorSubject<Widget>()..sink.add(const SizedBox());

class TemplateWidget extends StatefulWidget {
  final Widget child;
  final Widget menu;
  final List<SingleChildWidget>? providers;

  const TemplateWidget({
    super.key,
    this.providers,
    required this.child,
    required this.menu,
  });

  @override
  State<TemplateWidget> createState() => _TemplateWidgetState();
}

class _TemplateWidgetState extends State<TemplateWidget> {
  @override
  void initState() {
    // Controllers
    modalController.sink.add(const SizedBox());

    // Blocs

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.providers != null) {
      return MultiBlocProvider(
        providers: widget.providers ?? [],
        child: _body(),
      );
    }

    return _body();
  }

  Widget _body() {
    return Scaffold(
      body: Row(
        children: [
          widget.menu,
          Expanded(
            child: Stack(
              children: [
                widget.child,

                // Modal
                StreamBuilder(
                  stream: modalController,
                  builder: (context, snapshot) =>
                      snapshot.data ?? const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget errorTemplate(
  BuildContext context,
  Stream<Map<double, String>> feedback,
) {
  return StreamBuilder(
    stream: feedback,
    builder: (context, snapshot) {
      return Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: 493,
          child: Column(
            children: [
              const SizedBox(height: 200),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const RiveAsset(
                  'assets/img/error.riv',
                  // animations: ['Timeline 1'],
                ),
              ),
              const Text(
                'Something went wrong!',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(snapshot.hasData ? snapshot.data![0] ?? '' : ''),
            ],
          ),
        ),
      );
    },
  );
}

Widget loadingTemplate(BuildContext context, title) {
  return CustomScrollView(
    slivers: <Widget>[
      CupertinoSliverNavigationBar(
        backgroundColor: Colors.transparent,
        leading: const SizedBox(),
        largeTitle: Text(
          title, //'${AppLocalizations.of(context)!.stop}s',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge!.color,
          ),
        ),
      ),
      const SliverToBoxAdapter(child: Column(children: [])),
      const SliverFillRemaining(
        child: Column(
          children: [
            LinearProgressIndicator(),
            SizedBox(height: 450),
            Text('Loading...'),
          ],
        ),
      ),
    ],
  );
}

class RiveAsset extends StatefulWidget {
  final String path;
  final List<String>? animations;

  const RiveAsset(
    this.path, {
    super.key,
    this.animations,
  });

  @override
  State<RiveAsset> createState() => _RiveAssetState();
}

class _RiveAssetState extends State<RiveAsset> {
  late FileLoader _fileLoader;
  late StateMachineSelector _selector;
  bool _isFallbackActive = false;

  @override
  void initState() {
    super.initState();
    _initLoader();
    _prepareSelector();
  }

  void _initLoader() {
    _fileLoader = FileLoader.fromAsset(
      widget.path,
      riveFactory: Factory.rive,
    );
  }

  void _prepareSelector() {
    // Si la lista viene vacía, usamos el índice 0 directamente por seguridad
    if (widget.animations == null || widget.animations!.isEmpty) {
      _selector = StateMachineSelector.byIndex(0);
      _isFallbackActive = true;
    } else {
      _selector = StateMachineSelector.byName(widget.animations[0]);
      _isFallbackActive = false;
    }
  }

  @override
  void didUpdateWidget(covariant RiveAsset oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el path o las animaciones, reiniciamos el estado del componente
    if (oldWidget.path != widget.path || oldWidget.animations != widget.animations) {
      _fileLoader.dispose();
      _initLoader();
      _prepareSelector();
    }
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _fileLoader,
      stateMachineSelector: _selector,
      builder: (context, state) {
        
        // ¡AQUÍ ESTÁ LA MAGIA! Si el selector por nombre falla, nos auto-corregimos en vivo
        if (state is RiveFailed && !_isFallbackActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                // Forzamos a Rive a agarrar la primera State Machine del archivo (.riv)
                _selector = StateMachineSelector.byIndex(0);
                _isFallbackActive = true; 
              });
            }
          });
        }

        return switch (state) {
          RiveLoading() => const Center(child: CircularProgressIndicator()),
          
          // Si el fallback por índice también llegara a fallar, recién ahí muestra la alerta con el texto del error real
          RiveFailed(:final error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
          RiveLoaded() => RiveWidget(
              controller: state.controller,
              fit: Fit.contain,
            ),
        };
      },
    );
  }
}
