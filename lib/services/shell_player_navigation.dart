/// Opens [PlayerWidget] inside the bottom-nav shell without a GoRouter hop.
/// Registered by [NavBarPage]; used from Done/Home when already in the shell.
typedef ShellPlayerExtra = Map<String, dynamic>;

void Function(ShellPlayerExtra extra)? shellOpenPlayer;
