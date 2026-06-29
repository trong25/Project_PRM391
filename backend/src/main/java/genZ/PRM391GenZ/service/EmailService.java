package genZ.PRM391GenZ.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Value("${app.reset-token.expiry-minutes}")
    private int expiryMinutes;

    public boolean sendPasswordResetEmail(String toEmail, String resetLink, String userName) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail, "GenzCinema Hotel");
            helper.setTo(toEmail);
            helper.setSubject("Đặt lại mật khẩu - GenzCinema Hotel");
            helper.setText(buildEmailContent(userName, resetLink), true);

            mailSender.send(message);
            log.info("Password reset email sent to: {}", toEmail);
            return true;

        } catch (MessagingException | java.io.UnsupportedEncodingException e) {
            log.error("Failed to send email to {}: {}", toEmail, e.getMessage());
            return false;
        }
    }

    private String buildEmailContent(String name, String link) {
        return """
            <!DOCTYPE html>
            <html lang='vi'>
            <head>
              <meta charset='UTF-8'>
              <meta name='viewport' content='width=device-width, initial-scale=1.0'>
              <style>
                body { font-family: 'Segoe UI', sans-serif; background: #f5f3ff; margin: 0; padding: 20px; color: #2d1b44; }
                .container { max-width: 600px; margin: 0 auto; background: #fff; border-radius: 12px;
                             box-shadow: 0 8px 32px rgba(139,92,246,0.15); overflow: hidden; }
                .header { background: linear-gradient(135deg, #8b5cf6, #6d28d9); color: white; padding: 30px; text-align: center; }
                .header h1 { margin: 0 0 8px; font-size: 26px; }
                .content { padding: 30px; }
                .btn { display: inline-block; background: linear-gradient(135deg, #8b5cf6, #7c3aed);
                       color: white; padding: 14px 28px; text-decoration: none; border-radius: 8px;
                       font-weight: 600; margin: 20px 0; }
                .warning { background: #fef3c7; border-left: 4px solid #d97706; padding: 16px;
                           border-radius: 8px; margin: 20px 0; }
                .warning strong { color: #92400e; }
                .link-box { word-break: break-all; background: #f3f4f6; padding: 12px;
                            border-radius: 8px; font-family: monospace; font-size: 13px; }
                .footer { padding: 20px; text-align: center; color: #6b7280; font-size: 13px;
                          background: #f8fafc; border-top: 1px solid #e2e8f0; }
              </style>
            </head>
            <body>
              <div class='container'>
                <div class='header'>
                  <h1>GenzCinema Hotel</h1>
                  <p style='margin:0;opacity:.9'>Đặt lại mật khẩu</p>
                </div>
                <div class='content'>
                  <h3>👋 Xin chào %s!</h3>
                  <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu tài khoản của bạn.</p>
                  <div style='text-align:center'>
                    <a href='%s' class='btn'>Đặt lại mật khẩu ngay</a>
                  </div>
                  <div class='warning'>
                    <strong>⚠️ Lưu ý:</strong><br>
                    • Link hết hạn sau <strong>%d phút</strong><br>
                    • Không chia sẻ link này với bất kỳ ai<br>
                    • Nếu không yêu cầu, hãy bỏ qua email này
                  </div>
                  <p><strong>Nút không hoạt động?</strong> Sao chép link:</p>
                  <div class='link-box'>%s</div>
                </div>
                <div class='footer'>
                  <p>Email tự động từ hệ thống GenzCinema Hotel. Vui lòng không trả lời.</p>
                </div>
              </div>
            </body>
            </html>
            """.formatted(
                name != null ? name : "bạn",
                link,
                expiryMinutes,
                link
        );
    }
}
