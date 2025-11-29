// 通用的 CRUD 接口
abstract class Repository<T> {
  List<T> getAll();
  T? getById(String id);
  void add(T item);
  void update(T item);
  void delete(String id);
}
