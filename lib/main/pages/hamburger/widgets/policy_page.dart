import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart'; 

class PolicyPage extends StatelessWidget {
  String content;
  PolicyPage({super.key, required this.content});
  final String privacyPolicy = '''
Chính sách bảo mật này áp dụng cho ứng dụng DM Store trên thiết bị di động, được phát triển bởi DM (nhà cung cấp dịch vụ) dưới hình thức dịch vụ thương mại. Dịch vụ này được cung cấp theo nguyên tắc "Nguyên Trạng".

1. Thu Thập và Sử Dụng Thông Tin

Ứng dụng thu thập thông tin khi bạn tải xuống và sử dụng, bao gồm:
- Địa chỉ IP của thiết bị
- Các trang bạn truy cập trong Ứng dụng, thời gian và ngày truy cập
- Thời gian sử dụng Ứng dụng
- Hệ điều hành trên thiết bị di động của bạn
- Thông tin tài khoản (họ tên, số điện thoại, email, địa chỉ giao hàng)
- Lịch sử đơn hàng và giao dịch thanh toán

Ứng dụng không thu thập thông tin vị trí chính xác của thiết bị.

Nhà cung cấp dịch vụ có thể sử dụng thông tin của bạn để liên hệ cung cấp thông tin quan trọng, thông báo cần thiết và chương trình khuyến mãi.

2. Chia Sẻ Thông Tin với Bên Thứ Ba

Chỉ dữ liệu tổng hợp, ẩn danh mới được gửi định kỳ đến các dịch vụ bên ngoài nhằm cải thiện Ứng dụng. Nhà cung cấp dịch vụ sử dụng các dịch vụ bên thứ ba sau:
- Google Play Services
- Firebase 

Thông tin của bạn có thể được tiết lộ khi:
- Có yêu cầu từ cơ quan pháp luật
- Cần thiết để bảo vệ quyền lợi, sự an toàn của người dùng hoặc điều tra gian lận
- Hợp tác với các đối tác dịch vụ có ràng buộc bảo mật

3. Chính Sách Đổi Trả và Hoàn Tiền

- Sản phẩm được đổi trả trong vòng 7 ngày kể từ ngày nhận hàng nếu có lỗi từ nhà sản xuất
- Sản phẩm đổi trả phải còn nguyên hộp, đầy đủ phụ kiện và hóa đơn mua hàng
- Hoàn tiền được xử lý trong vòng 3-5 ngày làm việc sau khi xác nhận đổi trả hợp lệ
- Không áp dụng đổi trả với sản phẩm đã qua sử dụng, trầy xước do người dùng

4. Chính Sách Bảo Hành

- Sản phẩm được bảo hành theo chính sách của nhà sản xuất
- Thời gian bảo hành được ghi rõ trên phiếu bảo hành kèm theo sản phẩm
- Bảo hành không áp dụng với hư hỏng do tác động vật lý, chất lỏng hoặc tự ý sửa chữa

5. Thanh Toán

- Ứng dụng hỗ trợ thanh toán online qua các cổng thanh toán được bảo mật
- Thông tin thẻ thanh toán không được lưu trữ trên hệ thống của chúng tôi
- Mọi giao dịch đều được mã hóa và bảo vệ

6. Quyền Từ Chối

Bạn có thể dừng toàn bộ việc thu thập thông tin bằng cách gỡ cài đặt Ứng dụng thông qua quy trình gỡ cài đặt tiêu chuẩn của thiết bị hoặc chợ ứng dụng.

7. Lưu Trữ Dữ Liệu

Nhà cung cấp dịch vụ sẽ lưu trữ dữ liệu trong thời gian bạn sử dụng Ứng dụng và một khoảng thời gian hợp lý sau đó. Nếu muốn xóa dữ liệu, vui lòng liên hệ qua email: mynguyen.vo0974@gmail.com.

8. Bảo Mật

Nhà cung cấp dịch vụ áp dụng các biện pháp bảo vệ vật lý, điện tử và quy trình để bảo vệ thông tin người dùng.

9. Thay Đổi Chính Sách

Chính sách bảo mật có thể được cập nhật định kỳ. Mọi thay đổi sẽ được thông báo trên trang này. Việc tiếp tục sử dụng Ứng dụng đồng nghĩa với việc bạn chấp nhận các thay đổi đó.

Chính sách này có hiệu lực từ ngày 01/07/2026.

10. Liên Hệ

Nếu có thắc mắc về chính sách bảo mật, vui lòng liên hệ:
Email: mynguyen.vo0974@gmail.com
''';

