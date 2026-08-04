class PermissionHelper {
  static const List<String> _adminUsers = [
    'julioroca92@gmail.com',
    'rocio.roca.r@gmail.com',
  ];

  static bool isAdmin(String? email) {
    return _adminUsers.contains(email);
  }
}
