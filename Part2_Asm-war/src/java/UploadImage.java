import java.io.*;
import java.nio.file.*;
import javax.servlet.http.Part;

public class UploadImage {

    public static String uploadImage(Part filePart, String subfolder) throws Exception {
        if (filePart == null || filePart.getSize() == 0) {
            return null;
        }

        // Get original file name
        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
        System.out.println("Uploaded filename: " + fileName);

        // Validate file type
        String contentType = filePart.getContentType();
        System.out.println("Uploaded file type: " + contentType);
        if (!contentType.equals("image/jpeg") && !contentType.equals("image/png")) {
            throw new IllegalArgumentException("Only JPG and PNG files are allowed.");
        }

        // Get user's Downloads folder
        String userHome = System.getProperty("user.home"); // e.g., C:\Users\chris
        Path downloadPath = Paths.get(userHome, "Downloads", "AMC_images", subfolder);
        System.out.println(downloadPath);

        // Create directories if they don't exist
        File uploadDir = downloadPath.toFile();
        if (!uploadDir.exists()) {
            boolean created = uploadDir.mkdirs();
            System.out.println("Created upload directory? " + created);
        } else {
            System.out.println("Upload directory exists.");
        }

        // Save the file
        File uploadedFile = new File(uploadDir, fileName);
        try (InputStream inputStream = filePart.getInputStream();
                FileOutputStream output = new FileOutputStream(uploadedFile)) {
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                output.write(buffer, 0, bytesRead);
            }
        }

        return fileName; // Just return file name; store full path if you need it later
    }
}
