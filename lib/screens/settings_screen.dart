import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _currentLanguage = "English";

  // --- PEMBOLEHUBAH UNTUK SUBSCRIPTION ---
  bool _isPremium = false;
  String _planType = "Free Plan";

  // --- 1. KAMUS TRANSLASI (DICTIONARY) ---
  final Map<String, Map<String, String>> _lang = {
    'English': {
      'settings': 'Settings',
      'account': 'Account',
      'edit_profile': 'Edit Profile',
      'change_pw': 'Change Password',
      'subs': 'Subscription',
      'upgrade': 'Upgrade to Premium',
      'premium_benefits': 'Premium Benefits:',
      'feat_1': 'Ad-free Experience',
      'feat_2': 'Advanced Progress Analytics',
      'feat_3': 'Custom Diet & Workout Plans',
      'feat_4': 'Priority Developer Support',
      'monthly': 'Monthly Plan (RM 15/mo)',
      'yearly': 'Yearly Plan (RM 120/yr)',
      'choose_plan': 'Choose Your Plan',
      'free_plan': 'Free Plan',
      'payment': 'Payment Details',
      'bank_transfer': 'Manual Bank Transfer (CIMB)',
      'acc_name': 'Account Name',
      'acc_no': 'Account No',
      'confirm_payment': 'I Have Paid',
      'pref': 'Preferences',
      'notif': 'Push Notifications',
      'language': 'Language',
      'select_lang': 'Select Language',
      'more': 'More',
      'privacy': 'Privacy Policy',
      'help': 'Help & Support',
      'about': 'About',
      'logout': 'Log Out',
      'close': 'Close',
      'verify_identity': 'Verify Identity',
      'enter_email': 'Registered Email',
      'enter_phone': 'Registered Phone No.',
      'verify_btn': 'Verify',
      'verify_fail': 'Details do not match!',
      'privacy_content': 'Privacy Policy for FitTrack\n\nLast updated: July 2026\n\n1. Data Collection\nWe collect information you provide directly to us, such as your name, email, age, and fitness data (BMI, water intake) to provide and improve our services.\n\n2. Data Usage\nYour data is securely stored using Firebase and is used solely for tracking your fitness progress. We do not sell your personal data to third parties.\n\nBy using FitTrack, you agree to the collection and use of information in accordance with this policy.',
      'help_content': 'Need help or have questions regarding FitTrack? Feel free to reach out to the developer directly!\n\n📷 Instagram: @saifulallifnaadh\n📞 WhatsApp/Phone: 0135623681',
    },
    'Bahasa Melayu': {
      'settings': 'Tetapan',
      'account': 'Akaun',
      'edit_profile': 'Sunting Profil',
      'change_pw': 'Tukar Kata Laluan',
      'subs': 'Langganan',
      'upgrade': 'Naik Taraf Premium',
      'premium_benefits': 'Kelebihan Premium:',
      'feat_1': 'Pengalaman Tanpa Iklan',
      'feat_2': 'Analisis Progres Lanjutan',
      'feat_3': 'Pelan Pemakanan & Latihan Tersuai',
      'feat_4': 'Sokongan Keutamaan',
      'monthly': 'Pelan Bulanan (RM 15/bln)',
      'yearly': 'Pelan Tahunan (RM 120/thn)',
      'choose_plan': 'Pilih Pelan Anda',
      'free_plan': 'Pelan Percuma',
      'payment': 'Maklumat Pembayaran',
      'bank_transfer': 'Pindahan Bank (CIMB)',
      'acc_name': 'Nama Akaun',
      'acc_no': 'No. Akaun',
      'confirm_payment': 'Saya Telah Bayar',
      'pref': 'Keutamaan',
      'notif': 'Notifikasi (Push)',
      'language': 'Bahasa',
      'select_lang': 'Pilih Bahasa',
      'more': 'Lain-lain',
      'privacy': 'Dasar Privasi',
      'help': 'Bantuan & Sokongan',
      'about': 'Mengenai Kami',
      'logout': 'Log Keluar',
      'close': 'Tutup',
      'verify_identity': 'Sahkan Identiti',
      'enter_email': 'E-mel Berdaftar',
      'enter_phone': 'No. Telefon Berdaftar',
      'verify_btn': 'Sahkan',
      'verify_fail': 'Maklumat tidak sepadan!',
      'privacy_content': 'Dasar Privasi untuk FitTrack\n\nKemas kini terakhir: Julai 2026\n\n1. Pengumpulan Data\nKami mengumpul maklumat yang anda berikan secara terus, seperti nama, e-mel, umur, dan data kecergasan (BMI, pengambilan air) untuk menjejak progres anda.\n\n2. Penggunaan Data\nData anda disimpan dengan selamat menggunakan Firebase. Kami sama sekali tidak akan menjual data peribadi anda kepada pihak ketiga.\n\nDengan menggunakan FitTrack, anda bersetuju dengan dasar ini.',
      'help_content': 'Perlukan bantuan atau ada soalan mengenai FitTrack? Sila hubungi pembangun aplikasi kami secara terus!\n\n📷 Instagram: @saifulallifnaadh\n📞 WhatsApp/Telefon: 0135623681',
    }
  };

  String t(String key) {
    return _lang[_currentLanguage]?[key] ?? key;
  }

  // --- POPUP VERIFY IDENTITY SEBELUM TUKAR PASSWORD ---
  void _showVerificationDialog() {
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF00E5FF), width: 1)),
            title: Text(t('verify_identity'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: t('enter_email'),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF090E17),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: t('enter_phone'),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF090E17),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              if (!isVerifying)
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(t('close'), style: const TextStyle(color: Colors.grey))
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                onPressed: isVerifying ? null : () async {
                  if (emailCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                  
                  setStateDialog(() => isVerifying = true);
                  
                  try {
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
                    
                    if (userDoc.exists) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      String savedEmail = data['email']?.toString().trim() ?? '';
                      String savedPhone = data['phone']?.toString().trim() ?? '';

                      if (emailCtrl.text.trim() == savedEmail && phoneCtrl.text.trim() == savedPhone) {
                        if (mounted) {
                          Navigator.pop(context); 
                          _showChangePasswordDialog(); 
                        }
                      } else {
                        setStateDialog(() => isVerifying = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('verify_fail')), backgroundColor: Colors.redAccent));
                        }
                      }
                    }
                  } catch (e) {
                    setStateDialog(() => isVerifying = false);
                  }
                },
                child: isVerifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) 
                  : Text(t('verify_btn'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- POPUP TUKAR KATA LALUAN (KELUAR SELEPAS VERIFY) ---
  void _showChangePasswordDialog() {
    final TextEditingController passCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(t('change_pw'), style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _currentLanguage == 'English' ? 'New Password' : 'Kata Laluan Baru',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF090E17),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: Text(t('close'), style: const TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                onPressed: isSaving ? null : () async {
                  if (passCtrl.text.length < 6) return;
                  setStateDialog(() => isSaving = true);
                  try {
                    await FirebaseAuth.instance.currentUser?.updatePassword(passCtrl.text.trim());
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    setStateDialog(() => isSaving = false);
                  }
                },
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) : Text(_currentLanguage == 'English' ? 'Update' : 'Kemaskini', style: const TextStyle(color: Colors.black)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- POPUP PRIVACY POLICY ---
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip, color: Color(0xFF00E5FF)),
            const SizedBox(width: 10),
            Text(t('privacy'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            t('privacy_content'),
            style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- POPUP HELP & SUPPORT ---
  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.5))),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: Color(0xFF00E5FF), size: 28),
            const SizedBox(width: 10),
            Text(t('help'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          t('help_content'),
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('close'), style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- POPUP PILIH SUBSCRIPTION ---
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amber, width: 1)),
        title: Text(t('choose_plan'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 60),
              const SizedBox(height: 15),
              Text(t('premium_benefits'), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              _buildBenefitItem(t('feat_1')),
              _buildBenefitItem(t('feat_2')),
              _buildBenefitItem(t('feat_3')),
              _buildBenefitItem(t('feat_4')),
              const SizedBox(height: 25),
              _buildPlanOption(t('monthly'), 'Monthly Premium'),
              const SizedBox(height: 10),
              _buildPlanOption(t('yearly'), 'Yearly Premium'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String title, String planCode) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); 
        _showPaymentDialog(title, planCode); 
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber),
        ),
        child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  // --- POPUP MAKLUMAT BANK (CIMB) ---
  void _showPaymentDialog(String planTitle, String planCode) {
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131A26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.amber, width: 1)),
            title: Text(t('payment'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(planTitle, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(t('bank_transfer'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF090E17),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t('acc_name')}:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Text('FitTrack', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('${t('acc_no')}:', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Text('7649349664', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _currentLanguage == 'English' 
                    ? 'Please make the transfer and click confirm below.' 
                    : 'Sila buat pindahan bank dan tekan sahkan di bawah.', 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ],
            ),
            actions: [
              if (!isProcessing)
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(_currentLanguage == 'English' ? 'Cancel' : 'Batal', style: const TextStyle(color: Colors.grey))
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: isProcessing ? null : () async {
                  setStateDialog(() => isProcessing = true);
                  
                  await Future.delayed(const Duration(seconds: 2));
                  
                  if (mounted) {
                    setState(() {
                      _isPremium = true;
                      _planType = planCode;
                    });
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_currentLanguage == 'English' ? 'Payment Verified! Welcome to Premium.' : 'Bayaran Disahkan! Selamat Datang ke Premium.'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black)) 
                  : Text(t('confirm_payment'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- POPUP PILIH BAHASA ---
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131A26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('select_lang'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLangOption('English'),
            _buildLangOption('Bahasa Melayu'),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(String lang) {
    return ListTile(
      title: Text(lang, style: const TextStyle(color: Colors.white)),
      trailing: _currentLanguage == lang ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF)) : null,
      onTap: () {
        setState(() {
          _currentLanguage = lang; 
        });
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // WIDGET BANTUAN UI BARU (STANDARD INDUSTRI)
  // ==========================================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
      child: Text(
        title.toUpperCase(), 
        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2)
      ),
    );
  }

  // Wrapper untuk himpunkan senarai menjadi satu kad bersatu
  Widget _buildSectionGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile({
    required String title, 
    required IconData icon, 
    required VoidCallback onTap, 
    required Color iconBgColor,
    String? trailingText,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  if (trailingText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFF090E17), indent: 60),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title, 
    required IconData icon, 
    required Color iconBgColor,
    required bool value, 
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF00E5FF),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFF090E17), indent: 60),
      ],
    );
  }

  // ==========================================================
  // MAIN BUILD METHOD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('settings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- BAHAGIAN AKAUN ---
              _buildSectionHeader(t('account')),
              _buildSectionGroup(
                children: [
                  _buildListTile(
                    title: t('edit_profile'), 
                    icon: Icons.person, 
                    iconBgColor: const Color(0xFF00E5FF), // Biru Cyan
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)));
                    }
                  ),
                  _buildListTile(
                    title: t('change_pw'), 
                    icon: Icons.lock, 
                    iconBgColor: const Color(0xFFFF9800), // Oren
                    showDivider: false,
                    onTap: _showVerificationDialog,
                  ),
                ],
              ),

              // --- BAHAGIAN SUBSCRIPTION (LANGGANAN) ---
              _buildSectionHeader(t('subs')),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A24), Color(0xFF2D2310)], // Elegan Dark-to-Gold
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _isPremium ? Colors.amber.withOpacity(0.8) : Colors.grey.withOpacity(0.1)),
                  boxShadow: _isPremium ? [BoxShadow(color: Colors.amber.withOpacity(0.15), blurRadius: 25, spreadRadius: 1)] : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      _isPremium ? Icons.workspace_premium : Icons.card_membership, 
                      color: _isPremium ? Colors.amber : Colors.grey, 
                      size: 50
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPremium ? _planType : t('free_plan'),
                      style: TextStyle(color: _isPremium ? Colors.amber : Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (!_isPremium)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _showSubscriptionDialog,
                          child: Text(t('upgrade'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    else
                      Text(
                        _currentLanguage == 'English' ? 'You have access to all premium features.' : 'Anda mempunyai akses ke semua ciri premium.', 
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),

              // --- BAHAGIAN PREFERENSI (TETAPAN) ---
              _buildSectionHeader(t('pref')),
              _buildSectionGroup(
                children: [
                  _buildSwitchTile(
                    title: t('notif'), 
                    icon: Icons.notifications_active, 
                    iconBgColor: const Color(0xFFE91E63), // Pink
                    value: _notificationsEnabled, 
                    onChanged: (val) => setState(() => _notificationsEnabled = val)
                  ),
                  _buildListTile(
                    title: t('language'), 
                    icon: Icons.language, 
                    iconBgColor: const Color(0xFF4CAF50), // Hijau
                    trailingText: _currentLanguage,
                    showDivider: false,
                    onTap: _showLanguageDialog,
                  ),
                ],
              ),

              // --- BAHAGIAN LAIN-LAIN ---
              _buildSectionHeader(t('more')),
              _buildSectionGroup(
                children: [
                  _buildListTile(
                    title: t('privacy'), 
                    icon: Icons.privacy_tip, 
                    iconBgColor: const Color(0xFF607D8B), // Kelabu
                    onTap: _showPrivacyPolicyDialog
                  ),
                  _buildListTile(
                    title: t('help'), 
                    icon: Icons.help, 
                    iconBgColor: const Color(0xFF9C27B0), // Ungu
                    showDivider: false,
                    onTap: _showHelpSupportDialog
                  ),
                ],
              ),

              // --- BAHAGIAN ABOUT ---
              _buildSectionHeader(t('about')),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Image.asset('assets/logo.png', height: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, color: Color(0xFF00E5FF), size: 50)),
                    const SizedBox(height: 16),
                    const Text('FitTrack v1.0.0', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      'Developed by Saiful Allif\nDiploma in Computer Science (CDCS110)\nUniversiti Teknologi MARA (UiTM).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // --- BUTANG LOG OUT ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text(t('logout'), style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}