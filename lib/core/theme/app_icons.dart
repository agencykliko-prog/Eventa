import 'package:flutter/widgets.dart';

/// Jeu d'icônes unique de l'app : Phosphor (polices embarquées), trait régulier aux extrémités
/// arrondies ; variante pleine pour les états actifs.
abstract final class AppIcons {
  // Navigation
  static const IconData home = IconData(0xe2c2, fontFamily: 'PhosphorRegular');
  static const IconData homeOn = IconData(0xe2c2, fontFamily: 'PhosphorFill');
  static const IconData explore = IconData(
    0xe1c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData exploreOn = IconData(
    0xe1c8,
    fontFamily: 'PhosphorFill',
  );
  static const IconData agenda = IconData(
    0xe10a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData agendaOn = IconData(0xe10a, fontFamily: 'PhosphorFill');
  static const IconData account = IconData(
    0xe4c4,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData accountOn = IconData(
    0xe4c4,
    fontFamily: 'PhosphorFill',
  );

  // Actions
  static const IconData add = IconData(0xe3d4, fontFamily: 'PhosphorRegular');
  static const IconData minus = IconData(0xe32a, fontFamily: 'PhosphorRegular');
  static const IconData search = IconData(
    0xe30c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData bell = IconData(0xe0ce, fontFamily: 'PhosphorRegular');
  static const IconData back = IconData(0xe058, fontFamily: 'PhosphorRegular');
  static const IconData forward = IconData(
    0xe06c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData outward = IconData(
    0xe092,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chevron = IconData(
    0xe13a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chevronDown = IconData(
    0xe136,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData close = IconData(0xe4f6, fontFamily: 'PhosphorRegular');
  static const IconData check = IconData(0xe182, fontFamily: 'PhosphorRegular');
  static const IconData checkCircle = IconData(
    0xe184,
    fontFamily: 'PhosphorFill',
  );
  static const IconData share = IconData(0xe408, fontFamily: 'PhosphorRegular');
  static const IconData more = IconData(0xe1fe, fontFamily: 'PhosphorRegular');
  static const IconData edit = IconData(0xe3b4, fontFamily: 'PhosphorRegular');
  static const IconData trash = IconData(0xe4a6, fontFamily: 'PhosphorRegular');
  static const IconData filters = IconData(
    0xe434,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData sort = IconData(0xe444, fontFamily: 'PhosphorRegular');
  static const IconData send = IconData(0xe396, fontFamily: 'PhosphorRegular');
  static const IconData upload = IconData(
    0xe4c0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData refresh = IconData(
    0xe094,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData signOut = IconData(
    0xe42a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData settings = IconData(
    0xe270,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData help = IconData(0xe3e8, fontFamily: 'PhosphorRegular');
  static const IconData eyeOff = IconData(
    0xe224,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData userPlus = IconData(
    0xe4d0,
    fontFamily: 'PhosphorRegular',
  );

  // Contact
  static const IconData phone = IconData(0xe3b8, fontFamily: 'PhosphorRegular');
  static const IconData message = IconData(
    0xe16c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData whatsapp = IconData(
    0xe5d0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData mail = IconData(0xe214, fontFamily: 'PhosphorRegular');

  // Modules
  static const IconData wallet = IconData(
    0xe68a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData tasks = IconData(0xeadc, fontFamily: 'PhosphorRegular');
  static const IconData vendors = IconData(
    0xe470,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData team = IconData(0xe4d6, fontFamily: 'PhosphorRegular');
  static const IconData guests = IconData(
    0xe68e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData place = IconData(0xe316, fontFamily: 'PhosphorRegular');
  static const IconData clock = IconData(0xe19a, fontFamily: 'PhosphorRegular');
  static const IconData calendarCheck = IconData(
    0xe712,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData calendarPlus = IconData(
    0xe714,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData chart = IconData(0xe158, fontFamily: 'PhosphorRegular');
  static const IconData chartUp = IconData(
    0xe156,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData trendUp = IconData(
    0xe4ae,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData info = IconData(0xe2ce, fontFamily: 'PhosphorRegular');
  static const IconData reminder = IconData(
    0xe5e8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData archive = IconData(
    0xe00c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData timer = IconData(0xe492, fontFamily: 'PhosphorRegular');
  static const IconData sun = IconData(0xe472, fontFamily: 'PhosphorRegular');

  // Confiance, premium, IA
  static const IconData star = IconData(0xe46a, fontFamily: 'PhosphorFill');
  static const IconData starLine = IconData(
    0xe46a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData verified = IconData(0xe606, fontFamily: 'PhosphorFill');
  static const IconData shield = IconData(
    0xe40c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData lock = IconData(0xe2fe, fontFamily: 'PhosphorRegular');
  static const IconData crown = IconData(0xe614, fontFamily: 'PhosphorFill');
  static const IconData crownLine = IconData(
    0xe614,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData sparkle = IconData(0xe6a2, fontFamily: 'PhosphorFill');
  static const IconData sparkleLine = IconData(
    0xe6a2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData megaphone = IconData(
    0xe324,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData rocket = IconData(
    0xe3fc,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData diamond = IconData(
    0xe1ec,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData thumbsUp = IconData(
    0xe48e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData lightning = IconData(
    0xe2de,
    fontFamily: 'PhosphorRegular',
  );

  // Paiement
  static const IconData card = IconData(0xe1d2, fontFamily: 'PhosphorRegular');
  static const IconData mobile = IconData(
    0xe1e0,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData apple = IconData(0xe516, fontFamily: 'PhosphorRegular');
  static const IconData google = IconData(
    0xe292,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData receipt = IconData(
    0xe3ec,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData bank = IconData(0xe0b4, fontFamily: 'PhosphorRegular');
  static const IconData coins = IconData(0xe78e, fontFamily: 'PhosphorRegular');
  static const IconData handCoins = IconData(
    0xea8c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData piggy = IconData(0xea04, fontFamily: 'PhosphorRegular');
  static const IconData calculator = IconData(
    0xe538,
    fontFamily: 'PhosphorRegular',
  );

  // Documents & boutique
  static const IconData folder = IconData(
    0xe24a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData file = IconData(0xe23a, fontFamily: 'PhosphorRegular');
  static const IconData image = IconData(0xe2ca, fontFamily: 'PhosphorRegular');
  static const IconData images = IconData(
    0xe836,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData certificate = IconData(
    0xe766,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData invoice = IconData(
    0xee42,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData contract = IconData(
    0xe604,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData bag = IconData(0xe416, fontFamily: 'PhosphorRegular');
  static const IconData cart = IconData(0xe41e, fontFamily: 'PhosphorRegular');
  static const IconData gift = IconData(0xe276, fontFamily: 'PhosphorRegular');
  static const IconData qr = IconData(0xe3e6, fontFamily: 'PhosphorRegular');
  static const IconData globe = IconData(0xe288, fontFamily: 'PhosphorRegular');
  static const IconData table = IconData(0xe476, fontFamily: 'PhosphorRegular');
  static const IconData headset = IconData(
    0xe584,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData printer = IconData(
    0xe3dc,
    fontFamily: 'PhosphorRegular',
  );

  // Business
  static const IconData crm = IconData(0xe73c, fontFamily: 'PhosphorRegular');
  static const IconData plugs = IconData(0xeb56, fontFamily: 'PhosphorRegular');
  static const IconData code = IconData(0xe1bc, fontFamily: 'PhosphorRegular');
  static const IconData palette = IconData(
    0xe6c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData buildings = IconData(
    0xe102,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData handshake = IconData(
    0xe582,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData briefcase = IconData(
    0xe0ee,
    fontFamily: 'PhosphorRegular',
  );

  // Catégories d'événements
  static const IconData wedding = IconData(
    0xe2a8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData birthday = IconData(
    0xe780,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData baby = IconData(0xe774, fontFamily: 'PhosphorRegular');
  static const IconData friends = IconData(
    0xeaca,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData outing = IconData(
    0xe8ba,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData pro = IconData(0xe0ee, fontFamily: 'PhosphorRegular');
  static const IconData milestone = IconData(
    0xe62c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData family = IconData(
    0xe68e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData charity = IconData(
    0xe810,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData seasonal = IconData(
    0xe6dc,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData confetti = IconData(
    0xe81a,
    fontFamily: 'PhosphorRegular',
  );

  // Postes & prestataires
  static const IconData venue = IconData(0xe102, fontFamily: 'PhosphorRegular');
  static const IconData food = IconData(0xe262, fontFamily: 'PhosphorRegular');
  static const IconData drinks = IconData(
    0xe6b2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData decor = IconData(0xeacc, fontFamily: 'PhosphorRegular');
  static const IconData camera = IconData(
    0xe10e,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData music = IconData(0xe340, fontFamily: 'PhosphorRegular');
  static const IconData chair = IconData(0xe950, fontFamily: 'PhosphorRegular');
  static const IconData dress = IconData(0xea7e, fontFamily: 'PhosphorRegular');
  static const IconData car = IconData(0xe112, fontFamily: 'PhosphorRegular');
  static const IconData staff = IconData(0xe582, fontFamily: 'PhosphorRegular');
  static const IconData planner = IconData(
    0xe198,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData boat = IconData(0xe786, fontFamily: 'PhosphorRegular');
  static const IconData ticket = IconData(
    0xe490,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData hourglass = IconData(
    0xe2b2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData airplane = IconData(
    0xe002,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData mic = IconData(0xe75c, fontFamily: 'PhosphorRegular');

  // Compte, export, agenda
  static const IconData eye = IconData(0xe220, fontFamily: 'PhosphorRegular');
  static const IconData user = IconData(0xe4c2, fontFamily: 'PhosphorRegular');
  static const IconData chevronLeft = IconData(
    0xe138,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData link = IconData(0xe2e2, fontFamily: 'PhosphorRegular');
  static const IconData idCard = IconData(
    0xe2c8,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData download = IconData(
    0xe20c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData csv = IconData(0xeb1c, fontFamily: 'PhosphorRegular');
  static const IconData inbox = IconData(0xe4aa, fontFamily: 'PhosphorRegular');
  static const IconData grid = IconData(0xe464, fontFamily: 'PhosphorRegular');
  static const IconData calendarDots = IconData(
    0xe7b4,
    fontFamily: 'PhosphorRegular',
  );

  // Préférences, à propos, confidentialité
  static const IconData moon = IconData(0xe330, fontFamily: 'PhosphorRegular');
  static const IconData translate = IconData(
    0xe4a2,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData speaker = IconData(
    0xe44a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData speakerOff = IconData(
    0xe45a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData scroll = IconData(
    0xeb7a,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData cookie = IconData(
    0xe6ca,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData heart = IconData(0xe2a8, fontFamily: 'PhosphorRegular');
  static const IconData target = IconData(
    0xe47c,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData database = IconData(
    0xe1de,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData handHeart = IconData(
    0xe810,
    fontFamily: 'PhosphorRegular',
  );
  static const IconData lifebuoy = IconData(
    0xe63a,
    fontFamily: 'PhosphorRegular',
  );
}
