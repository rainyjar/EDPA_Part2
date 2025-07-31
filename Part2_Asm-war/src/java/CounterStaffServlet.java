import java.io.IOException;
import java.sql.Date;
import java.sql.Time;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.ArrayList;
import java.util.Calendar;
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
import model.Customer;
import model.CustomerFacade;
import model.Appointment;
import model.AppointmentFacade;
import model.Payment;
import model.PaymentFacade;
import model.Feedback;
import model.FeedbackFacade;
import model.Doctor;
import model.DoctorFacade;
import model.Treatment;
import model.TreatmentFacade;
import model.Schedule;
import model.ScheduleFacade;

@WebServlet(urlPatterns = {"/CounterStaffServlet"})
@MultipartConfig

public class CounterStaffServlet extends HttpServlet {

    @EJB
    private CounterStaffFacade counterStaffFacade;
    @EJB
    private CustomerFacade customerFacade;
    @EJB
    private AppointmentFacade appointmentFacade;
    @EJB
    private PaymentFacade paymentFacade;
    @EJB
    private FeedbackFacade feedbackFacade;
    @EJB
    private DoctorFacade doctorFacade;
    @EJB
    private TreatmentFacade treatmentFacade;
    @EJB
    private ScheduleFacade scheduleFacade;

    //    Handle all Counter Staff operations
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        try {
            // Check if counter staff is logged in for operations that require authentication
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

            // Validate session for authenticated operations (exclude legacy operations for manager)
            if (!isLegacyOperation(action) && !validateCounterStaffSession(loggedInStaff, request, response)) {
                return; // Session validation will handle redirect
            }

            switch (action) {
                // CUSTOMER OPERATIONS
                case "createCustomer":
                    handleCreateCustomer(request, response, loggedInStaff);
                    break;
                case "updateCustomer":
                    handleUpdateCustomer(request, response, loggedInStaff);
                    break;
                case "deleteCustomer":
                    handleDeleteCustomer(request, response, loggedInStaff);
                    break;

                // APPOINTMENT OPERATIONS
                case "bookAppointment":
                    handleBookAppointment(request, response, loggedInStaff);
                    break;
                case "rescheduleAppointment":
                    handleRescheduleAppointment(request, response, loggedInStaff);
                    break;
                case "cancelAppointment":
                    handleCancelAppointment(request, response, loggedInStaff);
                    break;
                case "assignDoctor":
                    handleAssignDoctor(request, response, loggedInStaff);
                    break;
                case "updateAppointmentStatus":
                    handleUpdateAppointmentStatus(request, response, loggedInStaff);
                    break;

                // PAYMENT OPERATIONS
                case "collectPayment":
                    handleCollectPayment(request, response, loggedInStaff);
                    break;
                case "updatePaymentStatus":
                    handleUpdatePaymentStatus(request, response, loggedInStaff);
                    break;
                case "generateReceipt":
                    handleGenerateReceipt(request, response, loggedInStaff);
                    break;

                // COUNTER STAFF PROFILE OPERATIONS can dont want
                case "updateProfile":
                    handleUpdateProfile(request, response, loggedInStaff);
                    break;

                // LEGACY OPERATIONS (for manager use) 
                case "delete":
                    handleDeleteCounterStaff(request, response);
                    break;
                case "update":
                    handleUpdateCounterStaff(request, response);
                    break;
                default:
                    handleRegisterCounterStaff(request, response);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred: " + e.getMessage());

            // Redirect based on user session
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            if (loggedInStaff != null) {
                request.getRequestDispatcher("/counter_staff/counter_homepage.jsp").forward(request, response);
            } else {
                response.sendRedirect(request.getContextPath() + "/login.jsp");
            }
        }

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
                    String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
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
        } else {
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
                    uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
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
                request.setAttribute("success", "Counter Staff registered successfully.");
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

    //    retrieve counter staff detail and handle GET requests
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        try {
            // Check for counter staff session for pages that require authentication
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");

            if ("edit".equals(action)) {
                // Manager editing counter staff - no session check needed
                int id = Integer.parseInt(request.getParameter("id"));
                CounterStaff counterStaff = counterStaffFacade.find(id);
                request.setAttribute("counterStaff", counterStaff);
                request.getRequestDispatcher("/manager/edit_cs.jsp").forward(request, response);

            } else if ("dashboard".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                loadDashboardData(request);
                // Pass logged in staff info to JSP
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/counter_homepage.jsp").forward(request, response);

            } else if ("manageCustomers".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                System.out.println("=== DEBUG: Loading customer management page for " + loggedInStaff.getName() + " ===");
                loadCustomersData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                System.out.println("=== DEBUG: Customer data loaded, forwarding to JSP ===");
                request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);

            } else if ("bookAppointment".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                loadAppointmentBookingData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/book_appointment.jsp").forward(request, response);

            } else if ("manageAppointments".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                loadAppointmentManagementData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);

            } else if ("collectPayments".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                loadPaymentData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/collect_payments.jsp").forward(request, response);

            } else if ("generateReceipts".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                loadPaymentData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/generate_receipts.jsp").forward(request, response);

            } else if ("viewTreatments".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                try {
                    List<Treatment> treatments = treatmentFacade.findAll();
                    request.setAttribute("treatments", treatments);
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("treatments", new ArrayList<Treatment>());
                }
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/view_treatments.jsp").forward(request, response);

            } else if ("viewRatings".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                try {
                    List<Feedback> feedbacks = feedbackFacade.findAll();
                    request.setAttribute("feedbacks", feedbacks);
                } catch (Exception e) {
                    e.printStackTrace();
                    request.setAttribute("feedbacks", new ArrayList<Feedback>());
                }
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/view_ratings.jsp").forward(request, response);

            } else if ("searchCustomers".equals(action)) {
                // Validate counter staff session
                if (!validateCounterStaffSession(loggedInStaff, request, response)) {
                    return;
                }
                String searchTerm = request.getParameter("search");
                if (searchTerm != null && !searchTerm.trim().isEmpty()) {
                    try {
                        List<Customer> allCustomers = customerFacade.findAll();
                        List<Customer> searchResults = new ArrayList<>();

                        for (Customer customer : allCustomers) {
                            if (customer.getName().toLowerCase().contains(searchTerm.toLowerCase())
                                    || customer.getEmail().toLowerCase().contains(searchTerm.toLowerCase())
                                    || (customer.getPhone() != null && customer.getPhone().contains(searchTerm))) {
                                searchResults.add(customer);
                            }
                        }

                        request.setAttribute("customers", searchResults);
                        request.setAttribute("searchTerm", searchTerm);
                    } catch (Exception e) {
                        e.printStackTrace();
                        request.setAttribute("customers", new ArrayList<Customer>());
                    }
                } else {
                    loadCustomersData(request);
                }
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);

            } else if ("view".equals(action)) {
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

            } else {
                // Default: show counter staff list (for manager) - no session check needed
                List<CounterStaff> counterStaff = counterStaffFacade.findAll();
                request.setAttribute("counterStaffList", counterStaff);
                request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "An error occurred: " + e.getMessage());

            // Determine which page to forward based on user type
            CounterStaff loggedInStaff = (CounterStaff) session.getAttribute("staff");
            if (loggedInStaff != null) {
                // Counter staff user - go to dashboard
                loadDashboardData(request);
                request.setAttribute("loggedInStaff", loggedInStaff);
                request.getRequestDispatcher("/counter_staff/counter_homepage.jsp").forward(request, response);
            } else {
                // Manager or other user - go to list or login
                response.sendRedirect(request.getContextPath() + "/login.jsp");
            }
        }
    }

    private void loadDashboardData(HttpServletRequest request) {
        try {
            // Get all customers
            List<Customer> allCustomers = customerFacade.findAll();
            int totalCustomers = allCustomers != null ? allCustomers.size() : 0;

            // Get all appointments
            List<Appointment> allAppointments = appointmentFacade.findAll();
            int totalAppointments = allAppointments != null ? allAppointments.size() : 0;

            // Count appointments by status
            int pendingAppointmentCount = 0;
            int overdueAppointments = 0;
            int completedAppointments = 0;
            int approvedAppointments = 0;
            List<Appointment> recentAppointments = new ArrayList<>();
            List<Appointment> todayAppointments = new ArrayList<>();

            if (allAppointments != null) {
                for (Appointment apt : allAppointments) {
                    if (apt.getStatus() != null) {
                        String status = apt.getStatus().toLowerCase();
                        switch (status) {
                            case "pending":
                                pendingAppointmentCount++;
                                break;
                            case "overdue":
                                overdueAppointments++;
                                break;
                            case "completed":
                                completedAppointments++;
                                break;
                            case "approved":
                                approvedAppointments++;
                                break;
                        }
                    }
                }
                // Get recent appointments (limit to 10)
                recentAppointments = allAppointments.size() > 10
                        ? allAppointments.subList(0, 10)
                        : allAppointments;

                // For simplicity, using recent appointments as today's appointments
                todayAppointments = recentAppointments;
            }

            // Get all payments
            List<Payment> allPayments = paymentFacade.findAll();
            int pendingPaymentCount = 0;
            double totalPayment = 0.0;
            double todayPayment = 0.0;
            List<Payment> pendingPayments = new ArrayList<>();

            // Get today's date
            LocalDate today = LocalDate.now();

            if (allPayments != null) {
                for (Payment payment : allPayments) {
                    if (payment.getStatus() != null) {
                        String status = payment.getStatus().toLowerCase();
                        if ("pending".equals(status)) {
                            pendingPaymentCount++;
                            pendingPayments.add(payment);
                        } else if ("completed".equals(status) || "paid".equals(status)) {
                            // Count total payment
                            totalPayment += payment.getAmount();

                            // Check if payment was made today
                            if (payment.getPaymentDate() != null) {
                                LocalDate paymentDate = payment.getPaymentDate()
                                        .toInstant()
                                        .atZone(ZoneId.systemDefault())
                                        .toLocalDate();
                                if (paymentDate.isEqual(today)) {
                                    todayPayment += payment.getAmount();
                                }
                            }
                        }
                    }
                }
            }

            // Get all feedbacks
            List<Feedback> allFeedbacks = feedbackFacade.findAll();
            List<Feedback> recentFeedbacks = new ArrayList<>();
            if (allFeedbacks != null) {
                recentFeedbacks = allFeedbacks.size() > 5
                        ? allFeedbacks.subList(0, 5)
                        : allFeedbacks;
            }

            // Get recent customers (limit to 10)
            List<Customer> recentCustomers = allCustomers != null && allCustomers.size() > 10
                    ? allCustomers.subList(0, 10)
                    : allCustomers;

            // Set all attributes for the JSP
            request.setAttribute("totalCustomers", totalCustomers);
            request.setAttribute("totalAppointments", totalAppointments);
            request.setAttribute("pendingAppointmentCount", pendingAppointmentCount);
            request.setAttribute("overdueAppointments", overdueAppointments);
            request.setAttribute("completedAppointments", completedAppointments);
            request.setAttribute("approvedAppointments", approvedAppointments);
            request.setAttribute("pendingPaymentCount", pendingPaymentCount);
            request.setAttribute("totalPayment", totalPayment); // Total payment collected
            request.setAttribute("todayPayment", todayPayment); // Today's payment collected

            // Set list attributes
            request.setAttribute("recentCustomers", recentCustomers);
            request.setAttribute("recentAppointments", recentAppointments);
            request.setAttribute("todayAppointments", todayAppointments);
            request.setAttribute("pendingPayments", pendingPayments);
            request.setAttribute("recentFeedbacks", recentFeedbacks);

        } catch (Exception e) {
            e.printStackTrace();
            // Set default values in case of error
            request.setAttribute("totalCustomers", 0);
            request.setAttribute("totalAppointments", 0);
            request.setAttribute("pendingAppointmentCount", 0);
            request.setAttribute("overdueAppointments", 0);
            request.setAttribute("completedAppointments", 0);
            request.setAttribute("approvedAppointments", 0);
            request.setAttribute("pendingPaymentCount", 0);
            request.setAttribute("totalPayment", 0.0);

            request.setAttribute("recentCustomers", new ArrayList<Customer>());
            request.setAttribute("recentAppointments", new ArrayList<Appointment>());
            request.setAttribute("todayAppointments", new ArrayList<Appointment>());
            request.setAttribute("pendingPayments", new ArrayList<Payment>());
            request.setAttribute("recentFeedbacks", new ArrayList<Feedback>());
        }
    }

    // ==================== CUSTOMER OPERATIONS ====================
    /**
     * Handle customer creation by counter staff
     */
    private void handleCreateCustomer(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
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
                request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
                return;
            }

            // Parse date of birth
            Date dob = null;
            if (dobStr != null && !dobStr.isEmpty()) {
                try {
                    dob = Date.valueOf(dobStr);
                } catch (IllegalArgumentException e) {
                    request.setAttribute("error", "Invalid date format. Please use YYYY-MM-DD.");
                    request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
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
                    // Log error but continue without profile picture
                    System.err.println("Profile picture upload failed: " + e.getMessage());
                }
            }

            // Create new customer
            Customer customer = new Customer();
            customer.setName(name);
            customer.setEmail(email);
            customer.setPassword(password);
            customer.setPhone(phone);
            customer.setGender(gender);
            customer.setDob(dob);
            if (uploadedFileName != null) {
                customer.setProfilePic(uploadedFileName);
            }

            customerFacade.create(customer);
            request.setAttribute("success", "Customer created successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to create customer: " + e.getMessage());
        }

        // Reload customers list and forward to management page
        loadCustomersData(request);
        request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
    }

    /**
     * Handle customer update by counter staff
     */
    private void handleUpdateCustomer(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Customer customer = customerFacade.find(id);

            if (customer != null) {
                customer.setName(request.getParameter("name"));
                customer.setEmail(request.getParameter("email"));
                if (request.getParameter("password") != null && !request.getParameter("password").isEmpty()) {
                    customer.setPassword(request.getParameter("password"));
                }
                customer.setPhone(request.getParameter("phone"));
                customer.setGender(request.getParameter("gender"));

                String dobStr = request.getParameter("dob");
                if (dobStr != null && !dobStr.isEmpty()) {
                    try {
                        customer.setDob(Date.valueOf(dobStr));
                    } catch (IllegalArgumentException e) {
                        request.setAttribute("error", "Invalid date format. Please use YYYY-MM-DD.");
                        request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
                        return;
                    }
                }

                // Handle profile picture update if provided
                Part file = request.getPart("profilePic");
                if (file != null && file.getSize() > 0) {
                    try {
                        String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                        if (uploadedFileName != null) {
                            customer.setProfilePic(uploadedFileName);
                        }
                    } catch (Exception e) {
                        System.err.println("Profile picture upload failed: " + e.getMessage());
                    }
                }

                customerFacade.edit(customer);
                request.setAttribute("success", "Customer updated successfully.");
            } else {
                request.setAttribute("error", "Customer not found.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to update customer: " + e.getMessage());
        }

        loadCustomersData(request);
        request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
    }

    /**
     * Handle customer deletion by counter staff
     */
    private void handleDeleteCustomer(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            Customer customer = customerFacade.find(id);

            if (customer != null) {
                // Check if customer has active appointments - simplified check
                // In a real implementation, you'd have a findByCustomer method
                customerFacade.remove(customer);
                request.setAttribute("success", "Customer deleted successfully.");
            } else {
                request.setAttribute("error", "Customer not found.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to delete customer: " + e.getMessage());
        }

        loadCustomersData(request);
        request.getRequestDispatcher("/counter_staff/manage_customers.jsp").forward(request, response);
    }

    // ==================== APPOINTMENT OPERATIONS ====================
    /**
     * Handle appointment booking by counter staff
     */
    private void handleBookAppointment(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int customerId = Integer.parseInt(request.getParameter("customerId"));
            int treatmentId = Integer.parseInt(request.getParameter("treatmentId"));
            String appointmentDateStr = request.getParameter("appointmentDate");
            String appointmentTimeStr = request.getParameter("appointmentTime");

            // Validate appointment date and time
            if (!isValidAppointmentDateTime(appointmentDateStr, appointmentTimeStr)) {
                request.setAttribute("error", "Invalid appointment date/time. Appointments are only available on weekdays from 9:00 AM to 5:00 PM, from today to next week.");
                loadAppointmentBookingData(request);
                request.getRequestDispatcher("/counter_staff/book_appointment.jsp").forward(request, response);
                return;
            }

            Customer customer = customerFacade.find(customerId);
            Treatment treatment = treatmentFacade.find(treatmentId);

            if (customer == null || treatment == null) {
                request.setAttribute("error", "Invalid customer or treatment selected.");
                loadAppointmentBookingData(request);
                request.getRequestDispatcher("/counter_staff/book_appointment.jsp").forward(request, response);
                return;
            }

            // Parse date and time
            Date appointmentDate = Date.valueOf(appointmentDateStr);
            Time appointmentTime = Time.valueOf(appointmentTimeStr + ":00");

            // Check if time slot is available
            if (!isTimeSlotAvailable(appointmentDate, appointmentTime)) {
                request.setAttribute("error", "The selected time slot is not available. Please choose another time.");
                loadAppointmentBookingData(request);
                request.getRequestDispatcher("/counter_staff/book_appointment.jsp").forward(request, response);
                return;
            }

            // Create appointment
            Appointment appointment = new Appointment();
            appointment.setCustomer(customer);
            appointment.setTreatment(treatment);
            appointment.setAppointmentDate(appointmentDate);
            appointment.setAppointmentTime(appointmentTime);
            appointment.setStatus("pending"); // Default status

            appointmentFacade.create(appointment);

            // Create corresponding payment record
            Payment payment = new Payment();
            payment.setAppointment(appointment);
            payment.setAmount(treatment.getBaseConsultationCharge());
            payment.setStatus("pending");
            payment.setPaymentDate(new Date(System.currentTimeMillis()));
            paymentFacade.create(payment);

            request.setAttribute("success", "Appointment booked successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to book appointment: " + e.getMessage());
        }

        loadAppointmentBookingData(request);
        request.getRequestDispatcher("/counter_staff/book_appointment.jsp").forward(request, response);
    }

    /**
     * Handle appointment status update by counter staff
     */
    private void handleUpdateAppointmentStatus(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            String newStatus = request.getParameter("newStatus");

            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            // Validate status change
            if (!isValidStatusChange(appointment.getStatus(), newStatus)) {
                request.setAttribute("error", "Invalid status change from " + appointment.getStatus() + " to " + newStatus);
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            appointment.setStatus(newStatus);
            appointmentFacade.edit(appointment);

            request.setAttribute("success", "Appointment status updated successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to update appointment status: " + e.getMessage());
        }

        loadAppointmentManagementData(request);
        request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
    }

    /**
     * Handle doctor assignment to appointment by counter staff
     */
    private void handleAssignDoctor(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            int doctorId = Integer.parseInt(request.getParameter("doctorId"));

            Appointment appointment = appointmentFacade.find(appointmentId);
            Doctor doctor = doctorFacade.find(doctorId);

            if (appointment == null || doctor == null) {
                request.setAttribute("error", "Invalid appointment or doctor selected.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            // Assign doctor and change status to approved
            appointment.setDoctor(doctor);
            appointment.setStatus("approved");
            appointmentFacade.edit(appointment);

            request.setAttribute("success", "Doctor assigned successfully. Appointment status changed to approved.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to assign doctor: " + e.getMessage());
        }

        loadAppointmentManagementData(request);
        request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
    }

    /**
     * Handle appointment rescheduling by counter staff
     */
    private void handleRescheduleAppointment(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));
            String newDateStr = request.getParameter("newDate");
            String newTimeStr = request.getParameter("newTime");

            // Validate new appointment date and time
            if (!isValidAppointmentDateTime(newDateStr, newTimeStr)) {
                request.setAttribute("error", "Invalid appointment date/time. Appointments are only available on weekdays from 9:00 AM to 5:00 PM, from today to next week.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            // Parse new date and time
            Date newDate = Date.valueOf(newDateStr);
            Time newTime = Time.valueOf(newTimeStr + ":00");

            // Check if new time slot is available
            if (!isTimeSlotAvailable(newDate, newTime)) {
                request.setAttribute("error", "The selected time slot is not available. Please choose another time.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            // Update appointment
            appointment.setAppointmentDate(newDate);
            appointment.setAppointmentTime(newTime);
            appointment.setStatus("pending"); // Reset to pending after reschedule
            appointmentFacade.edit(appointment);

            request.setAttribute("success", "Appointment rescheduled successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to reschedule appointment: " + e.getMessage());
        }

        loadAppointmentManagementData(request);
        request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
    }

    /**
     * Handle appointment cancellation by counter staff
     */
    private void handleCancelAppointment(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int appointmentId = Integer.parseInt(request.getParameter("appointmentId"));

            Appointment appointment = appointmentFacade.find(appointmentId);
            if (appointment == null) {
                request.setAttribute("error", "Appointment not found.");
                loadAppointmentManagementData(request);
                request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
                return;
            }

            // Cancel appointment
            appointment.setStatus("cancelled");
            appointmentFacade.edit(appointment);

            // Also update any associated payment status
            try {
                List<Payment> payments = paymentFacade.findAll();
                for (Payment payment : payments) {
                    if (payment.getAppointment() != null
                            && payment.getAppointment().getId() == appointmentId
                            && "pending".equalsIgnoreCase(payment.getStatus())) {
                        payment.setStatus("cancelled");
                        paymentFacade.edit(payment);
                        break;
                    }
                }
            } catch (Exception e) {
                System.err.println("Error updating payment status: " + e.getMessage());
            }

            request.setAttribute("success", "Appointment cancelled successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to cancel appointment: " + e.getMessage());
        }

        loadAppointmentManagementData(request);
        request.getRequestDispatcher("/counter_staff/manage_appointments.jsp").forward(request, response);
    }

    // ==================== PAYMENT OPERATIONS ====================
    /**
     * Handle payment collection by counter staff
     */
    private void handleCollectPayment(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int paymentId = Integer.parseInt(request.getParameter("paymentId"));
            String paymentMethod = request.getParameter("paymentMethod");

            Payment payment = paymentFacade.find(paymentId);
            if (payment == null) {
                request.setAttribute("error", "Payment not found.");
                loadPaymentData(request);
                request.getRequestDispatcher("/counter_staff/collect_payments.jsp").forward(request, response);
                return;
            }

            // Update payment status
            payment.setStatus("paid");
            payment.setPaymentMethod(paymentMethod);
            payment.setPaymentDate(new Date(System.currentTimeMillis()));
            paymentFacade.edit(payment);

            request.setAttribute("success", "Payment collected successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to collect payment: " + e.getMessage());
        }

        loadPaymentData(request);
        request.getRequestDispatcher("/counter_staff/collect_payments.jsp").forward(request, response);
    }

    /**
     * Handle payment status update by counter staff
     */
    private void handleUpdatePaymentStatus(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int paymentId = Integer.parseInt(request.getParameter("paymentId"));
            String newStatus = request.getParameter("newStatus");

            Payment payment = paymentFacade.find(paymentId);
            if (payment == null) {
                request.setAttribute("error", "Payment not found.");
                loadPaymentData(request);
                request.getRequestDispatcher("/counter_staff/collect_payments.jsp").forward(request, response);
                return;
            }

            payment.setStatus(newStatus);
            paymentFacade.edit(payment);

            request.setAttribute("success", "Payment status updated successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to update payment status: " + e.getMessage());
        }

        loadPaymentData(request);
        request.getRequestDispatcher("/counter_staff/collect_payments.jsp").forward(request, response);
    }

    /**
     * Handle receipt generation by counter staff
     */
    private void handleGenerateReceipt(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        try {
            int paymentId = Integer.parseInt(request.getParameter("paymentId"));

            Payment payment = paymentFacade.find(paymentId);
            if (payment == null || !"paid".equalsIgnoreCase(payment.getStatus())) {
                request.setAttribute("error", "Payment not found or not paid yet.");
                loadPaymentData(request);
                request.getRequestDispatcher("/counter_staff/generate_receipts.jsp").forward(request, response);
                return;
            }

            // Redirect to receipt servlet for PDF generation
            response.sendRedirect(request.getContextPath() + "/ReceiptServlet?paymentId=" + paymentId);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to generate receipt: " + e.getMessage());
            loadPaymentData(request);
            request.getRequestDispatcher("/counter_staff/generate_receipts.jsp").forward(request, response);
        }
    }

    // ==================== UTILITY METHODS ====================
    /**
     * Validate appointment date and time
     */
    private boolean isValidAppointmentDateTime(String dateStr, String timeStr) {
        if (dateStr == null || timeStr == null) {
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
    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response,
            CounterStaff loggedInStaff) throws ServletException, IOException {
        // Redirect to Profile servlet for profile updates
        response.sendRedirect(request.getContextPath() + "/Profile?action=update");
    }

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
    private void handleRegisterCounterStaff(HttpServletRequest request, HttpServletResponse response)
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
            counterStaff.setDob(dob);
            if (uploadedFileName != null) {
                counterStaff.setProfilePic(uploadedFileName);
            }

            counterStaffFacade.create(counterStaff);
            request.setAttribute("success", "Counter staff registered successfully.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to register counter staff: " + e.getMessage());
        }

        // Reload counter staff list and forward to management page
        List<CounterStaff> counterStaff = counterStaffFacade.findAll();
        request.setAttribute("counterStaffList", counterStaff);
        request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
    }

    /**
     * Handle counter staff update by manager
     */
    private void handleUpdateCounterStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counterStaff = counterStaffFacade.find(id);

            if (counterStaff != null) {
                counterStaff.setName(request.getParameter("name"));
                counterStaff.setEmail(request.getParameter("email"));
                if (request.getParameter("password") != null && !request.getParameter("password").isEmpty()) {
                    counterStaff.setPassword(request.getParameter("password"));
                }
                counterStaff.setPhone(request.getParameter("phone"));
                counterStaff.setGender(request.getParameter("gender"));

                String dobStr = request.getParameter("dob");
                if (dobStr != null && !dobStr.isEmpty()) {
                    try {
                        counterStaff.setDob(Date.valueOf(dobStr));
                    } catch (IllegalArgumentException e) {
                        request.setAttribute("error", "Invalid date format. Please use YYYY-MM-DD.");
                        List<CounterStaff> counterStaffList = counterStaffFacade.findAll();
                        request.setAttribute("counterStaffList", counterStaffList);
                        request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
                        return;
                    }
                }

                // Handle profile picture update if provided
                Part file = request.getPart("profilePic");
                if (file != null && file.getSize() > 0) {
                    try {
                        String uploadedFileName = UploadImage.uploadProfilePicture(file, getServletContext());
                        if (uploadedFileName != null) {
                            counterStaff.setProfilePic(uploadedFileName);
                        }
                    } catch (Exception e) {
                        System.err.println("Profile picture upload failed: " + e.getMessage());
                    }
                }

                counterStaffFacade.edit(counterStaff);
                request.setAttribute("success", "Counter staff updated successfully.");
            } else {
                request.setAttribute("error", "Counter staff not found.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to update counter staff: " + e.getMessage());
        }

        List<CounterStaff> counterStaff = counterStaffFacade.findAll();
        request.setAttribute("counterStaffList", counterStaff);
        request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
    }

    /**
     * Handle counter staff deletion by manager
     */
    private void handleDeleteCounterStaff(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            CounterStaff counterStaff = counterStaffFacade.find(id);

            if (counterStaff != null) {
                counterStaffFacade.remove(counterStaff);
                request.setAttribute("success", "Counter staff deleted successfully.");
            } else {
                request.setAttribute("error", "Counter staff not found.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to delete counter staff: " + e.getMessage());
        }

        List<CounterStaff> counterStaff = counterStaffFacade.findAll();
        request.setAttribute("counterStaffList", counterStaff);
        request.getRequestDispatcher("/manager/list_cs.jsp").forward(request, response);
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
