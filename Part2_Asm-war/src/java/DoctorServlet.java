
import java.io.BufferedReader;
import model.Doctor;
import model.DoctorFacade;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.List;
import java.util.stream.Collectors;
import javax.servlet.annotation.MultipartConfig;
import model.Customer;

@WebServlet("/DoctorServlet")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class DoctorServlet extends HttpServlet {

    @EJB
    private DoctorFacade doctorFacade;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        if (!isManagerLoggedIn(request, response)) {
            return;
        }
        String action = request.getParameter("action");

        if ("register".equals(action)) {
            handleRegister(request, response);
        } else if ("update".equals(action)) {
            handleUpdate(request, response);
        } else if ("delete".equals(action)) {
            handleDelete(request, response);
        } else {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String action = request.getParameter("action");
        // Default behavior: check session and show appropriate list
        Customer loggedInCustomer = (session != null) ? (Customer) session.getAttribute("customer") : null;
        System.out.println("Doctor Servlet: " + loggedInCustomer);

        if (loggedInCustomer != null) {
            // Authenticated as customer, show team page
            List<Doctor> doctorList = doctorFacade.findAll();
            request.setAttribute("doctorList", doctorList);
            request.getRequestDispatcher("/customer/team.jsp").forward(request, response);
        }

        // Manager logic only for view/edit/delete
        if ("view".equals(action) || "edit".equals(action) || "delete".equals(action)) {
            if (!isManagerLoggedIn(request, response)) {
                return;
            }

            try {
                int id = Integer.parseInt(request.getParameter("id"));
                Doctor doctor = doctorFacade.find(id);

                if (doctor == null) {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                    return;
                }

                if ("view".equals(action)) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/view_doc.jsp").forward(request, response);
                } else if ("edit".equals(action)) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                } else if ("delete".equals(action)) {
                    doctorFacade.remove(doctor);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=doctor_deleted");
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
            }
        }
    }

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Doctor doctor = new Doctor();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (!populateDoctorFromRequest(request, doctor, null)) {
            preserveFormData(request);
            request.setAttribute("doctor", doctor);
            request.getRequestDispatcher("/manager/register_doctor.jsp").forward(request, response);
            return;
        }
        doctorFacade.create(doctor);
        request.setAttribute("success", "Doctor registered successfully.");
        request.getRequestDispatcher("manager/register_doctor.jsp").forward(request, response);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Doctor doctor = doctorFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (doctor == null) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
            return;
        }

        if (!populateDoctorFromRequest(request, doctor, doctor.getEmail())) {
            request.setAttribute("doctor", doctor);
            response.sendRedirect(request.getContextPath() + "/DoctorServlet?action=edit&id=" + doctor.getId() + "&error=input_invalid");
            return;
        }

        doctorFacade.edit(doctor);
        request.setAttribute("success", "Doctor updated successfully.");
        request.setAttribute("doctor", doctor);
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=doctor_updated");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        Doctor doctor = doctorFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (doctor != null) {
            doctorFacade.remove(doctor);
        }
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
    }

    private boolean populateDoctorFromRequest(HttpServletRequest request, Doctor doctor, String existingEmail) throws IOException, ServletException {
        String name = readFormField(request.getPart("name"));
        String email = readFormField(request.getPart("email"));
        String password = readFormField(request.getPart("password"));
        String phone = readFormField(request.getPart("phone"));
        String gender = readFormField(request.getPart("gender"));
        String dobStr = readFormField(request.getPart("dob"));
        String specialization = readFormField(request.getPart("specialization"));
        String nric = readFormField(request.getPart("nric"));
        String address = readFormField(request.getPart("address"));

        if (name.isEmpty() || email.isEmpty() || password.isEmpty() || phone.isEmpty() || gender == null || dobStr.isEmpty() || specialization.isEmpty() || nric.isEmpty() || address.isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            return false;
        }

        if (!email.equals(existingEmail) && doctorFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        try {
            doctor.setName(name);
            doctor.setEmail(email);
            doctor.setPassword(password);
            doctor.setPhone(phone);
            doctor.setGender(gender);
            doctor.setDob(Date.valueOf(dobStr));
            doctor.setSpecialization(specialization);
            doctor.setIc(nric);
            doctor.setAddress(address);

        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                doctor.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        Doctor doctor = new Doctor();
        doctor.setName(readFormField(request.getPart("name")));
        doctor.setEmail(readFormField(request.getPart("email")));
        doctor.setPassword(readFormField(request.getPart("password")));
        doctor.setPhone(readFormField(request.getPart("phone")));
        doctor.setGender(readFormField(request.getPart("gender")));
        doctor.setSpecialization(readFormField(request.getPart("specialization")));
        doctor.setIc(readFormField(request.getPart("nric")));
        doctor.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                doctor.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("doctor", doctor);
    }

    private String readFormField(Part part) throws IOException {
        if (part == null) {
            return "";
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(part.getInputStream(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n")).trim();
        }
    }

    private boolean isManagerLoggedIn(HttpServletRequest request, HttpServletResponse response) throws IOException {
        try {
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("manager") == null) {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }
            return true;
        } catch (IllegalStateException e) {
            // Already committed response (e.g., forward was called), can't redirect
            System.out.println("Warning: Response already committed. Skipping redirect.");
            return false;
        }
    }

    @Override
    public String getServletInfo() {
        return "DoctorServlet - Handles CRUD operations for doctors";
    }
}
