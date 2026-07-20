package genZ.PRM391GenZ.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import genZ.PRM391GenZ.dto.room.RoomDto;
import genZ.PRM391GenZ.entity.Hotel;
import genZ.PRM391GenZ.entity.Room;
import genZ.PRM391GenZ.entity.TypeRoom;
import genZ.PRM391GenZ.repository.HotelRepository;
import genZ.PRM391GenZ.repository.RoomRepository;
import genZ.PRM391GenZ.repository.TypeRoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RoomService {

    private final RoomRepository roomRepository;
    private final HotelRepository hotelRepository;
    private final TypeRoomRepository typeRoomRepository;
    private final ObjectMapper objectMapper;

    public List<RoomDto> getAllRooms() {
        return roomRepository.findAll().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public RoomDto getRoomById(String id) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng với ID: " + id));
        return mapToDto(room);
    }

    public List<RoomDto> getRoomsByHotel(String hotelId) {
        return roomRepository.findByHotel_HotelId(hotelId).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public RoomDto createRoom(RoomDto dto) {
        Hotel hotel = hotelRepository.findById(dto.getHotelId())
                .orElseThrow(() -> new RuntimeException("Khách sạn không tồn tại"));

        TypeRoom typeRoom = typeRoomRepository.findById(dto.getTypeRoomId())
                .orElseThrow(() -> new RuntimeException("Loại phòng không tồn tại"));

        Room room = Room.builder()
                .roomId(UUID.randomUUID().toString())
                .nameRoom(dto.getNameRoom())
                .status(dto.getStatus() != null ? dto.getStatus() : "Trống")
                .imageUrl(serializeImageUrls(dto))
                .hotel(hotel)
                .typeRoom(typeRoom)
                .build();

        Room saved = roomRepository.save(room);
        log.info("Created new room: {}", saved.getNameRoom());
        return mapToDto(saved);
    }

    @Transactional
    public RoomDto updateRoom(String id, RoomDto dto) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng với ID: " + id));

        room.setNameRoom(dto.getNameRoom());
        if (dto.getStatus() != null) {
            room.setStatus(dto.getStatus());
        }
        if (dto.getImageUrls() != null || dto.getImageUrl() != null) {
            room.setImageUrl(serializeImageUrls(dto));
        }

        if (dto.getHotelId() != null) {
            Hotel hotel = hotelRepository.findById(dto.getHotelId())
                    .orElseThrow(() -> new RuntimeException("Khách sạn không tồn tại"));
            room.setHotel(hotel);
        }

        if (dto.getTypeRoomId() != null) {
            TypeRoom typeRoom = typeRoomRepository.findById(dto.getTypeRoomId())
                    .orElseThrow(() -> new RuntimeException("Loại phòng không tồn tại"));
            room.setTypeRoom(typeRoom);
        }

        Room updated = roomRepository.save(room);
        log.info("Updated room: {}", updated.getNameRoom());
        return mapToDto(updated);
    }

    @Transactional
    public void deleteRoom(String id) {
        if (!roomRepository.existsById(id)) {
            throw new RuntimeException("Không tìm thấy phòng với ID: " + id);
        }
        roomRepository.deleteById(id);
        log.info("Deleted room with ID: {}", id);
    }

    @Transactional
    public RoomDto updateRoomStatus(String id, String status) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng với ID: " + id));
        room.setStatus(status);
        Room updated = roomRepository.save(room);
        log.info("Updated room status for room {}: {}", id, status);
        return mapToDto(updated);
    }

    private RoomDto mapToDto(Room room) {
        List<String> imageUrls = parseImageUrls(room.getImageUrl());

        return RoomDto.builder()
                .roomId(room.getRoomId())
                .nameRoom(room.getNameRoom())
                .status(room.getStatus())
                .typeRoomId(room.getTypeRoom() != null ? room.getTypeRoom().getTypeRoomId() : null)
                .typeRoomName(room.getTypeRoom() != null ? room.getTypeRoom().getTypeRoom() : null)
                .hotelId(room.getHotel() != null ? room.getHotel().getHotelId() : null)
                .hotelName(room.getHotel() != null ? room.getHotel().getName() : null)
                .imageUrl(imageUrls.isEmpty() ? null : imageUrls.get(0))
                .imageUrls(imageUrls)
                .hotel(room.getHotel())
                .typeRoom(room.getTypeRoom())
                .build();
    }

    private String serializeImageUrls(RoomDto dto) {
        List<String> imageUrls = new ArrayList<>();
        if (dto.getImageUrls() != null) {
            imageUrls.addAll(dto.getImageUrls().stream()
                    .filter(url -> url != null && !url.isBlank())
                    .toList());
        } else if (dto.getImageUrl() != null && !dto.getImageUrl().isBlank()) {
            imageUrls.add(dto.getImageUrl());
        }

        if (imageUrls.isEmpty()) {
            return null;
        }

        try {
            return objectMapper.writeValueAsString(imageUrls);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Không lưu được danh sách ảnh phòng", e);
        }
    }

    private List<String> parseImageUrls(String storedValue) {
        if (storedValue == null || storedValue.isBlank()) {
            return Collections.emptyList();
        }

        String trimmed = storedValue.trim();
        if (!trimmed.startsWith("[")) {
            return List.of(trimmed);
        }

        try {
            return objectMapper.readValue(trimmed, new TypeReference<List<String>>() {})
                    .stream()
                    .filter(url -> url != null && !url.isBlank())
                    .toList();
        } catch (JsonProcessingException e) {
            return List.of(trimmed);
        }
    }
}