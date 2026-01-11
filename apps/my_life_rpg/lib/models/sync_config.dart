class SyncConfig {
  String token;
  String owner;
  String repo;
  String path; // 文件在 Repo 中的路径，例如 "data/core.json"

  SyncConfig({
    this.token = '',
    this.owner = '',
    this.repo = '',
    this.path = 'my_life_core.json',
  });

  bool get isValid =>
      token.isNotEmpty &&
      owner.isNotEmpty &&
      repo.isNotEmpty &&
      path.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'token': token,
    'owner': owner,
    'repo': repo,
    'path': path,
  };

  factory SyncConfig.fromJson(Map<String, dynamic> json) => SyncConfig(
    token: json['token'] ?? '',
    owner: json['owner'] ?? '',
    repo: json['repo'] ?? '',
    path: json['path'] ?? 'my_life_core.json',
  );
}
