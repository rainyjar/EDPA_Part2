
import java.io.IOException;
import java.sql.Date;
import java.util.List;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.Customer;
import model.DoctorFacade;
import model.Doctor;

@WebServlet(urlPatterns = {"/DoctorServlet"})
@MultipartConfig

public class DoctorServlet extends HttpServlet {

    @EJB
    private DoctorFacade doctorFacade;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Doctor doctor = doctorFacade.find(id);
            if (doctor != null) {
                doctorFacade.remove(doctor);
            }
            response.sendRedirect("DoctorServlet");
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Doctor doctor = doctorFacade.find(id);

            if (doctor != null) {
                // Validate and update doctor information
                String validationError = validateDoctorInput(request, doctor.getEmail(), doctor.getId());
                if (validationError != null) {
                    request.setAttribute("error", validationError);
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                    return;
                }

                doctor.setName(request.getParameter("name").trim());
                doctor.setEmail(request.getParameter("email").trim());
                doctor.setPassword(request.getParameter("password"));
                doctor.setPhone(request.getParameter("phone").trim());
                doctor.setGender(request.getParameter("gender"));
                doctor.setSpecialization(request.getParameter("specialization").trim());

                try {
                    String dobStr = request.getParameter("dob");
                    if (dobStr != null && !dobStr.isEmpty()) {
                        Date dob = Date.valueOf(dobStr);
                        doctor.setDob(dob);
                    }
                } catch (Exception e) {
                    request.setAttribute("error", "Invalid date format");
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                    return;
                }

                Part file = request.getPart("profilePic");
                try {
                    if (file != null && file.getSize() > 0) {
                        String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                        doctor.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                    return;
                }

                doctorFacade.edit(doctor); // update to DB
            }

            response.sendRedirect("DoctorServlet"); // go back to list
        } else {
            // Registration block with comprehensive validation
            try {
                // Validate input
                String validationError = validateDoctorInput(request, null, null);
                if (validationError != null) {
                    request.setAttribute("error", validationError);
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_doctor.jsp").forward(request, response);
                    return;
                }

                String name = request.getParameter("name").trim();
                String email = request.getParameter("email").trim();
                String password = request.getParameter("password");
                String phone = request.getParameter("phone").trim();
                String gender = request.getParameter("gender");
                String dobStr = request.getParameter("dob");
                String specialization = request.getParameter("specialization").trim();

                // Parse date of birth
                Date dob = null;
                if (dobStr != null && !dobStr.isEmpty()) {
                    dob = Date.valueOf(dobStr); // yyyy-MM-dd
                }

                String uploadedFileName = null;
                Part file = request.getPart("profilePic");

                try {
                    uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_doctor.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_doctor.jsp").forward(request, response);
                    return;
                }

                Doctor d = new Doctor();
                d.setName(name);
                d.setEmail(email);
                d.setPassword(password);
                d.setPhone(phone);
                d.setGender(gender);
                d.setDob(dob);
                d.setSpecialization(specialization);
                d.setProfilePic(uploadedFileName);

                doctorFacade.create(d);
                request.setAttribute("success", "Doctor registered successfully.");
                request.getRequestDispatcher("manager/register_doctor.jsp").include(request, response);

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register doctor: " + e.getMessage());
                preserveFormData(request);
                request.getRequestDispatcher("manager/register_doctor.jsp").include(request, response);
            }
        }
    }

    // Helper method to validate doctor input
    private String validateDoctorInput(HttpServletRequest request, String existingEmail, Integer doctorId) {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String phone = request.getParameter("phone");
        String gender = request.getParameter("gender");
        String dobStr = request.getParameter("dob");
        String specialization = request.getParameter("specialization");

        // Validate required fields
        if (name == null || name.trim().isEmpty()) {
            return "Full name is required";
        }
        if (email == null || email.trim().isEmpty()) {
            return "Email address is required";
        }
        if (password == null || password.trim().isEmpty()) {
            return "Password is required";
        }
        if (phone == null || phone.trim().isEmpty()) {
            return "Phone number is required";
        }
        if (gender == null || gender.trim().isEmpty()) {
            return "Gender is required";
        }
        if (dobStr == null || dobStr.trim().isEmpty()) {
            return "Date of birth is required";
        }
        if (specialization == null || specialization.trim().isEmpty()) {
            return "Medical specialization is required";
        }

        // Validate name length
        if (name.trim().length() < 2) {
            return "Name must be at least 2 characters long";
        }
        if (name.trim().length() > 100) {
            return "Name cannot exceed 100 characters";
        }

        // Validate email format
        String emailRegex = "^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$";
        if (!email.trim().matches(emailRegex)) {
            return "Please enter a valid email address";
        }

        // Check if email already exists (exclude current doctor if updating)
        if (existingEmail == null || !existingEmail.equals(email.trim())) {
            Doctor existingDoctor = doctorFacade.searchEmail(email.trim());
            if (existingDoctor != null && (doctorId == null || existingDoctor.getId() != doctorId)) {
                return "Email address is already registered";
            }
        }

        // Validate password
        if (password.length() < 6) {
            return "Password must be at least 6 characters long";
        }
        if (password.length() > 50) {
            return "Password cannot exceed 50 characters";
        }

        // Validate phone number
        String phoneRegex = "^[\\+]?[0-9\\s\\-\\(\\)]{10,15}$";
        if (!phone.trim().matches(phoneRegex)) {
            return "Please enter a valid phone number (10-15 digits)";
        }

        // Validate gender
        if (!gender.equals("M") && !gender.equals("F")) {
            return "Please select a valid gender";
        }

        // Validate date of birth
        try {
            Date dob = Date.valueOf(dobStr);
            Date today = new Date(System.currentTimeMillis());
            
            if (dob.compareTo(today) >= 0) {
                return "Date of birth cannot be in the future";
            }
            
            // Calculate age
            long ageInMillis = today.getTime() - dob.getTime();
            long ageInYears = ageInMillis / (365L * 24L * 60L * 60L * 1000L);
            
            if (ageInYears < 18) {
                return "Doctor must be at least 18 years old";
            }
            if (ageInYears > 100) {
                return "Please enter a valid date of birth";
            }
        } catch (IllegalArgumentException e) {
            return "Please enter a valid date of birth";
        }

        // Validate specialization
        if (specialization.trim().length() < 2) {
            return "Specialization must be at least 2 characters long";
        }
        if (specialization.trim().length() > 100) {
            return "Specialization cannot exceed 100 characters";
        }

        return null; // No validation errors
    }

    // Helper method to preserve form data on error
    private void preserveFormData(HttpServletRequest request) {
        Doctor doctor = new Doctor();
        doctor.setName(request.getParameter("name"));
        doctor.setEmail(request.getParameter("email"));
        doctor.setPassword(request.getParameter("password"));
        doctor.setPhone(request.getParameter("phone"));
        doctor.setGender(request.getParameter("gender"));
        doctor.setSpecialization(request.getParameter("specialization"));
        
        String dobStr = request.getParameter("dob");
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                doctor.setDob(Date.valueOf(dobStr));
            } catch (Exception e) {
                // Ignore invalid date
            }
        }
        
        request.setAttribute("doctor", doctor);
    }

