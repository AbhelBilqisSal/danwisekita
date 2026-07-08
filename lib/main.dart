import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/cart_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/buyer_homepage.dart';
import 'screens/seller_dashboard.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/product_details.dart';
import 'screens/store_screen.dart';
import 'screens/payment_method_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'DanWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          primaryColor: const Color(0xFFDC2626),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFDC2626),
            secondary: Color(0xFFEF4444),
            surface: Colors.white,
            background: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Color(0xFFDC2626),
            foregroundColor: Colors.white,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color(0xFFDC2626),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => LoginScreen(
            selectedRole: ModalRoute.of(context)?.settings.arguments as String? ?? 'buyer',
          ),
          '/register': (context) => RegisterScreen(
            selectedRole: ModalRoute.of(context)?.settings.arguments as String? ?? 'buyer',
          ),
          '/buyer-home': (context) => const BuyerHomepage(),
          '/seller-home': (context) => const SellerDashboard(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/payment-method': (context) => const PaymentMethodScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/product-detail') {
            final product = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            );
          }
          if (settings.name == '/store') {
            final seller = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => StoreScreen(seller: seller),
            );
          }
          return null;
        },
      ),
    );
  }
}