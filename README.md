# Xulianh_grayscale_histogram_medianfilter
verilog
CHƯƠNG 2: CƠ SỞ LÍ THUYẾT
2.1 Tổng quan xử lí ảnh số
Xử lí ảnh số (Digital Image Processing) là lĩnh vực nghiên cứu các phương pháp sử dụng máy tính hoặc phần cứng số để xử lí, phân tích và cải thiện chất lượng ảnh.
Ảnh sau khi được thu nhận từ camera hoặc cảm biến sẽ được biểu diễn dưới dạng dữ liệu số. Các thuật toán xử lí ảnh sẽ tác động lên dữ liệu này nhằm:
	Cải thiện chất lượng ảnh. 
	Loại bỏ nhiễu. 
	Tăng độ tương phản. 
	Trích xuất thông tin. 
	Hỗ trợ nhận dạng và phân tích ảnh. 
Ngày nay, xử lí ảnh số được ứng dụng rộng rãi trong nhiều lĩnh vực như:
	Camera giám sát. 
	Y tế. 
	Xe tự hành. 
	Nhận dạng khuôn mặt. 
	Công nghiệp tự động hóa. 
	Trí tuệ nhân tạo (AI).
Ảnh số là ảnh được biểu diễn dưới dạng ma trận các điểm ảnh (pixel). Mỗi pixel chứa thông tin về cường độ sáng hoặc màu sắc tại vị trí tương ứng trong ảnh. Ảnh có càng nhiều pixel thì ảnh càng sắc nét.
2.2 Chuyển ảnh màu sang ảnh xám (gray scale):
Ảnh màu RGB bao gồm ba thành phần màu Red (R); Green (G); Blue (B). Mỗi kênh màu được biểu diễn bằng 8-bit. Do đó, một pixel ảnh màu sẽ có tổng cộng 24-bit dữ liệu.
Để chuyển đổi ảnh RGB sang ảnh grayscale ta chuyển ảnh màu RGB sang ảnh bitmap
Tách từng pixel ảnh màu RGB thành 3 kênh màu R, G, B. Mỗi kênh màu là 8 bit. Sau đó ghép 3 kênh thành 24bit của bitmap. Như vậy mỗi pixel ảnh màu sẽ được chuyển thành 24bit với định dạng 3 màu R,G,B tương ứng R [23:16] G[15:8] B[7:0]
Xử dụng công thức chuẩn luminance để điều chỉnh giá trị từng kênh R,G,B để thành ảnh xám (gray scale)
 
Có tham số độ sáng để điều chỉnh. Các giá trị sẽ được cộng thêm tham số độ sáng.
2.3 Xử lí ảnh bị nhiễu (median filter)
Dùng bộ lọc trung vị (median filter) để xử lí
Lọc trung vị là một kĩ thuật lọc phi tuyến (non-linear), nó khá hiệu quả đối với hai loại nhiễu: nhiễu đốm (speckle noise) và nhiễu muối tiêu (salt-pepper noise). Kĩ thuật này là một bước rất phổ biến trong xử lý ảnh. 
Ý tưởng chính của thuật toán lọc trung vị như sau. Đầu tiên ta sử dụng một cửa sổ lọc (ma trận 3×3) quét qua lần lượt từng điểm ảnh của ảnh đầu vào input. Tại vị trí mỗi điểm ảnh lấy giá trị của các điểm ảnh tương ứng trong vùng 3×3 của ảnh gốc “lấp” vào ma trận lọc. Sau đó sắp xếp các điểm ảnh trong cửa sổ này theo thứ tự (tăng dần hoặc giảm dần tùy ý). Cuối cùng, gán điểm ảnh nằm chính giữa (Trung vị) của dãy giá trị điểm ảnh đã được sắp xếp ở trên cho giá trị điểm ảnh đang xét của ảnh đầu ra output.
 
Ví dụ về lọc trung vị trong xử lí ảnh:
 
Để tăng tốc độ xử lí trên FPGA, đề tài sử dụng Sort Network để sắp xếp dữ liệu cho bộ lọc trung vị.
Sort network (mạng phân loại/mạng sắp xếp) là một mô hình tính toán song song, bao gồm các bộ so sánh (comparators) kết nối cố định với nhau để sắp xếp một số lượng đầu vào xác định. Khác với thuật toán sắp xếp thông thường, thứ tự so sánh của sort network được định sẵn, không phụ thuộc vào kết quả các bước trước đó, giúp tối ưu cho phần cứng và xử lý song song. 
 