//    retrieve Doctors detail and handle CRUD operations
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession(false);

        // Handle CRUD operations first
        try {
            if ("view".equals(action)) {
                // View individual doctor details
                int id = Integer.parseInt(request.getParameter("id"));
                Doctor doctor = doctorFacade.find(id);
                
                if (doctor != null) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/view_doc.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                }
                return;
                
            } else if ("edit".equals(action)) {
                // Edit doctor - load doctor for editing
                int id = Integer.parseInt(request.getParameter("id"));
                Doctor doctor = doctorFacade.find(id);
                
                if (doctor != null) {
                    request.setAttribute("doctor", doctor);
                    request.getRequestDispatcher("/manager/edit_doctor.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                }
                return;
                
            } else if ("delete".equals(action)) {
                // Delete doctor
                int id = Integer.parseInt(request.getParameter("id"));
                Doctor doctor = doctorFacade.find(id);
                
                if (doctor != null) {
                    doctorFacade.remove(doctor);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=doctor_not_found");
                }
                return;
            }
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=invalid_id");
            return;
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
            return;
        }

        // Default behavior: check session and show appropriate list
        Customer loggedInCustomer = (session != null) ? (Customer) session.getAttribute("customer") : null;
        System.out.println("Doctor Servlet: " + loggedInCustomer);

        if (loggedInCustomer != null) {
            // Authenticated as customer, show team page
            List<Doctor> doctorList = doctorFacade.findAll();
            request.setAttribute("doctorList", doctorList);
            request.getRequestDispatcher("/customer/team.jsp").forward(request, response);
        } 
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
