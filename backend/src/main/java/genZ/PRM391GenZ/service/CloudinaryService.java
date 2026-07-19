package genZ.PRM391GenZ.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class CloudinaryService {

    private final Cloudinary cloudinary;

    public String uploadRoomImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("Vui lòng chọn ảnh phòng");
        }

        if (!isSupportedImage(file)) {
            throw new RuntimeException("File tải lên phải là ảnh JPG, PNG, WEBP, GIF, HEIC hoặc HEIF");
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
            return toBrowserFriendlyImageUrl(secureUrl.toString());
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

    private boolean isSupportedImage(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && contentType.startsWith("image/")) {
            return true;
        }

        String filename = file.getOriginalFilename();
        if (filename == null) {
            return false;
        }

        String lowerFilename = filename.toLowerCase(Locale.ROOT);
        return lowerFilename.endsWith(".heic")
                || lowerFilename.endsWith(".heif")
                || lowerFilename.endsWith(".jpg")
                || lowerFilename.endsWith(".jpeg")
                || lowerFilename.endsWith(".png")
                || lowerFilename.endsWith(".webp")
                || lowerFilename.endsWith(".gif");
    }

    private String toBrowserFriendlyImageUrl(String secureUrl) {
        if (!secureUrl.contains("/upload/")) {
            return secureUrl;
        }
        return secureUrl.replace("/upload/", "/upload/f_jpg,q_auto/");
    }
}
