package genZ.PRM391GenZ.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public String uploadRoomImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("Vui lòng chọn ảnh phòng");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new RuntimeException("File tải lên phải là ảnh");
        }

        try {
            Map uploadResult = cloudinary.uploader().upload(
                    file.getBytes(),
                    ObjectUtils.asMap(
                            "folder", "genz-cinema-hotel/rooms",
                            "resource_type", "image"
                    )
            );
            Object secureUrl = uploadResult.get("secure_url");
            if (secureUrl == null) {
                throw new RuntimeException("Cloudinary không trả về URL ảnh");
            }
            return secureUrl.toString();
        } catch (IOException e) {
            throw new RuntimeException("Không đọc được file ảnh", e);
        }
    }

    public List<String> uploadRoomImages(MultipartFile[] files) {
        if (files == null || files.length == 0) {
            throw new RuntimeException("Vui lòng chọn ít nhất một ảnh phòng");
        }

        return Arrays.stream(files)
                .map(this::uploadRoomImage)
                .toList();
    }
}