  final String termsConditions = '''
Các điều khoản này áp dụng cho ứng dụng DM Store trên thiết bị di động, được phát triển bởi DM (nhà cung cấp dịch vụ) dưới hình thức dịch vụ thương mại.

Khi tải xuống hoặc sử dụng Ứng dụng, bạn tự động đồng ý với các điều khoản sau. Vui lòng đọc kỹ trước khi sử dụng.

1. Quyền Sở Hữu Trí Tuệ

Nghiêm cấm sao chép, chỉnh sửa Ứng dụng, bất kỳ phần nào của Ứng dụng hoặc nhãn hiệu của chúng tôi. Mọi nỗ lực trích xuất mã nguồn, dịch sang ngôn ngữ khác hoặc tạo phiên bản phái sinh đều không được phép. Toàn bộ nhãn hiệu, bản quyền và quyền sở hữu trí tuệ liên quan đến Ứng dụng thuộc về Nhà cung cấp dịch vụ.

2. Điều Kiện Mua Hàng

- Bạn phải từ 18 tuổi trở lên hoặc có sự đồng ý của người giám hộ để thực hiện giao dịch
- Thông tin đặt hàng (tên, địa chỉ, số điện thoại) phải chính xác và đầy đủ
- Nhà cung cấp dịch vụ không chịu trách nhiệm nếu đơn hàng thất bại do thông tin sai
- Giá sản phẩm có thể thay đổi mà không cần thông báo trước
- Đơn hàng chỉ được xác nhận sau khi thanh toán thành công

3. Vận Chuyển và Giao Hàng

- Thời gian giao hàng dự kiến được hiển thị khi đặt hàng
- Nhà cung cấp dịch vụ không chịu trách nhiệm về chậm trễ do đơn vị vận chuyển hoặc sự kiện bất khả kháng
- Vui lòng kiểm tra hàng trước khi ký nhận

4. Thanh Toán

- Ứng dụng hỗ trợ nhiều phương thức thanh toán an toàn
- Mọi giao dịch đều được mã hóa và bảo mật
- Trong trường hợp thanh toán lỗi, vui lòng liên hệ hỗ trợ trước khi thực hiện lại giao dịch

5. Đổi Trả và Hoàn Tiền

- Sản phẩm được đổi trả trong vòng 7 ngày nếu có lỗi từ nhà sản xuất
- Sản phẩm đổi trả phải còn nguyên hộp, đầy đủ phụ kiện
- Hoàn tiền được xử lý trong 3-5 ngày làm việc

6. Trách Nhiệm Sử Dụng

Một số tính năng yêu cầu kết nối internet. Nhà cung cấp dịch vụ không chịu trách nhiệm nếu Ứng dụng không hoạt động đầy đủ do thiếu kết nối mạng hoặc hết dung lượng data.

Không nên jailbreak hoặc root thiết bị vì có thể gây mất bảo mật và ứng dụng hoạt động không ổn định.

7. Dịch Vụ Bên Thứ Ba

Ứng dụng sử dụng các dịch vụ bên thứ ba có Điều khoản riêng:
- Google Play Services
- Firebase

8. Thay Đổi Điều Khoản

Nhà cung cấp dịch vụ có thể cập nhật Điều khoản định kỳ. Bạn nên xem lại trang này thường xuyên. Việc tiếp tục sử dụng Ứng dụng sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận Điều khoản mới.

Điều khoản này có hiệu lực từ ngày 15/11/2025.

9. Liên Hệ

Nếu có câu hỏi hoặc góp ý về Điều khoản sử dụng, vui lòng liên hệ:
Email: mynguyen.vo0974@gmail.com
''';

  @override
  Widget build(BuildContext context) {
    final String title =
        content == 'policy' ? 'Chính sách bảo mật' : 'Điều khoản sử dụng';

    final String textContent =
        content == 'policy' ? privacyPolicy : termsConditions;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.scaffoldBg,
            leading: AppbarIcon(),
            elevation: 0,
            floating: true,
            snap: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(title, style: AppTextstyles.headingH5Bold),
                      const SizedBox(height: 12),
                      Container(
                        height: 2,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        textContent,
                        style: AppTextstyles.headingH7,
                      ),
                  
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
          const SliverToBoxAdapter(
            child: Center(
              child: Text(
                "DM Mobile © 2026",
                style: TextStyle(color: Colors.black45),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}
