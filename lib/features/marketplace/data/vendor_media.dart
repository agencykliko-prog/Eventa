import 'package:flutter/material.dart';

import '../../../ui/theme/eventa_colors.dart';
import '../../events/domain/models.dart';

/// Photos libres de droits (Unsplash), servies depuis leur CDN comme le
/// recommande Unsplash. Une réserve par catégorie alimente les portfolios.
abstract final class VendorMedia {
  static String url(String id, {int w = 900}) =>
      'https://images.unsplash.com/$id?w=$w&q=70&auto=format&fit=crop';

  static const pools = <VendorCategory, List<String>>{
    VendorCategory.venue: [
      'photo-1779308936221-89739e035a53',
      'photo-1783314867628-220ab03cac99',
      'photo-1765947384834-3bdcffcaffff',
      'photo-1763553113332-800519753e40',
      'photo-1775918427144-51f0bf53f8c4',
      'photo-1762765684665-6b6855bb6fe6',
      'photo-1780542900375-0cf459e38fbb',
      'photo-1783314863884-be035ed5ed5c',
      'photo-1761114905078-163aa92141c8',
      'photo-1759477274116-e3cb02d2b9d8',
    ],
    VendorCategory.decor: [
      'photo-1469371670807-013ccf25f16a',
      'photo-1644135129271-e80c8c673511',
      'photo-1677768062491-07f280ff830a',
      'photo-1737236119003-b9ff5b2b5c16',
      'photo-1737236118342-d4c175bf0814',
      'photo-1544813618-56d190260a84',
      'photo-1724847664831-27b55fef3121',
      'photo-1613067532295-b4f1760616cd',
      'photo-1521129866021-4313ccf20e9e',
    ],
    VendorCategory.catering: [
      'photo-1555244162-803834f70033',
      'photo-1722477936580-84aa10762b0b',
      'photo-1671612451404-f4f8fc5fe25e',
      'photo-1665332195309-9d75071138f0',
      'photo-1555939594-58d7cb561ad1',
      'photo-1603496987674-79600a000f55',
      'photo-1773209928058-cfd3314acc7c',
      'photo-1535254973040-607b474cb50d',
      'photo-1525257831700-183b9b8bf5c4',
      'photo-1771285119408-04cca3b35036',
    ],
    VendorCategory.photo: [
      'photo-1519741497674-611481863552',
      'photo-1758810409996-583f3bad7d51',
      'photo-1622277430358-f4d134452e2e',
      'photo-1769635177236-116c95222fab',
      'photo-1629756048377-09540f52caa1',
      'photo-1617724975854-70b5d0cedb0a',
      'photo-1611550287705-7ff8b459c8eb',
      'photo-1600164913117-2125c1f60b01',
      'photo-1722805740177-04256b6517f2',
    ],
    VendorCategory.music: [
      'photo-1470225620780-dba8ba36b745',
      'photo-1541126274323-dbac58d14741',
      'photo-1758944966810-9785cfbf4486',
      'photo-1571266028243-d220c6a7edbf',
      'photo-1762674541314-dc97fde0006c',
      'photo-1544785349-c4a5301826fd',
      'photo-1777734448523-6b441c719d8d',
      'photo-1496337589254-7e19d01cec44',
      'photo-1762092892289-423cecb4b516',
    ],
    VendorCategory.rental: [
      'photo-1665607437981-973dcd6a22bb',
      'photo-1620735692151-26a7e0748429',
      'photo-1759124650320-d629a3d73d9f',
      'photo-1780682568331-2bc7318210ce',
      'photo-1759124650342-b283fa8461fa',
      'photo-1762765685348-4bced247d12c',
      'photo-1769812343285-ec0775437680',
      'photo-1766719628920-854680a92c22',
      'photo-1759769583908-7cd4e3310ce6',
    ],
    VendorCategory.beauty: [
      'photo-1657563920440-0ac6d8932f20',
      'photo-1618999114008-fbf937170cdb',
      'photo-1501175635532-bdd01562edb2',
      'photo-1618998584360-10a0c28eec0f',
      'photo-1726276262267-ebb01cfa0982',
      'photo-1786529743856-4b92beab03a3',
      'photo-1786529744110-2bb63713b06f',
      'photo-1786529745854-fb41cbaf5fa3',
      'photo-1726276262266-492c00b38e62',
    ],
    VendorCategory.paper: [
      'photo-1632610992723-82d7c212f6d7',
      'photo-1633037773384-27d7ac0491e7',
      'photo-1738898179451-b5fc497f9f8e',
      'photo-1741893043659-ca8b82a8b637',
      'photo-1732649124686-3bab54f79aa3',
      'photo-1509316554658-04f9287cdb78',
      'photo-1758825178518-ca48833a6c57',
      'photo-1712313992209-93a2cc377ede',
      'photo-1676910490328-2a4d7e5e747c',
    ],
    VendorCategory.transport: [
      'photo-1570907870057-e1e338bc0665',
      'photo-1592514313074-794923c98162',
      'photo-1561100966-f6aa0145e8e6',
      'photo-1523371696700-91e21249c0ed',
      'photo-1777415923415-1792e87ae078',
      'photo-1782638865004-4e2234e653a7',
      'photo-1571113908007-5d6aae13d73e',
      'photo-1655757457375-c1668c7bc0ad',
      'photo-1516536900061-d881b27e8ff8',
    ],
    VendorCategory.staff: [
      'photo-1516788875874-c5912cae7b43',
      'photo-1719573019827-d06944a0c2be',
      'photo-1745930743491-799ff8538cf1',
      'photo-1776603174157-bf286ef86149',
      'photo-1786912029736-2d0862e394a6',
      'photo-1791535769610-1d1e036975eb',
      'photo-1512919586724-ae82d9fc1f19',
      'photo-1638704890058-841a4a376654',
      'photo-1546567075-d7113bee3c4a',
    ],
    VendorCategory.planner: [
      'photo-1511795409834-ef04bbd61622',
      'photo-1768055105012-4c53791b2877',
      'photo-1513128034602-7814ccaddd4e',
      'photo-1653821355736-0c2598d0a63e',
      'photo-1529651737248-dad5e287768e',
      'photo-1770135005669-0094609c733e',
      'photo-1530023367847-a683933f4172',
      'photo-1544655152-4dc3bc4df059',
      'photo-1527529482837-4698179dc6ce',
    ],
    VendorCategory.activity: [
      'photo-1604737637145-48cc31d160eb',
      'photo-1787586997698-614cac396bee',
      'photo-1602867612779-3aaf54b425c2',
      'photo-1552600337-6f42e4fb2e78',
      'photo-1775326714947-759837c872cb',
      'photo-1672939113905-49237296683a',
      'photo-1519801584609-8ee5f072eddd',
      'photo-1758626219703-46bfaeaa39fa',
      'photo-1622561931334-292caa9cd886',
      'photo-1501426026826-31c667bdf23d',
    ],
  };

  /// Photo de couverture d'un prestataire ajouté depuis la réserve.
  static String cover(VendorCategory c, int i) {
    final pool = pools[c]!;
    return url(pool[i % pool.length]);
  }

  /// Cinq photos de portfolio, différentes d'un prestataire à l'autre.
  static List<String> portfolioOf(Vendor v) {
    final pool = pools[v.category]!;
    final start = v.id.codeUnits.fold<int>(0, (a, c) => a + c) % pool.length;
    return [
      for (var i = 0; i < 5; i++)
        url(pool[(start + i * 2) % pool.length], w: 700),
    ];
  }
}

/// Image de prestataire : fichier de l'app ou photo en ligne, avec un fond
/// doux pendant le chargement et en cas d'échec réseau.
class VendorPhoto extends StatelessWidget {
  const VendorPhoto(
    this.src, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
  });

  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: Confetti.lavender,
    );
    if (!src.startsWith('http')) {
      return Image.asset(
        src,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
      );
    }
    return Image.network(
      src,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 260),
              child: frame == null ? placeholder : child,
            ),
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
