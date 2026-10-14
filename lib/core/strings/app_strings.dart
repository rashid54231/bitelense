/// Centralized user-facing strings for BiteLens.
/// Prepared for easy future localization (e.g. Urdu, Arabic).
class AppStrings {
  AppStrings._();

  // App Identity
  static const String appName = 'BiteLens';
  static const String appTagline = 'Smart AI Food & Calorie Tracker';
  static const String disclaimerShort = 'Estimates only. Not medical advice.';
  static const String dataPrivacyNote =
      'Photos are used solely to analyze meal nutritional content.';

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Create Account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String resetPasswordInstruction =
      'Enter your email to receive a password reset link';
  static const String sendResetLink = 'Send Reset Link';
  static const String resetLinkSent = 'Check your email for the reset link!';
  static const String googleSignIn = 'Continue with Google';
  static const String orDivider = 'OR';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String passwordTooShort =
      'Password must be at least 6 characters';
  static const String authFailed = 'Authentication failed. Please check your credentials.';

  // Onboarding
  static const String onboardingTitle1 = 'Snap & Know Instantly';
  static const String onboardingDesc1 =
      'Take a picture of your plate. BiteLens instantly identifies dishes, portions, and calories.';
  static const String onboardingTitle2 = 'Specialized in Desi Meals';
  static const String onboardingDesc2 =
      'From Biryani and Nihari to Daal, Roti, and Chai — accurate estimates for South Asian cuisines.';
  static const String onboardingTitle3 = 'Track Your Daily Goals';
  static const String onboardingDesc3 =
      'Keep track of calories, protein, carbs, and fats every day to reach your fitness goals.';
  static const String getStarted = 'Get Started';
  static const String next = 'Next';
  static const String skip = 'Skip';

  // Profile Setup
  static const String profileSetupTitle = 'Personalize Your Plan';
  static const String profileSetupSubtitle =
      'We use the Mifflin-St Jeor equation to calculate your optimal daily calorie target.';
  static const String displayName = 'Display Name';
  static const String sex = 'Sex';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';
  static const String birthYear = 'Birth Year';
  static const String height = 'Height (cm)';
  static const String weight = 'Weight (kg)';
  static const String activityLevel = 'Activity Level';
  static const String sedentary = 'Sedentary (Little or no exercise)';
  static const String light = 'Lightly Active (Exercise 1-3 days/week)';
  static const String moderate = 'Moderately Active (Exercise 3-5 days/week)';
  static const String active = 'Very Active (Hard exercise 6-7 days/week)';
  static const String veryActive = 'Extra Active (Physical job or 2x training)';
  static const String goal = 'Your Goal';
  static const String loseWeight = 'Lose Weight (-500 kcal)';
  static const String maintainWeight = 'Maintain Weight';
  static const String gainWeight = 'Gain Weight (+300 kcal)';
  static const String calculatedGoal = 'Calculated Daily Target';
  static const String manualOverride = 'Custom Daily Goal (kcal)';
  static const String saveProfile = 'Save & Continue';

  // Home / Today
  static const String today = 'Today';
  static const String greetingMorning = 'Good Morning';
  static const String greetingAfternoon = 'Good Afternoon';
  static const String greetingEvening = 'Good Evening';
  static const String caloriesEaten = 'Eaten';
  static const String caloriesRemaining = 'Remaining';
  static const String calorieGoal = 'Goal';
  static const String protein = 'Protein';
  static const String carbs = 'Carbs';
  static const String fat = 'Fat';
  static const String fiber = 'Fiber';
  static const String scansLeftToday = 'scans left today';
  static const String unlimitedScans = 'Unlimited (Pro)';
  static const String scanMeal = 'Scan Meal';
  static const String noMealsLoggedToday = 'No meals logged yet today';
  static const String snapMealPrompt = 'Snap your breakfast, lunch, or dinner to start tracking!';
  static const String breakfast = 'Breakfast';
  static const String lunch = 'Lunch';
  static const String dinner = 'Dinner';
  static const String snack = 'Snack';

