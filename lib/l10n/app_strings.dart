class AppStrings {
  final String _lang;
  const AppStrings._(this._lang);
  factory AppStrings.of(String langCode) => AppStrings._(langCode);
  bool get _isThai => _lang == 'th';

  String get onboardingQuestion =>
      _isThai ? 'ฉันควรเรียกคุณว่าอะไรดี?' : 'What should I call you?';
  String get onboardingHint    => _isThai ? 'ชื่อของคุณ' : 'Your name';
  String get onboardingConfirm => _isThai ? 'เริ่มต้นใช้งาน' : 'Get Started';

  String greeting(String n) => _isThai ? 'สวัสดี, $n 👋' : 'Hello, $n 👋';
  String get homeTitle       => _isThai ? 'ภาพรวมการเงิน' : 'Financial Overview';
  String get totalBalance    => _isThai ? 'ยอดคงเหลือรวม' : 'Total Balance';
  String get monthlyBalance  => _isThai ? 'ยอดเดือนนี้' : 'This Month';
  String get monthlyNet      => _isThai ? 'คงเหลือ' : 'Net';
  String get incomeLabel     => _isThai ? '↑  รายรับ' : '↑  Income';
  String get expenseLabel    => _isThai ? '↓  รายจ่าย' : '↓  Expense';
  String get myAccounts      => _isThai ? 'บัญชีของฉัน' : 'My Accounts';
  String get recentTx        => _isThai ? 'รายการล่าสุด' : 'Recent Transactions';
  String get viewAll         => _isThai ? 'ดูทั้งหมด →' : 'View all →';
  String get noNotification  =>
      _isThai ? 'ไม่มีการแจ้งเตือนใหม่' : 'No new notifications';

  String get navHome         => _isThai ? 'หน้าหลัก' : 'Home';
  String get navTransactions => _isThai ? 'รายการ' : 'Transactions';
  String get navReports      => _isThai ? 'รายงาน' : 'Reports';
  String get navAccounts     => _isThai ? 'บัญชี' : 'Accounts';

  String get accountsTitle     => _isThai ? 'บัญชีของฉัน' : 'My Accounts';
  String get totalAllAccounts  => _isThai ? 'ยอดรวมทุกบัญชี' : 'Total (all accounts)';
  String accountCount(int n)   =>
      _isThai ? '$n บัญชี' : '$n account${n == 1 ? "" : "s"}';
  String get addAccount        => _isThai ? '+ เพิ่มบัญชี' : '+ Add Account';
  String get addAccountTitle   =>
      _isThai ? 'เพิ่มบัญชี' : 'Add Account';
  String get editAccountTitle  => _isThai ? 'แก้ไขบัญชี' : 'Edit Account';
  String get accountNameHint   => _isThai ? 'ชื่อบัญชี' : 'Account name';
  String get balanceHint       => _isThai ? 'ยอดเงินในบัญชี' : 'Account balance';
  String get renameTitle       => _isThai ? 'เปลี่ยนชื่อบัญชี' : 'Rename Account';
  String get selectEmoji       => _isThai ? 'เลือกไอคอน' : 'Select Icon';
  String get confirm           => _isThai ? 'ยืนยัน' : 'Confirm';
  String get cancel            => _isThai ? 'ยกเลิก' : 'Cancel';

  String get allTransactions => _isThai ? 'รายการทั้งหมด' : 'All Transactions';
  String get filterAll       => _isThai ? 'ทั้งหมด' : 'All';
  String get filterIncome    => _isThai ? 'รายรับ' : 'Income';
  String get filterExpense   => _isThai ? 'รายจ่าย' : 'Expense';
  String get noTransactions  => _isThai ? 'ไม่มีรายการ' : 'No transactions';

  String get reportsTitle    => _isThai ? 'รายงาน' : 'Reports';
  String get incomeSummary   => _isThai ? 'รายรับ' : 'Income';
  String get expenseSummary  => _isThai ? 'รายจ่าย' : 'Expense';
  String get netCashFlow     => _isThai ? 'กระแสเงินสุทธิ' : 'Net Cash Flow';
  String get byCategory      => _isThai ? 'รายจ่ายตามหมวด' : 'Expense by Category';
  String get noExpenses      => _isThai ? 'ยังไม่มีรายจ่าย' : 'No expenses yet';

  String get addTransaction  => _isThai ? 'เพิ่มรายการ' : 'Add Transaction';
  String get txTypeExpense   => _isThai ? 'รายจ่าย' : 'Expense';
  String get txTypeIncome    => _isThai ? 'รายรับ' : 'Income';
  String get txNameHint      => _isThai ? 'ชื่อรายการ (ไม่บังคับ)' : 'Label (optional)';
  String get amountHint      => _isThai ? 'จำนวนเงิน' : 'Amount';
  String get save            => _isThai ? 'บันทึก' : 'Save';
  String get errorNoAmount   =>
      _isThai ? 'กรุณากรอกจำนวนเงิน' : 'Please enter an amount';
  String get errorBadAmount  => _isThai ? 'จำนวนเงินไม่ถูกต้อง' : 'Invalid amount';
  String get selectAccount   => _isThai ? 'เลือกบัญชี' : 'Select Account';

  String get addCategoryTitle     => _isThai ? 'เพิ่มหมวดหมู่' : 'Add Category';
  String get editCategoryTitle    => _isThai ? 'แก้ไขหมวดหมู่' : 'Edit Category';
  String get categoryNameHint     => _isThai ? 'ชื่อ (ภาษาไทย)' : 'Name (Thai)';
  String get categoryNameEnHint   => _isThai ? 'ชื่อ (ภาษาอังกฤษ)' : 'Name (English)';
  String get deleteCategory       => _isThai ? 'ลบหมวดหมู่' : 'Delete';
  String get addNewCategory       => _isThai ? 'เพิ่ม' : 'Add';

  String get langToggleLabel => _isThai ? 'EN' : 'TH';

  List<String> get months => _isThai
      ? [
          'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
          'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
        ]
      : [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
}
