
import java.io.IOException;
import java.sql.Date;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Manager;

@WebServlet(urlPatterns = {"/CounterStaffServlet"})
@MultipartConfig

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

    //    register new counter staff (not yet validate)
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        Manager manager = (Manager) session.getAttribute("manager");
        if (manager == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        session.setAttribute("manager", manager);
        System.out.println("Session is null? " + (session == null));
        System.out.println("Manager is null? " + (session != null && session.getAttribute("manager") == null));

        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);
            if (counter_staff != null) {
                counterStaffFacade.remove(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet"); // reload list
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counter_staff = counterStaffFacade.find(id);

            if (counter_staff != null) {
                counter_staff.setName(request.getParameter("name"));
                counter_staff.setEmail(request.getParameter("email"));
                counter_staff.setPassword(request.getParameter("password"));
                counter_staff.setPhone(request.getParameter("phone"));
                counter_staff.setGender(request.getParameter("gender"));

                try {
                    String dobStr = request.getParameter("dob");
                    java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                    java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                    counter_staff.setDob(sqlDate);
                } catch (ParseException e) {
                    e.printStackTrace(); // log or handle
                }

                Part file = request.getPart("profilePic");
                try {
                    String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                    if (uploadedFileName != null) {
                        counter_staff.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Upload failed: " + e.getMessage());
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                    return;
                }

                counterStaffFacade.edit(counter_staff);
            }
            response.sendRedirect("CounterStaffServlet");
            request.setAttribute("manager", manager);
            request.setAttribute("success", "Counter staff updated successfully!");
            request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
        } else if ("register".equals(action)) {
            // Registration block with comprehensive validation
            try {
                // Validate input
                String validationError = validateStaffInput(request, null, null);
                if (validationError != null) {
                    request.setAttribute("error", validationError);
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                    return;
                }

                String name = request.getParameter("name").trim();
                String email = request.getParameter("email").trim();
                String password = request.getParameter("password");
                String phone = request.getParameter("phone").trim();
                String gender = request.getParameter("gender");
                String dobStr = request.getParameter("dob");

                // Parse date of birth
                Date dob = null;
                if (dobStr != null && !dobStr.isEmpty()) {
                    dob = Date.valueOf(dobStr); // yyyy-MM-dd
                }

                String uploadedFileName = null;
                Part file = request.getPart("profilePic");

                try {
                    uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
                    return;
                }

                CounterStaff cs = new CounterStaff();
                cs.setName(name);
                cs.setEmail(email);
                cs.setPassword(password);
                cs.setPhone(phone);
                cs.setGender(gender);
                cs.setDob(dob);
                cs.setProfilePic(uploadedFileName);

                counterStaffFacade.create(cs);
                request.setAttribute("success", "Counter staff registered successfully.");
                request.getRequestDispatcher("manager/register_cs.jsp").include(request, response);

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register counter staff: " + e.getMessage());
                preserveFormData(request);
                request.getRequestDispatcher("manager/register_cs.jsp").include(request, response);
            }
        }
    }

    // Helper method to validate staff input
    private String validateStaffInput(HttpServletRequest request, String existingEmail, Integer staffId) {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String phone = request.getParameter("phone");
        String gender = request.getParameter("gender");
        String dobStr = request.getParameter("dob");

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

        // Check if email already exists (exclude current staff if updating)
        if (existingEmail == null || !existingEmail.equals(email.trim())) {
            CounterStaff existingStaff = counterStaffFacade.searchEmail(email.trim());
            if (existingStaff != null && (staffId == null || existingStaff.getId() != staffId)) {
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

            if (ageInYears < 16) {
                return "Staff member must be at least 16 years old";
            }
            if (ageInYears > 100) {
                return "Please enter a valid date of birth";
            }
        } catch (IllegalArgumentException e) {
            return "Please enter a valid date of birth";
        }

        return null; // No validation errors
    }

    // Helper method to preserve form data on error
    private void preserveFormData(HttpServletRequest request) {
        CounterStaff staff = new CounterStaff();
        staff.setName(request.getParameter("name"));
        staff.setEmail(request.getParameter("email"));
        staff.setPassword(request.getParameter("password"));
        staff.setPhone(request.getParameter("phone"));
        staff.setGender(request.getParameter("gender"));

        String dobStr = request.getParameter("dob");
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                staff.setDob(Date.valueOf(dobStr));
            } catch (Exception e) {
                // Ignore invalid date
            }
        }

        request.setAttribute("cstaff", staff);
    }

//    retrieve counter staff detail and handle CRUD operations
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        Manager manager = (Manager) session.getAttribute("manager");
        if (manager == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
        session.setAttribute("manager", manager);

        System.out.println("Session is null? " + (session == null));
        System.out.println("Manager is null? " + (session != null && session.getAttribute("manager") == null));

        try {
            if ("view".equals(action)) {
                // View individual counter staff details
                int id = Integer.parseInt(request.getParameter("id"));
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/view_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
                return;

            } else if ("edit".equals(action)) {
                // Edit counter staff - load staff for editing
                int id = Integer.parseInt(request.getParameter("id"));
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
                return;

            } else if ("delete".equals(action)) {
                // Delete counter staff
                int id = Integer.parseInt(request.getParameter("id"));
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    counterStaffFacade.remove(counterStaff);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
                return;

            }

        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
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
