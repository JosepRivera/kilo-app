abstract interface class BoughtStore {
  Future<Set<String>> read(String day);

  Future<void> write(String day, Set<String> supplyIds);
}
