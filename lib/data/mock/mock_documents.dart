/// Mock data for study documents
library;

import 'package:thpt_exam_prep_app/models.dart';

class MockDocumentsData {
  static final List<StudyDocument> documents = [
    StudyDocument(
      id: 'doc_001',
      topicId: 'topic_001',
      subjectId: 'subj_001',
      title: 'Hàm số bậc nhất và bậc hai',
      description:
          'Tài liệu chi tiết về hàm số bậc nhất, bậc hai và các tính chất',
      content: '''
Hàm số bậc nhất: y = ax + b (a ≠ 0)
- Tập xác định: D = ℝ
- Đồ thị: đường thẳng
- Hệ số a > 0: hàm đồng biến
- Hệ số a < 0: hàm nghịch biến

Hàm số bậc hai: y = ax² + bx + c (a ≠ 0)
- Tập xác định: D = ℝ
- Đồ thị: parabol
- Đỉnh: I(-b/2a, -Δ/4a)
- Trục đối xứng: x = -b/2a
- a > 0: parabol quay lên
- a < 0: parabol quay xuống
      ''',
      thumbnailUrl: '📊',
      author: 'Thầy Nguyễn Văn A',
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
      title: 'Phương trình và bất phương trình',
      description:
          'Các phương pháp giải phương trình và bất phương trình cơ bản',
      content: '''
Phương trình bậc nhất: ax + b = 0
Cách giải: x = -b/a (a ≠ 0)

Phương trình bậc hai: ax² + bx + c = 0 (a ≠ 0)
Δ = b² - 4ac
- Δ > 0: hai nghiệm phân biệt
- Δ = 0: nghiệm kép
- Δ < 0: vô nghiệm

Bất phương trình bậc nhất:
ax + b > 0 ⟺ x > -b/a (nếu a > 0)
ax + b > 0 ⟺ x < -b/a (nếu a < 0)
      ''',
      thumbnailUrl: '🔢',
      author: 'Thầy Trần Văn B',
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
      title: 'Phân tích tác phẩm: Trích Chinh Phụ Ngâm',
      description:
          'Phân tích chuyên sâu bài thơ Trích Chinh Phụ Ngâm của Đỗ Phủ',
      content: '''
Tác giả: Đỗ Phủ
Thể loại: Thơ cổ điển
Thời gian: Thế kỷ 18-19

Nội dung chính:
- Tình yêu, mất mát và nhớ nhung
- Vẻ đẹp của thiên nhiên qua tâm trạng nhân vật
- Nhân đạo thương xót độc giả

Kỹ thuật văn học:
- Sử dụng ẩn dụ, hoán dụ
- Điệp môn, điệp tự
- Hình ảnh thiên nhiên
      ''',
      thumbnailUrl: '📖',
      author: 'Cô Phạm Thị C',
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
      description: 'Tổng hợp các thì trong tiếng Anh và cách sử dụng',
      content: '''
Simple Present: I go, You go, He/She/It goes
- Hành động thường xuyên
- Sự thật hiển nhiên

Present Continuous: I am going
- Hành động đang diễn ra

Present Perfect: I have gone
- Hành động vừa mới xong

Past Simple: I went
- Hành động đã hoàn thành trong quá khứ

Past Continuous: I was going
- Hành động đang diễn ra trong quá khứ

Future Simple: I will go
- Hành động sẽ xảy ra trong tương lai
      ''',
      thumbnailUrl: '🌐',
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
      title: 'Cơ học: Chuyển động và lực',
      description: 'Những khái niệm cơ bản về chuyển động, vận tốc và lực',
      content: '''
Chuyển động cơ học:
- Thay đổi vị trí của vật theo thời gian
- Chuyển động thẳng đều: v = s/t
- Chuyển động thẳng biến đổi đều: v = v₀ + at

Vận tốc:
- Vận tốc trung bình: v = Δs/Δt
- Tốc độ tức thời: lim(Δt→0) Δs/Δt

Lực:
- F = ma (Định luật II Newton)
- F_k = μN (Lực ma sát)
- F_c = mg (Trọng lực)
      ''',
      thumbnailUrl: '⚙️',
      author: 'Thầy Lê Văn D',
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
      title: 'Hóa học: Cân bằng phương trình hóa học',
      description: 'Hướng dẫn cân bằng phương trình phản ứng hóa học',
      content: '''
Bước 1: Viết công thức hóa học của các chất
Bước 2: Xác định số nguyên tử của mỗi nguyên tố ở hai vế
Bước 3: Điều chỉnh hệ số để số nguyên tử bằng nhau ở hai vế

Ví dụ:
H₂ + O₂ → H₂O
Cân bằng: 2H₂ + O₂ → 2H₂O

Kiểm tra:
Vế trái: 4 H, 2 O
Vế phải: 4 H, 2 O ✓
      ''',
      thumbnailUrl: '🔬',
      author: 'Thầy Nguyễn Văn E',
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
      title: 'Sinh học: Nhân bản DNA',
      description: 'Quá trình nhân bản DNA và vai trò của các enzyme',
      content: '''
DNA là đại phân tử di truyền chứa thông tin di truyền

Cấu trúc: 
- Hai sợi xoắn đôi
- Nucleotide: 5-carbon sugar, phosphate, base nitrogenous

Quá trình nhân bản:
1. Sợi DNA tách rời
2. DNA polymerase tổng hợp sợi mới
3. Tạo ra hai phân tử DNA giống hệt

Enzyme:
- Helicase: tách sợi DNA
- DNA polymerase: tổng hợp sợi mới
- Ligase: nối các fragment
      ''',
      thumbnailUrl: '🧪',
      author: 'Cô Phan Thị F',
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
      title: 'Lịch sử: Cách mạng Tháng Tám 1945',
      description:
          'Quá trình diễn ra của Cách mạng Tháng Tám 1945 và ý nghĩa lịch sử',
      content: '''
Bối cảnh lịch sử:
- Nhật Bản sắp thua cuộc Thế chiến II
- Nước Pháp đã mất quyền kiểm soát Đông Dương
- Dân chúng Việt Nam chịu đói khát do chính sách của Nhật

Quá trình nổi dậy:
- Bắt đầu từ Hà Nội ngày 19/8/1945
- Lan rộng nhanh chóng khắp cả nước
- Quân Việt Minh tiếp quản chính quyền

Kết quả:
- Thiết lập chính quyền cách mạng
- Độc lập dân tộc được công nhân

Ý nghĩa:
- Kết thúc thế kỷ thống trị của Pháp
- Mở đầu thời kỳ độc lập của Việt Nam
      ''',
      thumbnailUrl: '🏛️',
      author: 'Thầy Võ Văn G',
      views: 284,
      rating: 4.8,
      ratingCount: 61,
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
  ];
}
