//
//import java.io.*;
//import java.nio.file.*;
//import javax.servlet.http.Part;
//import javax.servlet.ServletContext;
//
//public class UploadImage {
//
//    public static String uploadProfilePicture(Part filePart, ServletContext context) throws Exception {
//        if (filePart == null || filePart.getSize() == 0) {
//            return null;
//        }
//
//        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
//        System.out.println("Uploaded filename: " + fileName);
//
//        String contentType = filePart.getContentType();
//        System.out.println("Uploaded file type: " + contentType);
//        if (!contentType.equals("image/jpeg") && !contentType.equals("image/png")) {
//            throw new IllegalArgumentException("Only JPG and PNG files are allowed.");
//        }
//
//        String uploadDirPath = context.getRealPath("images/profile_pictures");
//        System.out.println("Real path to upload: " + uploadDirPath);
//        File uploadDir = new File(uploadDirPath);
//        if (!uploadDir.exists()) {
//            boolean created = uploadDir.mkdirs();
//            System.out.println("Created upload directory? " + created);
//        } else {
//            System.out.println("Upload directory exists.");
//        }
//
//        File uploadedFile = new File(uploadDir, fileName);
//        try (InputStream input = filePart.getInputStream(); FileOutputStream output = new FileOutputStream(uploadedFile)) {
//            byte[] buffer = new byte[1024];
//            int bytesRead;
//            while ((bytesRead = input.read(buffer)) != -1) {
//                output.write(buffer, 0, bytesRead);
//            }
//        }
//
//        return fileName;
//    }
//}
import java.io.*;
import java.nio.file.*;
import java.util.Properties;
import javax.servlet.http.Part;
import javax.servlet.ServletContext;

public class UploadImage {

    public static String uploadProfilePicture(Part filePart, ServletContext context) throws Exception {
        if (filePart == null || filePart.getSize() == 0) {
            return null;
        }

        String fileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
        System.out.println("Uploaded filename: " + fileName);

        String contentType = filePart.getContentType();
        System.out.println("Uploaded file type: " + contentType);
        if (!contentType.equals("image/jpeg") && !contentType.equals("image/png")) {
            throw new IllegalArgumentException("Only JPG and PNG files are allowed.");
        }

        // Load the config.properties
        Properties props = new Properties();
        InputStream input = context.getResourceAsStream("/WEB-INF/config.properties");
        if (input == null) {
            throw new FileNotFoundException("config.properties not found in /WEB-INF/");
        }
        props.load(input);

        String uploadDirPath = props.getProperty("uploadPath");
        if (uploadDirPath == null || uploadDirPath.trim().isEmpty()) {
            throw new IllegalStateException("uploadPath is not configured in config.properties");
        }

        System.out.println("Upload path from config: " + uploadDirPath);
        File uploadDir = new File(uploadDirPath);
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

        return fileName;
    }
}
