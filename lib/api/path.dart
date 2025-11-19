class ApiPath {
  static const String baseUrl = 'https://examify-api-iota.vercel.app/api';

  // ===== AUTH =====
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String social = '$baseUrl/auth/social';

  //static const String refreshToken = '$baseUrl/refresh-token';

  // ===== DASHBOARD =====
  static const String dashboardData = '$baseUrl/dashboard/data';
  static const String dashboardClass = '$baseUrl/dashboard/classes';

  static const String profile = '$baseUrl/auth/profile';
  static const String editProfile = '$baseUrl/auth/editProfile';

  // ===== CLASS =====
  static const String createClass = '$baseUrl/teacher/createClass';

  static const String getClasses = '$baseUrl/teacher/getClasses';
  static String getStudentsInClass(String classId) =>
      '$baseUrl/teacher/getStudentsInClass/$classId';
  static String getExamsInclas(String classId) =>
      '$baseUrl/exam/getExamsByClass/$classId';

  static String getClassDetail(String classId) => '$baseUrl/class/$classId';

  // ===== EXAM =====
  static const String createExam = '$baseUrl/exam/create-exam';
  static String examDetailForTeacher(String examId) =>
      '$baseUrl/exam/examDetailForTeacher/$examId';
  static String examDetailForStudent(String examId) =>
      '$baseUrl/exam/examDetailForStudent/$examId';
  static String addQuestion(String examId) =>
      '$baseUrl/exam/add-question/$examId';
  static String submitExam(String examId) =>
      '$baseUrl/exam/submit-exam/$examId';

  // ===== NOTIFICATION =====
  static const String getNotifications = '$baseUrl/notifications';

  // ===== STUDENT =====
  static const String studentJoinClass = '$baseUrl/student/join';
  static const String studentGetClasses = '$baseUrl/student/getClasses';
  static const String examResults = '$baseUrl/exam/exam-results';
}