2.4 Cân bằng độ tương phản (thuật toán Histogram Equalization):
Thuật toán histogram equalization là một phương pháp xử lý ảnh kỹ thuật số giúp tăng cường độ tương phản và mở rộng dải phân bố cường độ sáng. Kỹ thuật này trải đều các mức xám, làm cho hình ảnh rõ nét và chi tiết hơn, đặc biệt khi ảnh bị quá tối hoặc quá sáng
Nguyên lí hoạt động: Thuật toán Histogram Equalization gồm các bước chính:
	Xây dựng histogram gốc: 
Histogram là biểu đồ biểu diễn sự phân bố mức xám trong ảnh. Đối với ảnh grayscale 8-bit thì sự phân bố mức xám r trong khoảng 0 <= r <= 255. 
Để xây dựng Histogram gốc ta tiến hành thống kê tần suất xuất hiện h(r_{k}) của từng mức xám r_{k} trong ảnh. Sau đó ta tính xác xuất phân phối:
 p\left(r_{k}\right)=\ \frac{h(r_{k})}{N}
Trong đó:  p(r_{k})\  là xác xuất xuất hiện mức xám r_{k} trong ảnh.
Độ tương phản là sự khác biệt giữa vùng sáng và vùng tối trong ảnh.
Histogram tập trung hẹp → độ tương phản thấp.
Histogram trải rộng → độ tương phản cao.
 
		(ví dụ về histogram với độ tương phản khác nhau)
Histogram Equalization giúp trải rộng histogram nhằm tăng độ tương phản tổng thể của ảnh.
	Tính hàm phân phối tích lũy: 
Sau khi tính được xác suất phân bố, tiến hành tính hàm phân phối tích lũy (CDF – Cumulative Distribution Function)
  
Trong đó: CDF(r_{k}) là tổng xác suất từ mức xám 0 đến mức xám rk , luôn tăng dần từ 0 → 1.
Ý nghĩa: Biểu diễn xác suất tích lũy, dùng để ánh xạ mức xám.
	Tính hàm biến đổi mức xám
Sau khi tính được CDF , mức xám mới sẽ được tính dựa vào công thức:
 
Trong đó sk là mức xám mới , L là số mức xám của ảnh.
Đối với ảnh grayscale 8-bit  L sẽ bằng 256.
Do đó 	
sk = 255 × CDF(rk)
Kết quả sẽ được làm tròn thành số nguyên để tạo thành giá trị pixel mới.
	Bước cuối là tạo ảnh đầu ra. Ở bước cuối cùng, mỗi pixel có giá trị mức xám ban đầu rk  sẽ được thay thế bằng giá trị mới sk . Sau quá trình ánh xạ Histogram của ảnh sẽ được phân bố đều hơn, độ tương phản của ảnh được cải thiện và các chi tiết trong vùng tối và vùng sáng trở nên rõ hơn. 
r_{k}=\ s_{k}
CHƯƠNG 3. THIẾT KẾ HỆ THỐNG
3.1 Sơ đồ khối hệ thống
Hệ thống xử lí ảnh trên FPGA được thiết kế theo mô hình xử lí tuần tự gồm các khối chức năng chính: chuyển đổi ảnh RGB sang grayscale, lọc nhiễu bằng Median Filter và tăng cường độ tương phản bằng Histogram Equalization.
Ảnh đầu vào được truyền từ máy tính xuống FPGA và lưu vào bộ nhớ SDRAM. Sau đó dữ liệu ảnh lần lượt đi qua các module xử lí trước khi xuất ra ảnh kết quả.
 
Sơ đồ khối tổng quát của hệ thống như sau:
Chức năng các khối
	Nios2: CPU điều khiển các luồng dữ liệu và các khối sdram, jtag_uart
	 SDRAM: lưa data của ảnh
	Jtag_uart: giao tiếp truyền nhận data ảnh từ PC <-> hệ thống 
	RGB to Gray: chuyển đổi ảnh màu RGB sang ảnh grayscale 8-bit. 
	Median Filter: khử nhiễu ảnh bằng bộ lọc trung vị. 
	Histogram Equalization: cải thiện độ tương phản của ảnh. 
