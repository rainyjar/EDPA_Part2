
import java.io.IOException;
import javax.ejb.EJB;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import model.ManagerFacade;
import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.stream.Collectors;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import model.CounterStaff;
import model.CounterStaffFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Manager;

/**
 *
 * @author chris
 */
@WebServlet(urlPatterns = {"/ManagerServlet"})
@MultipartConfig

public class ManagerServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

    @EJB
    private DoctorFacade doctorFacade;

    @EJB
    private ManagerFacade managerFacade;

//    register new manager (not yet validate)
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html");
        String action = request.getParameter("action");

        if ("delete".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Manager manager = managerFacade.find(id);
            if (manager != null) {
                managerFacade.remove(manager);
            }
            response.sendRedirect("ManagerServlet");
        } else if ("update".equals(action)) {
            int id = Integer.parseInt(request.getParameter("id"));
            Manager manager = managerFacade.find(id);

            if (manager != null) {
                manager.setName(request.getParameter("name"));
                manager.setEmail(request.getParameter("email"));
                manager.setPassword(request.getParameter("password"));
                manager.setPhone(request.getParameter("phone"));
                manager.setGender(request.getParameter("gender"));

                try {
                    String dobStr = request.getParameter("dob");
                    java.util.Date utilDate = new SimpleDateFormat("yyyy-MM-dd").parse(dobStr);
                    java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                    manager.setDob(sqlDate);
                } catch (ParseException e) {
                    e.printStackTrace();
                }

                Part file = request.getPart("profilePic");
                try {
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                    if (uploadedFileName != null) {
                        manager.setProfilePic(uploadedFileName);
                    }
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Upload failed: " + e.getMessage());
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                    return;
                }

                managerFacade.edit(manager);
            }
            response.sendRedirect("ManagerServlet");

        } else {
            // Registration block with comprehensive validation
            try {
                // Validate input
                String validationError = validateManagerInput(request, null, null);
                if (validationError != null) {
                    request.setAttribute("error", validationError);
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
                    return;
                }

                String name = request.getParameter("name").trim();
                String email = request.getParameter("email").trim();
                String password = request.getParameter("password");
                String phone = request.getParameter("phone").trim();
                String gender = request.getParameter("gender");
                String dobStr = request.getParameter("dob");

                Date dob = null;
                if (dobStr != null && !dobStr.isEmpty()) {
                    dob = Date.valueOf(dobStr);
                }

                String uploadedFileName = null;
                Part file = request.getPart("profilePic");

                try {
                    uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
                    return;
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
                    preserveFormData(request);
                    request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
                    return;
                }

                Manager m = new Manager();
                m.setName(name);
                m.setEmail(email);
                m.setPassword(password);
                m.setPhone(phone);
                m.setGender(gender);
                m.setDob(dob);
                m.setProfilePic(uploadedFileName);

                managerFacade.create(m);
                request.setAttribute("success", "Manager registered successfully.");
                request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);

            } catch (Exception e) {
                e.printStackTrace();
                request.setAttribute("error", "Failed to register manager: " + e.getMessage());
                preserveFormData(request);
                request.getRequestDispatcher("/manager/register_manager.jsp").forward(request, response);
            }
        }
    }

    // Helper method to validate manager input
    private String validateManagerInput(HttpServletRequest request, String existingEmail, Integer managerId) {
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

        // Check if email already exists (exclude current manager if updating)
        if (existingEmail == null || !existingEmail.equals(email.trim())) {
            // Check in all user types
            List<Manager> managers = managerFacade.findAll();
            for (Manager mgr : managers) {
                if (mgr.getEmail().equals(email.trim()) && (managerId == null || mgr.getId() != managerId)) {
                    return "Email address is already registered";
                }
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

            if (ageInYears < 21) {
                return "Manager must be at least 21 years old";
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
        Manager manager = new Manager();
        manager.setName(request.getParameter("name"));
        manager.setEmail(request.getParameter("email"));
        manager.setPassword(request.getParameter("password"));
        manager.setPhone(request.getParameter("phone"));
        manager.setGender(request.getParameter("gender"));

        String dobStr = request.getParameter("dob");
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                manager.setDob(Date.valueOf(dobStr));
            } catch (Exception e) {
                // Ignore invalid date
            }
        }

        request.setAttribute("manager", manager);
    }

//    retrieve managers detail and handle all GET operations
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Manager loggedInManager = (Manager) session.getAttribute("manager");

        if (loggedInManager == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        try {
            if ("viewAll".equals(action) || action == null) {
                // Load all staff for manage staff page
                List<Doctor> doctorList = doctorFacade.findAll();
                List<CounterStaff> staffList = counterStaffFacade.findAll();
                List<Manager> managerList = managerFacade.findAll();

                // Debug output
                System.out.println("ManagerServlet: Loading staff data...");
                System.out.println("Doctors found: " + (doctorList != null ? doctorList.size() : "null"));
                System.out.println("Counter Staff found: " + (staffList != null ? staffList.size() : "null"));
                System.out.println("Managers found: " + (managerList != null ? managerList.size() : "null"));

                // Sort by rating/name
                if (doctorList != null) {
                    doctorList.sort((d1, d2) -> {
                        Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                        Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                        return rating2.compareTo(rating1);
                    });
                }

                if (staffList != null) {
                    staffList.sort((s1, s2) -> {
                        Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                        Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                        return rating2.compareTo(rating1);
                    });
                }

                if (managerList != null) {
                    managerList.sort((m1, m2) -> m1.getName().compareToIgnoreCase(m2.getName()));
                }

                request.setAttribute("doctorList", doctorList);
                request.setAttribute("staffList", staffList);
                request.setAttribute("managerList", managerList);

                System.out.println("ManagerServlet: Forwarding to manage_staff.jsp");
                request.getRequestDispatcher("/manager/manage_staff.jsp").forward(request, response);

            } else if ("search".equals(action)) {
                // Handle search and filter
                String searchQuery = request.getParameter("search");
                String roleFilter = request.getParameter("role");
                String genderFilter = request.getParameter("gender");

                List<Doctor> doctorList = null;
                List<CounterStaff> staffList = null;
                List<Manager> managerList = null;

                // Apply filters based on role
                if ("all".equals(roleFilter) || "doctor".equals(roleFilter)) {
                    doctorList = searchDoctors(searchQuery, genderFilter);
                }

                if ("all".equals(roleFilter) || "counter_staff".equals(roleFilter)) {
                    staffList = searchCounterStaff(searchQuery, genderFilter);
                }

                if ("all".equals(roleFilter) || "manager".equals(roleFilter)) {
                    managerList = searchManagers(searchQuery, genderFilter);
                }

                request.setAttribute("doctorList", doctorList);
                request.setAttribute("staffList", staffList);
                request.setAttribute("managerList", managerList);

                request.getRequestDispatcher("/manager/manage_staff.jsp").forward(request, response);

            } else if ("edit".equals(action)) {
                // Edit manager - load manager for editing
                int id = Integer.parseInt(request.getParameter("id"));
                Manager manager = managerFacade.find(id);

                if (manager != null) {
                    request.setAttribute("manager", manager);
                    request.getRequestDispatcher("/manager/edit_manager.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }

            } else if ("view".equals(action)) {
                // View individual manager details
                int id = Integer.parseInt(request.getParameter("id"));
                Manager viewManager = managerFacade.find(id);

                if (viewManager != null) {
                    request.setAttribute("viewManager", viewManager);
                    request.getRequestDispatcher("/manager/view_manager.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }

            } else if ("delete".equals(action)) {
                // Delete manager
                int id = Integer.parseInt(request.getParameter("id"));

                // Prevent self-deletion
                if (id == loggedInManager.getId()) {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=cannot_delete_self");
                    return;
                }

                Manager deleteManager = managerFacade.find(id);
                if (deleteManager != null) {
                    managerFacade.remove(deleteManager);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=staff_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=manager_not_found");
                }

            }

        } catch (NumberFormatException e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=invalid_id");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=system_error");
        }
    }

// Helper methods for search functionality
    private List<Doctor> searchDoctors(String searchQuery, String genderFilter) {
        List<Doctor> allDoctors = doctorFacade.findAll();
        if (allDoctors == null) {
            return null;
        }

        return allDoctors.stream()
                .filter(doctor -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || doctor.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || doctor.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || doctor.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((d1, d2) -> {
                    Double rating1 = d1.getRating() != null ? d1.getRating() : 0.0;
                    Double rating2 = d2.getRating() != null ? d2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                })
                .collect(Collectors.toList());
    }

    private List<CounterStaff> searchCounterStaff(String searchQuery, String genderFilter) {
        List<CounterStaff> allStaff = counterStaffFacade.findAll();
        if (allStaff == null) {
            return null;
        }

        return allStaff.stream()
                .filter(staff -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || staff.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || staff.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || staff.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((s1, s2) -> {
                    Double rating1 = s1.getRating() != null ? s1.getRating() : 0.0;
                    Double rating2 = s2.getRating() != null ? s2.getRating() : 0.0;
                    return rating2.compareTo(rating1);
                })
                .collect(Collectors.toList());
    }

    private List<Manager> searchManagers(String searchQuery, String genderFilter) {
        List<Manager> allManagers = managerFacade.findAll();
        if (allManagers == null) {
            return null;
        }

        return allManagers.stream()
                .filter(mgr -> {
                    boolean matchesSearch = searchQuery == null || searchQuery.trim().isEmpty()
                            || mgr.getName().toLowerCase().contains(searchQuery.toLowerCase())
                            || mgr.getEmail().toLowerCase().contains(searchQuery.toLowerCase());

                    boolean matchesGender = "all".equals(genderFilter)
                            || mgr.getGender().equals(genderFilter);

                    return matchesSearch && matchesGender;
                })
                .sorted((m1, m2) -> m1.getName().compareToIgnoreCase(m2.getName()))
                .collect(Collectors.toList());
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
