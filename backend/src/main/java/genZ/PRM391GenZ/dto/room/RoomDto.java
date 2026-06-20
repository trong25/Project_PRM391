package genZ.PRM391GenZ.dto.room;

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
}
