/// Mock data for study documents
library;
import 'package:thpt_exam_prep_app/models.dart';

class MockDocumentsData {
  static final List<StudyDocument> documents = [
    StudyDocument(
      id: 'doc_001',
      topicId: 'topic_001',
      subjectId: 'subj_001',
      title: 'HÃ m sá»‘ báº­c nháº¥t vÃ  báº­c hai',
      description: 'TÃ i liá»‡u chi tiáº¿t vá» hÃ m sá»‘ báº­c nháº¥t, báº­c hai vÃ  cÃ¡c tÃ­nh cháº¥t',
      content: '''
HÃ m sá»‘ báº­c nháº¥t: y = ax + b (a â‰  0)
- Táº­p xÃ¡c Ä‘á»‹nh: D = â„
- Äá»“ thá»‹: Ä‘Æ°á»ng tháº³ng
- Há»‡ sá»‘ a > 0: hÃ m Ä‘á»“ng biáº¿n
- Há»‡ sá»‘ a < 0: hÃ m nghá»‹ch biáº¿n

HÃ m sá»‘ báº­c hai: y = axÂ² + bx + c (a â‰  0)
- Táº­p xÃ¡c Ä‘á»‹nh: D = â„
- Äá»“ thá»‹: parabol
- Äá»‰nh: I(-b/2a, -Î”/4a)
- Trá»¥c Ä‘á»‘i xá»©ng: x = -b/2a
- a > 0: parabol quay lÃªn
- a < 0: parabol quay xuá»‘ng
      ''',
      thumbnailUrl: 'ðŸ“Š',
      author: 'Tháº§y Nguyá»…n VÄƒn A',
      views: 245,
      rating: 4.8,
      ratingCount: 52,
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_002',
      topicId: 'topic_001',
      subjectId: 'subj_001',
      title: 'PhÆ°Æ¡ng trÃ¬nh vÃ  báº¥t phÆ°Æ¡ng trÃ¬nh',
      description: 'CÃ¡c phÆ°Æ¡ng phÃ¡p giáº£i phÆ°Æ¡ng trÃ¬nh vÃ  báº¥t phÆ°Æ¡ng trÃ¬nh cÆ¡ báº£n',
      content: '''
PhÆ°Æ¡ng trÃ¬nh báº­c nháº¥t: ax + b = 0
CÃ¡ch giáº£i: x = -b/a (a â‰  0)

PhÆ°Æ¡ng trÃ¬nh báº­c hai: axÂ² + bx + c = 0 (a â‰  0)
Î” = bÂ² - 4ac
- Î” > 0: hai nghiá»‡m phÃ¢n biá»‡t
- Î” = 0: nghiá»‡m kÃ©p
- Î” < 0: vÃ´ nghiá»‡m

Báº¥t phÆ°Æ¡ng trÃ¬nh báº­c nháº¥t:
ax + b > 0 âŸº x > -b/a (náº¿u a > 0)
ax + b > 0 âŸº x < -b/a (náº¿u a < 0)
      ''',
      thumbnailUrl: 'ðŸ”¢',
      author: 'Tháº§y Tráº§n VÄƒn B',
      views: 189,
      rating: 4.6,
      ratingCount: 38,
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_003',
      topicId: 'topic_002',
      subjectId: 'subj_002',
      title: 'PhÃ¢n tÃ­ch tÃ¡c pháº©m: TrÃ­ch Chinh Phá»¥ NgÃ¢m',
      description: 'PhÃ¢n tÃ­ch chuyÃªn sÃ¢u bÃ i thÆ¡ TrÃ­ch Chinh Phá»¥ NgÃ¢m cá»§a Äá»— Phá»§',
      content: '''
TÃ¡c giáº£: Äá»— Phá»§
Thá»ƒ loáº¡i: ThÆ¡ cá»• Ä‘iá»ƒn
Thá»i gian: Tháº¿ ká»· 18-19

Ná»™i dung chÃ­nh:
- TÃ¬nh yÃªu, máº¥t mÃ¡t vÃ  nhá»› nhung
- Váº» Ä‘áº¹p cá»§a thiÃªn nhiÃªn qua tÃ¢m tráº¡ng nhÃ¢n váº­t
- NhÃ¢n Ä‘áº¡o thÆ°Æ¡ng xÃ³t Ä‘á»™c giáº£

Ká»¹ thuáº­t vÄƒn há»c:
- Sá»­ dá»¥ng áº©n dá»¥, hoÃ¡n dá»¥
- Äiá»‡p mÃ´n, Ä‘iá»‡p tá»±
- HÃ¬nh áº£nh thiÃªn nhiÃªn
      ''',
      thumbnailUrl: 'ðŸ“–',
      author: 'CÃ´ Pháº¡m Thá»‹ C',
      views: 312,
      rating: 4.9,
      ratingCount: 78,
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_004',
      topicId: 'topic_003',
      subjectId: 'subj_003',
      title: 'English Grammar: Tenses',
      description: 'Tá»•ng há»£p cÃ¡c thÃ¬ trong tiáº¿ng Anh vÃ  cÃ¡ch sá»­ dá»¥ng',
      content: '''
Simple Present: I go, You go, He/She/It goes
- HÃ nh Ä‘á»™ng thÆ°á»ng xuyÃªn
- Sá»± tháº­t hiá»ƒn nhiÃªn

Present Continuous: I am going
- HÃ nh Ä‘á»™ng Ä‘ang diá»…n ra

Present Perfect: I have gone
- HÃ nh Ä‘á»™ng vá»«a má»›i xong

Past Simple: I went
- HÃ nh Ä‘á»™ng Ä‘Ã£ hoÃ n thÃ nh trong quÃ¡ khá»©

Past Continuous: I was going
- HÃ nh Ä‘á»™ng Ä‘ang diá»…n ra trong quÃ¡ khá»©

Future Simple: I will go
- HÃ nh Ä‘á»™ng sáº½ xáº£y ra trong tÆ°Æ¡ng lai
      ''',
      thumbnailUrl: 'ðŸŒ',
      author: 'Ms. Johnson',
      views: 267,
      rating: 4.7,
      ratingCount: 54,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_005',
      topicId: 'topic_004',
      subjectId: 'subj_004',
      title: 'CÆ¡ há»c: Chuyá»ƒn Ä‘á»™ng vÃ  lá»±c',
      description: 'Nhá»¯ng khÃ¡i niá»‡m cÆ¡ báº£n vá» chuyá»ƒn Ä‘á»™ng, váº­n tá»‘c vÃ  lá»±c',
      content: '''
Chuyá»ƒn Ä‘á»™ng cÆ¡ há»c:
- Thay Ä‘á»•i vá»‹ trÃ­ cá»§a váº­t theo thá»i gian
- Chuyá»ƒn Ä‘á»™ng tháº³ng Ä‘á»u: v = s/t
- Chuyá»ƒn Ä‘á»™ng tháº³ng biáº¿n Ä‘á»•i Ä‘á»u: v = vâ‚€ + at

Váº­n tá»‘c:
- Váº­n tá»‘c trung bÃ¬nh: v = Î”s/Î”t
- Tá»‘c Ä‘á»™ tá»©c thá»i: lim(Î”tâ†’0) Î”s/Î”t

Lá»±c:
- F = ma (Äá»‹nh luáº­t II Newton)
- F_k = Î¼N (Lá»±c ma sÃ¡t)
- F_c = mg (Trá»ng lá»±c)
      ''',
      thumbnailUrl: 'âš™ï¸',
      author: 'Tháº§y LÃª VÄƒn D',
      views: 198,
      rating: 4.5,
      ratingCount: 42,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_006',
      topicId: 'topic_005',
      subjectId: 'subj_005',
      title: 'HÃ³a há»c: CÃ¢n báº±ng phÆ°Æ¡ng trÃ¬nh hÃ³a há»c',
      description: 'HÆ°á»›ng dáº«n cÃ¢n báº±ng phÆ°Æ¡ng trÃ¬nh pháº£n á»©ng hÃ³a há»c',
      content: '''
BÆ°á»›c 1: Viáº¿t cÃ´ng thá»©c hÃ³a há»c cá»§a cÃ¡c cháº¥t
BÆ°á»›c 2: XÃ¡c Ä‘á»‹nh sá»‘ nguyÃªn tá»­ cá»§a má»—i nguyÃªn tá»‘ á»Ÿ hai váº¿
BÆ°á»›c 3: Äiá»u chá»‰nh há»‡ sá»‘ Ä‘á»ƒ sá»‘ nguyÃªn tá»­ báº±ng nhau á»Ÿ hai váº¿

VÃ­ dá»¥:
Hâ‚‚ + Oâ‚‚ â†’ Hâ‚‚O
CÃ¢n báº±ng: 2Hâ‚‚ + Oâ‚‚ â†’ 2Hâ‚‚O

Kiá»ƒm tra:
Váº¿ trÃ¡i: 4 H, 2 O
Váº¿ pháº£i: 4 H, 2 O âœ“
      ''',
      thumbnailUrl: 'ðŸ”¬',
      author: 'Tháº§y Nguyá»…n VÄƒn E',
      views: 156,
      rating: 4.4,
      ratingCount: 28,
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_007',
      topicId: 'topic_006',
      subjectId: 'subj_006',
      title: 'Sinh há»c: NhÃ¢n báº£n DNA',
      description: 'QuÃ¡ trÃ¬nh nhÃ¢n báº£n DNA vÃ  vai trÃ² cá»§a cÃ¡c enzyme',
      content: '''
DNA lÃ  Ä‘áº¡i phÃ¢n tá»­ di truyá»n chá»©a thÃ´ng tin di truyá»n

Cáº¥u trÃºc: 
- Hai sá»£i xoáº¯n Ä‘Ã´i
- Nucleotide: 5-carbon sugar, phosphate, base nitrogenous

QuÃ¡ trÃ¬nh nhÃ¢n báº£n:
1. Sá»£i DNA tÃ¡ch rá»i
2. DNA polymerase tá»•ng há»£p sá»£i má»›i
3. Táº¡o ra hai phÃ¢n tá»­ DNA giá»‘ng há»‡t

Enzyme:
- Helicase: tÃ¡ch sá»£i DNA
- DNA polymerase: tá»•ng há»£p sá»£i má»›i
- Ligase: ná»‘i cÃ¡c fragment
      ''',
      thumbnailUrl: 'ðŸ§ª',
      author: 'CÃ´ Phan Thá»‹ F',
      views: 201,
      rating: 4.6,
      ratingCount: 45,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    StudyDocument(
      id: 'doc_008',
      topicId: 'topic_007',
      subjectId: 'subj_007',
      title: 'Lá»‹ch sá»­: CÃ¡ch máº¡ng ThÃ¡ng TÃ¡m 1945',
      description: 'QuÃ¡ trÃ¬nh diá»…n ra cá»§a CÃ¡ch máº¡ng ThÃ¡ng TÃ¡m 1945 vÃ  Ã½ nghÄ©a lá»‹ch sá»­',
      content: '''
Bá»‘i cáº£nh lá»‹ch sá»­:
- Nháº­t Báº£n sáº¯p thua cuá»™c Tháº¿ chiáº¿n II
- NÆ°á»›c PhÃ¡p Ä‘Ã£ máº¥t quyá»n kiá»ƒm soÃ¡t ÄÃ´ng DÆ°Æ¡ng
- DÃ¢n chÃºng Viá»‡t Nam chá»‹u Ä‘Ã³i khÃ¡t do chÃ­nh sÃ¡ch cá»§a Nháº­t

QuÃ¡ trÃ¬nh ná»•i dáº­y:
- Báº¯t Ä‘áº§u tá»« HÃ  Ná»™i ngÃ y 19/8/1945
- Lan rá»™ng nhanh chÃ³ng kháº¯p cáº£ nÆ°á»›c
- QuÃ¢n Viá»‡t Minh tiáº¿p quáº£n chÃ­nh quyá»n

Káº¿t quáº£:
- Thiáº¿t láº­p chÃ­nh quyá»n cÃ¡ch máº¡ng
- Äá»™c láº­p dÃ¢n tá»™c Ä‘Æ°á»£c cÃ´ng nhÃ¢n

Ã nghÄ©a:
- Káº¿t thÃºc tháº¿ ká»· thá»‘ng trá»‹ cá»§a PhÃ¡p
- Má»Ÿ Ä‘áº§u thá»i ká»³ Ä‘á»™c láº­p cá»§a Viá»‡t Nam
      ''',
      thumbnailUrl: 'ðŸ›ï¸',
      author: 'Tháº§y VÃµ VÄƒn G',
      views: 284,
      rating: 4.8,
      ratingCount: 61,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
  ];
}