  // Scan & Camera
  static const String takePhoto = 'Take Photo';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String cameraPermissionRequired =
      'Camera permission is required to photograph your meals.';
  static const String openSettings = 'Open Settings';
  static const String selectMealType = 'Select Meal Type';
  static const String analyzing = 'Analyzing Food...';
  static const String analyzingSubtext1 = 'Identifying South Asian & global dishes...';
  static const String analyzingSubtext2 = 'Estimating portion sizes and oil content...';
  static const String analyzingSubtext3 = 'Calculating macros and calorie density...';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String timeoutError = 'Analysis took too long. Please retry or check connection.';

  // Result
  static const String mealResult = 'Meal Result';
  static const String confidenceHigh = 'High Confidence';
  static const String confidenceMedium = 'Medium Confidence';
  static const String confidenceLow = 'Low Confidence (Hard to judge portion)';
  static const String notFoodTitle = 'Not Recognized as Food';
  static const String notFoodMessage =
      'We could not detect any food or drink items in this photo. This scan did not count against your daily limit.';
  static const String itemsDetected = 'Items Detected';
  static const String addItem = 'Add Item';
  static const String editItem = 'Edit Item';
  static const String itemName = 'Item Name';
  static const String portion = 'Portion';
  static const String grams = 'Grams (g)';
  static const String calories = 'Calories';
  static const String saveToLog = 'Save to Log';
  static const String discard = 'Discard';
  static const String mealSavedSuccess = 'Meal saved to your daily log!';
  static const String mealDeleted = 'Meal removed from log.';

  // History & Insights
  static const String history = 'History';
  static const String insights = 'Insights';
  static const String weeklyAverage = 'Daily Average';
  static const String loggingStreak = 'Day Streak';
  static const String weeklyCalorieChart = 'Weekly Calorie Intake';
  static const String macroDistribution = 'Average Macro Split';
  static const String proHistoryNotice = 'Free tier shows the last 3 days of meals.';
  static const String unlockFullHistory = 'Unlock Full History with Pro';

  // Paywall
  static const String upgradeToPro = 'Upgrade to BiteLens Pro';
  static const String proFeature1 = 'Unlimited AI food scans every day';
  static const String proFeature2 = 'Full lifetime history & meal archives';
  static const String proFeature3 = 'Advanced weekly insights & macro trends';
  static const String proFeature4 = 'Priority AI processing queue';
  static const String freeLimitReached =
      'You have used your 3 free scans for today. Upgrade to Pro for unlimited scanning!';
  static const String monthly = 'Monthly Plan';
  static const String yearly = 'Yearly Plan (Save 33%)';
  static const String restorePurchases = 'Restore Purchases';
  static const String purchaseSuccess = 'Welcome to BiteLens Pro!';
  static const String purchaseCancelled = 'Purchase cancelled.';
  static const String purchaseError = 'Purchase failed. Please try again.';

  // Settings
  static const String settings = 'Settings';
  static const String editProfile = 'Edit Profile & Goals';
  static const String units = 'Units';
  static const String metric = 'Metric (cm, kg)';
  static const String imperial = 'Imperial (ft, lbs)';
  static const String theme = 'Theme';
  static const String themeDark = 'Dark (Default)';
  static const String themeLight = 'Light';
  static const String themeSystem = 'System';
  static const String manageSubscription = 'Manage Subscription';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String about = 'About BiteLens';
  static const String sendFeedback = 'Send Feedback';
  static const String signOut = 'Sign Out';
  static const String deleteAccount = 'Delete Account';
  static const String deleteAccountConfirm =
      'Are you sure you want to delete your account? All your meals, photos, and profile data will be permanently removed.';
  static const String delete = 'Delete';

  // Global / Errors
  static const String offlineMessage = 'You are currently offline. Please check your connection.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
}
