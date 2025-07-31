
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.stream.Collectors;
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
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10) // 10MB

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;

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
        Manager loggedInManager = null;
        String action = request.getParameter("action");

        if (session != null) {
            loggedInManager = (Manager) session.getAttribute("manager");
        }

        if (!isManagerLoggedIn(request, response)) {
            return;
        }

        try {
            if ("view".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);
                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/view_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
            } else if ("edit".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    request.setAttribute("counterStaff", counterStaff);
                    request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
                }
            } else if ("delete".equals(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                System.out.print("Selected ID:" + id);
                CounterStaff counterStaff = counterStaffFacade.find(id);

                if (counterStaff != null) {
                    counterStaffFacade.remove(counterStaff);
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_deleted");
                } else {
                    response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=staff_not_found");
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

    private void handleRegister(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        CounterStaff counterStaff = new CounterStaff();
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (!populateCounterStaffFromRequest(request, counterStaff, null)) {
            preserveFormData(request);
            request.setAttribute("counterStaff", counterStaff);
            request.getRequestDispatcher("/manager/register_cs.jsp").forward(request, response);
            return;
        }
        counterStaffFacade.create(counterStaff);
        request.setAttribute("success", "Counter staff registered successfully.");
        request.getRequestDispatcher("manager/register_cs.jsp").forward(request, response);
    }

    private void handleUpdate(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        CounterStaff counterStaff = counterStaffFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (counterStaff == null) {
            response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&error=counterStaff_not_found");
            return;
        }

        if (!populateCounterStaffFromRequest(request, counterStaff, counterStaff.getEmail())) {
            request.setAttribute("counterStaff", counterStaff);
            response.sendRedirect(request.getContextPath() + "/CounterStaffServlet?action=edit&id=" + counterStaff.getId() + "&error=input_invalid");
            return;
        }

        counterStaffFacade.edit(counterStaff);
        request.setAttribute("success", "Counter Staff updated successfully.");
        request.setAttribute("counterStaff", counterStaff);
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_updated");
    }

    private void handleDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        CounterStaff counterStaff = counterStaffFacade.find(id);
        System.out.println("Session ID: " + request.getSession().getId());
        System.out.println("Manager still in session: " + request.getSession().getAttribute("manager"));

        if (counterStaff != null) {
            counterStaffFacade.remove(counterStaff);
        }
        response.sendRedirect(request.getContextPath() + "/ManagerServlet?action=viewAll&success=counter_deleted");
    }

    private boolean populateCounterStaffFromRequest(HttpServletRequest request, CounterStaff counterStaff, String existingEmail) throws IOException, ServletException {
        String name = readFormField(request.getPart("name"));
        String email = readFormField(request.getPart("email"));
        String password = readFormField(request.getPart("password"));
        String phone = readFormField(request.getPart("phone"));
        String gender = readFormField(request.getPart("gender"));
        String dobStr = readFormField(request.getPart("dob"));
        String nric = readFormField(request.getPart("nric"));
        String address = readFormField(request.getPart("address"));

        if (name.isEmpty() || email.isEmpty() || password.isEmpty() || phone.isEmpty() || gender == null || dobStr.isEmpty() || nric.isEmpty() || address.isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            return false;
        }

        if (!email.equals(existingEmail) && counterStaffFacade.searchEmail(email) != null) {
            request.setAttribute("error", "Email address is already registered.");
            return false;
        }

        try {
            LocalDate appointmentDate = LocalDate.parse(dateStr);
            LocalTime appointmentTime = LocalTime.parse(timeStr);

            LocalDate today = LocalDate.now();
            LocalDate nextWeek = today.plusWeeks(1);

            // Check if date is within range (today to next week)
            if (appointmentDate.isBefore(today) || appointmentDate.isAfter(nextWeek)) {
                return false;
            }

            // Check if it's a weekday (Monday=1, Sunday=7)
            if (appointmentDate.getDayOfWeek().getValue() > 5) {
                return false;
            }

            // Check if time is within business hours (9:00 AM to 5:00 PM)
            LocalTime startTime = LocalTime.of(9, 0);
            LocalTime endTime = LocalTime.of(17, 0);
            if (appointmentTime.isBefore(startTime) || appointmentTime.isAfter(endTime)) {
                return false;
            }

            // Check if time is on 30-minute intervals
            if (appointmentTime.getMinute() != 0 && appointmentTime.getMinute() != 30) {
                return false;
            }

            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Check if time slot is available
     */
    private boolean isTimeSlotAvailable(Date date, Time time) {
        // Simplified check - in real implementation, you'd query the database
        return true;
    }

    /**
     * Validate appointment status change
     */
    private boolean isValidStatusChange(String currentStatus, String newStatus) {
        if (currentStatus == null || newStatus == null) {
            return false;
        }

        // Define valid status transitions
        switch (currentStatus.toLowerCase()) {
            case "pending":
                return "approved".equalsIgnoreCase(newStatus)
                        || "cancelled".equalsIgnoreCase(newStatus);
            case "approved":
                return "completed".equalsIgnoreCase(newStatus)
                        || "cancelled".equalsIgnoreCase(newStatus)
                        || "overdue".equalsIgnoreCase(newStatus);
            case "overdue":
                return "pending".equalsIgnoreCase(newStatus)
                        || "completed".equalsIgnoreCase(newStatus)
                        || "cancelled".equalsIgnoreCase(newStatus);
            case "completed":
                return false; // No changes allowed from completed
            case "cancelled":
                return "pending".equalsIgnoreCase(newStatus); // Allow reactivation
            default:
                return false;
        }
    }

    /**
     * Load customers data for management page
     */
    private void loadCustomersData(HttpServletRequest request) {
        try {
            System.out.println("=== DEBUG: Loading customers from database ===");
            List<Customer> customers = customerFacade.findAll();
            System.out.println("=== DEBUG: Found " + (customers != null ? customers.size() : 0) + " customers ===");
            request.setAttribute("customers", customers);
        } catch (Exception e) {
            System.out.println("=== DEBUG: Error loading customers: " + e.getMessage() + " ===");
            e.printStackTrace();
            request.setAttribute("customers", new ArrayList<Customer>());
        }
    }

    /**
     * Load appointment booking data
     */
    private void loadAppointmentBookingData(HttpServletRequest request) {
        try {
            List<Customer> customers = customerFacade.findAll();
            List<Treatment> treatments = treatmentFacade.findAll();
            List<Doctor> doctors = doctorFacade.findAll();

            request.setAttribute("customers", customers);
            request.setAttribute("treatments", treatments);
            request.setAttribute("doctors", doctors);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("customers", new ArrayList<Customer>());
            request.setAttribute("treatments", new ArrayList<Treatment>());
            request.setAttribute("doctors", new ArrayList<Doctor>());
        }
    }

    /**
     * Load appointment management data
     */
    private void loadAppointmentManagementData(HttpServletRequest request) {
        try {
            List<Appointment> appointments = appointmentFacade.findAll();
            List<Doctor> doctors = doctorFacade.findAll();
            List<Treatment> treatments = treatmentFacade.findAll();
            List<CounterStaff> counterStaffList = counterStaffFacade.findAll();

            // Trim treatment names to only show the part before "-"
            for (Treatment treatment : treatments) {
                String name = treatment.getName();
                if (name.contains("-")) {
                    treatment.setName(name.split("-")[0].trim());
                }
            }

            // Use correct attribute names that JSP expects
            request.setAttribute("appointmentList", appointments);
            request.setAttribute("doctorList", doctors);
            request.setAttribute("treatmentList", treatments);
            request.setAttribute("staffList", counterStaffList);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("appointmentList", new ArrayList<Appointment>());
            request.setAttribute("doctorList", new ArrayList<Doctor>());
            request.setAttribute("treatmentList", new ArrayList<Treatment>());
            request.setAttribute("staffList", new ArrayList<CounterStaff>());
        }
    }

    /**
     * Load payment data
     */
    private void loadPaymentData(HttpServletRequest request) {
        try {
            List<Payment> payments = paymentFacade.findAll();
            request.setAttribute("payments", payments);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("payments", new ArrayList<Payment>());
        }
    }

    /**
     * Handle counter staff profile update
     */
//    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response,
//            CounterStaff loggedInStaff) throws ServletException, IOException {
//        // Redirect to Profile servlet for profile updates
//        response.sendRedirect(request.getContextPath() + "/Profile?action=update");
//    }

    /**
     * Validate counter staff session for secure operations
     */
    private boolean validateCounterStaffSession(CounterStaff loggedInStaff,
            HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (loggedInStaff == null) {
            // No counter staff session found - redirect to login
            request.setAttribute("error", "Please log in as counter staff to access this page.");
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return false;
        }

        // Additional validation - check if counter staff record still exists in database
        try {
            CounterStaff currentStaff = counterStaffFacade.find(loggedInStaff.getId());
            if (currentStaff == null) {
                // Counter staff record was deleted - invalidate session
                request.getSession().invalidate();
                request.setAttribute("error", "Your account is no longer active. Please contact the manager.");
                response.sendRedirect(request.getContextPath() + "/login.jsp");
                return false;
            }

            // Update session with latest data
            request.getSession().setAttribute("staff", currentStaff);
            return true;

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Session validation failed. Please log in again.");
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return false;
        }
    }

    /**
     * Check if the operation is a legacy operation that doesn't require session
     * validation
     */
    private boolean isLegacyOperation(String action) {
        // Manager operations that don't require counter staff session
        return "edit".equals(action) || action == null;
    }

    // ==================== LEGACY COUNTER STAFF OPERATIONS (FOR MANAGER) ====================
    /**
     * Handle counter staff registration by manager
     */
    private void handleRegister(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String phone = request.getParameter("phone");
            String gender = request.getParameter("gender");
            String dobStr = request.getParameter("dob");

            // Validate required fields
            if (name == null || email == null || password == null) {
                request.setAttribute("error", "Name, email, and password are required.");
                List<CounterStaff> counterStaff = counterStaffFacade.findAll();
                request.setAttribute("counterStaffList", counterStaff);
                request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
                return;
            }

            // Parse date of birth
            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                try {
                    dob = Date.valueOf(dobStr);
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", "Invalid date format. Please use YYYY-MM-DD.");
                    List<CounterStaff> counterStaff = counterStaffFacade.findAll();
                    request.setAttribute("counterStaffList", counterStaff);
                    request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
                    return;
                }
            }

            // Handle profile picture upload if provided
            String uploadedFileName = null;
            Part file = request.getPart("profilePic");
            if (file != null && file.getSize() > 0) {
                try {
                    uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                } catch (Exception e) {
                    System.err.println("Profile picture upload failed: " + e.getMessage());
                }
            }

            // Create new counter staff
            CounterStaff counterStaff = new CounterStaff();
            counterStaff.setName(name);
            counterStaff.setEmail(email);
            counterStaff.setPassword(password);
            counterStaff.setPhone(phone);
            counterStaff.setGender(gender);
            counterStaff.setDob(Date.valueOf(dobStr));
            counterStaff.setIc(nric);
            counterStaff.setAddress(address);
            
        } catch (Exception e) {
            request.setAttribute("error", "Invalid input format.");
            return false;
        }

        // Handle profile picture
        Part file = request.getPart("profilePic");
        try {
            if (file != null && file.getSize() > 0) {
                String uploadedFileName = UploadImage.uploadImage(file, "profile_pictures");
                counterStaff.setProfilePic(uploadedFileName);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Profile picture upload failed: " + e.getMessage());
            return false;
        }

        return true;
    }

    private void preserveFormData(HttpServletRequest request) throws IOException, ServletException {
        CounterStaff counterStaff = new CounterStaff();
        counterStaff.setName(readFormField(request.getPart("name")));
        counterStaff.setEmail(readFormField(request.getPart("email")));
        counterStaff.setPassword(readFormField(request.getPart("password")));
        counterStaff.setPhone(readFormField(request.getPart("phone")));
        counterStaff.setGender(readFormField(request.getPart("gender")));
        counterStaff.setIc(readFormField(request.getPart("nric")));
        counterStaff.setAddress(readFormField(request.getPart("address")));

        String dobStr = readFormField(request.getPart("dob"));
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                counterStaff.setDob(Date.valueOf(dobStr));
            } catch (Exception ignored) {
            }
        }

        request.setAttribute("counterStaff", counterStaff);
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
        return "CounterStaffServlet - Handles CRUD operations for counter staffs";
    }
}
