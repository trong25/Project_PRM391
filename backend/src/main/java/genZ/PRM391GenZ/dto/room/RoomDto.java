package genZ.PRM391GenZ.dto.room;

import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.entity.TypeRoom;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoomDto {
    private String roomId;
    
    @NotBlank(message = "Tên phòng không được để trống")
    private String nameRoom;
    
    @NotBlank(message = "Vui lòng chọn loại phòng")
    private String typeRoomId;
    private String typeRoomName;
    
    @NotBlank(message = "Vui lòng chọn chi nhánh khách sạn")
    private String hotelId;
    private String hotelName;
    
    private String status;
    // --- THÊM CÁC TRƯỜNG NÀY ĐỂ LIÊN KẾT VỚI FLUTTER ---
    private String imageUrl;   // Ảnh của phòng
    private Hotel hotel;       // Đối tượng Hotel chứa địa chỉ (address), SĐT (phone), imageUrl của khách sạn
    private TypeRoom typeRoom; // Đối tượng TypeRoom chứa giá phòng (pricePerHour)
}
