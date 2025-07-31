import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(urlPatterns = {"/ImageServlet"})
public class ImageServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String fileName = request.getParameter("file");
        String folder = request.getParameter("folder"); // e.g., "profile_pictures" or "treatment"

        if (fileName == null || fileName.isEmpty() || folder == null) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing 'file' parameter.");
            return;
        }

        String userHome = System.getProperty("user.home");
        Path imagePath = Paths.get(userHome, "Downloads", "AMC_images", folder, fileName);

        File imageFile = imagePath.toFile();

        if (!Files.exists(imagePath)) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // Set the content type
        String mimeType = getServletContext().getMimeType(imageFile.getName());
        if (mimeType == null) {
            mimeType = "application/octet-stream";
        }
        response.setContentType(mimeType);
        response.setContentLengthLong(imageFile.length());

        // Stream the file content
        try (BufferedInputStream in = new BufferedInputStream(new FileInputStream(imageFile));
                BufferedOutputStream out = new BufferedOutputStream(response.getOutputStream())) {

            byte[] buffer = new byte[8192];
            int bytesRead;

            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }
}
