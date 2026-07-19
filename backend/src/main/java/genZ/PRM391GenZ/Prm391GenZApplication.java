package genZ.PRM391GenZ;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@SpringBootApplication
public class Prm391GenZApplication {
	public static void main(String[] args) {
//		Chay lenh de hash password 123456, thay hash o phan 'run' vao phan password admin truoc khi Insert
		BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
		System.out.println(encoder.encode("123456"));
		SpringApplication.run(Prm391GenZApplication.class, args);
	}
}
