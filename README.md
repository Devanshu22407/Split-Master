# SplitMaster 💰

A comprehensive **expense sharing and bill splitting mobile application** built with Flutter. SplitMaster makes it easy to track shared expenses with friends, family, and roommates while providing detailed insights into your spending patterns.

## 🚀 Features

### 💸 Expense Management
- **Add Expenses**: Record expenses with categories, amounts, and dates
- **Multiple Categories**: Food, Transportation, Housing, Entertainment, Utilities, Groceries, Shopping, Health, Education, Travel, and more
- **Receipt Tracking**: Option to attach receipt images
- **Edit & Update**: Modify existing expenses with full edit capabilities

### 🤝 Bill Splitting Options
- **Equal Split**: Split bills equally among selected participants
- **Custom Split**: Manually define how much each person owes
- **"I Paid" Options**: Track when you pay for others
- **"Friend Paid" Options**: Track when friends pay for you
- **Flexible Participants**: Choose who's included in each split

### 📊 Smart Insights & Analytics
- **Spending Overview**: Visual charts showing total spending patterns
- **Category Breakdown**: Pie charts displaying spending by category
- **Monthly Trends**: Track spending patterns over time
- **Personal vs. Shared**: Distinguish between personal and shared expenses

### 👥 Friends & Social Features
- **Friends Management**: Add and manage your expense-sharing network
- **Split History**: Detailed history of splits with each friend
- **Outstanding Balances**: Clear overview of who owes what
- **Settlement Tracking**: Mark debts as paid when settled

### 📈 Budget Management
- **Daily Limits**: Set and track daily spending limits
- **Monthly Limits**: Set and monitor monthly budget goals
- **Limit Alerts**: Get notified when approaching spending limits
- **Personal Spend Tracking**: Monitor your individual share of expenses

### 🎯 Debt Tracking & Settlement
- **"You Owe" View**: See all amounts you owe to friends
- **"You're Owed" View**: Track money friends owe you
- **One-Click Settlement**: Mark payments as completed
- **Split Details**: Detailed breakdown of each shared expense

## 🛠️ Technology Stack

- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **State Management**: Provider pattern
- **Charts**: FL Chart for data visualization
- **UI**: Material Design with Google Fonts
- **Platform Support**: Android, iOS, Web, Windows, macOS, Linux

## 📱 Screenshots

*Screenshots will be added soon...*

## 🔧 Installation & Setup

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development on macOS)

### Steps
1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/SplitMaster.git
   cd SplitMaster
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 📦 Dependencies

### Core Dependencies
- `provider: ^6.1.1` - State management
- `google_fonts: ^6.1.0` - Typography
- `fl_chart: ^0.66.0` - Data visualization
- `intl: ^0.19.0` - Internationalization and date formatting
- `cupertino_icons: ^1.0.8` - iOS style icons

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^5.0.0` - Linting rules

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Main application entry point
├── models/                   # Data models
│   ├── app_user.dart        # User model
│   ├── expense.dart         # Expense model
│   └── split_share.dart     # Split details model
├── screens/                  # Application screens
│   ├── auth_screen.dart     # Login/Signup
│   ├── home_screen.dart     # Main dashboard
│   ├── add_expense_screen.dart
│   ├── insights_screen.dart
│   ├── friends_list_screen.dart
│   ├── split_detail_screen.dart
│   ├── my_info_screen.dart
│   └── set_limits_screen.dart
├── managers/                 # State management
│   ├── auth_manager.dart    # Authentication logic
│   ├── expense_manager.dart # Expense management
│   └── app_config.dart      # App configuration
└── widgets/                  # Reusable UI components
```

## 🎮 How to Use

### Getting Started
1. **Sign Up/Login**: Create an account or login with existing credentials
2. **Add Friends**: Build your expense-sharing network
3. **Record Expenses**: Start adding your shared expenses
4. **Split Bills**: Choose how to split each expense
5. **Track & Settle**: Monitor balances and settle debts

### Adding an Expense
1. Tap the "+" button on the home screen
2. Enter expense details (title, amount, category, date)
3. Choose splitting method:
   - **Equal Split**: Divide equally among participants
   - **Custom Split**: Set individual amounts
   - **I Paid Options**: Track when you covered others
   - **Friend Paid Options**: Track when others paid for you
4. Select participants from your friends list
5. Save the expense

### Managing Splits
- View outstanding balances on the home screen
- Tap on any friend to see detailed split history
- Use "Mark as Paid" to settle individual debts
- Access "You Owe" and "You're Owed" screens for complete overview

## 🔮 Future Enhancements

- [ ] Cloud synchronization across devices
- [ ] Push notifications for payment reminders
- [ ] Integration with payment apps (UPI, PayPal, etc.)
- [ ] Group expense management for trips/events
- [ ] Receipt scanning with OCR
- [ ] Export expense reports
- [ ] Multiple currency support
- [ ] Offline mode capabilities

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created as part of Mobile Application Development (MAD) coursework.

## 📞 Support

If you have any questions or run into issues, please open an issue on GitHub.

---

⭐ **Star this repository if you found it helpful!** ⭐
